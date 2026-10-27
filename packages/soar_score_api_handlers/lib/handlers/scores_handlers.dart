import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('Scores');

/// The score routes (all inside `/api/v1`):
///
/// - `GET /contests/{id}/scores` is every score slot of the current matrix
///   with its current official score, and how far each round is scored;
/// - `POST /contests/{id}/assignments/{assignmentId}/scores` enters the
///   official score of one pilot in one group (201). Entering a score for a
///   slot that already has one is a correction and adds the next score
///   revision; the earlier ones are kept. `cumulative_penalty` in
///   `components` is tri-state: absent (or `null`) means never applied, a
///   positive integer is an applied penalty and its value is the points
///   deducted, and `0` is a penalty that was applied and later removed; a
///   `0` is stored as stored, not dropped. The results are recalculated
///   afterwards in a separate transaction; the entry retries that once and,
///   if it still fails, keeps the score, leaves the results stale and warns
///   the director on the entry response (ticket 297). On a server that
///   publishes, the contest's public update mode then decides whether the
///   entry also reaches the public projection; a failed publish is logged
///   and audited, never an error;
/// - `GET /contests/{id}/assignments/{assignmentId}/scores/history` is every
///   submission to a slot, oldest first: the official revisions with their
///   reasons, and the attempts that never became official.
///
/// The handlers only translate between HTTP and [ScoresService].
///
/// [recalculation] defaults to a [RecalculationService] over [repository]; it
/// is exposed so tests can force a recalculation failure (ticket 297).
void addScoreRoutes(
  Router router,
  Repository repository, {
  bool publishingEnabled = false,
  RecalculationService? recalculation,
}) {
  final service = ScoresService(repository);
  final results = ResultsService(repository);
  final recalculationService = recalculation ?? RecalculationService(results);
  final publicUpdates = PublicUpdateService(repository);

  router.get('/contests/<id>/scores', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final scores = await service.list(contestId);
    return jsonResponse(scores.toJson());
  });

  router.get('/contests/<id>/assignments/<assignmentId>/scores/history', (
    Request request,
    String id,
    String assignmentId,
  ) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    _logger.fine(
      'Fetching score history for assignment $assignmentId in contest $id',
    );
    final history = await service.history(contestId, Id.parse(assignmentId));
    return jsonResponse(history.toJson());
  });

  router.post('/contests/<id>/assignments/<assignmentId>/scores', (
    Request request,
    String id,
    String assignmentId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, EnterScoreRequest.fromJson);

    _logger.fine(
      'Entering official score for assignment $assignmentId in contest $id',
    );

    var result = await service.enterOfficialScore(
      contestId,
      Id.parse(assignmentId),
      clientMutationId: body.clientMutationId,
      baseScoreRevision: body.baseScoreRevision,
      components: body.components,
      reason: body.reason,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    final warning = await recalculationService.recalculateAfterEntry(contestId);
    if (warning != null) {
      _logger.info(
        'Recalculation warning for assignment $assignmentId in contest $id: $warning',
      );
      result = ScoreEntryResult(
        officialScore: result.officialScore,
        placeholder: result.placeholder,
        contest: result.contest,
        calculated: result.calculated,
        recalculationWarning: warning,
      );
    } else {
      _logger.finer(
        'No recalculation warning for assignment $assignmentId in contest $id',
      );
    }
    if (publishingEnabled) {
      _logger.fine(
        'Publishing enabled, attempting public update for assignment $assignmentId in contest $id',
      );
      try {
        await publicUpdates.afterScoreEntry(
          contestId,
          assignmentId: Id.parse(assignmentId),
          entryMutationId: body.clientMutationId,
        );
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Public update after a score entry failed; the last projection '
          'stays public',
          error,
          stackTrace,
        );
      }
    }
    return jsonResponse(result.toJson(), statusCode: 201);
  });
}
