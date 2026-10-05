import 'package:equatable/equatable.dart';

import '../standings/team_entry.dart';

/// One pilot's entered flight in a round, as the official score holds it.
class F5jFlightEntry extends Equatable {
  F5jFlightEntry({
    required this.pilotId,
    required Map<String, Object?> components,
    this.landingBonus = 0,
    this.retired = false,
    this.cumulativePenalty = 0,
    this.underReview = false,
  }) : components = Map.unmodifiable(components);

  final String pilotId;

  /// The official score components, keyed like the F5J profile.
  final Map<String, Object?> components;

  /// The landing bonus, already resolved to points from the landing table.
  final double landingBonus;

  /// The pilot retired during this round, so the flight is left out of the
  /// group's normalization.
  final bool retired;
  final double cumulativePenalty;

  /// A review request is open, so the total stays preliminary.
  final bool underReview;

  @override
  List<Object?> get props => [
    pilotId,
    components,
    landingBonus,
    retired,
    cumulativePenalty,
    underReview,
  ];
}

/// The flight groups of one round. A pilot with no entry in any group of a
/// completed round has not flown it yet.
class F5jRoundInput extends Equatable {
  F5jRoundInput({
    required this.round,
    required List<List<F5jFlightEntry>> groups,
  }) : groups = List<List<F5jFlightEntry>>.unmodifiable([
         for (final g in groups) List<F5jFlightEntry>.unmodifiable(g),
       ]) {
    if (round < 1) throw ArgumentError.value(round, 'round', 'starts at 1');
  }

  final int round;
  final List<List<F5jFlightEntry>> groups;

  @override
  List<Object?> get props => [round, groups];
}

/// Everything the F5J recalculation reads: the immutable official data.
class F5jContestInput extends Equatable {
  F5jContestInput({
    required List<String> pilotIds,
    required List<F5jRoundInput> rounds,
    Map<String, int> retiredAtRound = const {},
    List<TeamEntry> teams = const [],
  }) : pilotIds = List.unmodifiable(pilotIds),
       rounds = List.unmodifiable(rounds),
       retiredAtRound = Map.unmodifiable(retiredAtRound),
       teams = List.unmodifiable(teams) {
    final numbers = this.rounds.map((r) => r.round).toList();
    if (numbers.toSet().length != numbers.length) {
      throw ArgumentError.value(rounds, 'rounds', 'a round appears twice');
    }
  }

  /// The pilots who fly, in the order totals and places are listed.
  final List<String> pilotIds;
  final List<F5jRoundInput> rounds;

  /// The first round each retired pilot did not fly.
  final Map<String, int> retiredAtRound;
  final List<TeamEntry> teams;

  @override
  List<Object?> get props => [pilotIds, rounds, retiredAtRound, teams];
}
