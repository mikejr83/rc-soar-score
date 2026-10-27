import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = '019c0000-0000-7000-8000-000000000020';
const _revisionId = '019c0000-0000-7000-8000-000000000501';

String _profileId(int n) => '019c0000-0000-7000-8000-0000000001${_pad(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-0000000002${_pad(n)}';
String _pad(int n) => n.toString().padLeft(2, '0');

void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  Future<void> createContest() async {
    final response = await api.send(
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
    expect(response.statusCode, 201);
  }

  Future<void> configure({Map<String, Object?> core = const {}}) async {
    final response = await api.send(
      'POST',
      '/contests/$_contestId/configuration',
      body: {
        'base_revision_number': 0,
        'discipline_profile_id': SystemDisciplineProfiles.f5jId.value,
        'config': {
          'core': core,
          'discipline': {'working_time': 600},
        },
      },
    );
    expect(response.statusCode, 201, reason: '${await api.json(response)}');
  }

  /// Adds [count] pilots, numbered 1 to [count].
  Future<void> addPilots(int count) async {
    for (var n = 1; n <= count; n++) {
      await api.send(
        'POST',
        '/participants',
        body: {'id': _profileId(n), 'first_name': 'P$n', 'last_name': 'X'},
      );
      final response = await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: {
          'id': _participationId(n),
          'participant_profile_id': _profileId(n),
          'role_id': SystemRoles.pilotId.value,
        },
      );
      expect(response.statusCode, 201);
    }
  }

  Future<dynamic> draw({
    int rounds = 3,
    int groups = 2,
    int? seed,
    int? attempts,
    int? seeds,
    String id = _revisionId,
  }) => api.send(
    'POST',
    '/contests/$_contestId/matrix/draws',
    body: {
      'id': id,
      'rounds': rounds,
      'groups_per_round': groups,
      'random_seed': ?seed,
      'attempts_per_round': ?attempts,
      'seed_count': ?seeds,
    },
  );

  Future<Map<String, Object?>> getMatrix() async =>
      api.json(await api.send('GET', '/contests/$_contestId/matrix'));

  group('GET /contests/{id}/matrix', () {
    test('is empty before the first draw', () async {
      await createContest();

      final matrix = await getMatrix();

      expect(matrix['revision'], isNull);
      expect(matrix['rounds'], isEmpty);
      expect(matrix['assignments'], isEmpty);
      expect(matrix['progress'], isEmpty);
    });

    test('is a 404 for an unknown contest', () async {
      final response = await api.send('GET', '/contests/$_contestId/matrix');

      expect(response.statusCode, 404);
    });
  });

  group('POST /contests/{id}/matrix/draws', () {
    test('draws, finalizes and readies the contest', () async {
      await createContest();
      await configure();
      await addPilots(6);

      final response = await draw(seed: 7);
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      expect((body['revision'] as Map)['id'], _revisionId);
      expect((body['revision'] as Map)['revision_number'], 1);
      expect(body['rounds'], hasLength(3));
      expect(body['groups'], hasLength(6));
      expect(body['assignments'], hasLength(18));
      expect(api.repository.scorePlaceholders.stored, hasLength(18));
      expect(
        [
          for (final round in body['progress'] as List)
            ((round as Map)['scored'], round['total']),
        ],
        [(0, 6), (0, 6), (0, 6)],
      );

      final contest = await api.json(
        await api.send('GET', '/contests/$_contestId'),
      );
      expect(contest['lifecycle_state'], 'Ready');
      final numbers = api.repository.participations.participations.values.map(
        (p) => p.participantNumber,
      );
      expect(numbers.toSet(), {1, 2, 3, 4, 5, 6});
      expect(await getMatrix(), body);
    });

    test('the same seed gives the same matrix', () async {
      Future<List<Object?>> run() async {
        api = HandlerHarness(_owner);
        await createContest();
        await configure();
        await addPilots(6);
        final body = await api.json(await draw(seed: 11));
        return [
          for (final a in (body['assignments'] as List).cast<Map>())
            [a['contest_participation_id'], a['group']],
        ];
      }

      expect(await run(), await run());
    });

    test('repeating the request returns the stored matrix', () async {
      await createContest();
      await configure();
      await addPilots(4);
      final first = await api.json(await draw());

      final again = await draw();

      expect(again.statusCode, 201);
      expect(await api.json(again), first);
      expect(api.repository.scorePlaceholders.stored, hasLength(12));
    });

    test('a contest that is not configured is a 409', () async {
      await createContest();
      await addPilots(4);

      final response = await draw();

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'not_configured');
    });

    test('a second draw is a 409', () async {
      await createContest();
      await configure();
      await addPilots(4);
      await draw();

      final response = await draw(id: '019c0000-0000-7000-8000-000000000502');

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'matrix_exists');
    });

    test('a locked contest is a 409', () async {
      await createContest();
      await configure();
      await addPilots(4);
      await api.send(
        'POST',
        '/contests/$_contestId/actions',
        body: {'action': 'lock', 'base_revision': 1},
      );

      final response = await draw();

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'contest_locked');
    });

    test('more groups than pilots is a 400', () async {
      await createContest();
      await configure();
      await addPilots(3);

      expect((await draw(groups: 4)).statusCode, 400);
    });

    test('an attempts count outside 1 to 200 is a 400', () async {
      await createContest();
      await configure();
      await addPilots(4);

      expect((await draw(attempts: 0)).statusCode, 400);
      expect((await draw(attempts: 201)).statusCode, 400);
      expect((await draw(attempts: 5)).statusCode, 201);
    });

    test('a seed count outside 1 to 20 is a 400', () async {
      await createContest();
      await configure();
      await addPilots(4);

      expect((await draw(seeds: 0)).statusCode, 400);
      expect((await draw(seeds: 21)).statusCode, 400);
      expect((await draw(seeds: 2)).statusCode, 201);
    });

    test(
      'records the engine settings, the winning seed and the score',
      () async {
        await createContest();
        await configure();
        await addPilots(6);

        final body = await api.json(await draw(seeds: 2, seed: 3));

        final revision = body['revision'] as Map;
        expect(revision['algorithm_version'], 'optimized-1');
        final config = revision['draw_config'] as Map;
        expect(config['seed_count'], 2);
        expect(config['requested_seed'], 3);
        final fairness = revision['fairness_summary'] as Map;
        expect(fairness['fairness_score'], inInclusiveRange(0, 100));
      },
    );

    test('records the attempts and the feasible-pair fairness', () async {
      await createContest();
      await configure();
      await addPilots(6);

      final body = await api.json(await draw(attempts: 5, seed: 3));

      final revision = body['revision'] as Map;
      expect((revision['draw_config'] as Map)['attempts_per_round'], 5);
      final fairness = revision['fairness_summary'] as Map;
      expect(fairness['feasible_pairs'], 15);
      expect(fairness, contains('mean_absolute_deviation'));
    });

    test('a retired pilot is skipped by the draw', () async {
      await createContest();
      await configure();
      await addPilots(5);
      final retire = await api.send(
        'PUT',
        '/contests/$_contestId/participations/${_participationId(5)}',
        body: {'base_revision': 0, 'retired_at_round': 1},
      );
      expect(retire.statusCode, 200, reason: '${await api.json(retire)}');

      final body = await api.json(await draw(seed: 5));

      final assignments = (body['assignments'] as List).cast<Map>();
      expect(assignments, hasLength(12));
      expect(
        assignments.map((a) => a['contest_participation_id']),
        isNot(contains(_participationId(5))),
      );
    });

    test('a seeded contest first draws only its preliminary rounds', () async {
      await createContest();
      await configure(
        core: {'draw_mode': 'SeededManOnMan', 'preliminary_rounds': 2},
      );
      await addPilots(4);

      final tooMany = await draw();

      expect(tooMany.statusCode, 409);
      expect(
        (await api.errorOf(tooMany))['code'],
        'seeded_rounds_need_standings',
      );
      expect((await draw(rounds: 2)).statusCode, 201);
    });

    test('no pilots is a 400', () async {
      await createContest();
      await configure();

      expect((await draw(groups: 1)).statusCode, 400);
    });

    test('an unknown contest is a 404', () async {
      expect((await draw()).statusCode, 404);
    });
  });

  group('with team protection', () {
    Future<void> team(String id, String name) async {
      final response = await api.send(
        'POST',
        '/contests/$_contestId/teams',
        body: {'id': id, 'name': name},
      );
      expect(response.statusCode, 201);
    }

    Future<void> member(String id, String teamId, int pilot) async {
      final response = await api.send(
        'POST',
        '/contests/$_contestId/team-memberships',
        body: {
          'id': id,
          'team_id': teamId,
          'contest_participation_id': _participationId(pilot),
        },
      );
      expect(response.statusCode, 201);
    }

    const teamId = '019c0000-0000-7000-8000-000000000301';

    test('a team of three needs three groups', () async {
      await createContest();
      await configure(
        core: {
          'teams_enabled': true,
          'team_pilot_count': 3,
          'team_protection': true,
        },
      );
      await addPilots(6);
      await team(teamId, 'Red');
      for (var n = 1; n <= 3; n++) {
        await member('019c0000-0000-7000-8000-00000000040$n', teamId, n);
      }

      final tooFew = await draw(groups: 2);
      expect(tooFew.statusCode, 400);

      final response = await draw(groups: 3);
      final body = await api.json(response);
      expect(response.statusCode, 201, reason: '$body');
      final assignments = (body['assignments'] as List).cast<Map>();
      final teammates = {
        _participationId(1),
        _participationId(2),
        _participationId(3),
      };
      final seen = <String>{};
      for (final a in assignments) {
        if (!teammates.contains(a['contest_participation_id'])) continue;
        // One teammate per group in every round.
        expect(
          seen.add('${a['scheduled_round_id']}/${a['group']}'),
          isTrue,
          reason: 'teammates share a group',
        );
      }
      expect(assignments, hasLength(18));
    });
  });

  group('contest-scoped authorization', () {
    late TwoAccountApi two;

    setUp(() => two = TwoAccountApi(owner: _owner));

    test('a foreign director cannot draw a contest', () async {
      two.storeContest(Id.parse(_contestId));

      await two.expectDenied(
        two.outsiderApi,
        'POST',
        '/contests/$_contestId/matrix/draws',
        body: {
          'id': '019c0000-0000-7000-8000-000000000501',
          'rounds': 1,
          'groups_per_round': 1,
          'random_seed': 7,
        },
      );

      expect(two.ownerApi.repository.matrixRevisions.revisions, isEmpty);
    });

    test('a foreign director cannot read or cancel a draw', () async {
      two.storeContest(Id.parse(_contestId));
      const drawId = '019c0000-0000-7000-8000-000000000501';
      final path = '/contests/$_contestId/matrix/draws/$drawId';

      await two.expectDenied(two.outsiderApi, 'GET', path);
      await two.expectDenied(two.outsiderApi, 'DELETE', path);
    });
  });
}
