import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/scoring/time_entry.dart';

TimeEntry _parse(String text) => TimeEntry.parse(text, workingTimeSeconds: 600);

void main() {
  group('compact input', () {
    test('630 is 6:30', () {
      final t = _parse('630');
      expect(t.seconds, 390);
      expect(t.display, '6:30');
      expect(t.error, isNull);
    });

    test('630.4 is 6:30.4', () {
      final t = _parse('630.4');
      expect(t.seconds, closeTo(390.4, 1e-9));
      expect(t.display, '6:30.4');
    });

    test('a comma is a decimal separator', () {
      expect(_parse('630,4').seconds, closeTo(390.4, 1e-9));
    });

    test('short values are seconds', () {
      expect(_parse('45').seconds, 45);
      expect(_parse('45').display, '0:45');
    });

    test('6:30 with a colon is accepted', () {
      expect(_parse('6:30').seconds, 390);
    });

    test('empty is neither valid nor an error', () {
      final t = _parse('  ');
      expect(t.isEmpty, isTrue);
      expect(t.isValid, isFalse);
      expect(t.error, isNull);
    });
  });

  group('rejected input', () {
    test('seconds above 59 are rejected and read as typed', () {
      final t = _parse('675');
      expect(t.seconds, isNull);
      expect(t.display, '6:75');
      expect(t.error, contains('59'));
      expect(t.text, '675');
    });

    test('the working time itself is rejected', () {
      final t = _parse('1000');
      expect(t.isValid, isFalse);
      expect(t.error, contains('9:59'));
    });

    test('9:59 is the most with a 10:00 working time', () {
      expect(_parse('959').seconds, 599);
    });

    test('letters are rejected', () {
      expect(_parse('6a3').error, isNotNull);
    });
  });

  test('clock formats seconds', () {
    expect(TimeEntry.clock(540), '9:00');
    expect(TimeEntry.clock(395.4), '6:35.4');
  });
}
