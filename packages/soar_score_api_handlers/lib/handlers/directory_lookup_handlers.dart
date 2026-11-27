import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/middleware/request_limits.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the routes where a signed-in director finds listed pilots in the
/// directory and copies one into their pilot list (#653) to [router]
/// (mounted under `/api/v1`):
///
/// - `POST /directory/lookups` ([DirectoryLookupRequest], answers a
///   [DirectoryLookupResponse]) finds listed pilots by exactly one of a
///   verified email, an FAI number or a national organization ID. It is a
///   POST so a typed email never reaches a URL or an access log. A pilot who
///   is not listed answers exactly as one who does not exist: an empty list.
///   A pilot who keeps their email private is not found by it either. An ID
///   answers every pilot holding it, each flagged `shared_key` when several
///   do (two countries can issue the same ID). A blank value is 400.
///   Lookups are limited per account (429).
/// - `POST /directory/copies` ([DirectoryCopyRequest], answers a
///   [DirectoryMatchDto]) links the pilot's account to the director's own
///   participant profile (which may not have synced yet) and returns the
///   details to copy. The pilot is never told which director copied them,
///   and the profile is never written here. Repeating it changes nothing.
///   404 `link_not_found` for an entry that is gone or not listed, 403
///   `profile_not_owned` for another director's profile, 409 `already_linked`
///   when another account holds the profile.
/// - `POST /directory/refreshes` ([DirectoryCopyRequest], answers a
///   [DirectoryMatchDto]) returns the entry's current details for the
///   director whose confirmed directory link to that profile is in place. It
///   writes nothing; 404 `link_not_found` for anything else.
///
/// Any number of directors can copy the same pilot, each to their own
/// profile. A stored email is returned only when the pilot made it visible,
/// and neither it nor the email a director typed is logged. A guest, local or
/// deleted account is 403 `registered_account_required`, before anything else
/// is said. With [invitations] null (no invitation secret) lookups still
/// work and copying answers 409 `invitations_not_available`; the embedded instance has no accounts and
/// answers 403 for the Local account.
void addDirectoryLookupRoutes(
  Router router,
  Repository repository, {
  required InvitationService? invitations,
  RequestRateLimiter? lookupLimiter,
}) {
  // A director typing a contest's roster is well inside this; a script
  // sweeping emails or ids is not.
  final limiter =
      lookupLimiter ??
      RequestRateLimiter(maxRequests: 60, window: const Duration(minutes: 10));
  // Looking up needs no invitation secret; copying does, and says so only
  // to a signed-in director.
  final service = DirectoryLookupService(
    repository,
    invitations == null
        ? null
        : ParticipantLinkService(repository, invitations),
  );

  DirectoryMatchDto dto(DirectoryMatch match) => DirectoryMatchDto(
    entryId: match.entry.id,
    firstName: match.entry.firstName,
    lastName: match.entry.lastName,
    club: match.entry.club,
    faiNumber: match.entry.faiNumber,
    nationalOrgId: match.entry.nationalOrgId,
    city: match.entry.city,
    state: match.entry.state,
    country: match.entry.country,
    email: match.email,
    emailAvailable: match.emailAvailable,
    copiedProfileId: match.copiedProfileId,
    sharedKey: match.sharedKey,
  );

  Response answer(Map<String, dynamic> json) =>
      jsonResponse(json).change(headers: {'cache-control': 'no-store'});

  router.post('/directory/lookups', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, DirectoryLookupRequest.fromJson);
    limiter.check('lookup:${principal.accountId.value}');
    final matches = await service.lookup(
      directorAccountId: principal.accountId,
      key: switch (body.key) {
        DirectoryLookupKeyDto.email => DirectoryLookupKey.email,
        DirectoryLookupKeyDto.faiNumber => DirectoryLookupKey.faiNumber,
        DirectoryLookupKeyDto.nationalOrgId => DirectoryLookupKey.nationalOrgId,
      },
      value: body.value,
    );
    return answer(
      DirectoryLookupResponse(results: [for (final m in matches) dto(m)])
          .toJson(),
    );
  });

  router.post('/directory/copies', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, DirectoryCopyRequest.fromJson);
    limiter.check('copy:${principal.accountId.value}');
    final match = await service.copy(
      directorAccountId: principal.accountId,
      entryId: body.entryId,
      profileId: body.profileId,
    );
    return answer(dto(match).toJson());
  });

  router.post('/directory/refreshes', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, DirectoryCopyRequest.fromJson);
    limiter.check('refresh:${principal.accountId.value}');
    final match = await service.refresh(
      directorAccountId: principal.accountId,
      entryId: body.entryId,
      profileId: body.profileId,
    );
    return answer(dto(match).toJson());
  });
}
