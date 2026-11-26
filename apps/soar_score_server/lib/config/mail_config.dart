import 'package:aws_common/aws_common.dart';

import '../mail/ses_v2_sender.dart';

/// The Fly app that serves the hosted API. Only it may send live mail.
const productionFlyApp = 'rc-soar-score-api';

/// The settings every feature that sends mail shares (support requests,
/// invitation emails): the delivery mode and the SES credentials.
class MailConfig {
  MailConfig({required this.mode, required this.sesCredentials});

  /// The variables [parse] reads (listed in `ServerConfig.environmentKeys`).
  static const environmentKeys = [
    'FLY_APP_NAME',
    'MAIL_DELIVERY_MODE',
    'SES_ACCESS_KEY_ID',
    'SES_SECRET_ACCESS_KEY',
  ];

  final MailDeliveryMode mode;
  final AWSCredentials sesCredentials;

  /// Reads the mail settings from [environment], or returns null when mail
  /// must stay disabled.
  ///
  /// Delivery mode: on `rc-soar-score-api` only an explicit `live` enables
  /// live mail. Elsewhere an unset value or `redirect` selects redirect, and
  /// any other value (including `live`) disables delivery.
  static MailConfig? parse(Map<String, String> environment) {
    String? value(String key) {
      final v = environment[key];
      return v == null || v.isEmpty ? null : v;
    }

    final rawMode = value('MAIL_DELIVERY_MODE');
    final MailDeliveryMode mode;
    if (value('FLY_APP_NAME') == productionFlyApp) {
      if (rawMode != 'live') return null;
      mode = MailDeliveryMode.live;
    } else if (rawMode == null || rawMode == 'redirect') {
      mode = MailDeliveryMode.redirect;
    } else {
      return null;
    }

    final accessKeyId = value('SES_ACCESS_KEY_ID');
    final secretAccessKey = value('SES_SECRET_ACCESS_KEY');
    if (accessKeyId == null || secretAccessKey == null) return null;
    return MailConfig(
      mode: mode,
      sesCredentials: AWSCredentials(accessKeyId, secretAccessKey),
    );
  }
}
