import 'dart:async';
import 'dart:convert';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'transactional_mail_sender.dart';

final _logger = Logger('SesV2Sender');

/// The sending region: Ohio, fixed by the deployment plan.
const sesRegion = 'us-east-2';

/// The address every message is sent from.
const sesFromAddress = 'notifications@rcsoarscore.com';

/// The only recipient redirect mode delivers to.
const redirectRecipient = 'test@rcsoarscore.com';

/// Subject prefix in redirect mode, so a test message cannot be mistaken for
/// a live one.
const redirectSubjectPrefix = '[TEST] ';

/// How long a send may wait for SES before it is unconfirmed.
const sesSendDeadline = Duration(seconds: 10);

/// Where a sender delivers. Live keeps the caller's destinations; redirect
/// replaces them with [redirectRecipient] (see [applyDeliveryMode]).
enum MailDeliveryMode { live, redirect }

/// Applies [mode] to [message] immediately before transport.
///
/// Redirect mode sends only to the test alias, removes CC and BCC, replaces
/// Reply-To with the test alias and prefixes the subject. Live mode keeps the
/// intended destinations.
MailMessage applyDeliveryMode(MailMessage message, MailDeliveryMode mode) {
  if (mode == MailDeliveryMode.live) return message;
  return MailMessage(
    to: const [redirectRecipient],
    replyTo: const [redirectRecipient],
    subject: '$redirectSubjectPrefix${message.subject}',
    text: message.text,
  );
}

/// Sends mail through the SES v2 HTTPS `SendEmail` API in Ohio.
///
/// [credentials] is a static key pair. A null [credentials] or [mode] means
/// the sender is not configured: every send returns [MailUnavailable] without
/// a network call.
///
/// Each send is one signed POST with no automatic retry: SES has no
/// idempotency token, so a retry could send a second copy.
class SesV2Sender implements TransactionalMailSender {
  SesV2Sender({
    required this.client,
    this.credentials,
    this.mode,
    this.deadline = sesSendDeadline,
  });

  final http.Client client;
  final AWSCredentials? credentials;
  final MailDeliveryMode? mode;
  final Duration deadline;

  static final endpoint = Uri.https(
    'email.$sesRegion.amazonaws.com',
    '/v2/email/outbound-emails',
  );

  @override
  Future<MailOutcome> send(MailMessage message) async {
    final credentials = this.credentials;
    final mode = this.mode;
    if (credentials == null || mode == null) {
      return const MailUnavailable();
    }

    final delivered = applyDeliveryMode(message, mode);
    final body = utf8.encode(jsonEncode(_payload(delivered)));
    final unsigned = AWSHttpRequest(
      method: AWSHttpMethod.post,
      uri: endpoint,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      body: body,
    );

    final http.Response response;
    try {
      final signed = await AWSSigV4Signer(
        credentialsProvider: AWSCredentialsProvider(credentials),
      ).sign(
        unsigned,
        credentialScope: AWSCredentialScope(
          region: sesRegion,
          service: AWSService.sesV2,
        ),
      );
      final request = http.Request('POST', endpoint)
        ..headers.addAll(signed.headers)
        ..bodyBytes = body;
      // One deadline for the whole exchange: the headers and the body share it.
      response = await _exchange(request).timeout(deadline);
    } on Object catch (error) {
      // A lost or late response: SES may have accepted the message.
      _logger.warning('SES send unconfirmed (${error.runtimeType}).');
      return const MailUnconfirmed();
    }

    return _outcome(response);
  }

  Future<http.Response> _exchange(http.BaseRequest request) async {
    final streamed = await client.send(request);
    return http.Response.fromStream(streamed);
  }

  MailOutcome _outcome(http.Response response) {
    final status = response.statusCode;
    if (status == 200) {
      try {
        final decoded = jsonDecode(response.body);
        final id = decoded is Map ? decoded['MessageId'] : null;
        if (id is String && id.isNotEmpty) return MailAccepted(id);
      } on FormatException {
        // Fall through: a success without a readable id is unconfirmed.
      }
      _logger.warning('SES success without a MessageId.');
      return const MailUnconfirmed();
    }
    if (status == 403 || status == 429) {
      // Denied credentials or throttling: nothing was sent.
      _logger.warning('SES refused the send (HTTP $status).');
      return const MailUnavailable();
    }
    if (status >= 500) {
      _logger.warning('SES server failure (HTTP $status).');
      return const MailUnconfirmed();
    }
    _logger.warning('SES rejected the send (HTTP $status).');
    return const MailRejected();
  }

  static Map<String, Object> _payload(MailMessage message) => {
    'FromEmailAddress': sesFromAddress,
    'Destination': {
      'ToAddresses': message.to,
      if (message.cc.isNotEmpty) 'CcAddresses': message.cc,
      if (message.bcc.isNotEmpty) 'BccAddresses': message.bcc,
    },
    if (message.replyTo.isNotEmpty) 'ReplyToAddresses': message.replyTo,
    'Content': {
      'Simple': {
        'Subject': {'Data': message.subject, 'Charset': 'UTF-8'},
        'Body': {
          'Text': {'Data': message.text, 'Charset': 'UTF-8'},
        },
      },
    },
  };
}
