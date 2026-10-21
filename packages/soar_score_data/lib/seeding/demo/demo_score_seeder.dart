import 'package:soar_score_core/services/services.dart' as services;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'demo_contest_plan.dart';
import 'demo_flight.dart';
import 'demo_ids.dart';

/// Enters the scores of a demo contest through [services.ScoresService], the
/// way a director would, then calculates the results.
class DemoScoreSeeder {
  DemoScoreSeeder(
    this._repository, {
    required core.Id actorId,
    required core.MutationMetadata Function() metadata,
  }) : _actorId = actorId,
       _metadata = metadata;

  final core.Repository _repository;
  final core.Id _actorId;
  final core.MutationMetadata Function() _metadata;

  /// Scores the first [DemoContestPlan.scoredRounds] rounds of [plan] whole
  /// and [DemoContestPlan.partialSlots] slots of the next round, then
  /// calculates the results.
  Future<void> score(DemoContestPlan plan) async {
    if (!plan.scored) {
      return;
    }
    final contestId = DemoIds.contest(plan.number);
    final matrix = await services.MatrixService(_repository).current(contestId);
    final scores = services.ScoresService(_repository);
    final rounds = [...matrix.rounds]
      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    for (final round in rounds) {
      final limit = round.ordinal <= plan.scoredRounds
          ? null
          : round.ordinal == plan.scoredRounds + 1
          ? plan.partialSlots
          : 0;
      final slots = [
        for (final assignment in matrix.assignments)
          if (assignment.scheduledRoundId == round.id) assignment,
      ];
      for (final (index, assignment) in slots.indexed) {
        if (limit != null && index >= limit) {
          break;
        }
        await _enter(
          scores,
          contestId,
          assignment.id,
          DemoFlight.of(
            contest: plan.number,
            round: round.ordinal,
            index: index,
          ),
          'demo/${plan.number}/${round.ordinal}/$index',
        );
      }
    }
    await services.ResultsService(_repository).recalculate(contestId);
  }

  Future<void> _enter(
    services.ScoresService scores,
    core.Id contestId,
    core.Id assignmentId,
    DemoFlight flight,
    String key,
  ) async {
    var revision = 0;
    final mistaken = flight.mistaken;
    if (mistaken != null) {
      await scores.enterOfficialScore(
        contestId,
        assignmentId,
        clientMutationId: '$key/first',
        baseScoreRevision: 0,
        components: mistaken,
        actorId: _actorId,
        metadata: _metadata(),
      );
      revision = 1;
    }
    await scores.enterOfficialScore(
      contestId,
      assignmentId,
      clientMutationId: key,
      baseScoreRevision: revision,
      components: flight.components,
      reason: mistaken == null
          ? null
          : (flight.mistakenReason ?? 'Timer misread'),
      actorId: _actorId,
      metadata: _metadata(),
    );
  }
}
