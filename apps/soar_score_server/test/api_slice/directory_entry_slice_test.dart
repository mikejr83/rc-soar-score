import 'dart:convert';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _path = '/account/directory-entry';
const _email = 'pat.pilot@example.com';

/// The signed-in account's own directory entry (#652) over a real database.
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
  final now = DateTime.utc(2026, 11, 25, 12);

  Future<core.Id> account(
    core.AccountKind kind, {
    String? email,
    bool verified = false,
  }) async {
    final id = core.Id.create();
    await repository.accountRepository.save(
      core.Account(
        id: id,
        firstName: 'Pat',
        lastName: 'Pilot',
        email: email,
        emailVerified: verified,
        kind: kind,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Map<String, Object?> body({
    String firstName = 'Pat',
    String lastName = 'Pilot',
    String? club,
    String? fai,
    bool listed = true,
    bool emailVisible = false,
  }) => {
    'first_name': firstName,
    'last_name': lastName,
    'club': club,
    'fai_number': fai,
    'national_org_id': null,
    'city': null,
    'state': null,
    'country': null,
    'is_listed': listed,
    'email_visible_to_directors': emailVisible,
  };

  setUp(() async {
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
  });

  tearDown(() => api.close());

  Map<String, Object?> entryOf(SliceResponse r) =>
      r.body['entry']! as Map<String, Object?>;

  test('an account with no entry gets null and its own name', () async {
    final pat = await account(
      core.AccountKind.registered,
      email: _email,
      verified: true,
    );

    final response = await api.actAs(pat, 'GET', _path);

    expect(response.status, 200);
    expect(response.body['entry'], isNull);
    expect(response.body['suggested_first_name'], 'Pat');
    expect(response.body['suggested_last_name'], 'Pilot');
    expect(response.body['email_available'], isTrue);
  });

  test('creates an entry, listed with email private as sent', () async {
    final pat = await account(
      core.AccountKind.registered,
      email: _email,
      verified: true,
    );

    final put = await api.actAs(pat, 'PUT', _path, body: body(club: ' Soar '));
    final get = await api.actAs(pat, 'GET', _path);

    expect(put.status, 200, reason: '${put.body}');
    expect(entryOf(put)['is_listed'], isTrue);
    expect(entryOf(put)['email_visible_to_directors'], isFalse);
    expect(put.body['email_available'], isTrue);
    expect(entryOf(put)['club'], 'Soar');
    expect(get.body, put.body);
    final stored = await repository.participantDirectoryEntryRepository
        .findForAccount(pat);
    expect(stored?.isListed, isTrue);
  });

  test('never returns or stores the email', () async {
    final pat = await account(
      core.AccountKind.registered,
      email: _email,
      verified: true,
    );

    final put = await api.actAs(pat, 'PUT', _path, body: body());
    final get = await api.actAs(pat, 'GET', _path);
    final stored = await repository.participantDirectoryEntryRepository
        .findForAccount(pat);

    expect(jsonEncode(put.body), isNot(contains(_email)));
    expect(jsonEncode(get.body), isNot(contains(_email)));
    expect(put.body.keys, isNot(contains('email')));
    expect(jsonEncode(stored!.toJson()), isNot(contains(_email)));
  });

  test('a second PUT updates the same entry; unlisting keeps it', () async {
    final pat = await account(core.AccountKind.registered);
    final first = await api.actAs(pat, 'PUT', _path, body: body());

    final again = await api.actAs(pat, 'PUT', _path, body: body());
    final unlisted = await api.actAs(
      pat,
      'PUT',
      _path,
      body: body(listed: false, emailVisible: true, fai: ' 12345 '),
    );

    expect(again.body, first.body, reason: 'a repeat changes nothing');
    expect(entryOf(unlisted)['id'], entryOf(first)['id']);
    expect(entryOf(unlisted)['is_listed'], isFalse);
    expect(entryOf(unlisted)['email_visible_to_directors'], isTrue);
    expect(entryOf(unlisted)['fai_number'], '12345');
    expect(unlisted.body['email_available'], isFalse);
    expect(
      await repository.participantDirectoryEntryRepository
          .listListedByFaiNumber('12345'),
      isEmpty,
    );
  });

  test('a blank name is 400 and stores nothing', () async {
    final pat = await account(core.AccountKind.registered);

    final response = await api.actAs(
      pat,
      'PUT',
      _path,
      body: body(firstName: '  '),
    );

    expect(response.status, 400);
    expect(
      await repository.participantDirectoryEntryRepository.findForAccount(pat),
      isNull,
    );
  });

  test('delete removes the entry and is repeatable', () async {
    final pat = await account(core.AccountKind.registered);
    await api.actAs(pat, 'PUT', _path, body: body());

    final first = await api.actAs(pat, 'DELETE', _path);
    final second = await api.actAs(pat, 'DELETE', _path);

    expect(first.status, 204);
    expect(second.status, 204);
    expect((await api.actAs(pat, 'GET', _path)).body['entry'], isNull);
  });

  test('another account never sees or changes the entry', () async {
    final pat = await account(core.AccountKind.registered);
    final sam = await account(core.AccountKind.registered);
    await api.actAs(pat, 'PUT', _path, body: body());

    final theirs = await api.actAs(sam, 'GET', _path);
    await api.actAs(sam, 'DELETE', _path);

    expect(theirs.body['entry'], isNull);
    expect((await api.actAs(pat, 'GET', _path)).body['entry'], isNotNull);
  });

  test('a concurrent first save becomes an update of the winner', () async {
    final pat = await account(core.AccountKind.registered);
    final racing = _RivalFirstSave(api.database, pat, now);

    final saved = await core.DirectoryEntryService(racing, clock: () => now)
        .put(
          accountId: pat,
          firstName: 'Patricia',
          lastName: 'Pilot',
          isListed: true,
          emailVisibleToDirectors: false,
        );

    // One entry: the rival's id, with this save's details.
    final stored = await repository.participantDirectoryEntryRepository
        .findForAccount(pat);
    expect(racing.rivalSaved, isTrue);
    expect(stored!.id, racing.rivalId);
    expect(stored.firstName, 'Patricia');
    expect(saved.entry!.id, racing.rivalId);
    expect(saved.entry!.firstName, 'Patricia');
  });

  for (final kind in [
    core.AccountKind.guest,
    core.AccountKind.local,
    core.AccountKind.deleted,
  ]) {
    test('a ${kind.name} account is 403 registered_account_required', () async {
      final id = await account(kind);

      for (final (method, send) in [
        ('GET', null),
        ('PUT', body()),
        ('DELETE', null),
      ]) {
        final response = await api.actAs(id, method, _path, body: send);

        expect(response.status, 403, reason: method);
        expect(
          (response.body['error']! as Map<String, Object?>)['code'],
          'registered_account_required',
        );
      }
      expect(
        await repository.participantDirectoryEntryRepository.findForAccount(id),
        isNull,
      );
    });
  }
}

/// A repository whose first directory-entry save is preceded by another
/// request storing the account's entry, as a concurrent first save would.
class _RivalFirstSave extends Repository {
  _RivalFirstSave(super.db, this.accountId, this.now);

  final core.Id accountId;
  final DateTime now;
  final rivalId = core.Id.create();
  bool rivalSaved = false;

  late final _entries = _RivalEntries(
    super.participantDirectoryEntryRepository,
    this,
  );

  @override
  core.ParticipantDirectoryEntryRepository
  get participantDirectoryEntryRepository => _entries;
}

class _RivalEntries implements core.ParticipantDirectoryEntryRepository {
  _RivalEntries(this._real, this._owner);

  final core.ParticipantDirectoryEntryRepository _real;
  final _RivalFirstSave _owner;

  @override
  Future<core.ParticipantDirectoryEntry> save(
    core.ParticipantDirectoryEntry entry,
  ) async {
    if (!_owner.rivalSaved) {
      _owner.rivalSaved = true;
      await _real.save(
        core.ParticipantDirectoryEntry(
          id: _owner.rivalId,
          accountId: _owner.accountId,
          firstName: 'Pat',
          lastName: 'Pilot',
          isListed: true,
          emailVisibleToDirectors: false,
          createdAt: _owner.now,
          updatedAt: _owner.now,
        ),
      );
    }
    return _real.save(entry);
  }

  @override
  Future<core.ParticipantDirectoryEntry?> findById(core.Id id) =>
      _real.findById(id);

  @override
  Future<core.ParticipantDirectoryEntry?> findForAccount(core.Id accountId) =>
      _real.findForAccount(accountId);

  @override
  Future<List<core.ParticipantDirectoryEntry>> listListedByFaiNumber(
    String faiNumber,
  ) => _real.listListedByFaiNumber(faiNumber);

  @override
  Future<List<core.ParticipantDirectoryEntry>> listListedByNationalOrgId(
    String nationalOrgId,
  ) => _real.listListedByNationalOrgId(nationalOrgId);

  @override
  Future<bool> remove(core.Id id) => _real.remove(id);
}
