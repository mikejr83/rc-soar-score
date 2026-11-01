import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the model routes to [router] (which is mounted under `/api/v1`):
///
/// - `GET|POST /participants/{id}/models` list and add a profile's models
/// - `PUT|DELETE /participants/{id}/models/{modelId}` change or remove one
/// - `GET /contests/{id}/model-links` lists the models of the contest's pilots
/// - `POST /contests/{id}/participations/{participationId}/model-links` adds
///   a model to a pilot (only a pilot has any)
/// - `PUT|DELETE /contests/{id}/model-links/{linkId}` change or remove one
///
/// A profile's models are private to the director who owns the profile;
/// another director's profile is answered as not found. A contest's links are
/// snapshots of the profile's models and stay after the profile's model
/// changes. Missing models are never an error, and a change recalculates
/// nothing. The handlers only translate between HTTP and [ModelsService].
void addModelRoutes(Router router, Repository repository) {
  final service = ModelsService(repository);

  router.get('/participants/<id>/models', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final models = await service.listProfileModels(
      principal.accountId,
      Id.parse(id),
    );
    return jsonResponse(<String, dynamic>{
      'models': [for (final model in models) model.toJson()],
    });
  });

  router.post('/participants/<id>/models', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, AddProfileModelRequest.fromJson);
    final model = await service.addProfileModel(
      principal.accountId,
      Id.parse(id),
      id: body.id,
      name: body.name,
      manufacturer: body.manufacturer,
      modelId: body.modelId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(model.toJson(), statusCode: 201);
  });

  router.put('/participants/<id>/models/<modelId>', (
    Request request,
    String id,
    String modelId,
  ) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(
      request,
      UpdateProfileModelRequest.fromJson,
    );
    final model = await service.updateProfileModel(
      principal.accountId,
      Id.parse(id),
      Id.parse(modelId),
      name: body.name,
      manufacturer: body.manufacturer,
      modelId: body.modelId,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(model.toJson());
  });

  router.delete('/participants/<id>/models/<modelId>', (
    Request request,
    String id,
    String modelId,
  ) async {
    final principal = requirePrincipal(request);
    await service.removeProfileModel(
      principal.accountId,
      Id.parse(id),
      Id.parse(modelId),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });

  router.get('/contests/<id>/model-links', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final links = await service.listLinks(contestId);
    return jsonResponse(<String, dynamic>{
      'model_links': [for (final link in links) link.toJson()],
    });
  });

  router.post('/contests/<id>/participations/<participationId>/model-links', (
    Request request,
    String id,
    String participationId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, AddModelLinkRequest.fromJson);
    final link = await service.addLink(
      contestId,
      principal.accountId,
      Id.parse(participationId),
      id: body.id,
      modelCatalogId: body.modelCatalogId,
      modelName: body.modelName,
      manufacturer: body.manufacturer,
      modelId: body.modelId,
      contestSpecificIdentifier: body.contestSpecificIdentifier,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(link.toJson(), statusCode: 201);
  });

  router.put('/contests/<id>/model-links/<linkId>', (
    Request request,
    String id,
    String linkId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, UpdateModelLinkRequest.fromJson);
    final link = await service.updateLink(
      contestId,
      Id.parse(linkId),
      modelName: body.modelName,
      manufacturer: body.manufacturer,
      modelId: body.modelId,
      contestSpecificIdentifier: body.contestSpecificIdentifier,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(link.toJson());
  });

  router.delete('/contests/<id>/model-links/<linkId>', (
    Request request,
    String id,
    String linkId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    await service.removeLink(
      contestId,
      Id.parse(linkId),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });
}
