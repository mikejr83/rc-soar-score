import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the landing table routes to [router] (mounted under `/api/v1`):
///
/// - `GET /landing-tables` lists the system tables and the caller's own,
///   each with an `in_use` flag
/// - `POST /landing-tables` creates a table owned by the request's principal
/// - `DELETE /landing-tables/{id}` removes one of the caller's tables that
///   nothing refers to
///
/// Tables never change, so there is no update. The handlers only translate
/// between HTTP and [LandingTablesService].
void addLandingTableRoutes(Router router, Repository repository) {
  final service = LandingTablesService(repository);

  router.get('/landing-tables', (Request request) async {
    final principal = requirePrincipal(request);
    // The system tables come with every owner's list: show them once.
    final tables = <Id, LandingTableView>{
      for (final owner in principal.visibleOwners)
        for (final table in await service.list(owner)) table.table.id: table,
    }.values;
    return jsonResponse(<String, dynamic>{
      'landing_tables': [for (final table in tables) table.toJson()],
    });
  });

  router.post('/landing-tables', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(
      request,
      CreateLandingTableRequest.fromJson,
    );
    final table = await service.create(
      principal.accountId,
      body.id,
      name: body.name,
      inputUnit: body.inputUnit,
      entries: body.entries,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(table.toJson(), statusCode: 201);
  });

  router.delete('/landing-tables/<id>', (Request request, String id) async {
    final principal = requirePrincipal(request);
    await service.delete(
      principal.accountId,
      Id.parse(id),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });
}
