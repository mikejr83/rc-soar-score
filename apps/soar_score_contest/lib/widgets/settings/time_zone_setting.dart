import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/new_contest/time_zones.dart';
import '../../services/preferences/preferences_controller.dart';
import '../new_contest/time_zone_picker.dart';

/// The `Time zone` card on the Settings page: the zone the director's own
/// times (last saved, last synced) are shown in. Pilot-facing times keep the
/// contest's zone.
class TimeZoneSetting extends StatelessWidget {
  const TimeZoneSetting({super.key, required this.controller});

  final PreferencesController controller;

  Future<void> _choose(BuildContext context, String? zoneId) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final message = switch (await controller.setTimeZone(zoneId)) {
      SaveResult.saved => null,
      SaveResult.needsSignIn => l10n.preferencesNeedSignIn,
      SaveResult.failed => l10n.timeZoneSaveFailed,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final zone = controller.timeZone;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.timeZoneHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.timeZoneDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TimeZonePicker(
              zone: zone ?? TimeZones.device(),
              helperText: zone == null ? l10n.timeZoneFollowsDevice : null,
              onChanged: (value) => _choose(context, value),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('time-zone-device-button'),
              onPressed: zone == null ? null : () => _choose(context, null),
              child: Text(l10n.timeZoneDeviceButton),
            ),
          ],
        ),
      ),
    );
  }
}
