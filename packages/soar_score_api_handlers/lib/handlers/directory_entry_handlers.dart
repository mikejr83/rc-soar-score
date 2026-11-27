import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('DirectoryEntry');

/// Adds the routes of the signed-in account's own directory entry (#652) to
/// [router] (mounted under `/api/v1`):
///
/// - `GET /account/directory-entry` answers the caller's entry, null when
///   the account has none yet, with the account's own name to start from
///   ([DirectoryEntryStateDto]).
/// - `PUT /account/directory-entry` ([PutDirectoryEntryRequest]; answers the
///   same state) creates the
///   entry or replaces its details, including "let contest directors find
///   me" (`is_listed`) and whether directors may see the email
///   (`email_visible_to_directors`). Repeating it changes nothing. A blank
///   name is 400.
/// - `DELETE /account/directory-entry` removes it (204, also when there was
///   none).
///
/// A guest, local or deleted account is 403 `registered_account_required`.
/// The account's email is never stored on the entry and never returned: the
/// answer only says whether one is `email_available`. Changes are logged
/// without the details. An installation's only account is its Local account,
/// so it answers 403 there.
void addDirectoryEntryRoutes(
  Router router,
  Repository repository, {
  DateTime Function()? clock,
}) {
  final service = DirectoryEntryService(repository, clock: clock);

  Response answer(OwnDirectoryEntry own) {
    final entry = own.entry;
    return jsonResponse(
      DirectoryEntryStateDto(
        entry: entry == null
            ? null
            : DirectoryEntryDto(
                id: entry.id,
                firstName: entry.firstName,
                lastName: entry.lastName,
                club: entry.club,
                faiNumber: entry.faiNumber,
                nationalOrgId: entry.nationalOrgId,
                city: entry.city,
                state: entry.state,
                country: entry.country,
                isListed: entry.isListed,
                emailVisibleToDirectors: entry.emailVisibleToDirectors,
                createdAt: entry.createdAt,
                updatedAt: entry.updatedAt,
              ),
        suggestedFirstName: own.suggestedFirstName,
        suggestedLastName: own.suggestedLastName,
        emailAvailable: own.emailAvailable,
      ).toJson(),
    ).change(headers: {'cache-control': 'no-store'});
  }

  router.get('/account/directory-entry', (Request request) async {
    final principal = requirePrincipal(request);
    return answer(await service.get(principal.accountId));
  });

  router.put('/account/directory-entry', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, PutDirectoryEntryRequest.fromJson);
    final before = await service.get(principal.accountId);
    final saved = await service.put(
      accountId: principal.accountId,
      firstName: body.firstName,
      lastName: body.lastName,
      club: body.club,
      faiNumber: body.faiNumber,
      nationalOrgId: body.nationalOrgId,
      city: body.city,
      state: body.state,
      country: body.country,
      isListed: body.isListed,
      emailVisibleToDirectors: body.emailVisibleToDirectors,
    );
    if (before.entry != saved.entry) {
      _logger.info(
        'directory entry ${before.entry == null ? 'created' : 'changed'} '
        'account=${principal.accountId.value} listed=${saved.entry?.isListed}',
      );
    }
    return answer(saved);
  });

  router.delete('/account/directory-entry', (Request request) async {
    final principal = requirePrincipal(request);
    if (await service.delete(principal.accountId)) {
      _logger.info(
        'directory entry removed account=${principal.accountId.value}',
      );
    }
    return Response(204, headers: {'cache-control': 'no-store'});
  });
}
