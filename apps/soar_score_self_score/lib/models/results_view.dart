import 'officialization_policy.dart';
import 'results_snapshot.dart';

/// The results page: standings as of a round, plus what the contest holds.
class ResultsView {
  const ResultsView({
    required this.contestName,
    required this.latestRound,
    required this.snapshot,
    this.heldRound,
    this.policy,
    this.preliminary = true,
  });

  final String contestName;
  final int latestRound;

  /// The standings as of [ResultsSnapshot.round].
  final ResultsSnapshot snapshot;

  /// The round standings are held at while the director hides overall
  /// results; null when nothing is hidden.
  final int? heldRound;

  /// When the contest makes scores official; null when unknown.
  final OfficializationPolicy? policy;

  /// False once every score in the standings is official.
  final bool preliminary;

  bool get isLatest => snapshot.round == latestRound;
}
