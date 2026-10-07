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
///   participants;
/// - `POST /contests/{id}/matrix/assignments/{assignmentId}/moves` moves a
///   pilot to another group, lane or round, resetting a score already
///   entered for the old slot;
/// - `POST /contests/{id}/matrix/late-adds` places a pilot who joined after
///   the draw, or who is making up a missed round, in a group with an open
///   spot.
///
/// The handlers only translate between HTTP and [MatrixService].
void addMatrixRoutes(Router router, Repository repository) {
  final service = MatrixService(repository);
  final moves = AssignmentMoveService(repository);
  final lateAdds = LateAddService(repository);

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
      attemptsPerRound:
          body.attemptsPerRound ?? BasicDraw.defaultAttemptsPerRound,
      seedCount: body.seedCount ?? DrawEngine.defaultSeedCount,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(matrix.toJson(), statusCode: 201);
  });

  router.post('/contests/<id>/matrix/assignments/<assignmentId>/moves', (
    Request request,
    String id,
    String assignmentId,
  ) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, MoveAssignmentRequest.fromJson);

    final matrix = await moves.move(
      Id.parse(id),
      Id.parse(assignmentId),
      id: body.id,
      scheduledRoundId: body.scheduledRoundId,
      group: body.group,
      lane: body.lane,
      reason: body.reason,
      overrideLocks: body.overrideLocks,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(matrix.toJson(), statusCode: 201);
  });

  router.post('/contests/<id>/matrix/late-adds', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, LateAddRequest.fromJson);

    final matrix = await lateAdds.add(
      Id.parse(id),
      id: body.id,
      participationId: body.contestParticipationId,
      scheduledRoundId: body.scheduledRoundId,
      creditedRoundId: body.creditedRoundId,
      group: body.group,
      lane: body.lane,
      reason: body.reason,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(matrix.toJson(), statusCode: 201);
  });
}
