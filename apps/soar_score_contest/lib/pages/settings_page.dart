import 'package:flutter/material.dart';

import '../collapsible_areas_provider.dart';
import '../theme_controller_provider.dart';
import '../widgets/settings/reset_areas_setting.dart';
import '../widgets/settings/theme_mode_setting.dart';

/// Settings kept on this device for the signed-in (or Local) account
/// (system scope, opened from the account control at the bottom of the rail).
///
/// Today: the theme and resetting the remembered hidden panels. The time zone
/// and locale preferences arrive with #325.
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
          children: [
            ThemeModeSetting(controller: themeControllerOf(context)),
            ResetAreasSetting(controller: collapsibleAreasOf(context)),
          ],
        ),
      ),
    );
  }
}
