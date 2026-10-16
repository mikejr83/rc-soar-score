import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'recalculation_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
final _other = Id.parse('019c0000-0000-7000-8000-000000000002');
const _contestId = '019c0000-0000-7000-8000-000000000020';
const _profileId = '019c0000-0000-7000-8000-000000000101';
const _participationId = '019c0000-0000-7000-8000-000000000201';

void main() {
  late HandlerHarness api;
  late List<int> recalculations;

  setUp(() async {
    recalculations = [];
    api = HandlerHarness(
      _owner,
      recalculation: RecalculationService(RefusingResults(recalculations)),
    );
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
    await api.send(
      'POST',
      '/participants',
      body: {'id': _profileId, 'first_name': 'Ada', 'last_name': 'Lovelace'},
    );
  });

  Map<String, Object?> addBody({
    String? id,
    String? roleId,
    String? classification,
  }) => {
    'id': id ?? _participationId,
    'participant_profile_id': _profileId,
    'role_id': roleId,
    'classification': classification,
  };

  Future<Map<String, Object?>> add([Map<String, Object?>? body]) async {
    final response = await api.send(
      'POST',
      '/contests/$_contestId/participations',
      body: body ?? addBody(),
    );
    final json = await api.json(response);
    expect(response.statusCode, 201, reason: '$json');
    return json;
  }

  String path([String id = _participationId]) =>
      '/contests/$_contestId/participations/$id';

  group('POST /contests/{id}/participations', () {
    test('adds a pilot by default, with a role snapshot', () async {
      final body = await add();

      expect(body['id'], _participationId);
      expect(body['contest_id'], _contestId);
      expect(body['participant_profile_id'], _profileId);
      expect(body['role_id'], SystemRoles.pilotId.value);
      expect(body['role_name'], 'Pilot');
      expect(body['role_type'], 'Pilot');
      expect(body['participant_number'], isNull);
      expect(body['scoring_uuid'], matches(RegExp(r'^[0-9a-f-]{36}$')));
    });

    test('adds a non-flier with another role', () async {
      final body = await add(addBody(roleId: SystemRoles.helperId.value));

      expect(body['role_name'], 'Helper');
      expect(body['role_type'], 'NonFlier');
    });

    test('repeating the request returns the same participation', () async {
      final first = await add();
      final second = await add();

      expect(second, first);
      expect(api.repository.participations.participations, hasLength(1));
    });

    test('the profile already being in the contest is a 409', () async {
      await add();

      final response = await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: addBody(id: '019c0000-0000-7000-8000-000000000202'),
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'already_stored');
    });

    test('an unknown contest, profile or role is a 404', () async {
      final unknownContest = await api.send(
        'POST',
        '/contests/019c0000-0000-7000-8000-0000000000ff/participations',
        body: addBody(),
      );
      final unknownProfile = await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: {
          ...addBody(),
          'participant_profile_id': '019c0000-0000-7000-8000-0000000000ff',
        },
      );
      final unknownRole = await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: addBody(roleId: '019c0000-0000-7000-8000-0000000000ff'),
      );

      expect(unknownContest.statusCode, 404);
      expect(unknownProfile.statusCode, 404);
      expect(unknownRole.statusCode, 404);
    });

    test('another director\'s profile is a 404', () async {
      final id = Id.parse(_profileId);
      final profile = api.repository.participantProfiles.profiles[id]!;
      api.repository.participantProfiles.profiles[id] =
          ParticipantProfile.fromJson({
            ...profile.toJson(),
            'owner_account_id': _other.value,
          });

      final response = await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: addBody(),
      );

      expect(response.statusCode, 404);
    });

    test('a Completed contest takes no new participants', () async {
      final contest = await api.contests.findById(Id.parse(_contestId));
      api.contests.replace(
        Contest.fromJson({
          ...contest!.toJson(),
          'lifecycle_state': 'Completed',
        }),
      );

      final response = await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: addBody(),
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'contest_completed');
    });

    test('a classification on a non-flier is a 400', () async {
      final response = await api.send(
        'POST',
        '/contests/$_contestId/participations',
        body: addBody(
          roleId: SystemRoles.helperId.value,
          classification: 'Expert',
        ),
      );

      expect(response.statusCode, 400);
    });
  });

  group('GET /contests/{id}/participations', () {
    test('lists who takes part', () async {
      await add();

      final body = await api.json(
        await api.send('GET', '/contests/$_contestId/participations'),
      );

      expect(body['participations'], hasLength(1));
    });

    test('an unknown contest is a 404', () async {
      final response = await api.send(
        'GET',
        '/contests/019c0000-0000-7000-8000-0000000000ff/participations',
      );

      expect(response.statusCode, 404);
    });
  });

  group('PUT /contests/{id}/participations/{participationId}', () {
    test('sets classification and retirement', () async {
      await add();

      final response = await api.send(
        'PUT',
        path(),
        body: {
          'base_revision': 0,
          'classification': 'Expert',
          'retired_at_round': 3,
        },
      );

      expect(response.statusCode, 200);
      final body = await api.json(response);
      expect(body['classification'], 'Expert');
      expect(body['retired_at_round'], 3);
      expect(body['revision'], 1);
    });

    test('changes the role and refreshes the snapshot', () async {
      await add();

      final body = await api.json(
        await api.send(
          'PUT',
          path(),
          body: {'base_revision': 0, 'role_id': SystemRoles.helperId.value},
        ),
      );

      expect(body['role_name'], 'Helper');
      expect(body['role_type'], 'NonFlier');
    });

    test('a pilot with assignments cannot become a non-flier', () async {
      await add();
      api.repository.matrixAssignments.participationsWithAssignments.add(
        Id.parse(_participationId),
      );

      final response = await api.send(
        'PUT',
        path(),
        body: {'base_revision': 0, 'role_id': SystemRoles.helperId.value},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'has_assignments');
    });

    test('a stale base revision is a 409', () async {
      await add();

      final response = await api.send(
        'PUT',
        path(),
        body: {'base_revision': 4, 'classification': 'Expert'},
      );

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'stale_revision');
    });

    test('a changed retirement recalculates the results', () async {
      await add();

      final response = await api.send(
        'PUT',
        path(),
        body: {'base_revision': 0, 'retired_at_round': 2},
      );

      expect(response.statusCode, 200);
      expect(recalculations, hasLength(1));
    });

    test('reversing a retirement recalculates the results', () async {
      await add();
      await api.send(
        'PUT',
        path(),
        body: {'base_revision': 0, 'retired_at_round': 2},
      );
      recalculations.clear();

      final response = await api.send(
        'PUT',
        path(),
        body: {'base_revision': 1},
      );

      expect(response.statusCode, 200);
      expect((await api.json(response))['retired_at_round'], isNull);
      expect(recalculations, hasLength(1));
    });

    test('a change that leaves the retirement alone does not', () async {
      await add();

      await api.send(
        'PUT',
        path(),
        body: {'base_revision': 0, 'classification': 'Expert'},
      );

      expect(recalculations, isEmpty);
    });

    test('a retirement on a non-flier is a 400', () async {
      await add(addBody(roleId: SystemRoles.helperId.value));

      final response = await api.send(
        'PUT',
        path(),
        body: {'base_revision': 0, 'retired_at_round': 2},
      );

      expect(response.statusCode, 400);
    });

    test('a participation of another contest is a 404', () async {
      await add();

      final response = await api.send(
        'PUT',
        '/contests/019c0000-0000-7000-8000-0000000000ff/participations/'
            '$_participationId',
        body: {'base_revision': 0},
      );

      expect(response.statusCode, 404);
    });
  });

  group('DELETE /contests/{id}/participations/{participationId}', () {
    test('removes the participant', () async {
      await add();

      final response = await api.send('DELETE', path());

      expect(response.statusCode, 204);
      expect(api.repository.participations.participations, isEmpty);
    });

    test('one with flight assignments is a 409', () async {
      await add();
      api.repository.matrixAssignments.participationsWithAssignments.add(
        Id.parse(_participationId),
      );

      final response = await api.send('DELETE', path());

      expect(response.statusCode, 409);
      expect((await api.errorOf(response))['code'], 'has_assignments');
      expect(api.repository.participations.participations, hasLength(1));
    });
  });
}
