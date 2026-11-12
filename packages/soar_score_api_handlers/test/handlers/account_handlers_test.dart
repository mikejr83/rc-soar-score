import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _account = Id.parse('019c0000-0000-7000-8000-000000000001');

void main() {
  test('GET /account answers the id the audit trail records', () async {
    final api = HandlerHarness(_account);

    final response = await api.send('GET', '/account');

    expect(response.statusCode, 200);
    expect(await api.json(response), {'account_id': _account.value});
  });
}
