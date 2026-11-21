import '../../../l10n/app_localizations.dart';
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
    AppLocalizations l10n,
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
    // Completion closes scoring, so a completed contest is official unless the
    // stored standings are stale or a score is still unresolved. This is the
    // same rule as the Reports card (`ReportsFacts.resultStatus`).
    final official = facts.isCompleted
        ? !results.isStale && unofficial == 0
        : !results.isPreliminary;
    if (official) {
      return const StandingsStatus(status: ResultStatus.official);
    }
    final parts = <String>[];
    for (final entry in missing.take(2)) {
      parts.add(l10n.standingsStatusRoundMissing(entry.key, entry.value));
    }
    if (missing.length > 2) {
      parts.add(l10n.standingsStatusMoreRounds(missing.length - 2));
    }
    final review = facts.inReviewByRound.entries
        .where((entry) => entry.key <= through)
        .fold<int>(0, (sum, entry) => sum + entry.value.length);
    if (review > 0) {
      parts.add(l10n.standingsStatusReview(review));
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
      reason = l10n.standingsStatusNotFinal;
    } else {
      final hint =
          options.provisional &&
              facts.lastFullyScoredRound > 0 &&
              facts.lastFullyScoredRound < options.to
              ? l10n.standingsStatusProvisionalHint(
                  facts.lastFullyScoredRound,
                )
              : '';
      reason = '${parts.join(' and ')}.$hint';
    }
    return StandingsStatus(
      status: ResultStatus.preliminary,
      reason: reason,
      action: ReportAction(
        l10n.standingsStatusOpenScoring,
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
