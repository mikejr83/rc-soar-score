import 'app_localizations.dart';

/// The words for a flight's zero reason [code] (`out_of_bounds`), or null
/// when the zero has no reason. A code this build does not know reads as its
/// own words, so a new server code still shows something sensible.
String? zeroReasonLabel(AppLocalizations l10n, String? code) {
  if (code == null) return null;
  return switch (code.toLowerCase()) {
    'out_of_bounds' => l10n.zeroReasonOutOfBounds,
    'motor_restart' => l10n.zeroReasonMotorRestart,
    'no_altitude_recorded' => l10n.zeroReasonNoAltitudeRecorded,
    'overflight_gt_one_min' => l10n.zeroReasonOverflight,
    final other => other.replaceAll('_', ' '),
  };
}
