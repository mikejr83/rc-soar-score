import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show RequestThrottleStore;

import '../middleware/client_address.dart';
import '../middleware/error_mapping.dart';
import '../middleware/request_limits.dart';
import 'health_handler.dart' show jsonResponse;
import 'request_body.dart';

final _logger = Logger('Support');

/// The request categories the public support form offers (plan
/// `plan/ui/public-site/support.md`). Exact strings: the form sends them.
const supportRequestTypes = {
  'Public site issue',
  'Contest Management',
  'Online Score Entry',
  'Feature Request',
  'User Account Inquiry',
  'General Inquiry',
  'Emergency Contest Issue',
};

/// The optional role the form offers; blank is allowed.
const supportUserTypes = {'Contest Director', 'Pilot', 'Participant'};

/// The longest message, in UTF-16 units, as the web form counts it.
const supportMessageLimit = 2000;

/// The largest support request body: the form's fields fit well under it.
const _maxSupportBodyBytes = 32 * 1024;

/// The longest challenge token Turnstile issues.
const _maxTokenLength = 2048;

/// Field names the form sends. Any other field is refused, so a caller can
/// never choose the destination of the mail.
const _allowedFields = {
  'name',
  'email',
  'userType',
  'requestType',
  'message',
  'captchaToken',
};

/// Printable ASCII, except the characters SES and mail headers forbid in an
/// address (commas, semicolons, angle brackets and double quotes).
final _printableAscii = RegExp(r'^[\x20-\x7E]*$');
final _emailShape = RegExp(
  r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+"
  r'@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
  r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
);

/// Validates one address the way the public form does (the server repeats
/// the rule, so direct posts are held to it too).
///
/// [raw] must hold only printable ASCII; surrounding ASCII spaces are trimmed.
/// Returns the trimmed address, or null when it is not one address. Unicode
/// domains are refused, not converted.
String? validateSupportEmail(String raw) {
  if (!_printableAscii.hasMatch(raw)) return null;
  final trimmed = raw.replaceAll(RegExp(r'^ +| +$'), '');
  if (trimmed.length > 254) return null;
  return _emailShape.hasMatch(trimmed) ? trimmed : null;
}

/// One validated submission from the public form.
class SupportSubmission {
  const SupportSubmission({
    required this.name,
    required this.email,
    required this.userType,
    required this.requestType,
    required this.message,
  });

  final String name;

  /// The trimmed, validated address; it becomes the live Reply-To.
  final String email;

  /// The optional role, or empty.
  final String userType;
  final String requestType;

  /// The message as sent (not trimmed), at most [supportMessageLimit].
  final String message;
}

/// What became of a validated submission once the mail sender answered.
enum SupportDelivery {
  /// The provider accepted the message with an id.
  accepted,

  /// The provider refused it, or the sender is not configured.
  rejected,

  /// The provider was throttling or denied the send before accepting it.
  unavailable,

  /// The outcome is unknown: the message may have been sent.
  unconfirmed,
}

/// Thrown by a [SupportChallengeVerifier] when Turnstile refused the token.
class SupportChallengeRejected implements Exception {
  const SupportChallengeRejected();
}

/// Verifies Turnstile challenge tokens. Any other exception means the
/// verification could not be completed (the handler answers 503).
abstract interface class SupportChallengeVerifier {
  Future<void> verify(String token, {required String address});
}

/// Sends one validated submission. Its own exceptions are unconfirmed.
typedef SupportSender = Future<SupportDelivery> Function(SupportSubmission);

/// Counts every attempt to use the support endpoint, shared by every
/// instance that uses [store].
///
/// Unlike invitation redemption, sending mail has no in-memory fallback: when
/// the store fails, [admit] throws and the endpoint answers 503 before any
/// upstream call. Callers are stored as a keyed hash ([keySecret]); the
/// unknown address shares one bucket key.
class SupportAttemptQuota {
  SupportAttemptQuota({
    required this.store,
    required String keySecret,
    this.maxAttempts = 5,
    this.window = const Duration(minutes: 10),
    DateTime Function()? clock,
  }) : _keySecret = utf8.encode(keySecret),
       _clock = clock ?? DateTime.now;

  final RequestThrottleStore store;
  final int maxAttempts;
  final Duration window;
  final List<int> _keySecret;
  final DateTime Function() _clock;
  DateTime? _lastPurge;

  static const _bucket = 'support-attempts';

  /// Counts one attempt from [address]. Throws [TooManyRequestsError] from
  /// the attempt after [maxAttempts] until the window ends. Other exceptions
  /// mean the store failed.
  Future<void> admit(String address) async {
    final now = _clock();
    final caller = address == 'unknown'
        ? 'unknown'
        : Hmac(sha256, _keySecret).convert(utf8.encode(address)).toString();
    final count = await store.hit(_bucket, caller, window: window, now: now);
    // Cleanup never changes the decision the count gave.
    await _purge(now);
    if (count.count > maxAttempts) {
      final left = count.windowStart.add(window).difference(now);
      throw TooManyRequestsError(left.isNegative ? Duration.zero : left);
    }
  }

