import '../../services/preferences/director_time.dart';

import 'package:flutter/material.dart';

import '../../services/sync/refused_change.dart';

/// The changes the service refused: what was changed, when and why.
class RefusedChangesCard extends StatelessWidget {
  const RefusedChangesCard({super.key, required this.changes});

  /// Null while they load.
  final List<RefusedChange>? changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changes = this.changes;
    return Card(
      key: const ValueKey('refused-changes-card'),
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
                'Changes the service refused',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            if (changes == null)
              const Text('Loading…')
            else if (changes.isEmpty)
              const Text(
                'None. The service accepted every change it has answered.',
              )
            else
              for (final change in changes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${change.entityType}, changed '
                        '${DirectorTime.of(context)(change.madeAt)}',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(change.reason),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
