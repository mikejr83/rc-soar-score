import 'package:soar_score_core/soar_score_core.dart';

/// Where a contest's results hiding stands at one moment, for the "Overall
/// results" control card.
sealed class ResultsHiding {
  const ResultsHiding();

  /// Reads [contest] at [now]. Hiding that has run its 24 hours counts as
  /// [ResultsVisible] even though the stored values stay until the next
  /// change.
  factory ResultsHiding.of(Contest contest, DateTime now) {
    final round = contest.resultsHiddenThroughRound;
    final endsAt = contest.hidingEndsAt;
    if (round == null || endsAt == null || contest.hidingExpiredAt(now)) {
      return const ResultsVisible();
    }
    return ResultsHidden(throughRound: round, endsAt: endsAt);
  }
}

/// Overall scores and placing are shown.
class ResultsVisible extends ResultsHiding {
  const ResultsVisible();
}

/// Overall scores and placing are hidden through [throughRound] until
/// [endsAt] (UTC) at the latest.
class ResultsHidden extends ResultsHiding {
  const ResultsHidden({required this.throughRound, required this.endsAt});

  final int throughRound;
  final DateTime endsAt;

  /// Time left at [now] before the 24 hours run out.
  Duration remainingAt(DateTime now) => endsAt.difference(now.toUtc());
}
