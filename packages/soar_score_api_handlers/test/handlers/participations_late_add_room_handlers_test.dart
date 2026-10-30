import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

/// A pilot who joins a drawn contest needs a seat in every round that is not
/// fully scored; otherwise the add is refused and nothing is saved.
void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

  Future<dynamic> join(int n, {String? roleId}) async {
    await api.send(
      'POST',
      '/participants',
      body: {
        'id': matrixTestProfileId(n),
        'first_name': 'P$n',
        'last_name': 'X',
      },
    );
    return api.send(
      'POST',
      '/contests/$_contestId/participations',
      body: {
        'id': matrixTestParticipationId(n),
        'participant_profile_id': matrixTestProfileId(n),
        'role_id': roleId ?? SystemRoles.pilotId.value,
      },
    );
  }

  Future<void> scoreRoundOne(int pilots) async {
    for (var n = 1; n <= pilots; n++) {
      final slot = await assignmentOfPilot(api, n);
      final response = await api.send(
        'POST',
        '/contests/$_contestId/assignments/${slot['id']}/scores',
        body: {
          'client_mutation_id': 'entry-$n',
          'base_score_revision': 0,
          'components': {'time_flown': 500 + n, 'launch_height': 100},
        },
      );
      expect(response.statusCode, 201, reason: '${await api.json(response)}');
    }
  }

  test('five pilots in two groups take a sixth but not a seventh', () async {
    await drawnContest(api, pilots: 5);

    final sixth = await join(6);
    final seventh = await join(7);

    expect(sixth.statusCode, 201);
    expect(seventh.statusCode, 409);
    final error = await api.errorOf(seventh);
    expect(error['code'], 'no_room_in_round');
    expect(error['message'], contains('Round 1'));
    expect(error['message'], contains('groups per round'));
    expect(
      api.repository.participations.participations.keys.map((id) => id.value),
      isNot(contains(matrixTestParticipationId(7))),
    );
  });

  test('a contest that is not drawn takes any pilot', () async {
    await drawnContest(api, pilots: 6, skipDraw: true);

    final response = await join(7);

    expect(response.statusCode, 201);
  });

  test('a non-flier is added whatever the groups hold', () async {
    await drawnContest(api, pilots: 6);

    final response = await join(7, roleId: SystemRoles.helperId.value);

    expect(response.statusCode, 201);
  });

  test('a round that is fully scored does not block', () async {
    // Round 1 is scored; rounds 2 and 3 are the ones to have room.
    await drawnContest(api, pilots: 5);
    await scoreRoundOne(5);

    expect((await join(6)).statusCode, 201);
    expect((await join(7)).statusCode, 409);
  });

  test(
    'a full round 1 that is scored is skipped, a full round 2 blocks',
    () async {
      await drawnContest(api, pilots: 6);
      await scoreRoundOne(6);

      final response = await join(7);

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['message'], contains('Round 2'));
    },
  );

  test(
    'a non-flier changed to a pilot is refused when no group has room',
    () async {
      await drawnContest(api, pilots: 6);
      expect(
        (await join(7, roleId: SystemRoles.helperId.value)).statusCode,
        201,
      );

      final response = await api.send(
        'PUT',
        '/contests/$_contestId/participations/${matrixTestParticipationId(7)}',
        body: {'base_revision': 0, 'role_id': SystemRoles.pilotId.value},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'no_room_in_round');
    },
  );

  test('groups that are locked do not count as room', () async {
    await drawnContest(api, pilots: 5);
    final matrix = await api.json(
      await api.send('GET', '/contests/$_contestId/matrix'),
    );
    final roundOne = (matrix['rounds']! as List).cast<Map>().firstWhere(
      (r) => r['ordinal'] == 1,
    );
    final sizes = <int, int>{};
    for (final a in (matrix['assignments']! as List).cast<Map>()) {
      if (a['scheduled_round_id'] == roundOne['id']) {
        sizes.update(a['group'] as int, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final roomy = sizes.entries.firstWhere((e) => e.value < 3).key;
    api.repository.roundGroups.groups.add(
      RoundGroup(
        id: Id.create(),
        contestId: Id.parse(_contestId),
        roundId: Id.parse(roundOne['id']! as String),
        groupNumber: roomy,
        status: GroupStatus.locked,
        lockedBy: _owner,
        lockedAt: DateTime.utc(2026, 10, 17),
      ),
    );

    final response = await join(6);

    expect(response.statusCode, 409);
    expect((await api.errorOf(response))['message'], contains('locked'));
  });
}
