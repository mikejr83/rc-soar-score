import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/middleware/request_id.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('ConfigurationHandlers');

/// Adds the contest configuration routes to [router] (which is mounted under
/// `/api/v1`):
///
/// - `GET /contests/{id}/configuration` is the latest revision
/// - `GET /contests/{id}/configuration/revisions` lists them, oldest first
/// - `POST /contests/{id}/configuration` stores the next revision as the
///   request's `Principal`, and returns it with the changed contest
///
/// A new revision makes every stored result stale (a result carries the
/// revision it was computed under), so a contest that has official scores is
/// recalculated right after the revision is stored. The revision stays stored
/// when that fails; the response then carries `recalculation_warning`, as a
/// score entry does.
///
/// The handlers only translate between HTTP and
/// [ContestConfigurationService].
///
/// [recalculation] defaults to a [RecalculationService] over [repository]; it
/// is exposed so tests can force a recalculation failure.
void addConfigurationRoutes(
  Router router,
  Repository repository, {
  RecalculationService? recalculation,
}) {
  final service = ContestConfigurationService(repository);
  final scoresService = ScoresService(repository);
  final recalculationService =
      recalculation ?? RecalculationService(ResultsService(repository));

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
    // The revision is already stored, so nothing after this may fail the
    // request: a failure to read the scores or to recalculate comes back as a
    // warning, and the results read as stale until a later recalculation.
    String? warning;
    try {
      // A contest with no official score has no results to go stale.
      final scores = await scoresService.list(contestId);
      if (scores.slots.any((slot) => slot.officialScore != null)) {
        warning = await recalculationService.recalculateAfterEntry(
          contestId,
          cause: 'a configuration change',
        );
      }
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Reading the scores after a configuration change failed',
        error,
        stackTrace,
      );
      warning =
          'Recalculation could not be started after a configuration change; '
          'the results are stale';
    }
    return jsonResponse(
      SavedConfiguration(
        revision: saved.revision,
        contest: saved.contest,
        recalculationWarning: warning,
      ).toJson(),
      statusCode: 201,
    );
  });
}
