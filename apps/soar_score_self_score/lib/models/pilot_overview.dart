import 'pilot_round.dart';

/// Everything the pilot overview shows for one pilot.
class PilotOverview {
  const PilotOverview({
    required this.contestName,
    required this.teamName,
    required this.pilotName,
    this.pilotNumber,
    required this.rounds,
  });

  final String contestName;
  final String? teamName;
  final String pilotName;

  /// Null when the contest gives pilots no number.
  final int? pilotNumber;
  final List<PilotRound> rounds;

  /// The round that must be scored before any later one opens.
  int get nextRound => rounds
      .firstWhere(
        (round) => round.status == PilotRoundStatus.nextToScore,
        orElse: () => rounds.last,
      )
      .number;
}
