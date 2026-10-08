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
      contests['Autumn ALES Classic']!.scoringAccess,
      core.ScoringAccess.closed,
    );
    expect(
      contests['Mountain States Team F5J']!.scoringAccess,
      core.ScoringAccess.open,
    );
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
