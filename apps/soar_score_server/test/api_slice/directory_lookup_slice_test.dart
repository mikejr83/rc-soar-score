import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';
const _email = 'pat.pilot@example.com';

/// A director finds a listed pilot in the directory and copies them (#653),
/// over a real database.
void main() {
  final postgresMissing = PostgresConfig.fromEnvironment() == null;
  for (final backend in SliceBackend.values) {
    group(
      backend.name,
      () => _tests(backend),
      skip: backend == SliceBackend.postgres && postgresMissing
          ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD)'
          : false,
    );
  }
}

void _tests(SliceBackend backend) {
  late SliceClient api;
  late core.Repository repository;
  late core.Id dana; // the harness director
  late core.Id sam; // a second director
  late core.Id pat; // a listed pilot, email private
  final now = DateTime.utc(2026, 11, 26, 12);
  final callers = <core.Id, Handler>{};
  final logs = <String>[];

  Future<core.Id> account(
    String first, {
    core.AccountKind kind = core.AccountKind.registered,
    String? email,
    bool verified = true,
  }) async {
    final id = core.Id.create();
    await repository.accountRepository.save(
      core.Account(
        id: id,
        firstName: first,
        lastName: 'Account',
        email: email,
        emailVerified: email != null && verified,
        kind: kind,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<core.ParticipantDirectoryEntry> entry(
    core.Id accountId, {
    bool listed = true,
    bool emailVisible = false,
    String? fai,
    String? national,
  }) => repository.participantDirectoryEntryRepository.save(
    core.ParticipantDirectoryEntry(
      id: core.Id.create(),
      accountId: accountId,
      firstName: 'Pat',
      lastName: 'Pilot',
      club: 'Soar Club',
      faiNumber: fai,
      nationalOrgId: national,
      isListed: listed,
      emailVisibleToDirectors: emailVisible,
      createdAt: now,
      updatedAt: now,
    ),
  );

  Future<({int status, Map<String, Object?> json, String text})> call(
    core.Id as,
    String path, {
    Object? body,
    String method = 'POST',
  }) async {
    final handler = callers.putIfAbsent(
      as,
      () => createServerHandler(
        api.database,
        authMiddleware: fixedPrincipal(Principal(accountId: as)),
        invitationSecret: _secret,
      ),
    );
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost/api/v1$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {'content-type': 'application/json'},
      ),
    );
    final text = await response.readAsString();
    return (
      status: response.statusCode,
      json: text.isEmpty
          ? const <String, Object?>{}
          : jsonDecode(text) as Map<String, Object?>,
      text: text,
    );
  }

  Future<List<Object?>> lookup(core.Id as, String key, String value) async {
    final r = await call(
      as,
      '/directory/lookups',
      body: {'key': key, 'value': value},
    );
    expect(r.status, 200, reason: r.text);
    return r.json['results']! as List<Object?>;
  }

  Map<String, Object?> copyBody(core.Id entryId, core.Id profileId) => {
    'entry_id': entryId.value,
    'profile_id': profileId.value,
  };

  setUp(() async {
    logs.clear();
    callers.clear();
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
    dana = api.director;
    sam = await account('Sam');
    pat = await account('Pat', email: _email);
  });

  tearDown(() => api.close());

  group('lookup', () {
    test('finds a listed pilot by each of the three keys', () async {
      await entry(pat, fai: 'FAI-123', national: 'NSS-9');

      for (final (key, value) in [
        ('email', ' Pat.Pilot@Example.com '),
        ('fai_number', 'FAI-123'),
        ('national_org_id', 'NSS-9'),
      ]) {
        final results = await lookup(dana, key, value);
        expect(results, hasLength(1), reason: key);
        final match = results.single! as Map<String, Object?>;
        expect(match['first_name'], 'Pat');
        expect(match['club'], 'Soar Club');
      }
    });

    test('an unlisted pilot looks exactly like a nonexistent one', () async {
      await entry(pat, listed: false, fai: 'FAI-123');

      final unlisted = await call(
        dana,
        '/directory/lookups',
        body: {'key': 'fai_number', 'value': 'FAI-123'},
      );
      final nobody = await call(
        dana,
        '/directory/lookups',
        body: {'key': 'fai_number', 'value': 'FAI-999'},
      );
      final byEmail = await call(
        dana,
        '/directory/lookups',
        body: {'key': 'email', 'value': _email},
      );

      expect(unlisted.status, 200);
      expect(unlisted.text, nobody.text);
      expect(byEmail.text, nobody.text);
    });

    test('an unverified email finds nothing', () async {
      final unverified = await account(
        'Una',
        email: 'una@example.com',
        verified: false,
      );
      await entry(unverified);

      expect(await lookup(dana, 'email', 'una@example.com'), isEmpty);
    });

    test('shows the email only when the pilot made it visible', () async {
      final visible = await account('Vic', email: 'vic@example.com');
      await entry(pat, fai: 'F1');
      await entry(visible, emailVisible: true, fai: 'F1');

      final results = await lookup(dana, 'fai_number', 'F1');

      final byFirst = {
        for (final r in results.cast<Map<String, Object?>>()) r['entry_id']: r,
      };
      final emails = byFirst.values.map((r) => r['email']).toSet();
      expect(emails, {null, 'vic@example.com'});
      for (final r in byFirst.values) {
        expect(r['email_available'], isTrue);
      }
      expect(jsonEncode(results), isNot(contains(_email)));
    });

    test('a private email appears in no response', () async {
      await entry(pat, fai: 'F1');

      final lookupResponse = await call(
        dana,
        '/directory/lookups',
        body: {'key': 'email', 'value': _email},
      );
      final profile = core.Id.create();
      final stored = await repository.participantDirectoryEntryRepository
          .findForAccount(pat);
      final copyResponse = await call(
        dana,
        '/directory/copies',
        body: copyBody(stored!.id, profile),
      );

      expect(lookupResponse.status, 200);
      expect(lookupResponse.text, isNot(contains(_email)));
      expect(copyResponse.status, 200, reason: copyResponse.text);
      expect(copyResponse.text, isNot(contains(_email)));
    });

    test('guest and local accounts cannot look up', () async {
      final guest = await account('Gus', kind: core.AccountKind.guest);

      final r = await call(
        guest,
        '/directory/lookups',
        body: {'key': 'fai_number', 'value': 'F1'},
      );

      expect(r.status, 403);
      expect((r.json['error']! as Map)['code'], 'registered_account_required');
    });

    test('a blank value is refused', () async {
      final r = await call(
        dana,
        '/directory/lookups',
        body: {'key': 'email', 'value': '  '},
      );

      expect(r.status, 400);
    });

    test('lookups are rate limited per account', () async {
      for (var i = 0; i < 60; i++) {
        await call(
          dana,
          '/directory/lookups',
          body: {'key': 'fai_number', 'value': 'F$i'},
        );
      }

      final r = await call(
        dana,
        '/directory/lookups',
        body: {'key': 'fai_number', 'value': 'F61'},
      );
      final other = await call(
        sam,
        '/directory/lookups',
        body: {'key': 'fai_number', 'value': 'F61'},
      );

      expect(r.status, 429);
      expect(other.status, 200);
    });
  });

  group('copy', () {
    late core.ParticipantDirectoryEntry patEntry;
    late core.Id profile;

    setUp(() async {
      patEntry = await entry(pat, fai: 'F1');
      profile = core.Id.create();
    });

    test(
      'links the pilot, leaves the entry alone, and is a no-op twice',
      () async {
        final before = await repository.participantDirectoryEntryRepository
            .findForAccount(pat);

        final first = await call(
          dana,
          '/directory/copies',
          body: copyBody(patEntry.id, profile),
        );
        final second = await call(
          dana,
          '/directory/copies',
          body: copyBody(patEntry.id, profile),
        );

        expect(first.status, 200, reason: first.text);
        expect(second.json, first.json);
        final links = await repository.participantAccountLinkRepository
            .listForAccount(pat);
        expect(links, hasLength(1));
        expect(links.single.participantProfileId, profile);
        expect(links.single.origin, core.ParticipantLinkOrigin.directoryPull);
        expect(links.single.status, core.ParticipantLinkStatus.confirmed);
        expect(
          await repository.participantDirectoryEntryRepository.findForAccount(
            pat,
          ),
          before,
        );
        final seen = await call(pat, '/account/links', method: 'GET');
        expect(seen.json['links'], hasLength(1));
      },
    );

    test('several directors can copy the same pilot', () async {
      final danaProfile = core.Id.create();
      final samProfile = core.Id.create();

      final a = await call(
        dana,
        '/directory/copies',
        body: copyBody(patEntry.id, danaProfile),
      );
      final b = await call(
        sam,
        '/directory/copies',
        body: copyBody(patEntry.id, samProfile),
      );

      expect(a.status, 200, reason: a.text);
      expect(b.status, 200, reason: b.text);
      final links = await repository.participantAccountLinkRepository
          .listForAccount(pat);
      expect(links.map((l) => l.participantProfileId).toSet(), {
        danaProfile,
        samProfile,
      });
    });

    test('an unlisted or unknown entry is 404 link_not_found', () async {
      final unlisted = await account('Una', email: 'una@example.com');
      final hidden = await entry(unlisted, listed: false);

      final a = await call(
        dana,
        '/directory/copies',
        body: copyBody(hidden.id, profile),
      );
      final b = await call(
        dana,
        '/directory/copies',
        body: copyBody(core.Id.create(), profile),
      );

      expect(a.status, 404);
      expect((a.json['error']! as Map)['code'], 'link_not_found');
      expect((b.json['error']! as Map)['code'], 'link_not_found');
    });

    test('a director cannot link a profile another director owns', () async {
      final owned = core.Id.create();
      final created = await call(
        sam,
        '/participants',
        body: {'id': owned.value, 'first_name': 'Pat', 'last_name': 'Pilot'},
      );
      expect(created.status, 201, reason: created.text);

      final r = await call(
        dana,
        '/directory/copies',
        body: copyBody(patEntry.id, owned),
      );

      expect(r.status, 403);
      expect((r.json['error']! as Map)['code'], 'profile_not_owned');
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });
  });

  group('refresh', () {
    late core.ParticipantDirectoryEntry patEntry;
    late core.Id profile;

    setUp(() async {
      patEntry = await entry(pat, fai: 'F1');
      profile = core.Id.create();
      final created = await call(
        dana,
        '/participants',
        body: {'id': profile.value, 'first_name': 'Pat', 'last_name': 'Pilot'},
      );
      expect(created.status, 201, reason: created.text);
    });

    test('returns the current details to the director who copied', () async {
      await call(
        dana,
        '/directory/copies',
        body: copyBody(patEntry.id, profile),
      );
      await repository.participantDirectoryEntryRepository.save(
        core.ParticipantDirectoryEntry(
          id: patEntry.id,
          accountId: pat,
          firstName: 'Patricia',
          lastName: 'Pilot',
          faiNumber: 'F1',
          isListed: true,
          createdAt: now,
          updatedAt: now.add(const Duration(days: 1)),
        ),
      );

      final r = await call(
        dana,
        '/directory/refreshes',
        body: copyBody(patEntry.id, profile),
      );

      expect(r.status, 200, reason: r.text);
      expect(r.json['first_name'], 'Patricia');
      expect(r.text, isNot(contains(_email)));
    });

    test('refuses a director who has not copied this pilot', () async {
      await call(
        dana,
        '/directory/copies',
        body: copyBody(patEntry.id, profile),
      );

      final other = await call(
        sam,
        '/directory/refreshes',
        body: copyBody(patEntry.id, core.Id.create()),
      );
      final borrowed = await call(
        sam,
        '/directory/refreshes',
        body: copyBody(patEntry.id, profile),
      );

      expect(other.status, 404);
      expect(borrowed.status, 404);
    });

    test('waits for a profile that has not synced yet', () async {
      final unsynced = core.Id.create();
      await call(
        dana,
        '/directory/copies',
        body: copyBody(patEntry.id, unsynced),
      );

      final theirs = await call(
        sam,
        '/directory/refreshes',
        body: copyBody(patEntry.id, unsynced),
      );
      final own = await call(
        dana,
        '/directory/refreshes',
        body: copyBody(patEntry.id, unsynced),
      );

      expect(theirs.status, 404);
      expect(own.status, 404);
    });

    test('stops once the pilot unlists', () async {
      await call(
        dana,
        '/directory/copies',
        body: copyBody(patEntry.id, profile),
      );
      await repository.participantDirectoryEntryRepository.save(
        core.ParticipantDirectoryEntry(
          id: patEntry.id,
          accountId: pat,
          firstName: 'Pat',
          lastName: 'Pilot',
          isListed: false,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final r = await call(
        dana,
        '/directory/refreshes',
        body: copyBody(patEntry.id, profile),
      );

      expect(r.status, 404);
    });
  });
}
