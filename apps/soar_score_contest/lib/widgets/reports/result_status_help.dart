import 'package:flutter/material.dart';

import '../../services/reports/result_status.dart';
import 'result_status_chip.dart';

/// "What do these mean?": a button that opens a short popover defining the
/// result statuses. A popover, not a tooltip, so it can be read at leisure and
/// reached by keyboard.
class ResultStatusHelp extends StatelessWidget {
  const ResultStatusHelp({super.key});

  static const _definitions = [
    (
      ResultStatus.official,
      'Every round up to the last round shown is complete: each pilot has an '
          'official score, no reviews are open, and the standings were '
          'calculated under the current configuration and matrix. Printed '
          'pages carry no stamp.',
    ),
    (
      ResultStatus.preliminary,
      'A round up to the last round shown has a missing score, a score not '
          'yet marked official, or an open review, or the standings are stale '
          'after a configuration or matrix change. Every page is stamped '
          'PRELIMINARY.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MenuAnchor(
      crossAxisUnconstrained: false,
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              key: const ValueKey('result-status-help'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text('Result status', style: theme.textTheme.titleMedium),
                for (final (status, text) in _definitions)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      ResultStatusChip(status: status, compact: true),
                      Text(text, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                Text(
                  'Each printed page repeats the status in its footer.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, _) => TextButton.icon(
        key: const ValueKey('result-status-help-button'),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.help_outline, size: 18),
        label: const Text('What do these mean?'),
      ),
    );
  }
}
