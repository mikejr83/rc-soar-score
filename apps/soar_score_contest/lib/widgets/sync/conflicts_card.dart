import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/sync/open_conflict.dart';

/// The conflicts that wait for a decision, each with a button to review it.
class ConflictsCard extends StatelessWidget {
  const ConflictsCard({
    super.key,
    required this.conflicts,
    required this.zoneId,
    required this.onReview,
  });

  /// Null while they load.
  final List<OpenConflict>? conflicts;
  final String zoneId;
  final void Function(OpenConflict conflict) onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflicts = this.conflicts;
    return Card(
      key: const ValueKey('conflicts-card'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Conflicts to decide',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            if (conflicts == null)
              const Text('Loading…')
            else if (conflicts.isEmpty)
              const Text('None. Nothing is waiting for your decision.')
            else
              for (final conflict in conflicts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${conflict.entityType}, found '
                              '${ContestTime.format(conflict.createdAt, zoneId)}',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(conflict.explanation),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        key: ValueKey('conflict-review-${conflict.id}'),
                        onPressed: () => onReview(conflict),
                        child: const Text('Review'),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
