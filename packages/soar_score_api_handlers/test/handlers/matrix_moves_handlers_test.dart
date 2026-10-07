import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

String _participationId(int n) => matrixTestParticipationId(n);
String _pad(int n) => n.toString().padLeft(2, '0');

void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  Future<void> drawn({
    int pilots = 6,
    int groups = 2,
    Map<String, Object?> core = const {},
    Future<void> Function()? beforeDraw,
  }) => drawnContest(
    api,
    pilots: pilots,
    groups: groups,
    core: core,
    beforeDraw: beforeDraw,
  );

  Future<List<Map<String, Object?>>> assignments() => currentAssignments(api);

  Future<Map<String, Object?>> assignmentOf(int n, {int ordinal = 1}) =>
      assignmentOfPilot(api, n, ordinal: ordinal);

  var moveCount = 0;
  Future<dynamic> move(
    Map<String, Object?> source, {
    int? group,
    int? lane,
    String? roundId,
    String? reason = 'Wrong group',
    bool? overrideLocks,
    String? id,
  }) => api.send(
    'POST',
    '/contests/$_contestId/matrix/assignments/${source['id']}/moves',
    body: {
      'id': id ?? '019c0000-0000-7000-8000-0000000009${_pad(++moveCount)}',
      'group': group ?? ((source['group'] as int) == 1 ? 2 : 1),
      'lane': ?lane,
      'scheduled_round_id': ?roundId,
      'reason': ?reason,
      'override_locks': ?overrideLocks,
    },
  );

  group('a move', () {
    test(
      'adds a Moved row, replaces the old one and adds a placeholder',
      () async {
        await drawn();
        final source = await assignmentOf(1);

        final response = await move(source);
        final body = await api.json(response);

        expect(response.statusCode, 201, reason: '$body');
        final live = (body['assignments'] as List).cast<Map>();
        expect(live, hasLength(18));
        expect(live.map((a) => a['id']), isNot(contains(source['id'])));
        final moved = live.firstWhere(
          (a) => a['source_assignment_id'] == source['id'],
        );
        expect(moved['assignment_type'], 'Moved');
        expect(moved['group'], isNot(source['group']));
        expect(moved['credited_round_id'], source['credited_round_id']);
        expect(moved['reason'], 'Wrong group');
        expect(moved['existing_score_handling'], 'None');
        final placeholders = api.repository.scorePlaceholders.stored;
        expect(placeholders, hasLength(19));
        expect(placeholders.last.assignmentId.value, moved['id']);
        expect(placeholders.last.state, ScorePlaceholderState.notEntered);
      },
    );

    test('repeating the request changes nothing more', () async {
      await drawn();
      final source = await assignmentOf(1);
      final first = await api.json(
        await move(source, id: '019c0000-0000-7000-8000-000000000901'),
      );

      final again = await move(
        source,
        id: '019c0000-0000-7000-8000-000000000901',
      );

      expect(again.statusCode, 201);
      expect(await api.json(again), first);
      expect(api.repository.scorePlaceholders.stored, hasLength(19));
    });

    test('can go to another round and stays credited to the first', () async {
      await drawn();
      final source = await assignmentOf(1);
      final later = await assignmentOf(1, ordinal: 2);

      final response = await move(
        source,
        roundId: later['scheduled_round_id'] as String,
        group: later['group'] == 1 ? 2 : 1,
      );
      final body = await api.json(response);

      // The pilot already flies in that round, in the other group: the move
      // is refused only if the target group is the one flown there.
      expect(response.statusCode, 201, reason: '$body');
      final moved = (body['assignments'] as List).cast<Map>().firstWhere(
        (a) => a['source_assignment_id'] == source['id'],
      );
      expect(moved['scheduled_round_id'], later['scheduled_round_id']);
      expect(moved['credited_round_id'], source['credited_round_id']);
    });

    test('moving the pilot again moves from the current assignment', () async {
      await drawn();
      final source = await assignmentOf(1);
      await move(source);

      final response = await move(source);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'assignment_superseded');
    });
  });

  group('a move of a scored assignment', () {
    Future<void> score(Map<String, Object?> source) async {
      final placeholders = api.repository.scorePlaceholders.stored;
      final index = placeholders.indexWhere(
        (p) => p.assignmentId.value == source['id'],
      );
      placeholders[index] = ScorePlaceholder(
        id: placeholders[index].id,
        contestId: placeholders[index].contestId,
        contestParticipationId: placeholders[index].contestParticipationId,
        assignmentId: placeholders[index].assignmentId,
        state: ScorePlaceholderState.submitted,
        scoreRevision: 2,
      );
    }

    test('resets the score and keeps the old one as history', () async {
      await drawn();
      final source = await assignmentOf(1);
      await score(source);

      final body = await api.json(await move(source));

      final moved = (body['assignments'] as List).cast<Map>().firstWhere(
        (a) => a['source_assignment_id'] == source['id'],
      );
      expect(moved['existing_score_handling'], 'Reset');
      expect(moved['reset_score_revision'], 2);
      final placeholders = api.repository.scorePlaceholders.stored;
      expect(placeholders, hasLength(19));
      expect(placeholders.last.state, ScorePlaceholderState.notEntered);
      expect(placeholders.last.scoreRevision, 0);
      final old = placeholders.firstWhere(
        (p) => p.assignmentId.value == source['id'],
      );
      expect(old.state, ScorePlaceholderState.submitted);
    });

    test('can stay in the same slot to reset a wrong entry', () async {
      await drawn();
      final source = await assignmentOf(1);
      await score(source);

      final response = await move(source, group: source['group'] as int);

      expect(response.statusCode, 201, reason: '${await api.json(response)}');
    });
  });

  group('a move that is refused', () {
    test('to the same slot without a score is a 409', () async {
      await drawn();
      final source = await assignmentOf(1);

      final response = await move(source, group: source['group'] as int);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'no_change');
    });

    test('without a reason is a 400', () async {
      await drawn();

      expect((await move(await assignmentOf(1), reason: null)).statusCode, 400);
      expect((await move(await assignmentOf(1), reason: '  ')).statusCode, 400);
    });

    test('to a group the round does not have is a 400', () async {
      await drawn();

      expect((await move(await assignmentOf(1), group: 3)).statusCode, 400);
    });

    test('with a lane when the contest has no lanes is a 400', () async {
      await drawn();

      expect((await move(await assignmentOf(1), lane: 1)).statusCode, 400);
    });

    test('in a locked contest is a 409', () async {
      await drawn();
      final source = await assignmentOf(1);
      await api.send(
        'POST',
        '/contests/$_contestId/actions',
        body: {'action': 'lock', 'base_revision': 2},
      );

      final response = await move(source);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'contest_locked');
    });

    test('of a retired pilot is a 409', () async {
      await drawn();
      final source = await assignmentOf(1);
      final retire = await api.send(
        'PUT',
        '/contests/$_contestId/participations/${_participationId(1)}',
        body: {'base_revision': 1, 'retired_at_round': 3},
      );
      expect(retire.statusCode, 200, reason: '${await api.json(retire)}');

      final response = await move(source);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'pilot_retired');
    });

    test('of an unknown assignment or contest is a 404', () async {
      await drawn();
      final source = await assignmentOf(1);

      final unknown = await api.send(
        'POST',
        '/contests/$_contestId/matrix/assignments/'
            '019c0000-0000-7000-8000-0000000000aa/moves',
        body: {
          'id': '019c0000-0000-7000-8000-000000000990',
          'group': 1,
          'reason': 'x',
        },
      );
      expect(unknown.statusCode, 404);

      final noContest = await api.send(
        'POST',
        '/contests/019c0000-0000-7000-8000-0000000000ff/matrix/assignments/'
            '${source['id']}/moves',
        body: {
          'id': '019c0000-0000-7000-8000-000000000991',
          'group': 1,
          'reason': 'x',
        },
      );
      expect(noContest.statusCode, 404);
    });
  });

  group('locks', () {
    Future<void> lockGroup(Map<String, Object?> assignment) async {
      final groups = api.repository.roundGroups.groups;
      final index = groups.indexWhere(
        (g) =>
            g.roundId.value == assignment['scheduled_round_id'] &&
            g.groupNumber == assignment['group'],
      );
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
    }

    test(
      'a locked group refuses a move unless the lock is overridden',
      () async {
        await drawn();
        final source = await assignmentOf(1);
        await lockGroup(source);

        final refused = await move(source);
        expect(refused.statusCode, 409);
        expect((await api.errorOf(refused))['code'], 'group_locked');

        final overridden = await move(source, overrideLocks: true);
        expect(
          overridden.statusCode,
          201,
          reason: '${await api.json(overridden)}',
        );
      },
    );

    test(
      'a locked score refuses a move unless the lock is overridden',
      () async {
        await drawn();
        final source = await assignmentOf(1);
        final placeholders = api.repository.scorePlaceholders.stored;
        final index = placeholders.indexWhere(
          (p) => p.assignmentId.value == source['id'],
        );
        final p = placeholders[index];
        placeholders[index] = ScorePlaceholder(
          id: p.id,
          contestId: p.contestId,
          contestParticipationId: p.contestParticipationId,
          assignmentId: p.assignmentId,
          lockedBy: _owner,
          lockedAt: DateTime.utc(2026, 10, 17, 15),
        );

        final refused = await move(source);
        expect(refused.statusCode, 409);
        expect((await api.errorOf(refused))['code'], 'score_locked');

        expect((await move(source, overrideLocks: true)).statusCode, 201);
      },
    );
  });

  group('with lanes', () {
    test('a taken lane is a 409 and a free lane is a 201', () async {
      await drawn(pilots: 7, core: {'lane_mode': 'Random'});
      final all = await assignments();
      final source = await assignmentOf(1);
      final inGroup = [
        for (final a in all)
          if (a['scheduled_round_id'] == source['scheduled_round_id'] &&
              a['group'] == source['group'])
            a,
      ];
      final used = {for (final a in inGroup) a['lane'] as int};
      final other = inGroup.firstWhere((a) => a['id'] != source['id']);

      final taken = await move(
        source,
        group: source['group'] as int,
        lane: other['lane'] as int,
      );
      expect(taken.statusCode, 409);
      expect((await api.errorOf(taken))['code'], 'lane_taken');

      final free = [
        for (var l = 1; l <= 4; l++)
          if (!used.contains(l)) l,
      ];
      if (free.isNotEmpty) {
        final ok = await move(
          source,
          group: source['group'] as int,
          lane: free.first,
        );
        expect(ok.statusCode, 201, reason: '${await api.json(ok)}');
      }
    });

    test('a move needs a lane that exists', () async {
      await drawn(core: {'lane_mode': 'Random'});

      final source = await assignmentOf(1);
      expect((await move(source, lane: 9)).statusCode, 400);
      expect((await move(source)).statusCode, 400);
    });
  });

  group('with team protection', () {
    test('a move next to a teammate is a 409', () async {
      await drawn(
        groups: 3,
        core: {
          'teams_enabled': true,
          'team_pilot_count': 3,
          'team_protection': true,
        },
        beforeDraw: () async {
          const teamId = '019c0000-0000-7000-8000-000000000301';
          await api.send(
            'POST',
            '/contests/$_contestId/teams',
            body: {'id': teamId, 'name': 'Red'},
          );
          for (var n = 1; n <= 2; n++) {
            final added = await api.send(
              'POST',
              '/contests/$_contestId/team-memberships',
              body: {
                'id': '019c0000-0000-7000-8000-00000000040$n',
                'team_id': teamId,
                'contest_participation_id': _participationId(n),
              },
            );
            expect(added.statusCode, 201, reason: '${await api.json(added)}');
          }
        },
      );
      final first = await assignmentOf(1);
      final mate = await assignmentOf(2);

      final response = await move(first, group: mate['group'] as int);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'team_conflict');
    });
  });
}
