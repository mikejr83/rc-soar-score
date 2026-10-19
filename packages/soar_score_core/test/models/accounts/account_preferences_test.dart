import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'account_test.dart' show make;

void main() {
  group('AccountPreferences', () {
    test('starts empty', () {
      expect(AccountPreferences().isEmpty, isTrue);
    });

    test('accepts a known zone and a supported locale', () {
      final preferences = AccountPreferences(
        preferredTimeZone: 'Europe/Rome',
        preferredLocale: 'en-US',
      );

      expect(preferences.isEmpty, isFalse);
      expect(AccountPreferences.fromJson(preferences.toJson()), preferences);
    });

    test('rejects an unknown IANA id', () {
      expect(
        () => AccountPreferences(preferredTimeZone: 'Mars/Olympus'),
        throwsArgumentError,
      );
    });

    test('rejects an unsupported locale', () {
      expect(
        () => AccountPreferences(preferredLocale: 'xx-YY'),
        throwsArgumentError,
      );
      expect(
        () => AccountPreferences(preferredLocale: 'en_US'),
        throwsArgumentError,
      );
    });

    test('orElse fills only the missing fields', () {
      final mine = AccountPreferences(preferredTimeZone: 'Asia/Tokyo');
      final other = AccountPreferences(
        preferredTimeZone: 'Europe/Rome',
        preferredLocale: 'en-US',
      );

      expect(
        mine.orElse(other),
        AccountPreferences(
          preferredTimeZone: 'Asia/Tokyo',
          preferredLocale: 'en-US',
        ),
      );
    });
  });

  group('Account preferences', () {
    test('are stored on the account and validated', () {
      final account = make().withPreferences(
        AccountPreferences(preferredTimeZone: 'Europe/Rome'),
        DateTime.utc(2026, 10, 19),
      );

      expect(account.preferredTimeZone, 'Europe/Rome');
      expect(account.updatedAt, DateTime.utc(2026, 10, 19));
      expect(Account.fromJson(account.toJson()), account);
      expect(
        () => Account.fromJson({
          ...account.toJson(),
          'preferred_time_zone': 'Nowhere/Land',
        }),
        throwsArgumentError,
      );
    });
  });
}
