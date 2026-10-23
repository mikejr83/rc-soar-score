import 'results_snapshot.dart';

/// The results page: standings as of a round, plus what the contest holds.
class ResultsView {
  const ResultsView({
    required this.contestName,
    required this.latestRound,
    required this.snapshot,
    this.heldRound,
  });

  final String contestName;
  final int latestRound;

  /// The standings as of [ResultsSnapshot.round].
  final ResultsSnapshot snapshot;

  /// The round standings are held at while the director hides overall
  /// results; null when nothing is hidden.
  final int? heldRound;

  bool get isLatest => snapshot.round == latestRound;
}
