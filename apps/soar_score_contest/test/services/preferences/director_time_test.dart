import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soar_score_contest/services/preferences/director_time.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en_GB'));

  final utc = DateTime.utc(2026, 10, 8, 12, 31);

  test('writes the instant in the preferred zone with the en-US layout', () {
    expect(
      DirectorTime.format(utc, zoneId: 'Europe/Rome'),
      '10/8/2026 14:31 CEST',
    );
    expect(
      DirectorTime.format(utc, zoneId: 'America/Denver'),
      '10/8/2026 06:31 MDT',
    );
  });

  test('a locale changes the layout, not the zone', () {
    expect(
      DirectorTime.format(utc, zoneId: 'Europe/Rome', locale: 'en-GB'),
      '08/10/2026 14:31 CEST',
    );
  });

  test('without a zone the device decides', () {
    final text = DirectorTime.format(utc);

    expect(text, matches(r'^\d{1,2}/\d{1,2}/2026 \d{2}:\d{2} \S+$'));
  });

  test('an unknown zone falls back to the device', () {
    expect(
      DirectorTime.format(utc, zoneId: 'Mars/Olympus'),
      DirectorTime.format(utc),
    );
  });

  test('pilot-facing contest time ignores the preference', () {
    expect(ContestTime.format(utc, 'Europe/Rome'), '2026-10-08 14:31 CEST');
    expect(
      DirectorTime.format(utc, zoneId: 'Asia/Tokyo'),
      isNot(contains('CEST')),
    );
  });
}
