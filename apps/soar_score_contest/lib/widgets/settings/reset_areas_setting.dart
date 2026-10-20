import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/collapsible_areas/collapsible_areas_controller.dart';

/// The `Panels` card on the Settings page: one button that brings back every
/// panel the user hid or minimized to how it starts.
class ResetAreasSetting extends StatelessWidget {
  const ResetAreasSetting({super.key, required this.controller});

  /// `null` when the build has no controller; the button is then disabled.
  final CollapsibleAreasController? controller;

  Future<void> _reset(
    BuildContext context,
    CollapsibleAreasController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await controller.resetAll();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved ? l10n.panelsResetDone : l10n.panelsResetSaveFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = this.controller;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.panelsHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.panelsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const ValueKey('reset-areas-button'),
              onPressed: controller == null
                  ? null
                  : () => _reset(context, controller),
              child: Text(l10n.panelsResetButton),
            ),
          ],
        ),
      ),
    );
  }
}
