import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../middleware/error_mapping.dart';
import '../middleware/request_id.dart';
import 'guest_session_cookie.dart';
import 'participant_principal.dart';

/// The auth layer of the participant routes.
///
/// Takes the session token from `Authorization: Bearer <token>` (native
/// clients, tests) or, failing that, from the guest session cookie (the web
/// app). [service] checks it against the stored invitation, the contest
/// lifecycle and scoring access, and the inner handler runs with a
/// [ParticipantPrincipal]. It checks on every request, so replacing or
/// revoking an invitation ends access at once, even for a retained session.
/// A request that changes something (anything but GET and HEAD) is also
/// checked for scoring access, lock and completion.
///
/// A write authenticated by the cookie must also pass [requireCookieWriteIsSameSite]
/// (a bearer token needs no such check: a forged request cannot add it).
///
/// Every refusal of the session itself is the same 401 `session_invalid`; one
/// that came with a cookie also clears it.
Handler Function(Handler) guestSessionAuth(
  InvitationService service, {
  Set<String> allowedOrigins = const {},
}) =>
    (inner) => (request) async {
      final bearer = _bearerToken(request);
      final cookie = guestSessionFromCookieHeader(request.headers['cookie']);
      final token = bearer ?? cookie;
      final viaCookie = bearer == null && cookie != null;
      Response unauthorized() =>
          errorResponse(
            401,
            'session_invalid',
            'This session is not valid.',
            requestId: requestIdOf(request),
          ).change(
            headers: {if (viaCookie) 'set-cookie': guestSessionClearCookie()},
          );
      if (token == null) return unauthorized();

      final write = !_isSafe(request.method);
      if (write && viaCookie) {
        final refusal = requireCookieWriteIsSameSite(request, allowedOrigins);
        if (refusal != null) return refusal;
      }
      final ParticipantAccess access;
      try {
        access = await service.authorize(token, write: write);
      } on InvitationAccessError {
        return unauthorized();
      }
      return inner(
        request.change(
          context: {
            participantPrincipalContextKey: ParticipantPrincipal(access),
          },
        ),
      );
    };

/// A 403 `csrf_check_failed` unless a write that rides on the cookie comes
/// from the web app: the custom [webClientHeader] is present (so a browser
/// made a preflighted request) and an `Origin`, when sent, is one of
/// [allowedOrigins]. Returns null when it passes.
Response? requireCookieWriteIsSameSite(
  Request request,
  Set<String> allowedOrigins,
) {
  final origin = request.headers['origin'];
  final hasHeader = (request.headers[webClientHeader] ?? '').isNotEmpty;
  final originOk =
      origin == null ||
      allowedOrigins.isEmpty ||
      allowedOrigins.contains(origin);
  if (hasHeader && originOk) return null;
  return errorResponse(
    403,
    'csrf_check_failed',
    'This request did not come from the self-scoring app.',
    requestId: requestIdOf(request),
  );
}

bool _isSafe(String method) => method == 'GET' || method == 'HEAD';

String? _bearerToken(Request request) {
  final header = request.headers['authorization'];
  if (header == null) return null;
  return RegExp(
    r'^bearer\s+(\S+)$',
    caseSensitive: false,
  ).firstMatch(header.trim())?.group(1);
}
