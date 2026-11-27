import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _account = Id.parse('019c0000-0000-7000-8000-000000000001');

/// An installation's only account is its Local account, which has no entry.
void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_account);
    api.repository.accounts.byId[_account.value] = Account(
      id: _account,
      firstName: 'Ada',
      lastName: 'Pilot',
      kind: AccountKind.local,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );
  });

  for (final method in ['GET', 'PUT', 'DELETE']) {
    test(
      '$method /account/directory-entry answers 403 for the Local account',
      () async {
        final response = await api.send(
          method,
          '/account/directory-entry',
          body: method == 'PUT'
              ? {
                  'first_name': 'Ada',
                  'last_name': 'Pilot',
                  'is_listed': true,
                  'email_visible_to_directors': false,
                }
              : null,
        );

        expect(response.statusCode, anyOf(403, 404, 409));
        expect(response.statusCode, isNot(200));
      },
    );
  }
}
