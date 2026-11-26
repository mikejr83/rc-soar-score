import 'dart:convert';

import 'package:aws_common/aws_common.dart';

import '../mail/ses_v2_sender.dart';
import 'mail_config.dart';

export 'mail_config.dart' show productionFlyApp;

/// Cloudflare's published dummy Turnstile secrets: they pass or fail every
/// challenge, so a live server must never run with one.
final _dummyTurnstileSecret = RegExp(r'^[123]x0{31}AA$');

/// The settings the public support endpoint needs. Built only when every
/// setting is valid; otherwise the endpoint is disabled (see [parse]).
class SupportConfig {
  SupportConfig({
    required this.mode,
    required this.sesCredentials,
    required this.turnstileSecret,
    required this.allowedHostnames,
    required this.throttleSecret,
  });

  /// The variables [parse] reads (listed in `ServerConfig.environmentKeys`).
  static const environmentKeys = [
    'FLY_APP_NAME',
    'MAIL_DELIVERY_MODE',
    'SES_ACCESS_KEY_ID',
    'SES_SECRET_ACCESS_KEY',
    'TURNSTILE_SECRET_KEY',
    'SUPPORT_ALLOWED_HOSTNAMES',
    'SUPPORT_THROTTLE_SECRET',
  ];

  final MailDeliveryMode mode;
  final AWSCredentials sesCredentials;

  /// Server-only verification secret. Never logged or described.
  final String turnstileSecret;

  /// Exact hostnames the Turnstile widget may report.
  final Set<String> allowedHostnames;

  /// Keys the throttle's HMAC; at least 32 bytes.
  final String throttleSecret;

  /// Reads the support settings from [environment], or returns null when the
  /// endpoint must stay disabled.
  ///
  /// Delivery mode: on `rc-soar-score-api` only an explicit `live` enables
  /// live mail. Elsewhere an unset value or `redirect` selects redirect, and
  /// any other value (including `live`) disables delivery.
  static SupportConfig? parse(Map<String, String> environment) {
    String? value(String key) {
      final v = environment[key];
      return v == null || v.isEmpty ? null : v;
    }

    final mail = MailConfig.parse(environment);
    if (mail == null) return null;
    final mode = mail.mode;

    final turnstile = value('TURNSTILE_SECRET_KEY');
    if (turnstile == null) return null;
    if (mode == MailDeliveryMode.live &&
        _dummyTurnstileSecret.hasMatch(turnstile)) {
      return null;
    }

    final hosts = <String>{};
    for (final raw in (value('SUPPORT_ALLOWED_HOSTNAMES') ?? '').split(',')) {
      final host = raw.trim();
      if (host.isEmpty) continue;
      if (!_isBareHostname(host)) return null;
      hosts.add(host);
    }
    if (hosts.isEmpty) return null;

    final throttle = value('SUPPORT_THROTTLE_SECRET');
    if (throttle == null || utf8.encode(throttle).length < 32) return null;

    return SupportConfig(
      mode: mode,
      sesCredentials: mail.sesCredentials,
      turnstileSecret: turnstile,
      allowedHostnames: hosts,
      throttleSecret: throttle,
    );
  }
}

/// A host name with no scheme, port, path or spaces.
bool _isBareHostname(String host) => RegExp(
  r'^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$',
).hasMatch(host);
