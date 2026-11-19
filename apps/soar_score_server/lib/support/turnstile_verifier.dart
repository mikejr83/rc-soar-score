import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

/// Cloudflare's Siteverify endpoint.
final siteverifyUri = Uri.parse(
  'https://challenges.cloudflare.com/turnstile/v0/siteverify',
);

/// The widget action the form renders; Siteverify must echo it.
const supportTurnstileAction = 'support';

/// How long Siteverify may take before the verification is unavailable.
const siteverifyDeadline = Duration(seconds: 5);

/// Error codes Siteverify uses for a token that cannot be used. Anything else
/// (secret, configuration or upstream faults) is an outage, not a rejection.
const _tokenCodes = {'invalid-input-response', 'timeout-or-duplicate'};

/// Verifies support challenge tokens with Cloudflare Turnstile Siteverify.
///
/// Requires `success`, the [supportTurnstileAction] action, and a hostname in
/// [allowedHostnames]. Refusals throw [SupportChallengeRejected]; every other
/// failure (secret, transport, timeout, invalid JSON) throws a plain exception,
/// which the support handler answers as unavailable.
class TurnstileVerifier implements SupportChallengeVerifier {
  TurnstileVerifier({
    required this.secret,
    required this.allowedHostnames,
    required this.client,
    this.deadline = siteverifyDeadline,
  });

  final String secret;
  final Set<String> allowedHostnames;
  final Duration deadline;
  final http.Client client;

  @override
  Future<void> verify(String token, {required String address}) async {
    // The visitor's address is not sent: a token is checked without it.
    final response = await client
        .post(siteverifyUri, body: {'secret': secret, 'response': token})
        .timeout(deadline);
    if (response.statusCode != 200) {
      throw StateError('Siteverify answered HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Siteverify body.');

    if (decoded['success'] == true) {
      final hostname = decoded['hostname'];
      if (decoded['action'] == supportTurnstileAction &&
          hostname is String &&
          allowedHostnames.contains(hostname)) {
        return;
      }
      throw const SupportChallengeRejected();
    }
    final codes = decoded['error-codes'];
    final list = codes is List ? codes.whereType<String>().toList() : const [];
    if (list.isNotEmpty && list.every(_tokenCodes.contains)) {
      throw const SupportChallengeRejected();
    }
    throw StateError('Siteverify refused the configuration.');
  }
}
