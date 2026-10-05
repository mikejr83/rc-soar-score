import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  final flights = [
    for (final row in exampleRows('flight_result'))
      core.FlightResult.fromJson(row),
  ];
  final standings = [
    for (final row in exampleRows('participation_standing'))
      core.ParticipationStanding.fromJson(row),
  ];
  final teamStandings = [
    for (final row in exampleRows('team_standing'))
      core.TeamStanding.fromJson(row),
  ];
  final contestId = flights.first.contestId;

  group('FlightResultRepository', () {
    late core.FlightResultRepository repo;
    setUp(() => repo = repository.flightResultRepository);

    test('reads back the example results unchanged', () async {
      for (final result in flights) {
        expect(await repo.findById(result.id), result);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test(
      'finds by placeholder and lists by contest or participation',
      () async {
        final first = flights.first;

        expect(await repo.findForPlaceholder(first.scorePlaceholderId), first);
        expect(await repo.findForPlaceholder(core.Id.create()), isNull);
        expect(await repo.listForContest(contestId), unorderedEquals(flights));
        expect(
          await repo.listForParticipation(first.contestParticipationId),
          unorderedEquals(
            flights.where(
              (f) => f.contestParticipationId == first.contestParticipationId,
            ),
          ),
        );
      },
    );

    test('replaceForContest swaps the results, with no mutation', () async {
      final before = await inst.count('mutation_records');
      final kept = flights.take(2).toList();

      await repo.replaceForContest(contestId, kept);

      expect(await repo.listForContest(contestId), unorderedEquals(kept));
      expect(await inst.count('mutation_records'), before);
    });

    test('replaceForContest with nothing clears the contest', () async {
      await repo.replaceForContest(contestId, const []);

      expect(await repo.listForContest(contestId), isEmpty);
    });

    test('replaceForContest refuses a result of another contest', () async {
      final foreign = core.FlightResult.fromJson({
        ...flights.first.toJson(),
        'id': core.Id.create().value,
        'contest_id': core.Id.create().value,
      });

      expect(
        () => repo.replaceForContest(contestId, [foreign]),
        throwsArgumentError,
      );
      expect(await repo.listForContest(contestId), hasLength(flights.length));
    });

    test('replaceForContest keeps the old results when a row fails', () async {
      final duplicate = core.FlightResult.fromJson({
        ...flights.first.toJson(),
        'id': core.Id.create().value,
      });

      await expectLater(
        repo.replaceForContest(contestId, [flights.first, duplicate]),
        throwsA(anything),
      );

      expect(await repo.listForContest(contestId), unorderedEquals(flights));
    });
  });

  group('ParticipationStandingRepository', () {
    late core.ParticipationStandingRepository repo;
    setUp(() => repo = repository.participationStandingRepository);

    test('reads back the example standings unchanged', () async {
      for (final standing in standings) {
        expect(await repo.findById(standing.id), standing);
      }
    });

    test('lists by contest, round and participation', () async {
      final first = standings.first;
      final round = first.asOfRound;
      final inRound = standings.where((s) => s.asOfRound == round).toList()
        ..sort((a, b) => a.place.compareTo(b.place));

      expect(await repo.listForContest(contestId), unorderedEquals(standings));
      expect(await repo.listAsOfRound(contestId, round), inRound);
      expect(await repo.listAsOfRound(contestId, 99), isEmpty);
      expect(
        await repo.listForParticipation(first.contestParticipationId),
        unorderedEquals(
          standings.where(
            (s) => s.contestParticipationId == first.contestParticipationId,
          ),
        ),
      );
    });

    test('replaceForContest swaps the standings', () async {
      final before = await inst.count('mutation_records');

      await repo.replaceForContest(contestId, [standings.first]);

      expect(await repo.listForContest(contestId), [standings.first]);
      expect(await inst.count('mutation_records'), before);
    });

    test('replaceForContest refuses a standing of another contest', () async {
      final foreign = core.ParticipationStanding.fromJson({
        ...standings.first.toJson(),
        'id': core.Id.create().value,
        'contest_id': core.Id.create().value,
      });

      expect(
        () => repo.replaceForContest(contestId, [foreign]),
        throwsArgumentError,
      );
      expect(await repo.listForContest(contestId), hasLength(standings.length));
    });
  });

  group('TeamStandingRepository', () {
    late core.TeamStandingRepository repo;
    setUp(() => repo = repository.teamStandingRepository);

    test('reads back the example standings unchanged', () async {
      for (final standing in teamStandings) {
        expect(await repo.findById(standing.id), standing);
      }
    });

    test('lists by contest, round and team', () async {
      final first = teamStandings.first;
      final inRound =
          teamStandings.where((s) => s.asOfRound == first.asOfRound).toList()
            ..sort((a, b) => a.place.compareTo(b.place));

      expect(
        await repo.listForContest(contestId),
        unorderedEquals(teamStandings),
      );
      expect(await repo.listAsOfRound(contestId, first.asOfRound), inRound);
      expect(
        await repo.listForTeam(first.teamId),
        unorderedEquals(teamStandings.where((s) => s.teamId == first.teamId)),
      );
    });

    test('replaceForContest swaps the standings', () async {
      await repo.replaceForContest(contestId, [teamStandings.first]);

      expect(await repo.listForContest(contestId), [teamStandings.first]);
    });

    test('replaceForContest refuses a standing of another contest', () async {
      final foreign = core.TeamStanding.fromJson({
        ...teamStandings.first.toJson(),
        'id': core.Id.create().value,
        'contest_id': core.Id.create().value,
      });

      expect(
        () => repo.replaceForContest(contestId, [foreign]),
        throwsArgumentError,
      );
    });
  });
}