  Future<void> _purge(DateTime now) async {
    final last = _lastPurge;
    if (last != null && now.difference(last) < window) return;
    _lastPurge = now;
    try {
      await store.purgeBefore(now.subtract(window));
    } on Object catch (error) {
      _logger.warning('Support counter cleanup failed (${error.runtimeType}).');
    }
  }
}

/// Builds the handler for `POST /public/support`.
///
/// Order: count the attempt (before any body is read), read the body with a
/// [bodyDeadline], validate every field, verify the challenge, then send.
/// Every failure before the send returns without sending mail.
Handler buildSupportHandler({
  required SupportAttemptQuota quota,
  required SupportChallengeVerifier verifier,
  required SupportSender send,
  String? trustedProxySecret,
  Duration bodyDeadline = const Duration(seconds: 10),
}) {
  return (Request request) async {
    final address = clientAddressOf(
      request,
      trustedProxySecret: trustedProxySecret,
    );
    try {
      await quota.admit(address);
    } on TooManyRequestsError {
      rethrow;
    } on Object catch (error) {
      _logger.warning('Support quota unavailable (${error.runtimeType}).');
      return _unavailable(request);
    }

    final parsed = await _readSubmission(request, bodyDeadline);
    if (parsed == null) return _timeoutResponse(request);
    final (submission, token) = parsed;

    try {
      await verifier.verify(token, address: address);
    } on SupportChallengeRejected {
      return handledError(
        request,
        400,
        'captcha_invalid',
        'The spam check was not passed. Please try again.',
      );
    } on Object catch (error) {
      _logger.warning('Turnstile verification failed (${error.runtimeType}).');
      return _unavailable(request);
    }

    final SupportDelivery outcome;
    try {
      outcome = await send(submission);
    } on Object catch (error) {
      _logger.warning('Support mail send threw (${error.runtimeType}).');
      return _unconfirmed(request);
    }
    switch (outcome) {
      case SupportDelivery.accepted:
        return jsonResponse({'accepted': true});
      case SupportDelivery.rejected:
      case SupportDelivery.unavailable:
        return _unavailable(request);
      case SupportDelivery.unconfirmed:
        return _unconfirmed(request);
    }
  };
}

/// Reads and validates the body, or returns null when reading timed out.
///
/// The timeout is reported separately so it can answer 408 before any
/// upstream call. Validation problems are [ArgumentError]s (400), and an
/// oversized body is a 413 from [readJsonBody].
Future<(SupportSubmission, String)?> _readSubmission(
  Request request,
  Duration deadline,
) async {
  try {
    return await readJsonBody<(SupportSubmission, String)>(
      request,
      _parse,
      maxBytes: _maxSupportBodyBytes,
      within: deadline,
    );
  } on TimeoutException {
    return null;
  }
}

(SupportSubmission, String) _parse(Map<String, dynamic> json) {
  for (final key in json.keys) {
    if (!_allowedFields.contains(key)) {
      throw ArgumentError('The request has a field that is not allowed.');
    }
  }
  String text(String key) {
    final value = json[key];
    if (value is! String) {
      throw ArgumentError('"$key" must be a text value.');
    }
    return value;
  }

  final name = text('name').trim();
  if (name.isEmpty) throw ArgumentError('"name" is required.');

  final rawEmail = text('email');
  final email = validateSupportEmail(rawEmail);
  if (email == null) {
    throw ArgumentError(
      '"email" must be one ASCII email address, such as name@example.com.',
    );
  }

  final userType = json['userType'] == null ? '' : text('userType');
  if (userType.isNotEmpty && !supportUserTypes.contains(userType)) {
    throw ArgumentError('"userType" is not one of the offered choices.');
  }

  final requestType = text('requestType');
  if (!supportRequestTypes.contains(requestType)) {
    throw ArgumentError('"requestType" is not one of the offered choices.');
  }

  final message = text('message');
  if (message.trim().isEmpty) throw ArgumentError('"message" is required.');
  if (message.length > supportMessageLimit) {
    throw ArgumentError(
      '"message" must be at most $supportMessageLimit characters.',
    );
  }

  final token = text('captchaToken');
  if (token.isEmpty || token.length > _maxTokenLength) {
    throw ArgumentError('"captchaToken" is required.');
  }

  return (
    SupportSubmission(
      name: name,
      email: email,
      userType: userType,
      requestType: requestType,
      message: message,
    ),
    token,
  );
}

Response _timeoutResponse(Request request) => handledError(
  request,
  408,
  'request_timeout',
  'The request did not arrive in time. Please try again.',
);

Response _unavailable(Request request) => handledError(
  request,
  503,
  'support_unavailable',
  'Support requests are unavailable right now. Please try again later.',
);

Response _unconfirmed(Request request) => handledError(
  request,
  503,
  'delivery_unconfirmed',
  'We could not confirm that your message was delivered. It may have been '
      'sent; please check before sending it again.',
);
