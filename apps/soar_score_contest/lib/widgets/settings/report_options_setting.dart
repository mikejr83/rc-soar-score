import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/reports/viewer/report_options_store.dart';

/// The `Report options` card on the Settings page: one button that brings
/// every report's remembered options back to how they start.
class ReportOptionsSetting extends StatelessWidget {
  const ReportOptionsSetting({super.key, required this.store});

  /// `null` when the build has no store; the button is then disabled.
  final ReportOptionsStore? store;

  Future<void> _reset(BuildContext context, ReportOptionsStore store) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await store.reset();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? l10n.reportOptionsResetDone
              : l10n.reportOptionsResetSaveFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final store = this.store;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reportOptionsHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.reportOptionsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const ValueKey('reset-report-options-button'),
              onPressed: store == null ? null : () => _reset(context, store),
              child: Text(l10n.reportOptionsResetButton),
            ),
          ],
        ),
      ),
    );
  }
}
