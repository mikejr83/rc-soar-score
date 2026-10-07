import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _tableId = '019c0000-0000-7000-8000-000000000301';

Map<String, Object?> _body({
  String name = 'Club table',
  List<Map<String, Object?>>? entries,
}) => {
  'id': _tableId,
  'name': name,
  'input_unit': 'meters',
  'entries':
      entries ??
      [
        {'entry_key': 'within_1m', 'display_value': '', 'point_value': 10},
        {'entry_key': 'within_2m', 'display_value': '2 m', 'point_value': 5},
      ],
};

void main() {
  late HandlerHarness api;

  setUp(() => api = HandlerHarness(_owner));

  Future<Map<String, Object?>> create([Map<String, Object?>? body]) async {
    final response = await api.send(
      'POST',
      '/landing-tables',
      body: body ?? _body(),
    );
    expect(response.statusCode, 201);
    return api.json(response);
  }

  group('POST /landing-tables', () {
    test('creates a table owned by the principal, entries in order', () async {
      final body = await create();

      final table = body['table']! as Map<String, Object?>;
      expect(table['id'], _tableId);
      expect(table['owner_account_id'], _owner.value);
      expect(body['in_use'], isFalse);
      final results = body['results']! as List<Object?>;
      expect(
        [for (final r in results) (r! as Map<String, Object?>)['entry_key']],
        ['within_1m', 'within_2m'],
      );
      expect(
        (results.first! as Map<String, Object?>)['display_value'],
        'within_1m',
      );
      expect(api.repository.landingTables.writtenWith.single.actorId, _owner);
    });

    test('repeating the request returns the same table', () async {
      final first = await create();
      final second = await create();

      expect(second, first);
      expect(api.repository.landingTables.writtenWith, hasLength(1));
    });

    test('the same id with other content is a 409', () async {
      await create();

      final response = await api.send(
        'POST',
        '/landing-tables',
        body: _body(name: 'Other'),
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'already_stored');
    });

    test('rejects a repeated key, no entries and malformed bodies', () async {
      for (final body in [
        _body(
          entries: [
            {'entry_key': 'a', 'display_value': '', 'point_value': 1},
            {'entry_key': 'a', 'display_value': '', 'point_value': 2},
          ],
        ),
        _body(entries: []),
        _body(name: ' '),
        {'name': 'no id'},
      ]) {
        final response = await api.send('POST', '/landing-tables', body: body);
        expect(response.statusCode, 400, reason: '$body');
      }
    });
  });

  group('GET /landing-tables', () {
    test('lists the system tables and the caller\'s own with in_use', () async {
      await create();
      api.repository.landingTables.inUse.add(Id.parse(_tableId));

      final response = await api.send('GET', '/landing-tables');
      final tables =
          ((await api.json(response))['landing_tables']! as List<Object?>)
              .cast<Map<String, Object?>>();

      expect(response.statusCode, 200);
      final mine = tables.singleWhere(
        (t) => (t['table']! as Map<String, Object?>)['id'] == _tableId,
      );
      expect(mine['in_use'], isTrue);
      expect(
        tables.where(
          (t) =>
              (t['table']! as Map<String, Object?>)['owner_account_id'] == null,
        ),
        isNotEmpty,
      );
    });
  });

  group('DELETE /landing-tables/{id}', () {
    test('removes an unused table', () async {
      await create();

      final response = await api.send('DELETE', '/landing-tables/$_tableId');

      expect(response.statusCode, 204);
      expect(
        await api.repository.landingTables.findById(Id.parse(_tableId)),
        isNull,
      );
    });

    test('a table in use is a 409 with the reason and stays stored', () async {
      await create();
      api.repository.landingTables.inUse.add(Id.parse(_tableId));

      final response = await api.send('DELETE', '/landing-tables/$_tableId');

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'in_use');
      expect(
        await api.repository.landingTables.findById(Id.parse(_tableId)),
        isNotNull,
      );
    });

    test('a system table is a 409', () async {
      final response = await api.send(
        'DELETE',
        '/landing-tables/${SystemLandingTables.f5jStandard.table.id.value}',
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'system_table');
    });

    test('an unknown table is a 404', () async {
      final response = await api.send('DELETE', '/landing-tables/$_tableId');

      expect(response.statusCode, 404);
    });
  });
}
