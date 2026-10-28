import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;
const _firstRevisionId = '019c0000-0000-7000-8000-000000000501';
const _secondRevisionId = '019c0000-0000-7000-8000-000000000701';

void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  /// Six pilots in two groups, three rounds.
  Future<void> drawn() async {
    await drawnContest(api);
  }

  Future<void> redraw() => api.send(
    'POST',
    '/contests/$_contestId/matrix/redraws',
    body: {
      'id': _secondRevisionId,
      'first_round': 4,
      'rounds': 2,
      'groups_per_round': 2,
      'random_seed': 9,
      'attempts_per_round': 5,
      'seed_count': 2,
      'reason': 'rounds added',
    },
  );

  Future<List<Map<String, Object?>>> revisions() async {
    final response = await api.send(
      'GET',
      '/contests/$_contestId/matrix/revisions',
    );
    final body = await api.json(response);
    expect(response.statusCode, 200, reason: '$body');
    return (body['revisions'] as List).cast<Map<String, Object?>>();
  }

  Future<Map<String, Object?>> readRevision(String id) async {
    final response = await api.send(
      'GET',
      '/contests/$_contestId/matrix/revisions/$id',
    );
    final body = await api.json(response);
    expect(response.statusCode, 200, reason: '$body');
    return body;
  }

  /// The assignments of [round] as `pilot: group` for [matrix].
  Map<Object?, Object?> placement(
    Map<String, Object?> matrix,
    Map<Object?, Object?> round,
  ) {
    return {
      for (final a in (matrix['assignments'] as List).cast<Map>())
        if (a['scheduled_round_id'] == round['id'])
          a['contest_participation_id']: a['group'],
    };
  }

  group('listing revisions', () {
    test('is empty before the first draw', () async {
      await drawnContest(api, skipDraw: true);

      expect(await revisions(), isEmpty);
    });

    test('has one revision after the first draw', () async {
      await drawn();

      final list = await revisions();
      expect(list, hasLength(1));
      expect(list.first['id'], _firstRevisionId);
      expect(list.first['revision_number'], 1);
      expect(list.first['first_round'], 1);
      expect(list.first['last_round'], 3);
      expect(list.first['reason'], 'initial draw');
      expect(list.first['created_by'], _owner.value);
      expect(list.first['algorithm_version'], MatrixService.algorithmVersion);
      expect(list.first['random_seed'], isNotNull);
      expect(list.first['created_at'], isNotNull);
    });

    test('shows both revisions, newest first, after a redraw', () async {
      await drawn();
      await redraw();

      final list = await revisions();
      expect(list, hasLength(2));
      expect(list[0]['id'], _secondRevisionId);
      expect(list[0]['revision_number'], 2);
      expect(list[0]['first_round'], 4);
      expect(list[0]['last_round'], 5);
      expect(list[1]['id'], _firstRevisionId);
      expect(list[1]['revision_number'], 1);
    });

    test('reports the fairness score of each revision', () async {
      await drawn();
      await redraw();

      final list = await revisions();
      expect(list[0]['fairness_score'], isNotNull);
      expect(list[1]['fairness_score'], isA<num>());
    });
  });

  group('reading a revision', () {
    test(
      'returns one superseded revision with its original assignments',
      () async {
        await drawn();
        final before = await api.json(
          await api.send('GET', '/contests/$_contestId/matrix'),
        );
        await redraw();

        final body = await readRevision(_firstRevisionId);
        expect((body['revision'] as Map)['id'], _firstRevisionId);
        final roundIds = {
          for (final r in (body['rounds'] as List).cast<Map>()) r['id'],
        };
        // Only the first revision's rounds, not the added ones.
        expect(roundIds, hasLength(3));
        // Each group belongs to a round of this revision.
        final groups = (body['groups'] as List).cast<Map>();
        for (final group in groups) {
          expect(roundIds, contains(group['round_id']));
        }
        // Round 2's placements survive the redraw untouched.
        final round2Body = (body['rounds'] as List).cast<Map>().firstWhere(
          (r) => r['ordinal'] == 2,
        );
        final round2Before = (before['rounds'] as List).cast<Map>().firstWhere(
          (r) => r['ordinal'] == 2,
        );
        expect(placement(body, round2Body), placement(before, round2Before));
        expect(body['progress'], isEmpty);
      },
    );

    test('of the latest revision equals the current matrix', () async {
      await drawn();

      final body = await readRevision(_firstRevisionId);
      final current = await api.json(
        await api.send('GET', '/contests/$_contestId/matrix'),
      );
      expect(body['revision'], current['revision']);
      expect(
        (body['rounds'] as List).length,
        (current['rounds'] as List).length,
      );
      expect(
        (body['assignments'] as List).length,
        (current['assignments'] as List).length,
      );
    });

    test(
      'shows the draw itself, not the moves and late adds made after it',
      () async {
        await drawnContest(api, pilots: 5);
        final before = await api.json(
          await api.send('GET', '/contests/$_contestId/matrix'),
        );
        final round1 = (before['rounds'] as List).cast<Map>().firstWhere(
          (r) => r['ordinal'] == 1,
        );
        final inRound1 = (before['assignments'] as List)
            .cast<Map>()
            .where((a) => a['scheduled_round_id'] == round1['id'])
            .toList();
        final byGroup = <int, List<Map>>{};
        for (final a in inRound1) {
          byGroup.putIfAbsent(a['group'] as int, () => []).add(a);
        }
        // The group with an open spot and the one it moves into.
        final open = byGroup.entries.firstWhere((e) => e.value.length < 3).key;
        final into = byGroup.entries.firstWhere((e) => e.value.length == 3).key;
        final source = byGroup[open]!.first;

        // Move a pilot to the other group, and add a new pilot to round 1.
        final move = await api.send(
          'POST',
          '/contests/$_contestId/matrix/assignments/${source['id']}/moves',
          body: {
            'id': '019c0000-0000-7000-8000-000000000901',
            'group': into,
            'reason': 'Wrong group',
          },
        );
        expect(move.statusCode, 201, reason: '${await api.json(move)}');
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
            'id': matrixTestParticipationId(6),
            'participant_profile_id': matrixTestProfileId(6),
            'role_id': SystemRoles.pilotId.value,
          },
        );
        final add = await api.send(
          'POST',
          '/contests/$_contestId/matrix/late-adds',
          body: {
            'id': '019c0000-0000-7000-8000-000000000801',
            'contest_participation_id': matrixTestParticipationId(6),
            'scheduled_round_id': round1['id'],
            'group': open,
            'reason': 'Joined late',
          },
        );
        expect(add.statusCode, 201, reason: '${await api.json(add)}');

        final body = await readRevision(_firstRevisionId);
        final rows = (body['assignments'] as List).cast<Map>();
        // The fifteen rows the draw made, nothing more.
        expect(rows, hasLength(15));
        expect(rows.map((a) => a['assignment_type']), everyElement('Original'));
        final ids = {for (final a in rows) a['id']};
        expect(ids, hasLength(15));
        // Round 1 is the draw's, with the moved pilot in the group drawn.
        final after1 = rows
            .where((a) => a['scheduled_round_id'] == round1['id'])
            .toList();
        expect(after1, hasLength(5));
        final byPilot = {
          for (final a in after1) a['contest_participation_id']: a['group'],
        };
        expect(byPilot[source['contest_participation_id']], source['group']);
        expect(byPilot.containsKey(matrixTestParticipationId(6)), isFalse);
      },
    );
  });

  group('refusals', () {
    test('of an unknown contest is a 404', () async {
      final response = await api.send(
        'GET',
        '/contests/${Id.create()}/matrix/revisions',
      );
      expect(response.statusCode, 404);

      final one = await api.send(
        'GET',
        '/contests/${Id.create()}/matrix/revisions/${Id.create()}',
      );
      expect(one.statusCode, 404);
    });

    test('of an unknown revision is a 404', () async {
      await drawn();

      final response = await api.send(
        'GET',
        '/contests/$_contestId/matrix/revisions/${Id.create()}',
      );
      expect(response.statusCode, 404);
    });

    test('of a revision of a different contest is a 404', () async {
      await drawn();
      final otherId = Id.create().value;
      final other = await api.send(
        'POST',
        '/contests',
        body: {
          'id': otherId,
          'name': 'Other Open',
          'start_date_time': '2026-11-17T14:00:00.000Z',
          'end_date_time': '2026-11-18T22:00:00.000Z',
          'timezone': 'America/Denver',
        },
      );
      expect(other.statusCode, 201);

      final response = await api.send(
        'GET',
        '/contests/$otherId/matrix/revisions/$_firstRevisionId',
      );
      expect(response.statusCode, 404);
    });

    test('a foreign director cannot list or read revisions', () async {
      final two = TwoAccountApi(owner: _owner);
      await drawnContest(two.ownerApi);

      await two.expectDenied(
        two.outsiderApi,
        'GET',
        '/contests/$_contestId/matrix/revisions',
      );
      await two.expectDenied(
        two.outsiderApi,
        'GET',
        '/contests/$_contestId/matrix/revisions/$_firstRevisionId',
      );
    });
  });
}
