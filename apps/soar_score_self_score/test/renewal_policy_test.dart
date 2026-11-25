import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/auth/renewal_policy.dart';

void main() {
  test('a timeout or an unknown failure keeps the session', () {
    expect(renewalEndsSession('TIMEOUT', const {}), isFalse);
    expect(renewalEndsSession('UNKNOWN', const {}), isFalse);
    expect(
      renewalEndsSession('AUTHENTICATION_ERROR', const {'code': 'network'}),
      isFalse,
    );
  });

  test('Auth0 rejecting the session ends it', () {
    expect(renewalEndsSession('MISSING_REFRESH_TOKEN', const {}), isTrue);
    expect(
      renewalEndsSession('AUTHENTICATION_ERROR', const {
        'code': 'login_required',
      }),
      isTrue,
    );
    expect(
      renewalEndsSession('AUTHENTICATION_ERROR', const {
        'code': 'invalid_grant',
      }),
      isTrue,
    );
  });
}
