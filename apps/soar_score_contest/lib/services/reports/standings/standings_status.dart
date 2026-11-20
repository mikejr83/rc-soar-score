import '../report_availability.dart';
import '../reports_facts.dart';
import '../result_status.dart';
import 'standings_options.dart';
import 'standings_report_data.dart';

/// Whether the standings the sheet shows are official, and if not, why.
///
/// The stored standings carry preliminary and stale flags. Completion closes
/// scoring, so blank flights alone do not make the sheet preliminary.
class StandingsStatus {
  const StandingsStatus({required this.status, this.reason, this.action});

  factory StandingsStatus.of(
    ReportsFacts facts,
    StandingsOptions options,
    StandingsReportData data,
  ) {
    final results = data.results;
    final standing = facts.standing;
    final missing = [
      for (final entry in standing.missingByRound.entries)
        if (entry.key <= options.to) entry,
    ]..sort((a, b) => a.key.compareTo(b.key));
    // A completed report can end before the last entered round when that
    // round has only pending scores. Those still affect its status.
    final through = facts.isCompleted ? facts.lastScoredRound : options.to;
    final unofficialByRound = standing.unofficialByRound.entries.where(
      (entry) => entry.key <= through,
    );
    final unofficial = unofficialByRound.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final completedWithGaps =
        facts.isCompleted && missing.isNotEmpty && !results.isStale;
    if ((!results.isPreliminary || completedWithGaps) &&
        (!facts.isCompleted || unofficial == 0)) {
      return const StandingsStatus(status: ResultStatus.official);
    }
    final parts = <String>[];
    for (final entry in missing.take(2)) {
      final count = entry.value;
      parts.add(
        'round ${entry.key} has $count missing '
        '${count == 1 ? 'score' : 'scores'}',
      );
    }
    if (missing.length > 2) {
      parts.add('${missing.length - 2} more rounds are missing scores');
    }
    final review = facts.inReviewByRound.entries
        .where((entry) => entry.key <= through)
        .fold<int>(0, (sum, entry) => sum + entry.value.length);
    if (review > 0) {
      parts.add(
        '$review ${review == 1 ? 'pilot has' : 'pilots have'} a score '
        'in review',
      );
    }
    final submitted = unofficial - review;
    if (facts.isCompleted && submitted > 0) {
      parts.add(
        '$submitted ${submitted == 1 ? 'score is' : 'scores are'} '
        'awaiting approval',
      );
    }
    if (results.isStale) {
      parts.add(
        'these results were calculated before the latest change to the '
        'scores, the configuration or the matrix',
      );
    }
    final String reason;
    if (parts.isEmpty) {
      reason = 'some scores are not final yet.';
    } else {
      final hint =
          options.provisional &&
              facts.lastFullyScoredRound > 0 &&
              facts.lastFullyScoredRound < options.to
          ? ' Turn off Provisional to print rounds 1 to '
                '${facts.lastFullyScoredRound} as Official.'
          : '';
      reason = '${parts.join(' and ')}.$hint';
    }
    return StandingsStatus(
      status: ResultStatus.preliminary,
      reason: reason,
      action: ReportAction(
        'Open Scoring',
        ReportDestination.scoring,
        round: missing.isNotEmpty
            ? missing.first.key
            : unofficialByRound.firstOrNull?.key,
      ),
    );
  }

  final ResultStatus status;

  /// Why it is not official, as the end of a sentence; `null` when it is.
  final String? reason;
  final ReportAction? action;
}
