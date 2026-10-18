import 'package:flutter/material.dart';

import '../theme_controller_provider.dart';
import '../widgets/settings/theme_mode_setting.dart';

/// Settings kept on this device for the signed-in (or Local) account
/// (system scope, opened from the account control at the bottom of the rail).
///
/// Today: the theme. Reset-to-defaults and the time zone and locale
/// preferences arrive with #321 and #325.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          key: const ValueKey('settings-page'),
          padding: const EdgeInsets.all(16),
          children: [ThemeModeSetting(controller: themeControllerOf(context))],
        ),
      ),
    );
  }
}
