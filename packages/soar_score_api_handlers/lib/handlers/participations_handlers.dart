import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
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
/// A change of the retirement round recalculates the results, which count a
/// retired pilot's later flights as retired, not as zeros. The change is
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

  router.get('/contests/<id>/participations', (
    Request request,
    String id,
  ) async {
    requirePrincipal(request);
    final participations = await service.list(Id.parse(id));
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
    final body = await readJsonBody(
      request,
      UpdateParticipationRequest.fromJson,
    );

    final contestId = Id.parse(id);
    final before = (await service.list(contestId))
        .where((p) => p.id == Id.parse(participationId))
        .firstOrNull;
    final participation = await service.update(
      contestId,
      principal.accountId,
      Id.parse(participationId),
      roleId: body.roleId,
      classification: body.classification,
      retiredAtRound: body.retiredAtRound,
      baseRevision: body.baseRevision,
      metadata: writeMetadata(principal),
    );
    String? warning;
    if (before != null &&
        before.retiredAtRound != participation.retiredAtRound) {
      // A contest with no official score has no results to go stale.
      final scores = await scoresService.list(contestId);
      if (scores.slots.any((slot) => slot.officialScore != null)) {
        warning = await recalculationService.recalculateAfterEntry(
          contestId,
          cause: 'a retirement change',
        );
      }
    }
    return jsonResponse(
      ParticipationUpdateResult(
        participation: participation,
        recalculationWarning: warning,
      ).toJson(),
    );
  });

  router.delete('/contests/<id>/participations/<participationId>', (
    Request request,
    String id,
    String participationId,
  ) async {
    final principal = requirePrincipal(request);
    await service.remove(
      Id.parse(id),
      Id.parse(participationId),
      metadata: writeMetadata(principal),
    );
    return Response(204);
  });
}
