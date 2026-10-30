import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;
const _firstRevisionId = '019c0000-0000-7000-8000-000000000501';

String _participationId(int n) => matrixTestParticipationId(n);

void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  /// Six pilots in two groups, three rounds.
  Future<void> drawn({Map<String, Object?> core = const {}}) =>
      drawnContest(api, core: core);

  var count = 0;

  /// [base] defaults to the contest's latest revision, like a client that
  /// draws from the matrix it shows.
  Future<Response> redraw({
    required int firstRound,
    int rounds = 2,
    int groups = 2,
    String? reason,
    String? id,
    int? base,
    bool? preview,
    int? randomSeed,
    int? seedCount,
  }) async {
    if (base == null) {
      final current = await api.json(
        await api.send('GET', '/contests/$_contestId/matrix'),
      );
      base = (current['revision'] as Map)['revision_number'] as int;
    }
    return api.send(
      'POST',
      '/contests/$_contestId/matrix/redraws',
      body: {
        'id':
            id ??
            '019c0000-0000-7000-8000-0000000007${(++count).toString().padLeft(2, '0')}',
        'first_round': firstRound,
        'rounds': rounds,
        'groups_per_round': groups,
        'random_seed': randomSeed ?? 9,
        'attempts_per_round': 5,
        'seed_count': seedCount ?? 2,
        'reason': ?reason,
        'base_matrix_revision': base,
        'preview': preview,
      },
    );
  }

  Future<Map<String, Object?>> matrix() async =>
      api.json(await api.send('GET', '/contests/$_contestId/matrix'));

  List<int> ordinals(Map<String, Object?> body) => [
    for (final r in (body['rounds'] as List).cast<Map>()) r['ordinal'] as int,
  ]..sort();

  /// The assignments of round [ordinal] as `pilot: group`.
  Map<Object?, Object?> placement(Map<String, Object?> body, int ordinal) {
    final round = (body['rounds'] as List).cast<Map>().firstWhere(
      (r) => r['ordinal'] == ordinal,
    );
    return {
      for (final a in (body['assignments'] as List).cast<Map>())
        if (a['scheduled_round_id'] == round['id'])
          a['contest_participation_id']: a['group'],
    };
  }

  group('adding rounds', () {
    test('draws the new rounds as the next revision', () async {
      await drawn();

      final response = await redraw(firstRound: 4);
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      expect(ordinals(body), [1, 2, 3, 4, 5]);
      expect(body['assignments'], hasLength(30));
      final revision = body['revision'] as Map;
      expect(revision['revision_number'], 2);
      expect(revision['previous_revision_id'], _firstRevisionId);
      expect(revision['first_round'], 4);
      expect(revision['last_round'], 5);
      expect(revision['reason'], 'rounds added');
      expect(api.repository.scorePlaceholders.stored, hasLength(30));
    });

    test('keeps stored results current when only rounds are added', () async {
      await drawn();
      final slot = await assignmentOfPilot(api, 1);
      await api.send(
        'POST',
        '/contests/$_contestId/assignments/${slot['id']}/scores',
        body: {
          'client_mutation_id': 'entry-1',
          'base_score_revision': 0,
          'components': {'time_flown': 540, 'launch_height': 200},
        },
      );

      await redraw(firstRound: 4);

      final results = await api.json(
        await api.send('GET', '/contests/$_contestId/results'),
      );
      expect(results['stale'], isFalse);
    });

    test('keeps the rounds already drawn as they are', () async {
      await drawn();
      final before = await matrix();

      final after = await api.json(await redraw(firstRound: 4));

      for (final ordinal in [1, 2, 3]) {
        expect(placement(after, ordinal), placement(before, ordinal));
      }
    });

    test('the fairness report covers all rounds', () async {
      await drawn();

      final body = await api.json(await redraw(firstRound: 4));

      final fairness = (body['revision'] as Map)['fairness_summary'] as Map;
      expect(fairness['feasible_pairs'], 15);
      final histogram = fairness['matchup_histogram'] as Map;
      final meetings = histogram.entries.fold<int>(
        0,
        (total, e) => total + int.parse(e.key as String) * (e.value as int),
      );
      // Two groups of three meet six pairs a round, over five rounds.
      expect(meetings, 30);
    });

    test('draws a pilot who joined after the first draw', () async {
      await drawnContest(api, pilots: 5);
      await api.send(
        'POST',
        '/participants',
        body: {
          'id': matrixTestProfileId(6),
          'first_name': 'P6',
          'last_name': 'X',
        },
      );
      await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: {
          'id': _participationId(6),
          'participant_profile_id': matrixTestProfileId(6),
          'role_id': SystemRoles.pilotId.value,
        },
      );

      final body = await api.json(await redraw(firstRound: 4));

      final seven = (body['assignments'] as List).cast<Map>().where(
        (a) => a['contest_participation_id'] == _participationId(6),
      );
      expect(seven, hasLength(2));
      expect(
        api
            .repository
            .participations
            .participations[Id.parse(_participationId(6))]!
            .participantNumber,
        6,
      );
    });

    test('leaves out a retired pilot', () async {
      await drawn();
      await api.send(
        'PUT',
        '/contests/$_contestId/participations/${_participationId(6)}',
        body: {'base_revision': 1, 'retired_at_round': 4},
      );

      final body = await api.json(await redraw(firstRound: 4));

      final six = (body['assignments'] as List).cast<Map>().where(
        (a) =>
            a['contest_participation_id'] == _participationId(6) &&
            a['matrix_revision_id'] != _firstRevisionId,
      );
      expect(six, isEmpty);
      expect(body['assignments'], hasLength(18 + 10));
    });

    test('repeating the request returns the matrix it drew', () async {
      await drawn();
      const id = '019c0000-0000-7000-8000-000000000990';
      final first = await api.json(await redraw(firstRound: 4, id: id));

      final again = await redraw(firstRound: 4, id: id);

      expect(again.statusCode, 201);
      expect(await api.json(again), first);
      expect(api.repository.scorePlaceholders.stored, hasLength(30));
    });

    test('a reason is kept', () async {
      await drawn();

      final body = await api.json(
        await redraw(firstRound: 4, reason: 'Added two rounds'),
      );

      expect((body['revision'] as Map)['reason'], 'Added two rounds');
    });
  });

  group('drawing the tail again', () {
    test('replaces the rounds from the first round on', () async {
      await drawn();
      final before = await matrix();

      final response = await redraw(firstRound: 2);
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      expect(ordinals(body), [1, 2, 3]);
      expect(body['assignments'], hasLength(18));
      expect(placement(body, 1), placement(before, 1));
      final revision = body['revision'] as Map;
      expect(revision['first_round'], 2);
      expect(revision['last_round'], 3);
      expect(revision['reason'], 'redraw from round 2');
      final oldRounds = {
        for (final r in (before['rounds'] as List).cast<Map>()) r['id'],
      };
      final newRounds = [
        for (final r in (body['rounds'] as List).cast<Map>()) r['id'],
      ];
      expect(newRounds.where(oldRounds.contains), hasLength(1));
    });

    test('a shorter tail cancels the rounds beyond it', () async {
      await drawn();

      final body = await api.json(await redraw(firstRound: 2, rounds: 1));

      expect(ordinals(body), [1, 2]);
      expect(body['assignments'], hasLength(12));
    });

    test('a longer tail adds rounds', () async {
      await drawn();

      final body = await api.json(await redraw(firstRound: 3, rounds: 3));

      expect(ordinals(body), [1, 2, 3, 4, 5]);
      expect(body['assignments'], hasLength(30));
    });

    test('a redraw from round 1 draws the whole matrix again', () async {
      await drawn();

      final body = await api.json(
        await redraw(firstRound: 1, rounds: 4, groups: 3),
      );

      expect(ordinals(body), [1, 2, 3, 4]);
      expect(body['assignments'], hasLength(24));
      expect((body['groups'] as List), hasLength(12));
    });

    test('is refused when a round to replace has a score', () async {
      await drawn();
      final scored = (await matrix())['assignments'] as List;
      final round3 = ((await matrix())['rounds'] as List)
          .cast<Map>()
          .firstWhere((r) => r['ordinal'] == 3);
      final inRound = scored.cast<Map>().firstWhere(
        (a) => a['scheduled_round_id'] == round3['id'],
      );
      final placeholders = api.repository.scorePlaceholders.stored;
      final index = placeholders.indexWhere(
        (p) => p.assignmentId.value == inRound['id'],
      );
      final p = placeholders[index];
      placeholders[index] = ScorePlaceholder(
        id: p.id,
        contestId: p.contestId,
        contestParticipationId: p.contestParticipationId,
        assignmentId: p.assignmentId,
        state: ScorePlaceholderState.official,
        scoreRevision: 1,
      );

      final refused = await redraw(firstRound: 2);
      expect(refused.statusCode, 409);
      expect((await api.errorOf(refused))['code'], 'rounds_have_scores');

      // Round 3 is not touched by an extension.
      expect((await redraw(firstRound: 4)).statusCode, 201);
    });

    test('is refused when a group of a round to replace is locked', () async {
      await drawn();
      final round2 = ((await matrix())['rounds'] as List)
          .cast<Map>()
          .firstWhere((r) => r['ordinal'] == 2);
      final groups = api.repository.roundGroups.groups;
      final index = groups.indexWhere((g) => g.roundId.value == round2['id']);
      final g = groups[index];
      groups[index] = RoundGroup(
        id: g.id,
        contestId: g.contestId,
        roundId: g.roundId,
        groupNumber: g.groupNumber,
        status: GroupStatus.locked,
        lockedBy: _owner,
        lockedAt: DateTime.utc(2026, 10, 17, 15),
      );

      final response = await redraw(firstRound: 2);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'group_locked');
    });
  });

  group('a redraw that is refused', () {
    test('from a round beyond the next one is a 400', () async {
      await drawn();

      expect((await redraw(firstRound: 5)).statusCode, 400);
      expect((await redraw(firstRound: 0)).statusCode, 400);
    });

    test('with more groups than pilots is a 400', () async {
      await drawn();

      expect((await redraw(firstRound: 4, groups: 7)).statusCode, 400);
    });

    test('before the first draw is a 409', () async {
      await drawnContest(api, pilots: 4, skipDraw: true);

      // No draw exists yet, so there is no revision to resolve from; the
      // 409 comes from the matrix being uneditable.
      final response = await redraw(firstRound: 1, base: 1);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'matrix_not_editable');
    });

    test('in a locked contest is a 409', () async {
      await drawn();
      await api.send(
        'POST',
        '/contests/$_contestId/actions',
        body: {'action': 'lock', 'base_revision': 2},
      );

      final response = await redraw(firstRound: 4);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'contest_locked');
    });

    test('of an unknown contest is a 404', () async {
      // The contest check comes before the body check, so a missing
      // `base_matrix_revision` in the body does not turn this into a 400.
      expect(
        (await api.send(
          'POST',
          '/contests/$_contestId/matrix/redraws',
          body: {
            'id': '019c0000-0000-7000-8000-000000000701',
            'first_round': 1,
            'rounds': 2,
            'groups_per_round': 2,
          },
        )).statusCode,
        404,
      );
    });
  });

  group('reading the base revision', () {
    test('without `base_matrix_revision` is a 400', () async {
      await drawn();

      final response = await api.send(
        'POST',
        '/contests/$_contestId/matrix/redraws',
        body: {
          'id': '019c0000-0000-7000-8000-000000000707',
          'first_round': 4,
          'rounds': 2,
          'groups_per_round': 2,
        },
      );

      expect(response.statusCode, 400);
    });
  });

  group('the stale-matrix check', () {
    test('against the latest revision is stored', () async {
      await drawn();
      final before = (await matrix())['revision'];

      final response = await redraw(firstRound: 4, base: 1);
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      expect((body['revision'] as Map)['revision_number'], 2);
      expect(before, allOf(isNotNull, isNot(body['revision'])));
    });

    test('behind the latest is a 409 that changes nothing', () async {
      await drawn();
      await redraw(firstRound: 4); // the matrix moves to revision 2.
      final before = await matrix();

      final refused = await redraw(firstRound: 3, base: 1);

      expect(refused.statusCode, 409);
      expect((await api.errorOf(refused))['code'], 'stale_matrix');
      expect(await matrix(), before);
    });

    test('applies to a preview too', () async {
      await drawn();
      await redraw(firstRound: 4); // the matrix moves to revision 2.
      final before = await matrix();

      final refused = await redraw(firstRound: 3, base: 1, preview: true);

      expect(refused.statusCode, 409);
      expect((await api.errorOf(refused))['code'], 'stale_matrix');
      expect(await matrix(), before);
    });
  });

  group('drawing without storing', () {
    test('answers the draw its confirm would store', () async {
      await drawn();
      final before = await matrix();

      final preview = await api.json(
        await redraw(firstRound: 4, preview: true),
      );

      expect(preview['seed'], isA<int>());
      expect(preview['candidate_fairness'], isA<Map>());
      expect(preview['current_fairness'], isA<Map>());
      expect(preview['better'], isA<bool>());

      // Nothing was stored: same revision, rounds and placeholders.
      expect(await matrix(), before);
      expect(api.repository.scorePlaceholders.stored, hasLength(18));
    });

    test('a confirm with its seed reproduces the previewed fairness', () async {
      await drawn();
      final preview = await api.json(
        await redraw(firstRound: 4, preview: true),
      );
      final seed = preview['seed'] as int;

      final body = await api.json(
        await redraw(firstRound: 4, randomSeed: seed, seedCount: 1),
      );

      expect(
        (body['revision'] as Map)['fairness_summary'],
        preview['candidate_fairness'],
        reason:
            'confirming the previewed seed must store the fairness the '
            'preview reported',
      );
    });

    test('a cancelled preview stores nothing', () async {
      final runner = HeldDrawRunner()..hold = false;
      final apiWithRunner = HandlerHarness(_owner, drawRunner: runner);
      await drawnContest(apiWithRunner);
      runner.hold = true;
      final before = await apiWithRunner.json(
        await apiWithRunner.send('GET', '/contests/$_contestId/matrix'),
      );
      Future<dynamic> preview() => apiWithRunner.send(
        'POST',
        '/contests/$_contestId/matrix/redraws',
        body: {
          'id': '019c0000-0000-7000-8000-000000000799',
          'first_round': 4,
          'rounds': 2,
          'groups_per_round': 2,
          'base_matrix_revision': 1,
          'preview': true,
        },
      );
      final drawing = preview();
      await runner.reported.future;
      expect(
        (await apiWithRunner.send(
          'DELETE',
          '/contests/$_contestId/matrix/draws/019c0000-0000-7000-8000-000000000799',
        )).statusCode,
        200,
      );

      final response = await drawing;

      expect(response.statusCode, 409);
      expect((await apiWithRunner.errorOf(response))['code'], 'draw_cancelled');
      expect(
        await apiWithRunner.json(
          await apiWithRunner.send('GET', '/contests/$_contestId/matrix'),
        ),
        before,
      );
    });
  });
}
