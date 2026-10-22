import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the role routes to [router] (which is mounted under `/api/v1`):
///
/// - `GET /roles` lists the system roles and the caller's own roles
/// - `POST /roles` adds a non-flier role owned by the request's principal
/// - `PUT /roles/{id}` renames one of the caller's roles
/// - `DELETE /roles/{id}` deletes one that no contest participant has
/// - `GET /roles/{id}/usage` lists the contests that use a role
///
/// System roles cannot be renamed or deleted; those requests are answered
/// with 409. The handlers only translate between HTTP and [RolesService].
void addRoleRoutes(Router router, Repository repository) {
  final service = RolesService(repository);

  router.get('/roles', (Request request) async {
    final principal = requirePrincipal(request);
    // The system roles come with every owner's list: show them once.
    final roles = <Id, Role>{
      for (final owner in principal.visibleOwners)
        for (final role in await service.list(owner)) role.id: role,
    }.values;
    return jsonResponse(<String, dynamic>{
      'roles': [for (final role in roles) role.toJson()],
    });
  });

  router.post('/roles', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, CreateRoleRequest.fromJson);
    final role = await service.create(
      principal.accountId,
      body.id,
      body.displayName,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(role.toJson(), statusCode: 201);
  });

  router.put('/roles/<id>', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, RenameRoleRequest.fromJson);
    final role = await service.rename(
      principal.accountId,
      Id.parse(id),
      body.displayName,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(role.toJson());
  });

  router.delete('/roles/<id>', (Request request, String id) async {
    final principal = requirePrincipal(request);
    await service.delete(
      principal.accountId,
      Id.parse(id),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });

  router.get('/roles/<id>/usage', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final usage = await service.usage(principal.accountId, Id.parse(id));
    return jsonResponse(<String, dynamic>{
      'usage': [for (final item in usage) item.toJson()],
    });
  });
}
