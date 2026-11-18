import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/startup/startup_splash_control.dart';

/// The `Startup screen` card on the Settings page: a switch for the splash
/// shown while the app starts. [control] is `null` where there is no splash
/// (the web build); the card is then not shown.
class StartupSplashSetting extends StatefulWidget {
  const StartupSplashSetting({super.key, required this.control});

  final Future<StartupSplashControl?> control;

  @override
  State<StartupSplashSetting> createState() => _StartupSplashSettingState();
}

class _StartupSplashSettingState extends State<StartupSplashSetting> {
  bool? _enabled;

  Future<void> _change(StartupSplashControl control, bool value) async {
    setState(() => _enabled = value);
    await control.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<StartupSplashControl?>(
      future: widget.control,
      builder: (context, snapshot) {
        final control = snapshot.data;
        if (control == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.startupSplashHeading,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.startupSplashDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SwitchListTile(
                  key: const ValueKey('startup-splash-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.startupSplashSwitch),
                  value: _enabled ?? control.enabled,
                  onChanged: (value) => _change(control, value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
