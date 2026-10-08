import 'package:soar_score_core/services/services.dart' as services;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'demo_configuration.dart';
import 'demo_contest_plan.dart';
import 'demo_ids.dart';
import 'demo_pilot.dart';
import 'demo_score_seeder.dart';

/// Fills an empty database with example data: pilots and contests in every
/// lifecycle state, with configurations, participants, teams, drawn matrices,
/// official scores and the results calculated from them.
///
/// Development only: the native app runs it for the demo database (see the
/// contest app README). Everything goes through the same services the API
/// uses, so the demo data obeys the rules real data does. The contests belong
/// to the installation's Local account, which is also the actor of every
/// mutation. Scores go through
/// `ScoresService` and the results through `ResultsService`, so the first
/// score starts a contest just as it does in real use.
class DemoDataSeeder {
  DemoDataSeeder(
    this._repository, {
    required core.Id localAccountId,
    DateTime Function()? clock,
  }) : _localAccountId = localAccountId,
       _clock = clock ?? DateTime.now;

  final core.Repository _repository;
  final core.Id _localAccountId;
  final DateTime Function() _clock;
  int _mutations = 0;

  /// Builds the demo data and returns how many contests it created. A
  /// database that already holds contests is left alone and the result is 0.
  Future<int> seed() async {
    if ((await _repository.contestRepository.getAll()).isNotEmpty) {
      return 0;
    }
    await _saveProfiles();
    for (final plan in DemoContestPlan.all) {
      await _build(plan);
    }
    return DemoContestPlan.all.length;
  }

  core.MutationMetadata _metadata() => core.MutationMetadata(
    clientMutationId: 'demo-seed/${_mutations++}',
    authority: core.Authority.system,
    clientTime: _clock().toUtc(),
    actorId: _localAccountId,
  );

  Future<void> _saveProfiles() async {
    final now = _clock().toUtc();
    for (final (index, pilot) in DemoPilot.roster.indexed) {
      await _repository.participantProfileRepository.save(
        core.ParticipantProfile(
          id: DemoIds.profile(index),
          ownerAccountId: _localAccountId,
          firstName: pilot.firstName,
          lastName: pilot.lastName,
          club: pilot.club,
          city: pilot.city,
          state: 'CO',
          country: 'US',
          createdAt: now,
          updatedAt: now,
        ),
        metadata: _metadata(),
      );
    }
  }

  Future<void> _build(DemoContestPlan plan) async {
    final contestId = DemoIds.contest(plan.number);
    await services.ContestsService(_repository).createContest(
      services.NewContest(
        id: contestId,
        details: services.ContestDetails(
          name: plan.name,
          startDateTime: plan.start,
          endDateTime: plan.end,
          city: plan.city,
          state: plan.state,
          country: 'US',
        ),
        timezone: 'America/Denver',
      ),
      ownerAccountId: _localAccountId,
      metadata: _metadata(),
    );
    if (!plan.configured) {
      return;
    }
    await services.ContestConfigurationService(_repository).save(
      contestId,
      services.ConfigurationInput(
        baseRevisionNumber: 0,
        disciplineProfileId: plan.disciplineProfileId,
        config: DemoConfiguration.of(plan),
      ),
      createdBy: _localAccountId,
      metadata: _metadata(),
    );
    final participations = await _addParticipants(plan);
    if (plan.teamSize != null) {
      await _addTeams(plan, participations);
    }
    if (!plan.drawn) {
      return;
    }
    await services.MatrixService(_repository).drawFirst(
      contestId,
      id: DemoIds.matrix(plan.number),
      rounds: plan.rounds,
      groupsPerRound: plan.groupsPerRound,
      randomSeed: plan.number,
      attemptsPerRound: 10,
      seedCount: 2,
      actorId: _localAccountId,
      metadata: _metadata(),
    );
    await _finish(plan);
  }

  /// The participations by roster number: pilots from the start of the
  /// roster, helpers from the end.
  Future<Map<int, core.Id>> _addParticipants(DemoContestPlan plan) async {
    final service = services.ParticipationsService(_repository);
    final roster = DemoPilot.roster.length;
    final members = [
      for (var i = 0; i < plan.pilots; i++) i,
      for (var i = roster - plan.helpers; i < roster; i++) i,
    ];
    final added = <int, core.Id>{};
    for (final pilot in members) {
      final flies = pilot < plan.pilots;
      final participation = await service.add(
        DemoIds.contest(plan.number),
        _localAccountId,
        id: DemoIds.participation(plan.number, pilot),
        participantProfileId: DemoIds.profile(pilot),
        roleId: flies ? null : core.SystemRoles.helperId,
        classification: flies && plan.classes
            ? (pilot.isEven ? 'Open' : 'Sportsman')
            : null,
        metadata: _metadata(),
      );
      added[pilot] = participation.id;
    }
    return added;
  }

  /// Consecutive pilots form a team, named for the team's number.
  Future<void> _addTeams(
    DemoContestPlan plan,
    Map<int, core.Id> participations,
  ) async {
    final service = services.TeamsService(_repository);
    final contestId = DemoIds.contest(plan.number);
    final size = plan.teamSize!;
    for (var team = 0; team < plan.pilots ~/ size; team++) {
      await service.createTeam(
        contestId,
        id: DemoIds.team(plan.number, team),
        name: 'Team ${team + 1}',
        metadata: _metadata(),
      );
      for (var i = 0; i < size; i++) {
        final pilot = team * size + i;
        await service.addMember(
          contestId,
          id: DemoIds.membership(plan.number, pilot),
          teamId: DemoIds.team(plan.number, team),
          participationId: participations[pilot]!,
          metadata: _metadata(),
        );
      }
    }
  }

  /// Scores the contest and moves it on: the first score makes it Running,
  /// then scoring opens, or the contest completes.
  Future<void> _finish(DemoContestPlan plan) async {
    await DemoScoreSeeder(
      _repository,
      actorId: _localAccountId,
      metadata: _metadata,
    ).score(plan);
    final action = switch (plan.finalState) {
      core.LifecycleState.running => core.ContestAction.openScoring,
      core.LifecycleState.completed => core.ContestAction.complete,
      _ => null,
    };
    if (action == null) {
      return;
    }
    final stored = await _repository.contestRepository.findById(
      DemoIds.contest(plan.number),
    );
    await services.ContestsService(_repository).applyAction(
      stored!.id,
      action,
      baseRevision: stored.revision,
      metadata: _metadata(),
    );
  }
}
