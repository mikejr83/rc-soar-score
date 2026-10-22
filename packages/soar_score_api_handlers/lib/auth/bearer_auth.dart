import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../middleware/error_mapping.dart';
import '../middleware/request_id.dart';
import 'account_principal_resolver.dart';
import 'principal.dart';
import 'token_verifier.dart';
import 'user_profile.dart';

final _logger = Logger('BearerAuth');

/// An auth layer for the hosted server's `/api/v1` subtree.
///
/// Reads `Authorization: Bearer <token>`, has [verifier] check it, has
/// [resolver] map it to an account, and runs the inner handler with that
/// account's [Principal]. A missing or bad token is answered with 401
/// (`unauthorized`) before any route runs.
///
/// It has the shape of `AuthMiddleware`, so it plugs into `buildApiHandler`
/// where `fixedPrincipal` does for the offline instance.
///
/// 401s here are answered inside this layer, so the 400-404-409 warning line
/// from `handledError` never runs: they use an older `401 on METHOD /path`
/// format. That split is deliberate — `errorMappingMiddleware` sees the 401
/// only as an opaque response. Grepping one format misses the other.
Handler Function(Handler) bearerAuth({
  required TokenVerifier verifier,
  required AccountPrincipalResolver resolver,
}) =>
    (inner) => (request) async {
      final requestId = requestIdOf(request);
      Response unauthorized(String message) {
        _logger.warning(
          '401 on ${request.method} /${request.url.path}: $message',
        );
        return errorResponse(
          401,
          'unauthorized',
          message,
          requestId: requestId,
        ).change(headers: {'www-authenticate': 'Bearer'});
      }

      final header = request.headers['authorization'];
      if (header == null) {
        return unauthorized('A bearer token is required.');
      }
      final match = RegExp(
        r'^bearer\s+(\S+)$',
        caseSensitive: false,
      ).firstMatch(header.trim());
      if (match == null) {
        return unauthorized('The Authorization header must be a bearer token.');
      }
      final token = match.group(1)!;

      final VerifiedToken verified;
      try {
        verified = await verifier.verify(token);
      } on TokenRejectedException catch (e) {
        _logger.warning(
          'Rejected a token on ${request.method} /${request.url.path}: '
          '${e.reason}',
        );
        return unauthorized('The token is not valid.');
      }

      final Principal principal;
      try {
        principal = await resolver.resolve(verified, token);
      } on UserProfileUnavailableException catch (e) {
        _logger.warning('Could not fetch the profile for a new sign-in: $e');
        return errorResponse(
          503,
          'sign_in_unavailable',
          'Sign-in could not be completed. Try again shortly.',
          requestId: requestId,
        );
      }
      return inner(request.change(context: {principalContextKey: principal}));
    };
