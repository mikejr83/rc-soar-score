import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/theme/theme_controller.dart';

/// The `Appearance` card on the Settings page: a System, Light or Dark choice
/// that applies at once and is remembered on this device for the account.
class ThemeModeSetting extends StatelessWidget {
  const ThemeModeSetting({super.key, required this.controller});

  /// `null` when the build has no theme controller; the choice is then shown
  /// but cannot be changed.
  final ThemeController? controller;

  Future<void> _choose(
    BuildContext context,
    ThemeController controller,
    ThemeMode mode,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).themeSaveFailed;
    if (await controller.setMode(mode)) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
            Text(l10n.appearanceHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.appearanceDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              key: const ValueKey('theme-mode-control'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {controller?.mode ?? ThemeMode.system},
              onSelectionChanged: controller == null
                  ? null
                  : (selection) =>
                        _choose(context, controller, selection.single),
            ),
          ],
        ),
      ),
    );
  }
}
