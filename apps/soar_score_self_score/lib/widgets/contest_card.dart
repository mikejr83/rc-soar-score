import 'package:flutter/material.dart';

import 'status_chip.dart';

/// A contest in the list: name, dates, state and the person's next flight.
class ContestCard extends StatelessWidget {
  const ContestCard({
    required this.name,
    required this.dates,
    required this.next,
    required this.onTap,
    super.key,
  });

  final String name;
  final String dates;
  final String next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          dates,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const StatusChip(
                    label: 'In progress',
                    icon: Icons.flight,
                    style: StatusChipStyle.filled,
                  ),
                ],
              ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Next: ',
                        children: [
                          TextSpan(
                            text: next,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
