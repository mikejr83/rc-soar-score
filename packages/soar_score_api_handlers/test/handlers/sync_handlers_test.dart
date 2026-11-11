import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _account = Id.parse('019c0000-0000-7000-8000-000000000001');
final _installation = Id.parse('019c0000-0000-7000-8000-00000000b001');

void main() {
  late HandlerHarness api;

  setUp(() => api = HandlerHarness(_account));

  Map<String, Object?> exchange({int protocol = 1, int schema = 1}) => {
    'protocol_version': protocol,
    'schema_version': schema,
    'installation_id': _installation.value,
    'scope': {'owner_account_id': _account.value},
    'last_acknowledged_sequence': 0,
    'mutations': <Object?>[],
  };

  test('info states the accepted ranges', () async {
    final response = await api.send('GET', '/sync/info');

    expect(response.statusCode, 200);
    final json = await api.json(response);
    expect(json['protocol_version'], 1);
    expect(json['min_schema_version'], 1);
    expect(json['max_schema_version'], 1);
  });

  test('a protocol outside the range is a 426 with its code', () async {
    final response = await api.send(
      'POST',
      '/sync/exchange',
      body: exchange(protocol: 2),
    );

    expect(response.statusCode, 426);
    expect(
      (await api.errorOf(response))['code'],
      'unsupported_protocol_version',
    );
  });

  test('a schema above the maximum is a 409', () async {
    final response = await api.send(
      'POST',
      '/sync/exchange',
      body: exchange(schema: 2),
    );

    expect(response.statusCode, 409);
  });

  test('a scope that names both owner and contest is a 400', () async {
    final body = exchange();
    body['scope'] = {
      'owner_account_id': _account.value,
      'contest_id': _installation.value,
    };

    final response = await api.send('POST', '/sync/exchange', body: body);

    expect(response.statusCode, 400);
  });

  test('revision refuses a contest id that is not an id', () async {
    final response = await api.send('GET', '/sync/revision?contest_id=nope');

    expect(response.statusCode, 400);
  });

  test('system data needs a non-negative after_sequence', () async {
    final missing = await api.send('GET', '/sync/system-data');
    final negative = await api.send(
      'GET',
      '/sync/system-data?after_sequence=-1',
    );

    expect(missing.statusCode, 400);
    expect(negative.statusCode, 400);
  });

  test('system data is an empty page at the seed sequence', () async {
    final response = await api.send(
      'GET',
      '/sync/system-data?after_sequence=0',
    );

    expect(response.statusCode, 200);
    final json = await api.json(response);
    expect(json['changes'], isEmpty);
    expect(json['system_data_seq'], isA<int>());
  });
}
