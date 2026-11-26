import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show
        InvitationCodec,
        InvitationEmailService,
        InvitationMailer,
        InvitationService,
        PromotionIntentPolicy;
import 'package:soar_score_data/soar_score_data.dart';

import 'support/support_wiring.dart';

const String serverName = 'soar_score_server';
const String serverDisplayName = 'Soar Score API Server';
const String serverVersion = '0.1.0';

/// Builds the top-level [Handler] for the deployed API server.
///
/// Wires the shared routing and middleware from `soar_score_api_handlers` to
/// the repositories of [database] and reports the server's identity for the
/// `/health` payload. [authMiddleware] guards the `/api/v1` routes and sets
/// each request's principal. [corsAllowedOrigins] are the browser origins
/// allowed to call the API cross-origin. [invitationSecret] turns on the
/// participant routes (invitation links and guest sessions).
/// [selfScoringBaseUrl] is the site those links point at.
/// [trustedProxySecret] is what the site's `/api` proxy sends with the
/// visitor's address (see `clientAddressOf`).
///
/// [invitationEmailLimit] replaces the hourly cap of new invitation emails per
/// director and contest (tests).
///
/// [invitationMailer] sends invitation emails (#790); without it the email
/// route answers 409 `email_not_available`.
///
/// [supportHandler] serves `POST /public/support`; it defaults to an
/// unavailable (503) handler so a hosted server without support settings
/// still serves everything else.
///
/// Opening an invitation link is throttled per caller address with counters in
/// [database] (`request_throttles`), so every machine counts together and a
/// restart forgets nothing. [invitationThrottle] replaces that (tests).
Handler createServerHandler(
  SoarScoreDatabase database, {
  required AuthMiddleware authMiddleware,
  Set<String> corsAllowedOrigins = const {},
  String? invitationSecret,
  String? selfScoringBaseUrl,
  String? trustedProxySecret,
  InvitationThrottle? invitationThrottle,
  PromotionIntentPolicy? promotionIntents,
  Handler? supportHandler,
  InvitationMailer? invitationMailer,
  int? invitationEmailLimit,
}) {
  final repository = Repository(database);
  final invitations = invitationSecret == null
      ? null
      : InvitationService(
          repository,
          InvitationCodec.fromText(invitationSecret),
        );
  final linkBase = (selfScoringBaseUrl ?? defaultSelfScoringBaseUrl).replaceAll(
    RegExp(r'/+$'),
    '',
  );
  return buildApiHandler(
    name: serverName,
    displayName: serverDisplayName,
    version: serverVersion,
    schemaRevision: database.schemaVersion,
    repository: repository,
    authMiddleware: authMiddleware,
    publishingEnabled: true,
    promotionIntents: promotionIntents,
    selfScoringBaseUrl: selfScoringBaseUrl ?? defaultSelfScoringBaseUrl,
    corsAllowedOrigins: corsAllowedOrigins,
    trustedProxySecret: trustedProxySecret,
    supportHandler: supportHandler ?? unavailableSupportHandler(),
    invitationThrottle: invitationSecret == null
        ? null
        : invitationThrottle ??
              InvitationThrottle(
                store: RequestThrottleStore(database),
                keySecret: invitationSecret,
              ),
    invitations: invitations,
    invitationEmail: invitations == null || invitationMailer == null
        ? null
        : InvitationEmailService(
            repository,
            invitations,
            invitationMailer,
            linkFor: (credential) => '$linkBase/invitations/$credential',
            throttle: RequestThrottleStore(database),
            maxSendsPerWindow:
                invitationEmailLimit ??
                InvitationEmailService.defaultMaxSendsPerWindow,
          ),
  );
}
