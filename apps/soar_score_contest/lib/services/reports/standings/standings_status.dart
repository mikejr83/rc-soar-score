import '../report_availability.dart';
import '../reports_facts.dart';
import '../result_status.dart';
import 'standings_options.dart';
import 'standings_report_data.dart';

/// Whether the standings the sheet shows are official, and if not, why.
///
/// The stored standings carry their own flags: preliminary while a score
/// counted is missing or in review, and stale after a change to the
/// configuration, matrix or calculation. Either makes the sheet Preliminary.
class StandingsStatus {
  const StandingsStatus({required this.status, this.reason, this.action});

  factory StandingsStatus.of(
    ReportsFacts facts,
    StandingsOptions options,
    StandingsReportData data,
  ) {
    final results = data.results;
    if (!results.isPreliminary) {
      return const StandingsStatus(status: ResultStatus.official);
    }
    final standing = facts.standing;
    final missing = [
      for (final entry in standing.missingByRound.entries)
        if (entry.key <= options.to) entry,
    ]..sort((a, b) => a.key.compareTo(b.key));
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
        .where((entry) => entry.key <= options.to)
        .fold<int>(0, (sum, entry) => sum + entry.value.length);
    if (review > 0) {
      parts.add(
        '$review ${review == 1 ? 'pilot has' : 'pilots have'} a score '
        'in review',
      );
    }
    final String reason;
    if (parts.isEmpty) {
      reason = results.isStale
          ? 'these results were calculated before the latest change to the '
                'scores, the configuration or the matrix.'
          : 'some scores are not final yet.';
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
        round: missing.isEmpty ? null : missing.first.key,
      ),
    );
  }

  final ResultStatus status;

  /// Why it is not official, as the end of a sentence; `null` when it is.
  final String? reason;
  final ReportAction? action;
}
