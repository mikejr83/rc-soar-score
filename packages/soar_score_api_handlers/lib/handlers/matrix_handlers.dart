import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The flight matrix routes (all inside `/api/v1`):
///
/// - `GET /contests/{id}/matrix` is the current matrix: the latest finalized
///   revision with its rounds, groups and assignments, empty before the first
///   draw;
/// - `POST /contests/{id}/matrix/draws` draws and finalizes the first matrix,
///   which moves a `Configuring` contest to `Ready` and numbers the
///   participants.
///
/// The handlers only translate between HTTP and [MatrixService].
void addMatrixRoutes(Router router, Repository repository) {
  final service = MatrixService(repository);

  router.get('/contests/<id>/matrix', (Request request, String id) async {
    requirePrincipal(request);
    final matrix = await service.current(Id.parse(id));
    return jsonResponse(matrix.toJson());
  });

  router.post('/contests/<id>/matrix/draws', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, DrawMatrixRequest.fromJson);

    final matrix = await service.drawFirst(
      Id.parse(id),
      id: body.id,
      rounds: body.rounds,
      groupsPerRound: body.groupsPerRound,
      randomSeed: body.randomSeed,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(matrix.toJson(), statusCode: 201);
  });
}
