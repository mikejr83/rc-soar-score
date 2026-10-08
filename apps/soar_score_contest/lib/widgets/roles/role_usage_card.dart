import 'package:flutter/material.dart';
import 'package:soar_score_core/services/role_usage.dart';

import '../api_error_text.dart';

/// Where a role is used: the contests that have participants in it. While
/// [usage] loads it shows a progress indicator, and a failure shows the
/// reason with a Retry button.
class RoleUsageCard extends StatelessWidget {
  const RoleUsageCard({super.key, required this.usage, required this.onRetry});

  final Future<List<RoleUsage>> usage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where it is used',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<RoleUsage>>(
              future: usage,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Usage could not be loaded. '
                          '${apiErrorText(snapshot.error!)}',
                        ),
                      ),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }
                final items = snapshot.data;
                if (items == null) {
                  return const LinearProgressIndicator();
                }
                if (items.isEmpty) {
                  return const Text('No contest uses this role yet.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${item.contestName}: ${item.participantCount} '
                          '${item.participantCount == 1 ? 'participant' : 'participants'}',
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
