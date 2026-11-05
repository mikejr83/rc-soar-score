import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../middleware/error_mapping.dart';
import '../middleware/request_id.dart';
import 'participant_principal.dart';

/// The auth layer of the participant routes.
///
/// Reads `Authorization: Bearer <session token>`, has [service] check it
/// against the stored invitation, the contest lifecycle and scoring access,
/// and runs the inner handler with a [ParticipantPrincipal]. It checks on
/// every request, so replacing or revoking an invitation ends access at
/// once, even for a retained session. A request that changes something
/// (anything but GET and HEAD) is also checked for scoring access, lock and
/// completion.
///
/// Every refusal of the session itself is the same 401 `session_invalid`.
Handler Function(Handler) guestSessionAuth(InvitationService service) =>
    (inner) => (request) async {
      final header = request.headers['authorization'];
      final match = header == null
          ? null
          : RegExp(
              r'^bearer\s+(\S+)$',
              caseSensitive: false,
            ).firstMatch(header.trim());
      if (match == null) {
        return errorResponse(
          401,
          'session_invalid',
          'This session is not valid.',
          requestId: requestIdOf(request),
        );
      }
      final write = request.method != 'GET' && request.method != 'HEAD';
      final access = await service.authorize(match.group(1)!, write: write);
      return inner(
        request.change(
          context: {
            participantPrincipalContextKey: ParticipantPrincipal(access),
          },
        ),
      );
    };
