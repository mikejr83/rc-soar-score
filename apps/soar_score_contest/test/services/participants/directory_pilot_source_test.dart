import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/participants/directory_pilot_source.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

final _entryA = Id.parse('019c0000-0000-7000-8000-0000000000a1');
final _entryB = Id.parse('019c0000-0000-7000-8000-0000000000b1');

Map<String, Object?> _match(Id id, String first, {String? email}) => {
  'entry_id': id.value,
  'first_name': first,
  'last_name': 'Pilot',
  'club': 'Soar Club',
  'fai_number': 'F1',
  'national_org_id': null,
  'city': null,
  'state': null,
  'country': null,
  'email': email,
  'email_available': true,
};

/// A director's search of the pilot directory and the copy into their list
/// (#653), against a canned server.
void main() {
  late List<http.Request> hostedRequests;
  late List<http.Request> localRequests;
  late Map<String, List<Map<String, Object?>>> byKey;
  late Map<String, int> failKeys; // lookup key -> status to answer with

  final created = <String, Map<String, Object?>>{};
  var localLosesAnswer = false;
  var copyAnswer = 0; // 0: answers, else the status to fail with
  var copyCommits = false; // the failure comes after the server committed

  DirectoryPilotSource source({
    LocalUiStore? store,
    DateTime Function()? clock,
  }) => DirectoryPilotSource(
    clock: clock,
    pause: const Duration(milliseconds: 5),
    store: store,
    accountId: 'dana',
    hosted: ApiClient(
      baseUrl: Uri.parse('http://hosted.invalid'),
      tokenProvider: () async => 'token',
      httpClient: MockClient((request) async {
        hostedRequests.add(request);
        final path = request.url.path;
        if (path.endsWith('/directory/lookups')) {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          final failure = failKeys[body['key']];
          if (failure != null) {
            return http.Response(
              jsonEncode({
                'error': {'code': 'rate_limited', 'message': 'slow down'},
              }),
              failure,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'results': byKey[body['key']] ?? const []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (copyAnswer != 0) {
          if (copyCommits) throw http.ClientException('lost', request.url);
          return http.Response(
            jsonEncode({
              'error': {'code': 'link_not_found', 'message': 'gone'},
            }),
            copyAnswer,
            headers: {'content-type': 'application/json'},
          );
        }
        final body = jsonDecode(request.body) as Map<String, Object?>;
        final entry = body['entry_id'] == _entryA.value
            ? _match(_entryA, 'Pat', email: 'pat@example.com')
            : _match(_entryB, 'Bea');
        return http.Response(
          jsonEncode(entry),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
    local: ApiClient(
      baseUrl: Uri.parse('http://local.invalid'),
      httpClient: MockClient((request) async {
        localRequests.add(request);
        Map<String, Object?> row(Map<String, Object?> body) => {
          ...body,
          'owner_account_id': Id.create().value,
          'created_at': '2026-11-26T12:00:00Z',
          'updated_at': '2026-11-26T12:00:00Z',
        };
        http.Response ok(Map<String, Object?> body, int status) =>
            http.Response(
              jsonEncode(row(body)),
              status,
              headers: {'content-type': 'application/json'},
            );
        if (request.method == 'GET') {
          final id = request.url.pathSegments.last;
          return ok(created[id]!, 200);
        }
        final body = jsonDecode(request.body) as Map<String, Object?>;
        final id = body['id']! as String;
        final stored = created[id];
        if (stored != null && jsonEncode(stored) != jsonEncode(body)) {
          return http.Response(
            jsonEncode({
              'error': {'code': 'conflict', 'message': 'different'},
            }),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        created[id] = body;
        if (localLosesAnswer) {
          localLosesAnswer = false;
          throw http.ClientException('lost', request.url);
        }
        return ok(body, 201);
      }),
    ),
  );

  setUp(() {
    hostedRequests = [];
    localRequests = [];
    byKey = {};
    failKeys = {};
    copyAnswer = 0;
    copyCommits = false;
    created.clear();
    localLosesAnswer = false;
  });

  test('text that cannot be a key makes no request', () async {
    final s = source();

    for (final text in [
      '',
      'ab',
      'pat@',
      'two words 123',
      'a@b',
      'a@b.c',
      'a@b.c1',
      'Zephyr',
    ]) {
      expect(await s.search(text), isEmpty, reason: text);
    }

    expect(hostedRequests, isEmpty);
  });

  test('an email is looked up as an email only', () async {
    byKey['email'] = [_match(_entryA, 'Pat')];
    final s = source();

    final found = await s.search(' pat@example.com ');

    expect(found.map((c) => c.name), ['Pat Pilot']);
    expect(hostedRequests, hasLength(1));
    final sent = jsonDecode(hostedRequests.single.body) as Map<String, Object?>;
    expect(sent, {'key': 'email', 'value': 'pat@example.com'});
  });

  List<String> keysAsked() => [
    for (final r in hostedRequests)
      (jsonDecode(r.body) as Map<String, Object?>)['key']! as String,
  ];

  test('an ID with an @ is only asked on purpose', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    // Typing text with an @ asks the email key at most (never the IDs).
    expect(await s.search('F@12'), isEmpty);
    expect(await s.search('f1@x.org2'), isEmpty);
    expect(hostedRequests, isEmpty);
    expect(await s.search('f1@x.org'), isEmpty);
    expect(keysAsked(), ['email']);

    // The lookup button asks the ID keys, for any text.
    hostedRequests.clear();
    expect((await s.lookup('F@12')).map((c) => c.name), ['Pat Pilot']);
    expect(keysAsked(), ['email', 'fai_number', 'national_org_id']);

    // An email address the director looks up by button is also still an ID.
    hostedRequests.clear();
    await s.lookup('pat@example.com');
    expect(keysAsked(), ['email', 'fai_number', 'national_org_id']);
  });

  test('a lookup on purpose asks the email key for any address', () async {
    byKey['email'] = [_match(_entryA, 'Pat')];
    final s = source();

    final found = await s.lookup('pilot@example.xn--p1ai');

    expect(found.map((c) => c.name), ['Pat Pilot']);
    expect(keysAsked(), contains('email'));
  });

  test('one key failing keeps what the others found', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    failKeys['email'] = 500;
    final s = source();

    final found = await s.lookup('pat@example.com');

    expect(found.map((c) => c.name), ['Pat Pilot']);
  });

  test(
    'a refused lookup is reported as too many, and not remembered',
    () async {
      failKeys['email'] = 429;
      final s = source();

      await expectLater(
        s.lookup('pat@example.com'),
        throwsA(isA<DirectoryRateLimited>()),
      );
      // The remaining keys would be refused too.
      expect(keysAsked(), ['email']);

      // Typed text is asked again once the limit has passed.
      failKeys.clear();
      byKey['email'] = [_match(_entryA, 'Pat')];
      hostedRequests.clear();
      expect((await s.search('pat@example.com')).map((c) => c.name), [
        'Pat Pilot',
      ]);
    },
  );

  test('every key failing reports the failure', () async {
    failKeys['email'] = 500;
    failKeys['fai_number'] = 500;
    failKeys['national_org_id'] = 500;
    final s = source();

    await expectLater(
      s.lookup('pat@example.com'),
      throwsA(isA<ApiHttpError>()),
    );
  });

  test('several pilots sharing an ID are all offered', () async {
    byKey['fai_number'] = [
      {..._match(_entryA, 'Pat'), 'country': 'US'},
      {..._match(_entryB, 'Bea'), 'country': 'DE'},
    ];
    final s = source();

    final found = await s.lookup('F1');

    expect(found.map((c) => c.name), ['Pat Pilot', 'Bea Pilot']);
    expect(found.map((c) => c.profileId).toSet(), hasLength(2));
  });

  test('IDs differing only by case are separate questions', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    await s.search('F123');
    await s.search('f123');

    expect(hostedRequests, hasLength(4));
  });

  test(
    'an id is tried as FAI number and national ID, once per pilot',
    () async {
      byKey['fai_number'] = [_match(_entryA, 'Pat')];
      byKey['national_org_id'] = [
        _match(_entryA, 'Pat'),
        _match(_entryB, 'Bea'),
      ];
      final s = source();

      final found = await s.search('F1234');

      expect(found.map((c) => c.name), ['Pat Pilot', 'Bea Pilot']);
      expect(hostedRequests, hasLength(2));
    },
  );

  test('a newer query during the pause drops the older one', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    final first = s.search('F123');
    final second = s.search('F1234');

    expect(await first, isEmpty);
    expect(await second, isNotEmpty);
    expect(hostedRequests, hasLength(2)); // two keys, one query
  });

  test('an answered query is not asked again', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    await s.search('F1234');
    await s.search('F1234');
    expect(hostedRequests, hasLength(2));
    await s.search('f1234'); // IDs are matched exactly, so asked again
    expect(hostedRequests, hasLength(4));
  });

  test('the same pilot always gets the same profile id', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    final a = (await s.search('F1234')).single;
    final b = (await s.search('F5678')).single;

    expect(b.profileId, a.profileId);
  });

  test(
    'copy links first, then creates the profile with what was shared',
    () async {
      byKey['fai_number'] = [_match(_entryA, 'Pat')];
      final s = source();
      final candidate = (await s.search('F1234')).single;
      hostedRequests.clear();

      final profile = await s.copy(candidate);

      expect(hostedRequests.single.url.path, endsWith('/directory/copies'));
      final link =
          jsonDecode(hostedRequests.single.body) as Map<String, Object?>;
      expect(link, {
        'entry_id': _entryA.value,
        'profile_id': candidate.profileId.value,
      });
      expect(profile.id, candidate.profileId);
      final created =
          jsonDecode(localRequests.single.body) as Map<String, Object?>;
      expect(created['id'], candidate.profileId.value);
      expect(created['first_name'], 'Pat');
      expect(created['email'], 'pat@example.com');
    },
  );

  test('a pilot who keeps their email private is copied without one', () async {
    byKey['fai_number'] = [_match(_entryB, 'Bea')];
    final s = source();
    final candidate = (await s.search('F1234')).single;

    await s.copy(candidate);

    final created =
        jsonDecode(localRequests.single.body) as Map<String, Object?>;
    expect(created['email'], isNull);
    expect(candidate.emailVisible, isFalse);
  });

  test('a profile that already holds the pilot is not offered again', () async {
    byKey['fai_number'] = [_match(_entryB, 'Bea')];
    final s = source();
    final candidate = (await s.search('F1234')).single;
    final own = ParticipantProfile(
      id: Id.create(),
      ownerAccountId: Id.create(),
      firstName: 'Bea',
      lastName: 'Pilot',
      faiNumber: ' F1 ',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );

    expect(candidate.copiesIn([own]), isNotEmpty);
    expect(candidate.copiesIn(const []), isEmpty);
  });

  test(
    'a private email the director typed still finds their own profile',
    () async {
      byKey['email'] = [_match(_entryB, 'Bea')];
      final s = source();
      final candidate = (await s.search('bea@example.com')).single;
      ParticipantProfile own(String? email, String? fai) => ParticipantProfile(
        id: Id.create(),
        ownerAccountId: Id.create(),
        firstName: 'Bea',
        lastName: 'Pilot',
        email: email,
        faiNumber: fai,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      );

      expect(candidate.directory!.email, isNull);
      expect(candidate.copiesIn([own('Bea@Example.com', 'other')]), isNotEmpty);
      expect(candidate.copiesIn([own('x@example.com', 'other')]), isEmpty);
    },
  );

  test('clearing or an invalid text ends a lookup that is waiting', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    final s = source();

    final waiting = s.search('F1234');
    await s.search('');

    expect(await waiting, isEmpty);
    expect(hostedRequests, isEmpty);
  });

  test(
    'an explicit lookup takes IDs typing skips: short, letters, spaces',
    () async {
      byKey['fai_number'] = [_match(_entryA, 'Pat')];
      final s = source();

      for (final id in ['AB', 'ABCDEF', 'NSS 12 A']) {
        expect(await s.search(id), isEmpty, reason: id);
      }
      expect(hostedRequests, isEmpty);
      for (final id in ['AB', 'ABCDEF', 'NSS 12 A']) {
        expect((await s.lookup(id)).map((c) => c.name), [
          'Pat Pilot',
        ], reason: id);
      }
      expect(await s.lookup('  '), isEmpty);
      expect(await s.lookup('x' * 65), isEmpty);
    },
  );

  test('IDs are matched exactly, emails ignoring case', () async {
    byKey['fai_number'] = [_match(_entryA, 'Pat')];
    byKey['email'] = [_match(_entryB, 'Bea')];
    final s = source();

    await s.search('bea@example.com');
    await s.search('Bea@Example.com'); // same email, reused
    expect(hostedRequests, hasLength(1));
    hostedRequests.clear();
    await s.search('ab12');
    await s.search('AB12'); // IDs are exact
    expect(hostedRequests, hasLength(4));
  });

  test('a copy the server already knows keeps its profile id', () async {
    final known = Id.create();
    byKey['fai_number'] = [
      {..._match(_entryA, 'Pat'), 'copied_profile_id': known.value},
    ];
    final s = source();

    final candidate = (await s.search('F1234')).single;

    expect(candidate.profileId, known);
    final own = ParticipantProfile(
      id: known,
      ownerAccountId: Id.create(),
      firstName: 'Pat',
      lastName: 'Pilot',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    expect(candidate.copiesIn([own]), isNotEmpty);
  });

  test(
    'a copy made before the profile synced is remembered by a new source',
    () async {
      // The hosted server never names a copy: the profile has not synced.
      byKey['fai_number'] = [_match(_entryB, 'Bea')];
      final store = BackendLocalUiStore(MemoryLocalUiBackend());
      final first = source(store: store);
      final candidate = (await first.search('F1234')).single;
      await first.copy(candidate);

      final restarted = source(store: store); // a new page, or a restart
      final again = (await restarted.search('F1234')).single;

      expect(again.profileId, candidate.profileId);
      hostedRequests.clear();
      await restarted.copy(again);
      final sent =
          jsonDecode(hostedRequests.single.body) as Map<String, Object?>;
      expect(sent['profile_id'], candidate.profileId.value);
      // Another account on the device has not copied them.
      final other = DirectoryPilotSource(
        pause: const Duration(milliseconds: 5),
        hosted: first.hosted,
        local: first.local,
        store: store,
        accountId: 'sam',
      );
      expect(
        (await other.search('F1234')).single.profileId,
        isNot(candidate.profileId),
      );
    },
  );

  test('FAI numbers and national IDs match exactly, as the server looks '
      'them up', () async {
    byKey['fai_number'] = [
      {..._match(_entryB, 'Bea'), 'national_org_id': 'NSS-1'},
    ];
    final s = source();
    final candidate = (await s.search('F1234')).single;
    ParticipantProfile own({String? fai, String? national}) =>
        ParticipantProfile(
          id: Id.create(),
          ownerAccountId: Id.create(),
          firstName: 'Other',
          lastName: 'Pilot',
          faiNumber: fai,
          nationalOrgId: national,
          createdAt: DateTime.utc(2026, 11, 1),
          updatedAt: DateTime.utc(2026, 11, 1),
        );

    expect(candidate.copiesIn([own(fai: 'f1')]), isEmpty);
    expect(candidate.copiesIn([own(national: 'nss-1')]), isEmpty);
    final exactFai = own(fai: 'F1');
    final exactNational = own(national: 'NSS-1');
    expect(candidate.copiesIn([own(fai: 'f1'), exactFai, exactNational]), [
      exactFai,
      exactNational,
    ]);
  });

  test('a profile that shares any identifier is shown, not hidden', () async {
    byKey['fai_number'] = [
      {..._match(_entryB, 'Bea'), 'national_org_id': 'NSS-1'},
    ];
    final s = source();
    final candidate = (await s.search('F1234')).single;
    ParticipantProfile own(String? national) => ParticipantProfile(
      id: Id.create(),
      ownerAccountId: Id.create(),
      firstName: 'Bea',
      lastName: 'P',
      nationalOrgId: national,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    final held = own(' NSS-1 ');

    expect(candidate.copiesIn([own('x'), held]), [held]);
  });

  test(
    'a miss is not remembered past its life, nor by an explicit lookup',
    () async {
      var now = DateTime.utc(2026, 11, 26, 12);
      final s = source(clock: () => now);

      expect(await s.search('F1234'), isEmpty); // not listed yet
      byKey['fai_number'] = [_match(_entryA, 'Pat')]; // the pilot lists
      hostedRequests.clear();
      expect(await s.search('F1234'), isEmpty);
      expect(hostedRequests, isEmpty); // typing again reuses the answer
      expect((await s.lookup('F1234')).single.name, 'Pat Pilot'); // retry asks

      now = now.add(const Duration(minutes: 1));
      byKey['fai_number'] = [_match(_entryA, 'Patricia')]; // corrected
      expect((await s.search('F1234')).single.name, 'Patricia Pilot');
    },
  );

  test('a copy whose answer is lost is retried as the same profile', () async {
    byKey['fai_number'] = [_match(_entryB, 'Bea')];
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final first = source(store: store);
    final candidate = (await first.search('F1234')).single;
    copyAnswer = 500;
    copyCommits = true; // the server linked, the answer never came

    await expectLater(first.copy(candidate), throwsA(anything));
    copyAnswer = 0;
    final restarted = source(store: store);
    final again = (await restarted.search('F1234')).single;
    hostedRequests.clear();
    await restarted.copy(again);

    expect(again.profileId, candidate.profileId);
    final sent = jsonDecode(hostedRequests.single.body) as Map<String, Object?>;
    expect(sent['profile_id'], candidate.profileId.value);
  });

  test(
    'a refused retry keeps the id of a copy whose answer was lost',
    () async {
      byKey['fai_number'] = [_match(_entryB, 'Bea')];
      final store = BackendLocalUiStore(MemoryLocalUiBackend());
      final candidate = (await source(store: store).search('F1234')).single;
      copyAnswer = 500;
      copyCommits = true; // linked on the server, the answer never came
      await expectLater(
        source(store: store).copy(candidate),
        throwsA(anything),
      );

      copyCommits = false;
      copyAnswer = 429; // the retry is refused
      final second = source(store: store);
      final again = (await second.search('F1234')).single;
      await expectLater(second.copy(again), throwsA(isA<ApiHttpError>()));

      copyAnswer = 0; // after another recreation, a retry succeeds
      final third = source(store: store);
      final last = (await third.search('F1234')).single;
      hostedRequests.clear();
      await third.copy(last);

      expect(again.profileId, candidate.profileId);
      expect(last.profileId, candidate.profileId);
      final sent =
          jsonDecode(hostedRequests.single.body) as Map<String, Object?>;
      expect(sent['profile_id'], candidate.profileId.value);
    },
  );

  test('a profile created with its answer lost is found again after the entry changes', () async {
    byKey['fai_number'] = [_match(_entryB, 'Bea')];
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final s = source(store: store);
    final candidate = (await s.search('F1234')).single;
    localLosesAnswer = true;
    await expectLater(s.copy(candidate), throwsA(anything));

    // The pilot changes a detail before the retry.
    byKey['fai_number'] = [
      {..._match(_entryB, 'Bea'), 'club': 'New Club'},
    ];
    final again = (await source(store: store).lookup('F1234')).single;
    final profile = await source(store: store).copy(again);

    expect(profile.id, candidate.profileId);
    expect(profile.club, 'Soar Club'); // the first create stands
  });
}
