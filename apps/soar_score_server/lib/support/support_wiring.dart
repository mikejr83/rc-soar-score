import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_data/soar_score_data.dart';

import '../config/support_config.dart';
import '../mail/ses_v2_sender.dart';
import '../mail/transactional_mail_sender.dart';
import 'turnstile_verifier.dart';

/// The inbox every support request is delivered to.
const supportInbox = 'support@rcsoarscore.com';

/// The answer while the support endpoint is not configured: 503, never a
/// send, so a hosted server without settings still starts and serves the rest.
Handler unavailableSupportHandler() =>
    (Request request) => handledError(
      request,
      503,
      'support_unavailable',
      'Support requests are unavailable right now. Please try again later.',
    );

/// The real support endpoint, built from [config].
///
/// [http] is the upstream client the verifier and sender share; the caller
/// owns it and closes it on shutdown.
Handler supportHandlerFor(
  SupportConfig config,
  SoarScoreDatabase database, {
  required http.Client http,
  String? trustedProxySecret,
}) {
  return buildSupportHandler(
    quota: SupportAttemptQuota(
      store: RequestThrottleStore(database),
      keySecret: config.throttleSecret,
    ),
    verifier: TurnstileVerifier(
      secret: config.turnstileSecret,
      allowedHostnames: config.allowedHostnames,
      client: http,
    ),
    send: supportSender(
      SesV2Sender(
        client: http,
        credentials: config.sesCredentials,
        mode: config.mode,
      ),
    ),
    trustedProxySecret: trustedProxySecret,
  );
}

/// Turns a validated submission into a mail to [supportInbox] and maps the
/// sender's outcome to the endpoint's contract.
SupportSender supportSender(TransactionalMailSender mail) =>
    (SupportSubmission submission) async {
      final outcome = await mail.send(
        MailMessage(
          to: const [supportInbox],
          replyTo: [submission.email],
          subject: 'Support: ${submission.requestType}',
          text: _body(submission),
        ),
      );
      return switch (outcome) {
        MailAccepted() => SupportDelivery.accepted,
        MailRejected() => SupportDelivery.rejected,
        MailUnavailable() => SupportDelivery.unavailable,
        MailUnconfirmed() => SupportDelivery.unconfirmed,
      };
    };

String _body(SupportSubmission s) => [
  'Name: ${s.name}',
  'Email: ${s.email}',
  'Category: ${s.requestType}',
  if (s.userType.isNotEmpty) 'Role: ${s.userType}',
  '',
  s.message,
  '',
].join('\n');
