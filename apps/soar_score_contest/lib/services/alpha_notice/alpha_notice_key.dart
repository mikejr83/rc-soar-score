import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

/// How long an acknowledged alpha warning stays quiet.
const Duration alphaNoticeQuietPeriod = Duration(hours: 24);

/// When the alpha warning was last acknowledged on this device, or `null`
/// when it never was (or the stored value cannot be read).
///
/// Kept under the device-wide UI account rather than the signed-in account, so
/// signing in (which changes the account) does not bring the warning back.
final LocalUiKey<DateTime?> alphaNoticeAcknowledgedKey = LocalUiKey<DateTime?>(
  name: 'alpha_notice_acknowledged_at',
  defaultValue: null,
  encode: (at) => at?.toUtc().toIso8601String(),
  decode: (data) => DateTime.parse(data as String),
);
