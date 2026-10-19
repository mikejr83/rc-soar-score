import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _account = Id.parse('019c0000-0000-7000-8000-000000000001');
const _path = '/account/preferences';

void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_account);
    api.repository.accounts.byId[_account.value] = Account(
      id: _account,
      firstName: 'Ada',
      lastName: 'Pilot',
      kind: AccountKind.registered,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );
  });

  test('a new account has no preferences', () async {
    final response = await api.send('GET', _path);

    expect(response.statusCode, 200);
    expect(await api.json(response), {
      'preferred_time_zone': null,
      'preferred_locale': null,
    });
  });

  test('stores and returns the preferences', () async {
    final body = {
      'preferred_time_zone': 'Europe/Rome',
      'preferred_locale': 'en-US',
    };

    final put = await api.send('PUT', _path, body: body);
    final get = await api.send('GET', _path);

    expect(put.statusCode, 200);
    expect(await api.json(put), body);
    expect(await api.json(get), body);
    expect(
      api.repository.accounts.byId[_account.value]?.preferredTimeZone,
      'Europe/Rome',
    );
  });

  test('a null field clears that choice', () async {
    await api.send(
      'PUT',
      _path,
      body: {'preferred_time_zone': 'Europe/Rome', 'preferred_locale': null},
    );

    final response = await api.send(
      'PUT',
      _path,
      body: {'preferred_time_zone': null, 'preferred_locale': null},
    );

    expect(await api.json(response), {
      'preferred_time_zone': null,
      'preferred_locale': null,
    });
  });

  test('an unknown time zone answers 400 and stores nothing', () async {
    final response = await api.send(
      'PUT',
      _path,
      body: {'preferred_time_zone': 'Mars/Olympus', 'preferred_locale': null},
    );

    expect(response.statusCode, 400);
    expect(
      api.repository.accounts.byId[_account.value]?.preferredTimeZone,
      isNull,
    );
  });

  test('an unsupported locale answers 400', () async {
    final response = await api.send(
      'PUT',
      _path,
      body: {'preferred_time_zone': null, 'preferred_locale': 'xx-YY'},
    );

    expect(response.statusCode, 400);
  });

  test('an unknown account answers 404', () async {
    api.repository.accounts.byId.clear();

    final response = await api.send('GET', _path);

    expect(response.statusCode, 404);
  });
}
