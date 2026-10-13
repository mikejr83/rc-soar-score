import '../progress/progress_summary.dart';
import '../workspace_fact_source.dart';
import '../workspace_facts.dart';
import 'attention_item.dart';
import 'attention_source.dart';

/// Scores missing from finished rounds. It reads the progress summary, so the
/// card and the list share one rule for what is missing. A round never flown
/// behind the latest scored round is part of this row, not a row of its own.
class MissingScoresSource implements AttentionSource {
  const MissingScoresSource();

  @override
  AttentionResult read(WorkspaceFacts facts) {
    if (!facts.hasMatrix) {
      return const AttentionResult();
    }
    if (facts.unavailable.contains(WorkspaceFactSource.scores)) {
      return const AttentionResult.unavailable();
    }
    final summary = ProgressSummary.of(facts);
    final missing = summary.missingRounds;
    if (missing.isEmpty) {
      return const AttentionResult();
    }
    final total = summary.missingTotal;
    return AttentionResult(
      items: [
        AttentionItem(
          kind: AttentionKind.missingScores,
          count: total,
          title:
              '$total ${total == 1 ? 'score' : 'scores'} missing in finished '
              '${missing.length == 1 ? 'round' : 'rounds'}',
          detail: [
            for (final round in missing)
              'Round ${round.ordinal}: ${round.missing}',
          ].join(', '),
          linkLabel: 'Open in Scoring',
          scoringRound: missing.first.ordinal,
        ),
      ],
    );
  }
}
