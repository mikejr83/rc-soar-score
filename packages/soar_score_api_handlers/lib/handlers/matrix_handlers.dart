import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/draw/isolate_draw_runner.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
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
/// - `POST /contests/{id}/matrix/late-placements` puts a pilot who joined
///   after the draw in the last group that can take them in every round, with
///   a zero score in rounds that are already fully scored;
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
  RecalculationService? recalculation,
}) {
  final jobs = DrawJobs();
  final service = MatrixService(repository, runner: drawRunner, jobs: jobs);
  final moves = AssignmentMoveService(repository);
  final lateAdds = LateAddService(repository);
  final placements = LatePlacementService(repository);
  final recalculationService =
      recalculation ?? RecalculationService(ResultsService(repository));
  final redraws = MatrixRedrawService(
    repository,
    runner: drawRunner,
    jobs: jobs,
  );

  router.get('/contests/<id>/matrix', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final matrix = await service.current(contestId);
    return jsonResponse(matrix.toJson());
  });

  router.post('/contests/<id>/matrix/draws', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, DrawMatrixRequest.fromJson);

    final matrix = await service.drawFirst(
      contestId,
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
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final status = jobs.status(contestId, Id.parse(drawId));
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
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final status = jobs.cancel(contestId, Id.parse(drawId));
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
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, MoveAssignmentRequest.fromJson);

    final matrix = await moves.move(
      contestId,
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
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, LateAddRequest.fromJson);

    final matrix = await lateAdds.add(
      contestId,
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

  router.post('/contests/<id>/matrix/late-placements', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final participationId = await readJsonBody(
      request,
      (json) => Id.parse(json['contest_participation_id']! as String),
    );

    final rounds = await placements.placeInAllRounds(
      contestId,
      participationId,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    // A zero score changes the results.
    final warning = rounds.any((round) => round.zeroed)
        ? await recalculationService.recalculateAfterEntry(
            contestId,
            cause: 'a pilot added after the round was scored',
          )
        : null;
    return jsonResponse(
      LatePlacementResult(
        rounds: rounds,
        recalculationWarning: warning,
      ).toJson(),
      statusCode: 201,
    );
  });

  router.post('/contests/<id>/matrix/redraws', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, RedrawMatrixRequest.fromJson);

    final matrix = await redraws.redraw(
      contestId,
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
