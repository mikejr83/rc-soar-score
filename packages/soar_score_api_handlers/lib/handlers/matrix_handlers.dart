import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/draw/isolate_draw_runner.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The flight matrix routes (all inside `/api/v1`):
///
/// - `GET /contests/{id}/matrix` is the current matrix: the latest finalized
///   revision with its rounds, groups and assignments, empty before the first
///   draw;
/// - `POST /contests/{id}/matrix/draws` draws and finalizes the first matrix,
///   which moves a `Configuring` contest to `Ready` and numbers the
///   participants;
/// - `GET /contests/{id}/matrix/draws/{drawId}` says how far a draw has come
///   (404 when the server does not know it), and `DELETE` on the same path
///   cancels it, which fails the draw request with 409 `draw_cancelled` and
///   changes nothing; {drawId} is the `id` of the draw's request and must belong to the contest in the path (404 otherwise);
/// - `POST /contests/{id}/matrix/assignments/{assignmentId}/moves` moves a
///   pilot to another group, lane or round, resetting a score already
///   entered for the old slot;
/// - `POST /contests/{id}/matrix/late-adds` places a pilot who joined after
///   the draw, or who is making up a missed round, in a group with an open
///   spot;
/// - `POST /contests/{id}/matrix/redraws` adds rounds to the matrix or draws
///   its unscored tail again, as a new matrix revision.
///
/// Draws run on an isolate of their own ([drawRunner], an
/// [IsolateDrawRunner] unless given), so a long draw never stops the server
/// from answering.
///
/// The handlers only translate between HTTP and [MatrixService].
void addMatrixRoutes(
  Router router,
  Repository repository, {
  DrawRunner drawRunner = const IsolateDrawRunner(),
}) {
  final jobs = DrawJobs();
  final service = MatrixService(repository, runner: drawRunner, jobs: jobs);
  final moves = AssignmentMoveService(repository);
  final lateAdds = LateAddService(repository);
  final redraws = MatrixRedrawService(
    repository,
    runner: drawRunner,
    jobs: jobs,
  );

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

  router.get('/contests/<id>/matrix/draws/<drawId>', (
    Request request,
    String id,
    String drawId,
  ) async {
    requirePrincipal(request);
    final status = jobs.status(Id.parse(id), Id.parse(drawId));
    if (status == null) {
      throw EntityNotFoundError(entityType: 'Draw', entityId: Id.parse(drawId));
    }
    return jsonResponse(DrawStatusDto.of(status).toJson());
  });

  router.delete('/contests/<id>/matrix/draws/<drawId>', (
    Request request,
    String id,
    String drawId,
  ) async {
    requirePrincipal(request);
    final status = jobs.cancel(Id.parse(id), Id.parse(drawId));
    if (status == null) {
      throw EntityNotFoundError(entityType: 'Draw', entityId: Id.parse(drawId));
    }
    return jsonResponse(DrawStatusDto.of(status).toJson());
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

  router.post('/contests/<id>/matrix/redraws', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, RedrawMatrixRequest.fromJson);

    final matrix = await redraws.redraw(
      Id.parse(id),
      id: body.id,
      firstRound: body.firstRound,
      rounds: body.rounds,
      groupsPerRound: body.groupsPerRound,
      randomSeed: body.randomSeed,
      attemptsPerRound:
          body.attemptsPerRound ?? BasicDraw.defaultAttemptsPerRound,
      seedCount: body.seedCount ?? DrawEngine.defaultSeedCount,
      reason: body.reason,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(matrix.toJson(), statusCode: 201);
  });
}
