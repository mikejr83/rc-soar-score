import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/reports/result_status.dart';
import 'result_status_chip.dart';

/// "What do these mean?": a button that opens a short popover defining the
/// result statuses. A popover, not a tooltip, so it can be read at leisure and
/// reached by keyboard.
class ResultStatusHelp extends StatelessWidget {
  const ResultStatusHelp({super.key});

  static List<(ResultStatus, String)> _definitions(AppLocalizations l10n) => [
    (ResultStatus.official, l10n.resultStatusOfficial),
    (ResultStatus.preliminary, l10n.resultStatusPreliminary),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final definitions = _definitions(l10n);
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
                Text(
                  l10n.resultStatusHelpTitle,
                  style: theme.textTheme.titleMedium,
                ),
                for (final (status, text) in definitions)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      ResultStatusChip(status: status, compact: true),
                      Text(text, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                Text(
                  l10n.resultStatusHelpFooter,
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
        label: Text(l10n.resultStatusHelpButton),
      ),
    );
  }
}
