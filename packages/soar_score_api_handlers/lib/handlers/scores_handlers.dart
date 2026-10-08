import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('Scores');

/// The score routes (all inside `/api/v1`):
///
/// - `GET /contests/{id}/scores` is every score slot of the current matrix
///   with its current official score, and how far each round is scored;
/// - `POST /contests/{id}/assignments/{assignmentId}/scores` enters the
///   official score of one pilot in one group (201). Entering a score for a
///   slot that already has one is a correction and adds the next score
///   revision; the earlier ones are kept. The results are recalculated
///   afterwards in a separate transaction; if that fails the score is kept
///   and the results read as stale. On a server that publishes, the contest's
///   public update mode then decides whether the entry also reaches the public
///   projection; a failed publish is logged and audited, never an error.
///
/// The handlers only translate between HTTP and [ScoresService].
void addScoreRoutes(
  Router router,
  Repository repository, {
  bool publishingEnabled = false,
}) {
  final service = ScoresService(repository);
  final results = ResultsService(repository);
  final publicUpdates = PublicUpdateService(repository);

  router.get('/contests/<id>/scores', (Request request, String id) async {
    requirePrincipal(request);
    final scores = await service.list(Id.parse(id));
    return jsonResponse(scores.toJson());
  });

  router.post('/contests/<id>/assignments/<assignmentId>/scores', (
    Request request,
    String id,
    String assignmentId,
  ) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, EnterScoreRequest.fromJson);

    final result = await service.enterOfficialScore(
      Id.parse(id),
      Id.parse(assignmentId),
      clientMutationId: body.clientMutationId,
      baseScoreRevision: body.baseScoreRevision,
      components: body.components,
      reason: body.reason,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    try {
      await results.recalculate(Id.parse(id));
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Recalculation after a score entry failed; the results are stale',
        error,
        stackTrace,
      );
    }
    if (publishingEnabled) {
      try {
        await publicUpdates.afterScoreEntry(
          Id.parse(id),
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
