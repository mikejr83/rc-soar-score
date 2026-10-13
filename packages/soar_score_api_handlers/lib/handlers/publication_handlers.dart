import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The publication routes (all inside `/api/v1`, for the contest's director):
///
/// - `POST /contests/{id}/publication` publishes the contest (201). The first
///   publish creates an Unlisted publication; later ones add the next
///   projection. Repeating a `client_mutation_id` returns the first result
///   (200);
/// - `GET /contests/{id}/publication` is the director's view of it;
/// - `PATCH /contests/{id}/publication/visibility` switches between
///   `Unlisted` and `Public`.
///
/// Publishing exists only on the hosted server. With [enabled] false (the
/// embedded server) every route answers 409 `publishing_not_available`, so a
/// contest kept on one machine never publishes by accident.
///
/// The handlers only translate between HTTP and [PublicationService].
void addPublicationRoutes(
  Router router,
  Repository repository, {
  required bool enabled,
}) {
  final service = PublicationService(repository);

  Principal available(Request request) {
    final principal = requirePrincipal(request);
    if (!enabled) {
      throw ContestStateError(
        'publishing_not_available',
        'this server does not publish contests',
      );
    }
    return principal;
  }

  router.post('/contests/<id>/publication', (Request request, String id) async {
    final principal = available(request);
    final body = await readJsonBody(request, PublishContestRequest.fromJson);
    final result = await service.publish(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
      clientMutationId: body.clientMutationId,
      sourceContestRevision: body.sourceContestRevision,
    );
    return jsonResponse(
      result.view.toJson(),
      statusCode: result.created ? 201 : 200,
    );
  });

  router.get('/contests/<id>/publication', (Request request, String id) async {
    final principal = available(request);
    final view = await service.read(
      Id.parse(id),
      actorId: principal.accountId,
      authority: principal.authority,
    );
    return jsonResponse(view.toJson());
  });

  router.patch('/contests/<id>/publication/visibility', (
    Request request,
    String id,
  ) async {
    final principal = available(request);
    final body = await readJsonBody(request, SetVisibilityRequest.fromJson);
    final visibility = switch (body.visibility) {
      'Unlisted' => PublicationVisibility.unlisted,
      'Public' => PublicationVisibility.public,
      _ => throw ArgumentError('visibility must be Unlisted or Public'),
    };
    final view = await service.setVisibility(
      Id.parse(id),
      visibility,
      actorId: principal.accountId,
      authority: principal.authority,
    );
    return jsonResponse(view.toJson());
  });
}
