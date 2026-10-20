import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/preferences/preferences_controller.dart';

/// The `Language and formats` card on the Settings page: the shipped locales
/// plus following the device.
class LocaleSetting extends StatelessWidget {
  const LocaleSetting({super.key, required this.controller});

  final PreferencesController controller;

  /// The choice that leaves the locale to the device.
  static const String deviceChoice = '';

  static String _name(AppLocalizations l10n, String tag) => switch (tag) {
    'en-US' => l10n.localeEnUs,
    _ => tag,
  };

  Future<void> _choose(BuildContext context, String? choice) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final tag = choice == null || choice == deviceChoice ? null : choice;
    final message = switch (await controller.setLocale(tag)) {
      SaveResult.saved => null,
      SaveResult.needsSignIn => l10n.preferencesNeedSignIn,
      SaveResult.failed => l10n.localeSaveFailed,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.localeHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.localeDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => DropdownMenu<String>(
                key: ValueKey('locale-${controller.localeTag}'),
                initialSelection: controller.localeTag ?? deviceChoice,
                width: constraints.maxWidth,
                label: Text(l10n.localeLabel),
                inputDecorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                ),
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                    value: deviceChoice,
                    label: l10n.localeDevice,
                  ),
                  for (final tag in SupportedLocales.ids)
                    DropdownMenuEntry(value: tag, label: _name(l10n, tag)),
                ],
                onSelected: (value) => _choose(context, value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
