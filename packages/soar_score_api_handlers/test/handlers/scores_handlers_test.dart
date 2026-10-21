import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  var mutations = 0;
  Future<dynamic> enter(
    Map<String, Object?> assignment, {
    Map<String, Object?>? components,
    int base = 0,
    String? mutation,
    String? reason,
  }) => api.send(
    'POST',
    '/contests/$_contestId/assignments/${assignment['id']}/scores',
    body: {
      'client_mutation_id': mutation ?? 'entry-${mutations++}',
      'base_score_revision': base,
      'components':
          components ??
          {'time_flown': 540, 'launch_height': 200, 'landing': 'points_50'},
      'reason': ?reason,
    },
  );

  Future<Map<String, Object?>> assignmentOf(int n, {int ordinal = 1}) =>
      assignmentOfPilot(api, n, ordinal: ordinal);

  Future<Map<String, Object?>> contest() async =>
      api.json(await api.send('GET', '/contests/$_contestId'));

  group('entering a score', () {
    test('stores it, calculates the flight and starts the contest', () async {
      await drawnContest(api);
      expect((await contest())['lifecycle_state'], 'Ready');

      final response = await enter(await assignmentOf(1));
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      final official = body['official_score']! as Map;
      expect(official['score_revision'], 1);
      expect(official['set_by'], _owner.value);
      expect(official['reason'], 'Entered by the director');
      expect((official['components'] as Map)['time_flown'], 540);
      final placeholder = body['placeholder']! as Map;
      expect(placeholder['state'], 'Official');
      expect(placeholder['score_revision'], 1);
      final calculated = body['calculated']! as Map;
      expect(calculated['outcome'], 'Scored');
      expect(calculated['flight_points'], 540);
      expect(calculated['landing_bonus'], 50);
      expect(calculated['height_penalty'], 100);
      expect(calculated['raw_score'], 490);
      expect((body['contest']! as Map)['lifecycle_state'], 'Running');
      expect((await contest())['lifecycle_state'], 'Running');
      final attempt = api.repository.scoreAttempts.stored.single;
      expect(attempt.authority, Authority.director);
      expect(attempt.rawComponents['launch_height'], 200);
    });

    test('a cumulative penalty is accepted and stored', () async {
      await drawnContest(api);

      final response = await enter(
        await assignmentOf(1),
        components: {
          'time_flown': 540,
          'launch_height': 200,
          'cumulative_penalty': 25,
        },
      );
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      final official = body['official_score']! as Map;
      expect((official['components'] as Map)['cumulative_penalty'], 25);
    });

    test('a cumulative penalty of 0 is stored as 0', () async {
      await drawnContest(api);

      final response = await enter(
        await assignmentOf(1),
        components: {
          'time_flown': 540,
          'launch_height': 200,
          'cumulative_penalty': 0,
        },
      );
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      final official = body['official_score']! as Map;
      expect((official['components'] as Map)['cumulative_penalty'], 0);
      expect(
        (api.repository.officialScores.stored.single.components)
            ['cumulative_penalty'],
        0,
      );
    });

    test('a negative cumulative penalty is 400', () async {
      await drawnContest(api);

      final response = await enter(
        await assignmentOf(1),
        components: {
          'time_flown': 540,
          'launch_height': 200,
          'cumulative_penalty': -5,
        },
      );

      expect(response.statusCode, 400);
      expect((await api.errorOf(response))['code'], 'invalid_request');
      expect(api.repository.officialScores.stored, isEmpty);
    });

    test('a zero flight is scored zero with its reason', () async {
      await drawnContest(api);

      final body = await api.json(
        await enter(await assignmentOf(1), components: {'motor_restart': true}),
      );

      final calculated = body['calculated']! as Map;
      expect(calculated['outcome'], 'Zero');
      expect(calculated['raw_score'], 0);
      expect(calculated['zero_reasons'], ['motor_restart']);
    });

    test('repeating a client mutation id returns the first entry', () async {
      await drawnContest(api);
      final slot = await assignmentOf(1);
      final first = await api.json(await enter(slot, mutation: 'same'));

      final again = await enter(slot, mutation: 'same');

      expect(again.statusCode, 201);
      expect(await api.json(again), first);
      expect(api.repository.officialScores.stored, hasLength(1));
    });

    test('a correction adds the next revision and keeps the first', () async {
      await drawnContest(api);
      final slot = await assignmentOf(1);
      await enter(slot);

      final response = await enter(
        slot,
        base: 1,
        components: {'time_flown': 500, 'launch_height': 200},
        reason: 'Timer misread',
      );
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      expect((body['official_score']! as Map)['score_revision'], 2);
      expect((body['official_score']! as Map)['reason'], 'Timer misread');
      expect((body['calculated']! as Map)['landing_bonus'], 0);
      expect(api.repository.officialScores.stored, hasLength(2));
    });

    test('a correction without a reason is 400', () async {
      await drawnContest(api);
      final slot = await assignmentOf(1);
      await enter(slot);

      final response = await enter(slot, base: 1);

      expect(response.statusCode, 400);
      expect(api.repository.officialScores.stored, hasLength(1));
    });

    test('a stale score revision is 409 and stores nothing', () async {
      await drawnContest(api);
      final slot = await assignmentOf(1);
      await enter(slot);

      final response = await enter(slot, base: 0);
      final error = await api.errorOf(response);

      expect(response.statusCode, 409);
      expect(error['code'], 'stale_revision');
      // Both revisions are carried in the free-text message.
      expect(error['message'], contains('at revision 1'));
      expect(error['message'], contains('based on 0'));
      expect(api.repository.officialScores.stored, hasLength(1));
    });

    test('components the discipline refuses are 400', () async {
      await drawnContest(api);

      final response = await enter(
        await assignmentOf(1),
        components: {'time_flown': 540},
      );

      expect(response.statusCode, 400);
      expect((await api.errorOf(response))['code'], 'invalid_request');
      expect(api.repository.officialScores.stored, isEmpty);
      expect((await contest())['lifecycle_state'], 'Ready');
    });

    test('a landing the table does not have is 400', () async {
      await drawnContest(api);

      final response = await enter(
        await assignmentOf(1),
        components: {
          'time_flown': 540,
          'launch_height': 200,
          'landing': 'points_99',
        },
      );

      expect(response.statusCode, 400);
      expect(api.repository.officialScores.stored, isEmpty);
    });

    test('a locked contest is 409', () async {
      await drawnContest(api);
      final locked = await api.send(
        'POST',
        '/contests/$_contestId/actions',
        body: {
          'action': 'lock',
          'base_revision': (await contest())['revision'],
        },
      );
      expect(locked.statusCode, 200);

      final response = await enter(await assignmentOf(1));

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'contest_locked');
    });

    test('a contest that is not drawn takes no score', () async {
      await drawnContest(api, skipDraw: true);

      final response = await api.send(
        'POST',
        '/contests/$_contestId/assignments/${Id.create().value}/scores',
        body: {
          'client_mutation_id': 'x',
          'base_score_revision': 0,
          'components': {'motor_restart': true},
        },
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'scoring_not_available');
    });

    test('a locked group is 409', () async {
      await drawnContest(api);
      final slot = await assignmentOf(1);
      final groupNumber = slot['group'] as int;
      final index = api.repository.roundGroups.groups.indexWhere(
        (g) =>
            g.roundId.value == slot['scheduled_round_id'] &&
            g.groupNumber == groupNumber,
      );
      final group = api.repository.roundGroups.groups[index];
      api.repository.roundGroups.groups[index] = RoundGroup(
        id: group.id,
        contestId: group.contestId,
        roundId: group.roundId,
        groupNumber: group.groupNumber,
        status: GroupStatus.locked,
        lockedBy: _owner,
        lockedAt: DateTime.utc(2026, 10, 17),
      );

      final response = await enter(slot);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'group_locked');
    });

    test('an unknown slot is 404', () async {
      await drawnContest(api);

      final response = await enter({'id': Id.create().value});

      expect(response.statusCode, 404);
    });
  });

  group('reading scores', () {
    test('lists every slot and the progress of each round', () async {
      await drawnContest(api);
      await enter(await assignmentOf(1));
      await enter(await assignmentOf(2));

      final response = await api.send('GET', '/contests/$_contestId/scores');
      final body = await api.json(response);

      expect(response.statusCode, 200, reason: '$body');
      final slots = (body['scores'] as List).cast<Map>();
      expect(slots, hasLength(18));
      final scored = slots.where((s) => s['official_score'] != null);
      expect(scored, hasLength(2));
      expect(scored.map((s) => (s['placeholder'] as Map)['state']).toSet(), {
        'Official',
      });
      final rounds = (body['rounds'] as List).cast<Map>();
      expect(rounds.map((r) => r['ordinal']), [1, 2, 3]);
      expect(rounds.map((r) => r['total']), [6, 6, 6]);
      expect(rounds.map((r) => r['scored']), [2, 0, 0]);
    });

    test('a contest with no matrix has no slots', () async {
      await drawnContest(api, skipDraw: true);

      final body = await api.json(
        await api.send('GET', '/contests/$_contestId/scores'),
      );

      expect(body['scores'], isEmpty);
      expect(body['rounds'], isEmpty);
    });

    test('an unknown contest is 404', () async {
      final response = await api.send(
        'GET',
        '/contests/${Id.create().value}/scores',
      );

      expect(response.statusCode, 404);
    });
  });

  group('reading the history of a slot', () {
    Future<dynamic> history(Object assignmentId) => api.send(
      'GET',
      '/contests/$_contestId/assignments/$assignmentId/scores/history',
    );

    test('lists every revision with its reason', () async {
      await drawnContest(api);
      final slot = await assignmentOf(1);
      await enter(slot);
      await enter(
        slot,
        base: 1,
        components: {'time_flown': 500, 'launch_height': 200},
        reason: 'Timer misread',
      );

      final response = await history(slot['id']!);
      final body = await api.json(response);

      expect(response.statusCode, 200, reason: '$body');
      expect(body['assignment_id'], slot['id']);
      final entries = (body['entries'] as List).cast<Map>();
      expect(entries.map((e) => e['score_revision']), [1, 2]);
      expect(entries.map((e) => e['outcome']), ['superseded', 'current']);
      expect(entries.map((e) => e['reason']), [
        'Entered by the director',
        'Timer misread',
      ]);
      expect(entries.last['actor_id'], _owner.value);
      expect(entries.last['authority'], 'Director');
      expect((entries.first['components'] as Map)['time_flown'], 540);
      expect(entries.last['at'], isNotNull);
    });

    test('is empty for a slot with no score', () async {
      await drawnContest(api);

      final body = await api.json(
        await history((await assignmentOf(1))['id']!),
      );

      expect(body['entries'], isEmpty);
    });

    test('an unknown slot is 404', () async {
      await drawnContest(api);

      final response = await history(Id.create().value);

      expect(response.statusCode, 404);
    });
  });
}
