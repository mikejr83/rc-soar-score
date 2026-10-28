import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the participation routes to [router] (which is mounted under
/// `/api/v1`):
///
/// - `GET /contests/{id}/participations` lists who takes part
/// - `POST /contests/{id}/participations` adds one of the caller's profiles
/// - `PUT /contests/{id}/participations/{participationId}` changes the role,
///   classification or retirement
/// - `DELETE /contests/{id}/participations/{participationId}` removes one
///
/// A pilot with matrix rows but no scores can be removed, or can become a
/// non-flier; the rows go with the change and the answer says how many
/// (`matrix_rows_removed`), because the draw then needs redoing. One with a
/// score is refused with `has_scores`.
///
/// A change of the retirement round, the role or the classification
/// recalculates the results (a retired pilot's later flights count as
/// retired, not as zeros; a class or role decides who is ranked where). The
/// change is
/// stored first; if the recalculation fails the results read as stale and the
/// response carries `recalculation_warning`, as a score entry does.
///
/// The handlers only translate between HTTP and [ParticipationsService].
///
/// [recalculation] defaults to a [RecalculationService] over [repository]; it
/// is exposed so tests can force a recalculation failure.
void addParticipationRoutes(
  Router router,
  Repository repository, {
  RecalculationService? recalculation,
}) {
  final service = ParticipationsService(repository);
  final scoresService = ScoresService(repository);
  final recalculationService =
      recalculation ?? RecalculationService(ResultsService(repository));

  /// A contest with no official score has no results to go stale.
  Future<String?> recalculateIfScored(
    Id contestId, {
    required String cause,
  }) async {
    final scores = await scoresService.list(contestId);
    if (!scores.slots.any((slot) => slot.officialScore != null)) return null;
    return recalculationService.recalculateAfterEntry(contestId, cause: cause);
  }

  router.get('/contests/<id>/participations', (
    Request request,
    String id,
  ) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final participations = await service.list(contestId);
    return jsonResponse(<String, dynamic>{
      'participations': [
        for (final participation in participations) participation.toJson(),
      ],
    });
  });

  router.post('/contests/<id>/participations', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, AddParticipationRequest.fromJson);

    final participation = await service.add(
      contestId,
      principal.accountId,
      id: body.id,
      participantProfileId: body.participantProfileId,
      roleId: body.roleId,
      classification: body.classification,
      metadata: writeMetadata(principal),
    );
    return jsonResponse(participation.toJson(), statusCode: 201);
  });

  router.put('/contests/<id>/participations/<participationId>', (
    Request request,
    String id,
    String participationId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(
      request,
      UpdateParticipationRequest.fromJson,
    );

    final before = (await service.list(contestId))
        .where((p) => p.id == Id.parse(participationId))
        .firstOrNull;
    final change = await service.update(
      contestId,
      principal.accountId,
      Id.parse(participationId),
      roleId: body.roleId,
      classification: body.classification,
      retiredAtRound: body.retiredAtRound,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    final participation = change.participation;
    String? warning;
    if (before != null &&
        (before.retiredAtRound != participation.retiredAtRound ||
            before.roleId != participation.roleId ||
            before.classification != participation.classification)) {
      warning = await recalculateIfScored(
        contestId,
        cause: before.retiredAtRound != participation.retiredAtRound
            ? 'a retirement change'
            : 'a participant change',
      );
    }
    return jsonResponse(
      ParticipationUpdateResult(
        participation: participation,
        recalculationWarning: warning,
        matrixRowsRemoved: change.matrixRowsRemoved,
      ).toJson(),
    );
  });

  router.delete('/contests/<id>/participations/<participationId>', (
    Request request,
    String id,
    String participationId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final removed = await service.remove(
      contestId,
      Id.parse(participationId),
      metadata: writeMetadata(principal),
    );
    // The other pilots' ranks move when one leaves a scored contest.
    final warning = await recalculateIfScored(
      contestId,
      cause: 'a participant removal',
    );
    return jsonResponse(
      ParticipationRemoveResult(
        matrixRowsRemoved: removed,
        recalculationWarning: warning,
      ).toJson(),
    );
  });
}
