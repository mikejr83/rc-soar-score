import '../../sync/sync_scope_summary.dart';
import '../workspace_facts.dart';
import 'attention_item.dart';
import 'attention_source.dart';

/// Changes the service refused and conflicts waiting for a decision. A build
/// that does not synchronize, or a contest with no sync state yet, adds no
/// row.
///
/// A *refused change* is a mutation the service answered `Rejected`; a
/// conflict is a `ConflictRecord` that needs action. Both stay until the
/// director looks at them, so both are rows here.
class SyncSource implements AttentionSource {
  const SyncSource(this.summary);

  /// The contest's sync summary; null when there is none to read.
  final SyncScopeSummary? summary;

  @override
  AttentionResult read(WorkspaceFacts facts) {
    final summary = this.summary;
    if (summary == null || summary.needsAttention == 0) {
      return const AttentionResult();
    }
    final refused = summary.rejectedChanges;
    final conflicts = summary.conflicts;
    final total = summary.needsAttention;
    return AttentionResult(
      items: [
        AttentionItem(
          kind: AttentionKind.rejectedSync,
          count: total,
          title: _title(refused, conflicts),
          detail: [
            if (refused > 0) '$refused refused by the service',
            if (conflicts > 0)
              '$conflicts ${conflicts == 1 ? 'conflict needs' : 'conflicts need'} '
                  'a decision',
          ].join(', '),
          linkLabel: 'Open sync details',
          opensSync: true,
        ),
      ],
    );
  }

  static String _title(int refused, int conflicts) {
    if (conflicts == 0) {
      return refused == 1
          ? '1 change was refused by the service'
          : '$refused changes were refused by the service';
    }
    if (refused == 0) {
      return conflicts == 1
          ? '1 conflict needs a decision'
          : '$conflicts conflicts need a decision';
    }
    return '${refused + conflicts} synced changes need a look';
  }
}
