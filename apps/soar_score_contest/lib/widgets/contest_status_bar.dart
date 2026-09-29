import 'package:flutter/material.dart';

/// The shell's application status area (ticket 020 slot, ticket 023 content).
///
/// A thin full-width bar at the bottom of the shell: icon plus text placeholder.
/// State is communicated by icon and text, never by color alone.
class ContestStatusBar extends StatelessWidget {
  const ContestStatusBar({super.key});

  static const String status = 'Ready';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('contest-status-bar'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Semantics(
        label: 'Application status',
        value: status,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(status, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
