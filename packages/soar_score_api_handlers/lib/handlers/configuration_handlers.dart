import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/middleware/request_id.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the contest configuration routes to [router] (which is mounted under
/// `/api/v1`):
///
/// - `GET /contests/{id}/configuration` is the latest revision
/// - `GET /contests/{id}/configuration/revisions` lists them, oldest first
/// - `POST /contests/{id}/configuration` stores the next revision as the
///   request's `Principal`, and returns it with the changed contest
///
/// The handlers only translate between HTTP and
/// [ContestConfigurationService].
void addConfigurationRoutes(Router router, Repository repository) {
  final service = ContestConfigurationService(repository);

  router.get('/contests/<id>/configuration', (
    Request request,
    String id,
  ) async {
    final revision = await service.latest(Id.parse(id));
    return jsonResponse(revision.toJson());
  });

  router.get('/contests/<id>/configuration/revisions', (
    Request request,
    String id,
  ) async {
    final revisions = await service.revisions(Id.parse(id));
    return jsonResponse(<String, dynamic>{
      'revisions': [for (final revision in revisions) revision.toJson()],
    });
  });

  router.post('/contests/<id>/configuration', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    final body = await readJsonBody(request, SaveConfigurationRequest.fromJson);

    final saved = await service.save(
      contestId,
      ConfigurationInput(
        baseRevisionNumber: body.baseRevisionNumber,
        disciplineProfileId: body.disciplineProfileId,
        config: body.config,
        landingTableId: body.landingTableId,
        notes: body.notes,
      ),
      createdBy: principal.accountId,
      metadata: principal.mutationMetadata(
        clientMutationId: generateRequestId(),
        clientTime: DateTime.now().toUtc(),
      ),
    );
    return jsonResponse(saved.toJson(), statusCode: 201);
  });
}
