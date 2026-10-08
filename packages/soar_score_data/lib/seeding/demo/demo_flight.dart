import 'dart:math';

/// One flight the demo scores: the F5J components entered for a slot and, for
/// a corrected score, the wrong entry that came first.
class DemoFlight {
  const DemoFlight(this.components, {this.mistaken});

  final Map<String, Object?> components;

  /// The wrong components entered first, then corrected to [components].
  final Map<String, Object?>? mistaken;

  /// The flight for slot [index] of round [round] of contest [contest].
  ///
  /// Mostly ordinary flights with a deterministic spread; the first rounds
  /// also carry the cases a director meets: a corrected timer, a flight
  /// penalty, a late landing and a motor restart that scores zero.
  static DemoFlight of({
    required int contest,
    required int round,
    required int index,
  }) {
    final random = Random(contest * 10007 + round * 101 + index);
    final landing = 50 - 5 * random.nextInt(6);
    final ordinary = <String, Object?>{
      'time_flown': random.nextInt(4) == 0 ? 599 : 420 + random.nextInt(170),
      'launch_height': 170 + random.nextInt(50),
      'landing': 'points_$landing',
    };
    return switch ((round, index)) {
      (1, 0) => DemoFlight(
        {...ordinary, 'time_flown': 585},
        mistaken: {...ordinary, 'time_flown': 358},
      ),
      (1, 1) => DemoFlight({...ordinary, 'flight_penalty': 20}),
      (2, 1) => const DemoFlight({
        'time_flown': 599,
        'launch_height': 200,
        'late_landing': true,
      }),
      (3, 2) => DemoFlight({...ordinary, 'motor_restart': true}),
      _ => DemoFlight(ordinary),
    };
  }
}
