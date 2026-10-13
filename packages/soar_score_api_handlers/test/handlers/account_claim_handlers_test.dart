import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _account = Id.parse('019c0000-0000-7000-8000-000000000001');
final _other = Id.parse('019c0000-0000-7000-8000-000000000002');
final _local = Id.parse('019c0000-0000-7000-8000-00000000a001');
const _path = '/account/local-claims';

void main() {
  late HandlerHarness api;

  setUp(() => api = HandlerHarness(_account));

  Future<void> claim(Id local, {Id? as}) => api.repository.accountAliases.claim(
    localAccountId: local,
    accountId: as ?? _other,
    claimedAt: DateTime.utc(2026, 10, 1),
  );

  test('claims a Local account into the caller\'s account', () async {
    final response = await api.send(
      'POST',
      _path,
      body: {'local_account_id': _local.value},
    );

    expect(response.statusCode, 200);
    final json = await api.json(response);
    expect(json['local_account_id'], _local.value);
    expect(json['claimed_at'], isNotNull);
    expect(json['account_id'], _account.value);
    final stored = await api.repository.accountAliases.findById(_local);
    expect(stored?.accountId, _account);
  });

  test('claiming again answers the same and stores nothing new', () async {
    final first = await api.json(
      await api.send('POST', _path, body: {'local_account_id': _local.value}),
    );

    final response = await api.send(
      'POST',
      _path,
      body: {'local_account_id': _local.value},
    );

    expect(response.statusCode, 200);
    expect(await api.json(response), first);
    expect(api.repository.accountAliases.byId, hasLength(1));
  });

  test('a Local account another account claimed answers 409', () async {
    await claim(_local);

    final response = await api.send(
      'POST',
      _path,
      body: {'local_account_id': _local.value},
    );

    expect(response.statusCode, 409);
    expect((await api.errorOf(response))['code'], 'already_claimed');
    final stored = await api.repository.accountAliases.findById(_local);
    expect(stored?.accountId, _other);
  });

  test('the caller\'s own id is refused', () async {
    final response = await api.send(
      'POST',
      _path,
      body: {'local_account_id': _account.value},
    );

    expect(response.statusCode, 400);
    expect(api.repository.accountAliases.byId, isEmpty);
  });

  test('the id of an existing account is refused', () async {
    api.repository.accounts.byId[_other.value] = Account(
      id: _other,
      firstName: 'Sam',
      lastName: 'Pilot',
      kind: AccountKind.registered,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );

    final response = await api.send(
      'POST',
      _path,
      body: {'local_account_id': _other.value},
    );

    expect(response.statusCode, 400);
    expect(api.repository.accountAliases.byId, isEmpty);
  });

  test('a body without a valid id answers 400', () async {
    for (final body in [
      <String, Object?>{},
      {'local_account_id': 'nope'},
    ]) {
      final response = await api.send('POST', _path, body: body);
      expect(response.statusCode, 400, reason: '$body');
    }
  });
}
