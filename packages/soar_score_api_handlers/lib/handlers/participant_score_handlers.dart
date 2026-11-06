import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../auth/participant_principal.dart';
import '../middleware/request_id.dart';
import 'health_handler.dart';
import 'request_body.dart';

final _logger = Logger('ParticipantScores');

/// The pilot's score submission, added to the guest-session router of the
/// participant routes (`/api/v1/self-scoring`):
///
/// - `POST /rounds/{round}/scores` stores the score the pilot of the session
///   enters for one of their own rounds (201 with a
///   [SubmitParticipantScoreResponse]). The pilot and the slot come from the
///   session, never from the body. A repeat of the same `client_mutation_id`
///   answers the first acceptance (200). A refusal answers a
///   [ParticipantErrorDto] as the bare body: `score_already_submitted` (409,
///   with the accepted score), `validation_failed` (400, with the fields),
///   `stale_matrix`, `out_of_order` and `mutation_conflict` (409). A closed
///   or locked contest is 409 `scoring_closed` / `contest_locked`.
///
/// After a stored score the results are recalculated once, and on a server
/// that publishes the contest's public update mode decides whether the score
/// reaches the public projection; a failed recalculation or publish is
/// logged and never fails the submission (the score is stored).
void addParticipantScoreRoutes(
  Router router,
  Repository repository, {
  RecalculationService? recalculation,
  bool publishingEnabled = false,
  DateTime Function()? clock,
}) {
  final scores = ScoresService(repository, clock: clock);
  final recalculationService =
      recalculation ?? RecalculationService(ResultsService(repository));
  final publicUpdates = PublicUpdateService(repository);

  router.post('/rounds/<round>/scores', (Request request, String round) async {
    final principal = requireParticipant(request);
    final roundNumber = int.tryParse(round);
    if (roundNumber == null || roundNumber < 1) {
      throw ArgumentError('the round must be a positive whole number');
    }
    final body = await readJsonBody(
      request,
      SubmitParticipantScoreRequest.fromJson,
    );
    final requestId = requestIdOf(request);
    try {
      final stored = await scores.submitParticipantScore(
        principal.access,
        roundNumber,
        clientMutationId: body.clientMutationId,
        matrixRevision: body.matrixRevision,
        components: body.components,
        sourceDevice: _sourceDevice(request),
      );
      // A repeat runs both again, so a request that stopped after the store
      // is finished by its retry (both are safe to repeat).
      {
        final warning = await recalculationService.recalculateAfterEntry(
          principal.contestId,
        );
        if (warning != null) {
          _logger.info(
            'Recalculation warning after a participant score in contest '
            '${principal.contestId.value}: $warning',
          );
        }
        if (publishingEnabled) {
          try {
            await publicUpdates.afterScoreEntry(
              principal.contestId,
              assignmentId: stored.assignmentId,
              entryMutationId: body.clientMutationId,
            );
          } on Object catch (error, stackTrace) {
            _logger.warning(
              'Public update after a participant score failed; the last '
              'projection stays public',
              error,
              stackTrace,
            );
          }
        }
      }
      final name = await _pilotName(repository, principal);
      return _json(
        SubmitParticipantScoreResponse(
          score: _scoreDto(stored, name),
          nextOperation: 'view_results',
          nextRound: stored.nextRound,
        ).toJson(),
        stored.replayed ? 200 : 201,
      );
    } on ParticipantSubmissionRefusal catch (refusal) {
      final accepted = refusal.accepted;
      _logger.warning(
        '${refusal.statusCode} on participant score submission '
        'code=${refusal.code} request=$requestId',
      );
      return _json(
        ParticipantErrorDto(
          code: refusal.code,
          message: refusal.message,
          requestId: requestId,
          acceptedScore: accepted == null
              ? null
              : _scoreDto(accepted, await _pilotName(repository, principal)),
          nextOperation: accepted == null ? null : 'view_results',
          fieldErrors: [
            for (final e in refusal.fieldErrors)
              FieldErrorDto(field: e.field, code: e.code),
          ],
        ).toJson(),
        refusal.statusCode,
      );
    }
  });
}

String? _sourceDevice(Request request) {
  final agent = request.headers['user-agent']?.trim();
  if (agent == null || agent.isEmpty) return null;
  return agent.length <= 200 ? agent : agent.substring(0, 200);
}

Future<String> _pilotName(
  Repository repository,
  ParticipantPrincipal principal,
) async {
  final profile = await repository.participantProfileRepository.findById(
    principal.access.participation.participantProfileId,
  );
  return [profile?.firstName, profile?.lastName].whereType<String>().join(' ');
}

ParticipantScoreDto _scoreDto(ParticipantSubmission stored, String pilotName) {
  final byPilot = stored.authority == Authority.participant;
  return ParticipantScoreDto(
    assignmentId: stored.assignmentId,
    round: stored.round,
    // The pilot's own score is the preliminary "submitted" one; once the
    // director entered or corrected it, it is "official".
    state: byPilot
        ? ParticipantScoreState.submitted
        : ParticipantScoreState.official,
    revision: stored.placeholder.scoreRevision,
    components: stored.officialScore.components,
    enteredBy: byPilot ? pilotName : 'Director',
    enteredAt: stored.officialScore.setAt,
    flightScore: stored.calculated.rawScore,
    rawScore: stored.calculated.rawScore,
  );
}

Response _json(Map<String, Object?> body, int status) => jsonResponse(
  body,
  statusCode: status,
).change(headers: {'cache-control': 'no-store'});
