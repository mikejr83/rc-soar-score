import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

String _participationId(int n) => matrixTestParticipationId(n);

/// A pilot who joins after the draw is put in the last group of every round
/// that can take them; a round already fully scored gives them a zero.
void main() {
  late HandlerHarness api;

  setUp(() {
    api = HandlerHarness(_owner);
  });

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

  Future<Map<String, Object?>> place(int n) async {
    final response = await api.send(
      'POST',
      '/contests/$_contestId/matrix/late-placements',
      body: {'contest_participation_id': _participationId(n)},
    );
    final body = await api.json(response);
    expect(response.statusCode, 201, reason: '$body');
    return body;
  }

  List<Map> roundsOf(Map<String, Object?> body) =>
      (body['rounds']! as List).cast<Map>();

  /// Scores every pilot of round 1 (pilots 1 to [pilots]).
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

  /// The group of round [ordinal] that has room for one more of five.
  Future<int> groupWithRoom(int ordinal) async {
    final matrix = await api.json(
      await api.send('GET', '/contests/$_contestId/matrix'),
    );
    final round = (matrix['rounds']! as List).cast<Map>().firstWhere(
      (r) => r['ordinal'] == ordinal,
    );
    final sizes = <int, int>{};
    for (final a in (matrix['assignments']! as List).cast<Map>()) {
      if (a['scheduled_round_id'] == round['id']) {
        sizes.update(a['group'] as int, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    // Five pilots in two groups: the one with two has room (a group holds 3).
    return sizes.entries.firstWhere((e) => e.value < 3).key;
  }

  test(
    'with no scores the pilot goes to a group with room in every round',
    () async {
      await drawnContest(api, pilots: 5);
      final room = [
        for (final n in [1, 2, 3]) await groupWithRoom(n),
      ];
      await joins(6);

      final body = await place(6);

      expect(roundsOf(body), hasLength(3));
      for (final (index, round) in roundsOf(body).indexed) {
        expect(round['group'], room[index]);
        expect(round['zeroed'], isFalse);
        expect(round['skipped_reason'], isNull);
      }
      for (final ordinal in [1, 2, 3]) {
        final assignment = await assignmentOfPilot(api, 6, ordinal: ordinal);
        expect(assignment['assignment_type'], 'LateAdd');
        expect(assignment['group'], room[ordinal - 1]);
      }
    },
  );

  test('placing again places nobody twice', () async {
    await drawnContest(api, pilots: 5);
    await joins(6);
    await place(6);

    final again = await place(6);

    for (final round in roundsOf(again)) {
      expect(round['already_placed'], isTrue);
      expect(round['group'], isNull);
    }
    final matrix = await api.json(
      await api.send('GET', '/contests/$_contestId/matrix'),
    );
    final mine = (matrix['assignments']! as List).cast<Map>().where(
      (a) => a['contest_participation_id'] == _participationId(6),
    );
    expect(mine, hasLength(3));
  });

  test('a round that is fully scored gives the pilot a zero', () async {
    await drawnContest(api, pilots: 5);
    await scoreRoundOne(5);
    await joins(6);

    final body = await place(6);

    final rounds = roundsOf(body);
    expect(rounds[0]['zeroed'], isTrue);
    expect(rounds[0]['group'], isNotNull);
    expect(rounds[1]['zeroed'], isFalse);
    expect(rounds[2]['zeroed'], isFalse);
    // The zero is an official score of the new pilot's round 1 slot.
    final slot = await assignmentOfPilot(api, 6);
    final scores = await api.json(
      await api.send('GET', '/contests/$_contestId/scores'),
    );
    final mine = (scores['scores']! as List).cast<Map>().firstWhere(
      (s) => (s['placeholder'] as Map)['assignment_id'] == slot['id'],
    );
    expect(mine['official_score'], isNotNull);
    expect((mine['official_score'] as Map)['components'], isEmpty);
  });

  test('a round with no open group is reported, not failed', () async {
    // Six pilots in two full groups of three.
    await drawnContest(api, pilots: 6);
    await joins(7);

    final body = await place(7);

    for (final round in roundsOf(body)) {
      expect(round['group'], isNull);
      expect(round['skipped_reason'], contains('no open spot'));
    }
  });

  test('placing again finishes a zero that failed the first time', () async {
    await drawnContest(api, pilots: 5);
    await scoreRoundOne(5);
    await joins(6);
    await place(6);
    // The state a failed second write leaves: placed, with no score.
    final slot = await assignmentOfPilot(api, 6);
    final stub = api.repository;
    final placeholder = stub.scorePlaceholders.stored.firstWhere(
      (p) => p.assignmentId.value == slot['id'],
    );
    stub.scoreAttempts.stored.removeWhere(
      (s) => s.scorePlaceholderId == placeholder.id,
    );
    stub.officialScores.stored.removeWhere(
      (s) => s.scorePlaceholderId == placeholder.id,
    );
    stub.scorePlaceholders.stored[stub.scorePlaceholders.stored.indexOf(
      placeholder,
    )] = ScorePlaceholder(
      id: placeholder.id,
      contestId: placeholder.contestId,
      contestParticipationId: placeholder.contestParticipationId,
      assignmentId: placeholder.assignmentId,
    );

    final again = await place(6);

    expect(roundsOf(again)[0]['already_placed'], isTrue);
    expect(roundsOf(again)[0]['zeroed'], isTrue);
    expect(
      stub.scorePlaceholders.stored
          .firstWhere((p) => p.assignmentId == placeholder.assignmentId)
          .state,
      ScorePlaceholderState.official,
    );
  });

  test('only a pilot can be placed', () async {
    await drawnContest(api, pilots: 5);
    await joins(6, roleId: SystemRoles.helperId.value);

    final response = await api.send(
      'POST',
      '/contests/$_contestId/matrix/late-placements',
      body: {'contest_participation_id': _participationId(6)},
    );

    expect(response.statusCode, 409);
    expect((await api.errorOf(response))['code'], 'not_a_pilot');
  });

  test('a contest with no matrix cannot place anyone', () async {
    await drawnContest(api, pilots: 5, skipDraw: true);

    final response = await api.send(
      'POST',
      '/contests/$_contestId/matrix/late-placements',
      body: {'contest_participation_id': _participationId(1)},
    );

    expect(response.statusCode, 409);
  });
}
