import 'package:soar_score_core/soar_score_core.dart' as core;

import 'demo_ids.dart';

/// What one demo contest looks like once the seeder has built it.
class DemoContestPlan {
  const DemoContestPlan({
    required this.number,
    required this.name,
    required this.start,
    required this.end,
    required this.city,
    required this.state,
    required this.disciplineProfileId,
    required this.finalState,
    this.pilots = 0,
    this.helpers = 0,
    this.teamSize,
    this.classes = false,
    this.rounds = 0,
    this.groupsPerRound = 0,
    this.scoredRounds = 0,
    this.partialSlots = 0,
    this.configured = true,
  });

  /// Names the contest's ids (see [DemoIds]).
  final int number;
  final String name;
  final DateTime start;
  final DateTime end;
  final String city;
  final String state;
  final core.Id disciplineProfileId;

  /// The lifecycle state the contest ends in. `Created` has no configuration,
  /// `Configuring` has participants but no matrix, `Ready` has the drawn
  /// matrix, `Running` has scores entered and scoring open, `Completed` has every round
  /// scored and scoring closed.
  final core.LifecycleState finalState;

  /// Pilots, taken from the start of the roster.
  final int pilots;

  /// Non-flying helpers, taken from the end of the roster. Giving a contest
  /// helpers turns participant roles on.
  final int helpers;

  /// Pilots per team; `null` leaves teams off. Needs a multiple of it as the
  /// pilot count.
  final int? teamSize;

  /// Splits the pilots into Open and Sportsman.
  final bool classes;

  /// Rounds and groups of the drawn matrix; `0` rounds leaves it undrawn.
  final int rounds;
  final int groupsPerRound;

  /// Rounds scored whole, and slots scored in the round after them. Any
  /// score makes the contest Running; a Completed contest scores every round.
  final int scoredRounds;
  final int partialSlots;

  /// Whether the contest gets a configuration.
  final bool configured;

  bool get drawn => rounds > 0;

  bool get scored => scoredRounds > 0 || partialSlots > 0;

  /// The contests the demo database holds, one for each lifecycle state.
  static final List<DemoContestPlan> all = [
    DemoContestPlan(
      number: 1,
      name: 'Autumn F5J Classic',
      start: DateTime.utc(2026, 9, 12, 15),
      end: DateTime.utc(2026, 9, 13, 22),
      city: 'Golden',
      state: 'CO',
      disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
      finalState: core.LifecycleState.completed,
      pilots: 8,
      rounds: 5,
      groupsPerRound: 2,
      scoredRounds: 5,
    ),
    DemoContestPlan(
      number: 2,
      name: 'Mountain States Team F5J',
      start: DateTime.utc(2026, 10, 3, 14),
      end: DateTime.utc(2026, 10, 4, 22),
      city: 'Boulder',
      state: 'CO',
      disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
      finalState: core.LifecycleState.running,
      pilots: 12,
      teamSize: 3,
      rounds: 6,
      groupsPerRound: 3,
      scoredRounds: 4,
      partialSlots: 5,
    ),
    DemoContestPlan(
      number: 3,
      name: 'Front Range F5J Open',
      start: DateTime.utc(2026, 10, 17, 14),
      end: DateTime.utc(2026, 10, 18, 22),
      city: 'Longmont',
      state: 'CO',
      disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
      finalState: core.LifecycleState.ready,
      pilots: 14,
      helpers: 2,
      classes: true,
      rounds: 8,
      groupsPerRound: 3,
    ),
    DemoContestPlan(
      number: 4,
      name: 'Club Thermal Fun Fly',
      start: DateTime.utc(2026, 11, 7, 16),
      end: DateTime.utc(2026, 11, 7, 23),
      city: 'Fort Collins',
      state: 'CO',
      disciplineProfileId: core.SystemDisciplineProfiles.thermalId,
      finalState: core.LifecycleState.configuring,
      pilots: 6,
    ),
    DemoContestPlan(
      number: 5,
      name: 'Spring F3J Challenge',
      start: DateTime.utc(2027, 4, 24, 15),
      end: DateTime.utc(2027, 4, 25, 22),
      city: 'Lakewood',
      state: 'CO',
      disciplineProfileId: core.SystemDisciplineProfiles.f3jId,
      finalState: core.LifecycleState.created,
      configured: false,
    ),
  ];
}
