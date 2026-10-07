import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

String _participationId(int n) => matrixTestParticipationId(n);

void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  /// A contest of five pilots in two groups of three and two, three rounds.
  Future<void> drawn({Map<String, Object?> core = const {}}) =>
      drawnContest(api, pilots: 5, core: core);

  /// Adds pilot [n] to the contest, after the draw.
  Future<void> joins(int n, {String? roleId}) async {
    await api.send(
      'POST',
      '/participants',
      body: {
        'id': matrixTestProfileId(n),
        'first_name': 'P$n',
        'last_name': 'X',
      },
    );
    final response = await api.send(
      'POST',
      '/contests/$_contestId/participations',
      body: {
        'id': _participationId(n),
        'participant_profile_id': matrixTestProfileId(n),
        'role_id': roleId ?? SystemRoles.pilotId.value,
      },
    );
    expect(response.statusCode, 201, reason: '${await api.json(response)}');
  }

  Future<Map<String, Object?>> matrix() async =>
      api.json(await api.send('GET', '/contests/$_contestId/matrix'));

  /// The (round id, group) of the groups of round [ordinal], keyed by group,
  /// with the assignments in them.
  Future<Map<int, List<Map>>> groupsOf(int ordinal) async {
    final body = await matrix();
    final round = (body['rounds'] as List).cast<Map>().firstWhere(
      (r) => r['ordinal'] == ordinal,
    );
    final byGroup = <int, List<Map>>{};
    for (final a in (body['assignments'] as List).cast<Map>()) {
      if (a['scheduled_round_id'] == round['id']) {
        byGroup.putIfAbsent(a['group'] as int, () => []).add(a);
      }
    }
    return byGroup;
  }

  Future<String> roundId(int ordinal) async {
    final body = await matrix();
    return ((body['rounds'] as List).cast<Map>().firstWhere(
          (r) => r['ordinal'] == ordinal,
        ))['id']
        as String;
  }

  /// The group of round [ordinal] that has an open spot, and one that is full.
  Future<(int open, int full)> spots(int ordinal) async {
    final groups = await groupsOf(ordinal);
    final open = groups.entries.firstWhere((e) => e.value.length < 3).key;
    final full = groups.entries.firstWhere((e) => e.value.length == 3).key;
    return (open, full);
  }

  var count = 0;
  Future<dynamic> lateAdd({
    int pilot = 6,
    int ordinal = 1,
    int? creditedOrdinal,
    required int group,
    int? lane,
    String? reason = 'Joined late',
    String? id,
  }) async => api.send(
    'POST',
    '/contests/$_contestId/matrix/late-adds',
    body: {
      'id':
          id ??
          '019c0000-0000-7000-8000-0000000008${(++count).toString().padLeft(2, '0')}',
      'contest_participation_id': _participationId(pilot),
      'scheduled_round_id': await roundId(ordinal),
      if (creditedOrdinal != null)
        'credited_round_id': await roundId(creditedOrdinal),
      'group': group,
      'lane': ?lane,
      'reason': ?reason,
    },
  );

  group('a late add', () {
    test('places the pilot, gives a number and adds a placeholder', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(1);

      final response = await lateAdd(group: open);
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      final added = (body['assignments'] as List).cast<Map>().firstWhere(
        (a) => a['contest_participation_id'] == _participationId(6),
      );
      expect(added['assignment_type'], 'LateAdd');
      expect(added['group'], open);
      expect(added['credited_round_id'], added['scheduled_round_id']);
      expect(added['reason'], 'Joined late');
      expect(body['assignments'], hasLength(16));
      expect(api.repository.scorePlaceholders.stored, hasLength(16));
      final pilot = api
          .repository
          .participations
          .participations[Id.parse(_participationId(6))]!;
      expect(pilot.participantNumber, 6);
    });

    test('repeating the request changes nothing more', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(1);
      const id = '019c0000-0000-7000-8000-000000000990';
      final first = await api.json(await lateAdd(group: open, id: id));

      final again = await lateAdd(group: open, id: id);

      expect(again.statusCode, 201);
      expect(await api.json(again), first);
      expect(api.repository.scorePlaceholders.stored, hasLength(16));
    });

    test('can make up a missed round in a later round', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(2);

      final response = await lateAdd(
        ordinal: 2,
        creditedOrdinal: 1,
        group: open,
      );
      final body = await api.json(response);

      expect(response.statusCode, 201, reason: '$body');
      final added = (body['assignments'] as List).cast<Map>().firstWhere(
        (a) => a['contest_participation_id'] == _participationId(6),
      );
      expect(added['scheduled_round_id'], await roundId(2));
      expect(added['credited_round_id'], await roundId(1));
    });

    test('can fill every round, one add each', () async {
      await drawn();
      await joins(6);
      for (final ordinal in [1, 2, 3]) {
        final (open, _) = await spots(ordinal);
        final response = await lateAdd(ordinal: ordinal, group: open);
        expect(response.statusCode, 201, reason: '${await api.json(response)}');
      }

      expect((await matrix())['assignments'], hasLength(18));
    });
  });

  group('a late add that is refused', () {
    test('into a full group is a 409', () async {
      await drawn();
      await joins(6);
      final (_, full) = await spots(1);

      final response = await lateAdd(group: full);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'group_full');
    });

    test('of a pilot who already flies the round is a 409', () async {
      await drawn();
      final (open, _) = await spots(1);

      final response = await lateAdd(pilot: 1, group: open);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'already_assigned');
    });

    test('into a group that already has scores is a 409', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(1);
      final inGroup = (await groupsOf(1))[open]!.first;
      final placeholders = api.repository.scorePlaceholders.stored;
      final index = placeholders.indexWhere(
        (p) => p.assignmentId.value == inGroup['id'],
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

      final response = await lateAdd(group: open);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'group_already_flown');
    });

    test('into a locked group is a 409', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(1);
      final round = await roundId(1);
      final groups = api.repository.roundGroups.groups;
      final index = groups.indexWhere(
        (g) => g.roundId.value == round && g.groupNumber == open,
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

      final response = await lateAdd(group: open);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'group_locked');
    });

    test('without a reason is a 400', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(1);

      expect((await lateAdd(group: open, reason: null)).statusCode, 400);
      expect((await lateAdd(group: open, reason: ' ')).statusCode, 400);
    });

    test('into a group the round does not have is a 400', () async {
      await drawn();
      await joins(6);

      expect((await lateAdd(group: 3)).statusCode, 400);
    });

    test('of a participant who is not a pilot is a 409', () async {
      await drawn();
      await joins(6, roleId: SystemRoles.helperId.value);
      final (open, _) = await spots(1);

      final response = await lateAdd(group: open);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'not_a_pilot');
    });

    test('of a retired pilot is a 409', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(1);
      final retire = await api.send(
        'PUT',
        '/contests/$_contestId/participations/${_participationId(6)}',
        body: {'base_revision': 0, 'retired_at_round': 1},
      );
      expect(retire.statusCode, 200, reason: '${await api.json(retire)}');

      final response = await lateAdd(group: open);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'pilot_retired');
    });

    test('in a locked contest is a 409', () async {
      await drawn();
      await joins(6);
      final (open, _) = await spots(1);
      await api.send(
        'POST',
        '/contests/$_contestId/actions',
        body: {'action': 'lock', 'base_revision': 2},
      );

      final response = await lateAdd(group: open);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'contest_locked');
    });

    test('of an unknown participation is a 404', () async {
      await drawn();
      final (open, _) = await spots(1);

      expect((await lateAdd(pilot: 9, group: open)).statusCode, 404);
    });
  });

  group('with lanes', () {
    test('a taken lane is a 409 and a free lane is a 201', () async {
      await drawn(core: {'lane_mode': 'Random'});
      await joins(6);
      final (open, _) = await spots(1);
      final inGroup = (await groupsOf(1))[open]!;
      final used = {for (final a in inGroup) a['lane'] as int};

      final taken = await lateAdd(group: open, lane: used.first);
      expect(taken.statusCode, 409);
      expect((await api.errorOf(taken))['code'], 'lane_taken');

      expect((await lateAdd(group: open)).statusCode, 400);
      expect((await lateAdd(group: open, lane: 9)).statusCode, 400);

      final free = [
        for (var lane = 1; lane <= 3; lane++)
          if (!used.contains(lane)) lane,
      ];
      final response = await lateAdd(group: open, lane: free.first);
      expect(response.statusCode, 201, reason: '${await api.json(response)}');
    });
  });
}
