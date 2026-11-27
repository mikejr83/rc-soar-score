import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show
        InvitationDeliveryFeedback,
        InvitationEmailFeedback,
        InvitationFeedbackResult;

import 'sns_message.dart';
import 'sns_verifier.dart';

final _logger = Logger('SesFeedback');

/// The largest body the endpoint reads; SES notifications are a few KB.
const _maxBodyBytes = 256 * 1024;

/// How long confirming a subscription may take.
const _confirmDeadline = Duration(seconds: 5);

/// The answer while the endpoint is not configured.
Handler unavailableSesFeedbackHandler() =>
    (Request request) => handledError(
      request,
      503,
      'feedback_unavailable',
      'Delivery reports are not accepted here.',
    );

/// `POST /webhooks/ses-feedback`: receives SES bounce and complaint reports
/// through an SNS HTTPS subscription (#790).
///
/// Anonymous by nature (SNS sends no credentials), so every message is
/// checked by [verifier] first. A genuine report for an invitation email
/// marks that email `bounced` or `complained` through [feedback]; a
/// subscription confirmation from the configured topic is confirmed with a
/// request to its SNS address. Every other genuine message (delivery events,
/// reports about mail that is not an invitation, repeats) answers 200 and
/// changes nothing, because SNS retries anything else.
///
/// Message ids, addresses and bodies are never logged.
Handler sesFeedbackHandler({
  required SnsVerifier verifier,
  required InvitationDeliveryFeedback feedback,
  required http.Client client,
}) {
  return (Request request) async {
    if (request.method != 'POST') {
      return handledError(request, 405, 'method_not_allowed', 'Use POST.');
    }
    final body = await _readBody(request);
    if (body == null) {
      return handledError(request, 413, 'too_large', 'The body is too large.');
    }
    final message = SnsMessage.parse(body);
    if (message == null) {
      return handledError(request, 400, 'bad_request', 'Not an SNS message.');
    }
    switch (await verifier.verify(message)) {
      case SnsVerification.valid:
        break;
      case SnsVerification.invalid:
        return handledError(request, 403, 'forbidden', 'Not a valid message.');
      case SnsVerification.unavailable:
        // Nothing is wrong with the message; we could not check it. A 5xx
        // makes SNS deliver it again, where a 403 would drop it for good.
        return handledError(
          request,
          503,
          'verification_unavailable',
          'The message could not be verified right now. Try again later.',
        );
    }

    final bool done;
    switch (message.type) {
      case SnsMessageType.subscriptionConfirmation:
        done = await _confirm(message, verifier.topic, client);
      case SnsMessageType.unsubscribeConfirmation:
        _logger.warning('SNS reports that the feedback subscription ended.');
        done = true;
      case SnsMessageType.notification:
        done = await _record(message, feedback);
    }
    if (!done) {
      // Retryable: SNS delivers the message again after a short wait.
      return handledError(
        request,
        503,
        'try_again',
        'The message could not be handled yet. Try again later.',
      );
    }
    return Response.ok(
      '{}',
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  };
}

/// The body as text, or null when it is over the limit.
Future<String?> _readBody(Request request) async {
  final declared = request.contentLength;
  if (declared != null && declared > _maxBodyBytes) return null;
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > _maxBodyBytes) return null;
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return '';
  }
}

/// True when the subscription is confirmed, or the message is not one to act
/// on; false when the confirmation request failed and SNS should try again.
Future<bool> _confirm(
  SnsMessage message,
  SnsTopic topic,
  http.Client client,
) async {
  final url = message.subscribeUrl!;
  // The signature already ties the message to the configured topic; the
  // address must also be that topic's own SNS host, never one the sender
  // chose.
  if (!topic.allowsUrl(url)) {
    _logger.warning('A subscription confirmation named an unexpected host.');
    return true;
  }
  try {
    final response = await client.get(Uri.parse(url)).timeout(_confirmDeadline);
    if (response.statusCode == 200) {
      _logger.info('Feedback subscription confirmed.');
      return true;
    }
    _logger.warning(
      'Feedback subscription confirmation was refused '
      '(HTTP ${response.statusCode}).',
    );
    return false;
  } on Object catch (error) {
    _logger.warning(
      'Feedback subscription confirmation failed (${error.runtimeType}).',
    );
    return false;
  }
}

/// True when the report is dealt with; false when it may belong to a send
/// whose answer is not stored yet, so SNS should deliver it again.
Future<bool> _record(
  SnsMessage message,
  InvitationDeliveryFeedback feedback,
) async {
  final Object? payload;
  try {
    payload = jsonDecode(message.message);
  } on FormatException {
    return true;
  }
  if (payload is! Map) return true;
  final kind = payload['notificationType'] ?? payload['eventType'];
  final mail = payload['mail'];
  final messageId = mail is Map ? mail['messageId'] : null;
  if (messageId is! String) return true;

  final InvitationEmailFeedback report;
  String? bounceType;
  switch (kind) {
    case 'Bounce':
      report = InvitationEmailFeedback.bounce;
      final bounce = payload['bounce'];
      final raw = bounce is Map ? bounce['bounceType'] : null;
      bounceType = switch (raw) {
        'Permanent' => 'permanent',
        'Transient' => 'transient',
        _ => 'undetermined',
      };
    case 'Complaint':
      report = InvitationEmailFeedback.complaint;
    default:
      return true;
  }
  final result = await feedback.recordFeedback(
    messageId: messageId,
    feedback: report,
    bounceType: bounceType,
  );
  switch (result) {
    case InvitationFeedbackResult.recorded:
      _logger.info('An invitation email was reported as ${report.name}.');
    case InvitationFeedbackResult.pending:
      _logger.info('A report is waiting for a send to store its answer.');
      return false;
    case InvitationFeedbackResult.unchanged:
    case InvitationFeedbackResult.unmatched:
      break;
  }
  return true;
}
