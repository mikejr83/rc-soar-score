import 'package:intl/date_symbol_data_local.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final summer = DateTime.utc(2026, 7, 1, 12);
  final winter = DateTime.utc(2026, 1, 1, 12);

  group('ContestTimeZones', () {
    test('offers every region and keeps UTC', () {
      expect(
        ContestTimeZones.ids,
        containsAll([
          'America/Los_Angeles',
          'Europe/Rome',
          'Asia/Shanghai',
          'Asia/Tokyo',
          'Australia/Brisbane',
          'Pacific/Auckland',
          'UTC',
        ]),
      );
      expect(
        ContestTimeZones.ids.where((id) => id.startsWith('Etc/')),
        isEmpty,
      );
    });

    test('validates ids', () {
      expect(ContestTimeZones.isValid('Europe/Rome'), isTrue);
      expect(ContestTimeZones.isValid('Mars/Olympus'), isFalse);
      expect(
        () => ContestTimeZones.location('Mars/Olympus'),
        throwsArgumentError,
      );
    });

    test('labels have no underscores and show the offset on that date', () {
      expect(
        ContestTimeZones.label('Europe/Rome', at: summer),
        'Central European Time · Rome · UTC+02:00',
      );
      expect(
        ContestTimeZones.label('Europe/Rome', at: winter),
        'Central European Time · Rome · UTC+01:00',
      );
      expect(
        ContestTimeZones.label('America/New_York', at: winter),
        'Eastern Time (US & Canada) · New York · UTC-05:00',
      );
      expect(
        ContestTimeZones.label('Asia/Bangkok', at: winter),
        'Bangkok · Asia · UTC+07:00',
      );
      expect(
        ContestTimeZones.label('Asia/Kolkata', at: winter),
        'India Standard Time · Kolkata · UTC+05:30',
      );
      expect(
        ContestTimeZones.label('America/Argentina/Buenos_Aires', at: winter),
        contains('Buenos Aires'),
      );
      for (final id in ContestTimeZones.ids) {
        expect(ContestTimeZones.label(id, at: summer), isNot(contains('_')));
      }
    });

    test('search matches ids, cities and friendly names', () {
      expect(ContestTimeZones.search('rome'), contains('Europe/Rome'));
      expect(ContestTimeZones.search('new york'), contains('America/New_York'));
      expect(
        ContestTimeZones.search('central european'),
        contains('Europe/Paris'),
      );
      expect(ContestTimeZones.search('zzzz'), isEmpty);
      expect(ContestTimeZones.search(''), ContestTimeZones.ids);
    });
  });

  group('ContestTime', () {
    test('shows a stored UTC instant in the contest zone', () {
      final start = DateTime.utc(2026, 7, 1, 7, 30);
      expect(ContestTime.format(start, 'Europe/Rome'), '2026-07-01 09:30 CEST');
      expect(
        ContestTime.format(start, 'America/Los_Angeles'),
        '2026-07-01 00:30 PDT',
      );
      expect(ContestTime.format(start, 'UTC'), '2026-07-01 07:30 UTC');
    });

    test('follows daylight saving for the date', () {
      expect(
        ContestTime.format(DateTime.utc(2026, 1, 1, 7, 30), 'Europe/Rome'),
        '2026-01-01 08:30 CET',
      );
    });

    test('rejects an unknown zone', () {
      expect(
        () => ContestTime.format(summer, 'Mars/Olympus'),
        throwsArgumentError,
      );
    });
  });

  group('ContestTime with a locale', () {
    final start = DateTime.utc(2026, 7, 1, 7, 30);

    setUpAll(() => initializeDateFormatting());

    test('lays the date out the way the locale does', () {
      expect(
        ContestTime.format(start, 'Europe/Rome', locale: 'en-US'),
        '7/1/2026 09:30 CEST',
      );
      expect(
        ContestTime.format(start, 'Europe/Rome', locale: 'en-GB'),
        '01/07/2026 09:30 CEST',
      );
    });

    test('still uses the zone it is given, not the locale\'s', () {
      expect(
        ContestTime.format(start, 'America/Los_Angeles', locale: 'en-GB'),
        '01/07/2026 00:30 PDT',
      );
    });

    test('lays out a wall-clock time and just its clock', () {
      final wall = DateTime(2026, 7, 1, 9, 30);

      expect(
        ContestTime.formatWallClock(wall, 'CEST', locale: 'en-US'),
        '7/1/2026 09:30 CEST',
      );
      expect(ContestTime.formatClock(wall, locale: 'en-US'), '09:30');
    });

    test('is unchanged without a locale', () {
      expect(ContestTime.format(start, 'Europe/Rome'), '2026-07-01 09:30 CEST');
    });
  });
}
