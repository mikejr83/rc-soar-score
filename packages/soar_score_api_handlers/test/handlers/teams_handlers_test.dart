import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = '019c0000-0000-7000-8000-000000000020';
const _teamId = '019c0000-0000-7000-8000-000000000301';
const _team2Id = '019c0000-0000-7000-8000-000000000302';
const _membershipId = '019c0000-0000-7000-8000-000000000401';
const _pilotParticipation = '019c0000-0000-7000-8000-000000000201';
const _helperParticipation = '019c0000-0000-7000-8000-000000000202';

void main() {
  late HandlerHarness api;

  setUp(() async {
    api = HandlerHarness(_owner);
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
    // Two participants, a pilot and a helper.
    for (final (profile, participation, role) in [
      (
        '019c0000-0000-7000-8000-000000000101',
        _pilotParticipation,
        SystemRoles.pilotId,
      ),
      (
        '019c0000-0000-7000-8000-000000000102',
        _helperParticipation,
        SystemRoles.helperId,
      ),
    ]) {
      await api.send(
        'POST',
        '/participants',
        body: {'id': profile, 'first_name': 'A', 'last_name': 'B'},
      );
      await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: {
          'id': participation,
          'participant_profile_id': profile,
          'role_id': role.value,
        },
      );
    }
  });

  Future<Map<String, Object?>> createTeam({
    String id = _teamId,
    String name = 'Team Red',
  }) async {
    final response = await api.send(
      'POST',
      '/contests/$_contestId/teams',
      body: {'id': id, 'name': name},
    );
    final json = await api.json(response);
    expect(response.statusCode, 201, reason: '$json');
    return json;
  }

  Future<Map<String, Object?>> addMember({
    String id = _membershipId,
    String team = _teamId,
    String participation = _pilotParticipation,
  }) async {
    final response = await api.send(
      'POST',
      '/contests/$_contestId/team-memberships',
      body: {
        'id': id,
        'team_id': team,
        'contest_participation_id': participation,
      },
    );
    final json = await api.json(response);
    expect(response.statusCode, 201, reason: '$json');
    return json;
  }

  void drawMatrix() =>
      api.repository.matrixRevisions.drawnContests.add(Id.parse(_contestId));

  group('teams', () {
    test('creates a team and lists it', () async {
      final team = await createTeam(name: '  Team Red ');

      expect(team['name'], 'Team Red');
      expect(team['contest_id'], _contestId);
      final list = await api.json(
        await api.send('GET', '/contests/$_contestId/teams'),
      );
      expect(list['teams'], [team]);
    });

    test('repeating the request returns the same team', () async {
      final first = await createTeam();
      final second = await createTeam();

      expect(second, first);
      expect(api.repository.teams.teams, hasLength(1));
    });

    test('a name already used in the contest is a 409', () async {
      await createTeam();

      final response = await api.send(
        'POST',
        '/contests/$_contestId/teams',
        body: {'id': _team2Id, 'name': 'team red'},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'already_stored');
    });

    test('rejects a blank name and an unknown contest', () async {
      final blank = await api.send(
        'POST',
        '/contests/$_contestId/teams',
        body: {'id': _teamId, 'name': '  '},
      );
      final unknown = await api.send(
        'POST',
        '/contests/019c0000-0000-7000-8000-0000000000ff/teams',
        body: {'id': _teamId, 'name': 'Team Red'},
      );

      expect(blank.statusCode, 400);
      expect(unknown.statusCode, 404);
    });

    test('renames a team and refuses a taken name', () async {
      await createTeam();
      await createTeam(id: _team2Id, name: 'Team Blue');

      final renamed = await api.send(
        'PUT',
        '/contests/$_contestId/teams/$_teamId',
        body: {'base_revision': 0, 'name': 'Team Crimson'},
      );
      final taken = await api.send(
        'PUT',
        '/contests/$_contestId/teams/$_teamId',
        body: {'base_revision': 1, 'name': 'Team Blue'},
      );

      expect(renamed.statusCode, 200);
      expect((await api.json(renamed))['name'], 'Team Crimson');
      expect(taken.statusCode, 409);
    });

    test('a stale base revision is a 409', () async {
      await createTeam();

      final response = await api.send(
        'PUT',
        '/contests/$_contestId/teams/$_teamId',
        body: {'base_revision': 3, 'name': 'Team Crimson'},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'stale_revision');
    });

    test('deletes a team', () async {
      await createTeam();

      final response = await api.send(
        'DELETE',
        '/contests/$_contestId/teams/$_teamId',
      );

      expect(response.statusCode, 204);
      expect(api.repository.teams.teams, isEmpty);
    });

    test('a team with a pilot cannot be deleted after the draw', () async {
      await createTeam();
      await addMember();
      drawMatrix();

      final response = await api.send(
        'DELETE',
        '/contests/$_contestId/teams/$_teamId',
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'matrix_exists');
    });

    test('a Completed contest takes no new teams', () async {
      final contest = (await api.contests.findById(Id.parse(_contestId)))!;
      api.contests.replace(
        Contest.fromJson({...contest.toJson(), 'lifecycle_state': 'Completed'}),
      );

      final response = await api.send(
        'POST',
        '/contests/$_contestId/teams',
        body: {'id': _teamId, 'name': 'Team Red'},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'contest_completed');
    });
  });

  group('memberships', () {
    setUp(() async => createTeam());

    test('puts a participant on a team and lists it', () async {
      final membership = await addMember();

      expect(membership['team_id'], _teamId);
      expect(membership['contest_participation_id'], _pilotParticipation);
      final list = await api.json(
        await api.send('GET', '/contests/$_contestId/team-memberships'),
      );
      // The join answer also says whether a recalculation failed.
      expect(membership['recalculation_warning'], isNull);
      expect(list['team_memberships'], [
        {...membership}..remove('recalculation_warning'),
      ]);
    });

    test('repeating the request returns the same membership', () async {
      final first = await addMember();
      final second = await addMember();

      expect(second, first);
      expect(api.repository.teamMemberships.memberships, hasLength(1));
    });

    test('a participant on a team cannot join another', () async {
      await createTeam(id: _team2Id, name: 'Team Blue');
      await addMember();

      final response = await api.send(
        'POST',
        '/contests/$_contestId/team-memberships',
        body: {
          'id': '019c0000-0000-7000-8000-000000000402',
          'team_id': _team2Id,
          'contest_participation_id': _pilotParticipation,
        },
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'already_stored');
    });

    test('an unknown team or participation is a 404', () async {
      final team = await api.send(
        'POST',
        '/contests/$_contestId/team-memberships',
        body: {
          'id': _membershipId,
          'team_id': '019c0000-0000-7000-8000-0000000000ff',
          'contest_participation_id': _pilotParticipation,
        },
      );
      final participation = await api.send(
        'POST',
        '/contests/$_contestId/team-memberships',
        body: {
          'id': _membershipId,
          'team_id': _teamId,
          'contest_participation_id': '019c0000-0000-7000-8000-0000000000ff',
        },
      );

      expect(team.statusCode, 404);
      expect(participation.statusCode, 404);
    });

    test('a pilot can leave and a pilot can join after the draw', () async {
      await addMember();
      drawMatrix();

      final leave = await api.send(
        'DELETE',
        '/contests/$_contestId/team-memberships/$_membershipId',
      );
      final join = await api.send(
        'POST',
        '/contests/$_contestId/team-memberships',
        body: {
          'id': '019c0000-0000-7000-8000-000000000403',
          'team_id': _teamId,
          'contest_participation_id': _pilotParticipation,
        },
      );

      expect(leave.statusCode, 204);
      expect(join.statusCode, 201);
    });

    test('a non-flier can leave after the draw', () async {
      await addMember(
        id: '019c0000-0000-7000-8000-000000000403',
        participation: _helperParticipation,
      );
      drawMatrix();

      final response = await api.send(
        'DELETE',
        '/contests/$_contestId/team-memberships/'
            '019c0000-0000-7000-8000-000000000403',
      );

      expect(response.statusCode, 204);
    });

    test('removes a member before the draw', () async {
      await addMember();

      final response = await api.send(
        'DELETE',
        '/contests/$_contestId/team-memberships/$_membershipId',
      );

      expect(response.statusCode, 204);
      expect(api.repository.teamMemberships.memberships, isEmpty);
    });
  });

  group('contest-scoped authorization', () {
    late TwoAccountApi two;

    setUp(() => two = TwoAccountApi(owner: _owner));

    test('a foreign director cannot create teams or memberships', () async {
      two.storeContest(Id.parse(_contestId));

      await two.expectDenied(
        two.outsiderApi,
        'POST',
        '/contests/$_contestId/teams',
        body: {'id': _teamId, 'name': 'Team Red'},
      );
      await two.expectDenied(
        two.outsiderApi,
        'POST',
        '/contests/$_contestId/team-memberships',
        body: {
          'id': _membershipId,
          'team_id': _teamId,
          'contest_participation_id': _pilotParticipation,
        },
      );

      expect(two.ownerApi.repository.teams.teams, isEmpty);
      expect(two.ownerApi.repository.teamMemberships.memberships, isEmpty);
    });
  });
}
