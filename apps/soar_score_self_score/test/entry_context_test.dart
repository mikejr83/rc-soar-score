import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/models/entry_context.dart';

EntryContext _context({String? taskType, List<String> fieldKeys = const []}) =>
    EntryContext(
      pilotName: 'Alex Rivera',
      round: 1,
      roundCount: 3,
      group: 'A',
      taskType: taskType,
      fieldKeys: fieldKeys,
      landingTable: const [],
    );

void main() {
  group('EntryContext.formSupported', () {
    test('every F5J field the server sends is supported', () {
      expect(
        _context(
          fieldKeys: [
            'time_flown',
            'launch_height',
            'landing',
            'late_landing',
            'motor_restart',
            'out_of_bounds',
            'no_altitude_recorded',
            'flight_penalty',
          ],
        ).formSupported,
        isTrue,
      );
    });

    test('an unknown field is not supported', () {
      expect(
        _context(fieldKeys: ['time_flown', 'no_altitude']).formSupported,
        isFalse,
      );
    });

    test('a named task is not supported', () {
      expect(
        _context(taskType: 'poker', fieldKeys: ['time_flown']).formSupported,
        isFalse,
      );
    });
  });
}
