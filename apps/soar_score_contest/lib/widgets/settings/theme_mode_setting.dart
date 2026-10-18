import 'package:flutter/material.dart';

import '../../services/theme/theme_controller.dart';

/// The `Appearance` card on the Settings page: a System, Light or Dark choice
/// that applies at once and is remembered on this device for the account.
class ThemeModeSetting extends StatelessWidget {
  const ThemeModeSetting({super.key, required this.controller});

  /// `null` when the build has no theme controller; the choice is then shown
  /// but cannot be changed.
  final ThemeController? controller;

  static const heading = 'Appearance';
  static const description =
      'Choose a light or dark look, or follow your device. This is saved on '
      'this device for your account and is not shared with other devices.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = this.controller;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              key: const ValueKey('theme-mode-control'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {controller?.mode ?? ThemeMode.system},
              onSelectionChanged: controller == null
                  ? null
                  : (selection) => controller.setMode(selection.single),
            ),
          ],
        ),
      ),
    );
  }
}
