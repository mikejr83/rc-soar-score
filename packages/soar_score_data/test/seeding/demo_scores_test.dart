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
  late Map<String, core.Contest> contests;

  setUp(() async {
    inst = await Installation.open(backend);
    await SystemDataSeeder(inst.db).seed();
    repository = Repository(inst.db);
    await DemoDataSeeder(repository, localAccountId: core.Id.create()).seed();
    contests = {
      for (final c in await repository.contestRepository.getAll()) c.name: c,
    };
  });
  tearDown(() => inst.close());

  test('the completed contest has every round scored and results', () async {
    final contest = contests['Autumn F5J Classic']!;

    final scores = await services.ScoresService(repository).list(contest.id);
    expect(scores.rounds, hasLength(5));
    expect(scores.rounds.every((round) => round.isComplete), isTrue);

    final results = await services.ResultsService(repository).read(contest.id);
    expect(results.standings, hasLength(8));
    expect(results.isStale, isFalse);
    expect(contest.lifecycleState, core.LifecycleState.completed);
    expect(contest.scoringAccess, core.ScoringAccess.closed);
  });

  test('the running contest has partial progress and team standings', () async {
    final contest = contests['Mountain States Team F5J']!;

    final scores = await services.ScoresService(repository).list(contest.id);
    expect(scores.rounds.map((r) => r.scored), [12, 12, 12, 12, 5, 0]);
    expect(contest.lifecycleState, core.LifecycleState.running);
    expect(contest.scoringAccess, core.ScoringAccess.open);

    final results = await services.ResultsService(repository).read(contest.id);
    expect(results.standings, isNotEmpty);
    expect(results.teams, hasLength(4));
  });

  test('keeps the corrected scores and their reasons', () async {
    final contest = contests['Autumn F5J Classic']!;
    final scores = await services.ScoresService(repository).list(contest.id);

    final corrected = scores.slots
        .where((slot) => slot.officialScore?.scoreRevision == 2)
        .toList();
    expect(corrected, hasLength(2));
    expect(
      corrected.map((slot) => slot.officialScore!.reason),
      unorderedEquals([
        'Timer misread',
        'Penalty removed: the timer slip was a misread',
      ]),
    );
  });

  test('drawn contests without scores stay Ready', () async {
    final contest = contests['Front Range F5J Open']!;

    expect(contest.lifecycleState, core.LifecycleState.ready);
    final scores = await services.ScoresService(repository).list(contest.id);
    expect(scores.slots.every((slot) => slot.officialScore == null), isTrue);
  });
}
