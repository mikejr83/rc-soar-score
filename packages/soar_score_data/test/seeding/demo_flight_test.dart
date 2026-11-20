import 'package:soar_score_data/seeding/demo/demo_flight.dart';
import 'package:test/test.dart';

void main() {
  test('a seeded zeroing flight holds no time, height or landing', () {
    for (var contest = 1; contest <= 8; contest++) {
      for (var round = 1; round <= 8; round++) {
        for (var index = 0; index < 20; index++) {
          final flight = DemoFlight.of(
            contest: contest,
            round: round,
            index: index,
          );
          for (final components in [flight.components, flight.mistaken]) {
            if (components == null) continue;
            final zeroing =
                components['motor_restart'] == true ||
                components['out_of_bounds'] == true ||
                components['no_altitude_recorded'] == true;
            if (!zeroing) continue;
            expect(components.keys, isNot(contains('time_flown')));
            expect(components.keys, isNot(contains('launch_height')));
            expect(components.keys, isNot(contains('landing')));
          }
        }
      }
    }
  });
}
