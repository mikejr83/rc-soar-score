import 'package:flutter/material.dart';

import '../collapsible_areas_provider.dart';
import '../preferences_controller_provider.dart';
import '../text_size_controller_provider.dart';
import '../theme_controller_provider.dart';
import '../widgets/settings/about_setting.dart';
import '../widgets/settings/locale_setting.dart';
import '../widgets/settings/reset_areas_setting.dart';
import '../widgets/settings/text_size_setting.dart';
import '../widgets/settings/theme_mode_setting.dart';
import '../widgets/settings/time_zone_setting.dart';

/// Settings kept on this device for the signed-in (or Local) account
/// (system scope, opened from the account control at the bottom of the rail).
///
/// The theme, the text size, the account's preferred time zone and locale, and resetting the
/// remembered hidden panels, and an About card (version, open source
/// licences, Privacy Policy and Terms).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = preferencesOf(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        // Every card is built, so a card far down the page can be found
        // without scrolling to it first.
        child: SingleChildScrollView(
          key: const ValueKey('settings-page'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ThemeModeSetting(controller: themeControllerOf(context)),
              TextSizeSetting(controller: textSizeControllerOf(context)),
              if (preferences != null) ...[
                TimeZoneSetting(controller: preferences),
                LocaleSetting(controller: preferences),
              ],
              ResetAreasSetting(controller: collapsibleAreasOf(context)),
              const AboutSetting(),
            ],
          ),
        ),
      ),
    );
  }
}
