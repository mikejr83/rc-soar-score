import 'package:material_ui/material_ui.dart';

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
      'Entered scores are official and no reviews are open. A completed '
          'contest can have blank flights. Printed pages carry no stamp.',
    ),
    (
      ResultStatus.preliminary,
      'A score awaits approval or review, the standings are out of date, '
          'or an open contest has a missing score in the rounds shown. '
          'Every page is stamped PRELIMINARY.',
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
