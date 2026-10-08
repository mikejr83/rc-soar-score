import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

void main() {
  late HandlerHarness api;
  var mutations = 0;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  Future<void> enter(int pilot, int seconds, {int ordinal = 1}) async {
    final slot = await assignmentOfPilot(api, pilot, ordinal: ordinal);
    final response = await api.send(
      'POST',
      '/contests/$_contestId/assignments/${slot['id']}/scores',
      body: {
        'client_mutation_id': 'entry-${mutations++}',
        'base_score_revision': 0,
        'components': {
          'time_flown': seconds,
          'launch_height': 200,
          'landing': 'points_50',
        },
      },
    );
    expect(response.statusCode, 201, reason: '${await api.json(response)}');
  }

  Future<Map<String, Object?>> results() async =>
      api.json(await api.send('GET', '/contests/$_contestId/results'));

  List<Map<String, Object?>> standingsOf(Map<String, Object?> body) =>
      (body['standings']! as List).cast<Map<String, Object?>>();

  Future<void> scoreRoundOne() async {
    for (var pilot = 1; pilot <= 6; pilot++) {
      await enter(pilot, 600 - pilot * 10);
    }
  }

  group('GET /contests/{id}/results', () {
    test('a contest with no scores has no standings', () async {
      await drawnContest(api);

      final body = await results();

      expect(body['as_of_round'], isNull);
      expect(body['stale'], isFalse);
      expect(body['preliminary'], isFalse);
      expect(body['standings'], isEmpty);
      expect(body['teams'], isEmpty);
    });

    test('a fully scored round ranks the pilots by their scores', () async {
      await drawnContest(api);
      await scoreRoundOne();

      final body = await results();

      expect(body['as_of_round'], 1);
      expect(body['stale'], isFalse);
      expect(body['preliminary'], isFalse);
      final standings = standingsOf(body);
      expect(standings, hasLength(6));
      final places = [for (final s in standings) s['place']! as int];
      expect(places.first, 1);
      expect(places, [...places]..sort());
      expect(
        standings.first['contest_participation_id'],
        matrixTestParticipationId(1),
      );
    });

    test('a round with unscored flights reads as preliminary', () async {
      await drawnContest(api);
      await enter(1, 500);

      final body = await results();

      expect(body['as_of_round'], 1);
      expect(body['stale'], isFalse);
      expect(body['preliminary'], isTrue);
    });

    test('a correction recalculates the standings', () async {
      await drawnContest(api);
      await scoreRoundOne();
      final slot = await assignmentOfPilot(api, 6);
      final before = standingsOf(await results());
      expect(
        before.first['contest_participation_id'],
        matrixTestParticipationId(1),
      );

      final response = await api.send(
        'POST',
        '/contests/$_contestId/assignments/${slot['id']}/scores',
        body: {
          'client_mutation_id': 'fix',
          'base_score_revision': 1,
          'reason': 'Timer misread',
          'components': {
            'time_flown': 595,
            'launch_height': 200,
            'landing': 'points_50',
          },
        },
      );
      expect(response.statusCode, 201, reason: '${await api.json(response)}');

      final standings = standingsOf(await results());
      final pilot6 = standings.firstWhere(
        (s) => s['contest_participation_id'] == matrixTestParticipationId(6),
      );
      expect(pilot6['place'], 1);
    });

    test('results computed under other revisions read as stale', () async {
      await drawnContest(api);
      await scoreRoundOne();
      final stored = api.repository.participationStandings.stored;
      final old = [
        for (final standing in stored)
          ParticipationStanding.fromJson({
            ...standing.toJson(),
            'calculation_version': 'f5j-0',
          }),
      ];
      stored
        ..clear()
        ..addAll(old);

      final stale = await results();
      expect(stale['stale'], isTrue);
      expect(stale['preliminary'], isTrue);

      final recalculated = await api.json(
        await api.send('POST', '/contests/$_contestId/results/recalculation'),
      );
      expect(recalculated['stale'], isFalse);
      expect(recalculated['preliminary'], isFalse);
    });

    test(
      'results lost since the last score read as stale until rebuilt',
      () async {
        await drawnContest(api);
        await scoreRoundOne();
        api.repository.participationStandings.stored.clear();

        expect((await results())['stale'], isTrue);

        final rebuilt = await api.json(
          await api.send('POST', '/contests/$_contestId/results/recalculation'),
        );
        expect(rebuilt['stale'], isFalse);
        expect(standingsOf(rebuilt), hasLength(6));
      },
    );

    test('an unknown contest is 404', () async {
      final response = await api.send(
        'GET',
        '/contests/019c0000-0000-7000-8000-0000000000ee/results',
      );
      expect(response.statusCode, 404);
    });
  });

  group('GET /contests/{id}/results/rounds/{n}', () {
    test('lists the flight results of the round by group', () async {
      await drawnContest(api);
      await scoreRoundOne();

      final response = await api.send(
        'GET',
        '/contests/$_contestId/results/rounds/1',
      );
      final body = await api.json(response);

      expect(response.statusCode, 200, reason: '$body');
      expect(body['ordinal'], 1);
      expect(body['stale'], isFalse);
      final flights = (body['flights']! as List).cast<Map<String, Object?>>();
      expect(flights, hasLength(6));
      expect({for (final f in flights) f['group']}, {1, 2});
    });

    test('a round that does not exist is 400', () async {
      await drawnContest(api);

      final missing = await api.send(
        'GET',
        '/contests/$_contestId/results/rounds/9',
      );
      expect(missing.statusCode, 400);

      final text = await api.send(
        'GET',
        '/contests/$_contestId/results/rounds/first',
      );
      expect(text.statusCode, 400);
    });
  });

  group('POST /contests/{id}/results/recalculation', () {
    test('a contest that is not configured is 409', () async {
      await api.send(
        'POST',
        '/contests',
        body: {
          'id': _contestId,
          'name': 'Spring Open',
          'start_date_time': '2026-10-17T14:00:00.000Z',
          'end_date_time': '2026-10-18T22:00:00.000Z',
          'timezone': 'America/Denver',
        },
      );

      final response = await api.send(
        'POST',
        '/contests/$_contestId/results/recalculation',
      );

      expect(response.statusCode, 409);
    });
  });
}
