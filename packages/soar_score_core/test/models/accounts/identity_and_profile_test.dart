import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

void main() {
  group('AccountIdentity', () {
    AccountIdentity make({
      String issuer = 'https://idp.example/',
      String sub = 'auth0|1',
    }) => AccountIdentity(
      id: exampleId(1),
      accountId: exampleId(2),
      issuer: issuer,
      subject: sub,
      createdAt: t0,
    );

    test('round trips and is private backend data', () {
      final i = make();
      expect(AccountIdentity.fromJson(i.toJson()), i);
      expect(i, isA<BackendOnly>());
      expect(i, isA<PrivateData>());
    });

    test('needs an issuer and a subject', () {
      expect(() => make(issuer: ' '), throwsArgumentError);
      expect(() => make(sub: ''), throwsArgumentError);
    });
  });

  group('AccountPublicProfile', () {
    AccountPublicProfile make({Id? account, String name = 'Sam O.'}) =>
        AccountPublicProfile(
          id: exampleId(3),
          accountId: account,
          displayName: name,
          createdAt: t0,
        );

    test('round trips, linked or unlinked', () {
      final linked = make(account: exampleId(2));
      expect(linked.isUnlinked, isFalse);
      expect(AccountPublicProfile.fromJson(linked.toJson()), linked);
      final unlinked = make();
      expect(unlinked.isUnlinked, isTrue);
      expect(unlinked.toJson()['account_id'], isNull);
      expect(unlinked, isA<BackendOnly>());
    });

    test('needs a display name', () {
      expect(() => make(name: ' '), throwsArgumentError);
    });
  });
}
