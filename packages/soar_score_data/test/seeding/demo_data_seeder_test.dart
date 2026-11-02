import 'package:soar_score_core/services/services.dart' as services;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;
  late DemoDataSeeder seeder;
  final owner = core.Id.create();

  setUp(() async {
    inst = await Installation.open(backend);
    await SystemDataSeeder(inst.db).seed();
    repository = Repository(inst.db);
    seeder = DemoDataSeeder(repository, localAccountId: owner);
  });
  tearDown(() => inst.close());

  Future<Map<String, core.Contest>> contestsByName() async => {
    for (final c in await repository.contestRepository.getAll()) c.name: c,
  };

  test('builds a contest in every lifecycle state', () async {
    expect(await seeder.seed(), 5);

    final contests = await contestsByName();
    expect(contests.values.map((c) => c.lifecycleState).toSet(), {
      core.LifecycleState.created,
      core.LifecycleState.configuring,
      core.LifecycleState.ready,
      core.LifecycleState.running,
      core.LifecycleState.completed,
    });
    expect(contests.values.map((c) => c.ownerAccountId), everyElement(owner));
    expect(
      contests['Autumn F5J Classic']!.scoringAccess,
      core.ScoringAccess.closed,
    );
    expect(
      contests['Mountain States Team F5J']!.scoringAccess,
      core.ScoringAccess.open,
    );
  });

  test(
    'records the demo contests\' state transitions as audit events',
    () async {
      await seeder.seed();
      final contests = await contestsByName();
      final audits = repository.auditEventRepository;

      final completed = await audits.listForContest(
        contests['Autumn F5J Classic']!.id,
        action: core.AuditAction.stateTransition,
      );
      final running = await audits.listForContest(
        contests['Mountain States Team F5J']!.id,
        action: core.AuditAction.stateTransition,
      );

      expect(completed.map(core.ContestTransitionAudit.actionOf), [
        core.ContestAction.complete,
      ]);
      expect(completed.single.actorId, owner);
      expect(running.map(core.ContestTransitionAudit.actionOf), [
        core.ContestAction.openScoring,
      ]);
    },
  );

  test(
    'records configuration saves and matrix draws as audit events',
    () async {
      await seeder.seed();
      final contests = await contestsByName();
      final audits = repository.auditEventRepository;

      final drawn = contests['Front Range F5J Open']!.id;
      final undrawn = contests['Club Thermal Fun Fly']!.id;
      expect(
        await audits.listForContest(
          drawn,
          action: core.AuditAction.configurationSaved,
        ),
        isNotEmpty,
      );
      expect(
        await audits.listForContest(
          drawn,
          action: core.AuditAction.matrixDrawn,
        ),
        hasLength(1),
      );
      expect(
        await audits.listForContest(
          undrawn,
          action: core.AuditAction.matrixDrawn,
        ),
        isEmpty,
      );
    },
  );

  test('logs the demo corrections, and only those, as score events', () async {
    await seeder.seed();
    final contests = await contestsByName();
    final audits = repository.auditEventRepository;

    final completed = await audits.listForContest(
      contests['Autumn F5J Classic']!.id,
      action: core.AuditAction.scoreAttempt,
    );
    // Every event is a correction naming pilot and round; first entries of
    // the many scored slots leave none.
    expect(completed, isNotEmpty);
    expect(
      completed.map((e) => services.ScoreCorrectionAudit.parse(e)),
      everyElement(isNotNull),
    );
    var corrections = 0;
    for (final placeholder
        in await repository.scorePlaceholderRepository.listForContest(
          contests['Autumn F5J Classic']!.id,
        )) {
      corrections +=
          (await repository.officialScoreRepository.listForPlaceholder(
            placeholder.id,
          )).length -
          1;
    }
    expect(completed, hasLength(corrections));
  });

  test('gives drawn contests a matrix and unnumbered ones none', () async {
    await seeder.seed();
    final contests = await contestsByName();
    final matrix = services.MatrixService(repository);

    final ready = await matrix.current(contests['Front Range F5J Open']!.id);
    expect(ready.rounds, hasLength(8));
    expect(ready.groups, hasLength(24));
    final configuring = await matrix.current(
      contests['Club Thermal Fun Fly']!.id,
    );
    expect(configuring.rounds, isEmpty);
  });

  test('adds participants, helpers and teams', () async {
    await seeder.seed();
    final contests = await contestsByName();

    final open = contests['Front Range F5J Open']!;
    final participations = await repository.contestParticipationRepository
        .listForContest(open.id);
    expect(participations, hasLength(16));
    expect(participations.where((p) => p.isPilot), hasLength(14));

    final team = contests['Mountain States Team F5J']!;
    expect(
      await repository.teamRepository.listForContest(team.id),
      hasLength(4),
    );
    expect(
      await repository.teamMembershipRepository.listForContest(team.id),
      hasLength(12),
    );
  });

  test('is idempotent', () async {
    await seeder.seed();
    final first = await contestsByName();

    expect(await seeder.seed(), 0);
    expect(await contestsByName(), first);
  });
}
