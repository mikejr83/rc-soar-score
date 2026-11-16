import 'package:soar_score_core/services/services.dart' as services;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'demo_contest_plan.dart';
import 'demo_flight.dart';
import 'demo_ids.dart';

/// Adds the pilots' own scores a contest has not accepted yet: slots that are
/// `Submitted` with a preliminary attempt and no official score, and one of
/// them `InReview` with an open review request.
///
/// A real submission is made on the hosted server and reaches the director's
/// installation by sync. This one is written on the installation itself, so
/// it carries the director's authority on its mutation: a mutation of
/// participant authority would be refused when the installation uploaded it.
/// The attempt itself keeps the participant authority, as a real one does,
/// with a made-up guest account and no invitation.
class DemoPendingSeeder {
  DemoPendingSeeder(
    this._repository, {
    required core.MutationMetadata Function() metadata,
    required DateTime Function() clock,
  }) : _metadata = metadata,
       _clock = clock;

  final core.Repository _repository;
  final core.MutationMetadata Function() _metadata;
  final DateTime Function() _clock;

  /// Submits the first [DemoContestPlan.pendingSlots] slots of the round after
  /// the scored ones that have no score yet. The last of them also gets an
  /// open review when [DemoContestPlan.reviewedSlots] is more than zero.
  Future<void> add(DemoContestPlan plan) async {
    if (plan.pendingSlots == 0) {
      return;
    }
    final contestId = DemoIds.contest(plan.number);
    final matrix = await services.MatrixService(_repository).current(contestId);
    final revision = await _repository.contestConfigurationRevisionRepository
        .latestForContest(contestId);
    final round = matrix.rounds.firstWhere(
      (r) => r.ordinal == plan.scoredRounds + 1,
    );
    final slots = [
      for (final assignment in matrix.assignments)
        if (assignment.scheduledRoundId == round.id) assignment,
    ];
    final first = plan.partialSlots;
    for (var index = first; index < first + plan.pendingSlots; index++) {
      final assignment = slots[index];
      final placeholder = (await _repository.scorePlaceholderRepository
          .findForAssignment(assignment.id))!;
      final reviewed =
          index == first + plan.pendingSlots - 1 && plan.reviewedSlots > 0;
      final guest = DemoIds.guest(plan.number, index);
      final components = DemoFlight.of(
        contest: plan.number,
        round: round.ordinal,
        index: index,
      ).components;
      final attempt = core.ScoreAttempt(
        id: core.Id.create(),
        contestId: contestId,
        scorePlaceholderId: placeholder.id,
        configRevisionId: revision!.id,
        matrixRevisionId: assignment.matrixRevisionId,
        rawComponents: components,
        actorId: guest,
        authority: core.Authority.participant,
        sourceDevice: 'demo',
        clientMutationId: 'demo/${plan.number}/pending/$index',
        baseScoreRevision: 0,
        acceptedAt: _clock().toUtc(),
      );
      await _repository.scoreAttemptRepository.recordAttempt(
        attempt,
        core.ScorePlaceholder(
          id: placeholder.id,
          contestId: contestId,
          contestParticipationId: placeholder.contestParticipationId,
          assignmentId: placeholder.assignmentId,
          state: reviewed
              ? core.ScorePlaceholderState.inReview
              : core.ScorePlaceholderState.submitted,
          scoreRevision: 1,
          currentAttemptId: attempt.id,
          lockedBy: placeholder.lockedBy,
          lockedAt: placeholder.lockedAt,
          revision: placeholder.revision,
        ),
        metadata: _metadata(),
      );
      if (reviewed) {
        await _repository.reviewRequestRepository.save(
          core.ReviewRequest(
            id: core.Id.create(),
            contestId: contestId,
            scorePlaceholderId: placeholder.id,
            proposedComponents: {
              ...components,
              'time_flown': (components['time_flown']! as int) + 20,
            },
            participantMessage: 'My timer read 20 seconds longer.',
            requesterId: guest,
            baseScoreRevision: 1,
            requestedAt: _clock().toUtc(),
          ),
          metadata: _metadata(),
        );
      }
    }
  }
}
