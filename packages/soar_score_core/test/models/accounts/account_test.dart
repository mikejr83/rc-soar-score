import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

Account make({
  AccountKind kind = AccountKind.registered,
  String? email = 'ada@example.com',
  bool verified = true,
  AccountStatus status = AccountStatus.active,
  DateTime? archivedAt,
  bool admin = false,
}) => Account(
  id: exampleId(1),
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: email,
  emailVerified: verified,
  kind: kind,
  status: status,
  archivedAt: archivedAt,
  isSystemAdmin: admin,
  createdAt: t0,
  updatedAt: t0,
);

void main() {
  group('Account', () {
    test('round trips with documented enum text', () {
      final a = make();
      expect(a.toJson()['kind'], 'registered');
      expect(a.toJson()['status'], 'active');
      expect(Account.fromJson(a.toJson()), a);
      expect(a, isA<BackendOnly>());
    });

    test('stores the email lowercase', () {
      expect(make(email: ' Ada@Example.COM ').email, 'ada@example.com');
    });

    test('only an active registered account can sign in', () {
      expect(make().canSignIn, isTrue);
      expect(make(kind: AccountKind.guest, verified: false).canSignIn, isFalse);
      expect(
        make(status: AccountStatus.archived, archivedAt: t0).canSignIn,
        isFalse,
      );
    });

    test('a guest never has a verified email', () {
      expect(() => make(kind: AccountKind.guest), throwsArgumentError);
    });

    test('local and deleted accounts have no email', () {
      expect(
        () => make(kind: AccountKind.local, verified: false),
        throwsArgumentError,
      );
      expect(
        make(kind: AccountKind.deleted, email: null, verified: false).email,
        isNull,
      );
    });

    test('the deleted-user account cannot be archived', () {
      expect(
        () => make(
          kind: AccountKind.deleted,
          email: null,
          verified: false,
          status: AccountStatus.archived,
          archivedAt: t0,
        ),
        throwsArgumentError,
      );
    });

    test('archived_at is set exactly when archived', () {
      expect(() => make(status: AccountStatus.archived), throwsArgumentError);
      expect(() => make(archivedAt: t0), throwsArgumentError);
    });

    test('only a registered account can be a system admin', () {
      expect(make(admin: true).isSystemAdmin, isTrue);
      expect(
        () => make(admin: true, kind: AccountKind.guest, verified: false),
        throwsArgumentError,
      );
    });
  });
}
