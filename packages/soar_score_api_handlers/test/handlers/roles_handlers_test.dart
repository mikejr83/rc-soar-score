import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
final _other = Id.parse('019c0000-0000-7000-8000-000000000002');
const _roleId = '019c0000-0000-7000-8000-000000000301';
const _contestId = '019c0000-0000-7000-8000-000000000020';
const _profileId = '019c0000-0000-7000-8000-000000000101';

void main() {
  late HandlerHarness api;

  setUp(() => api = HandlerHarness(_owner));

  Future<Map<String, Object?>> create([
    String name = 'Timer',
    String id = _roleId,
  ]) async {
    final response = await api.send(
      'POST',
      '/roles',
      body: {'id': id, 'display_name': name},
    );
    final json = await api.json(response);
    expect(response.statusCode, 201, reason: '$json');
    return json;
  }

  /// Puts a participant in [roleId] in a new contest.
  Future<void> useRole(String roleId, {String contestName = 'Spring'}) async {
    await api.send(
      'POST',
      '/contests',
      body: {
        'id': _contestId,
        'name': contestName,
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
    final response = await api.send(
      'POST',
      '/contests/$_contestId/participations',
      body: {
        'id': '019c0000-0000-7000-8000-000000000201',
        'participant_profile_id': _profileId,
        'role_id': roleId,
      },
    );
    expect(response.statusCode, 201, reason: await response.readAsString());
  }

  Future<String> errorCode(String method, String path, [Object? body]) async {
    final response = await api.send(method, path, body: body);
    expect(response.statusCode, 409);
    return (await api.errorOf(response))['code']! as String;
  }

  group('GET /roles', () {
    test('lists the system roles and the principal\'s own', () async {
      await create('Timer');

      final body = await api.json(await api.send('GET', '/roles'));

      final names = [
        for (final role in body['roles']! as List<Object?>)
          (role! as Map<String, Object?>)['display_name'],
      ];
      expect(names, containsAll(['Pilot', 'Helper', 'Team Manager', 'Timer']));
    });

    test('does not list another director\'s roles', () async {
      api.repository.roles.roles.add(
        Role(
          id: Id.parse(_roleId),
          ownerAccountId: _other,
          displayName: 'Theirs',
          type: RoleType.nonFlier,
        ),
      );

      final body = await api.json(await api.send('GET', '/roles'));

      expect(body.toString(), isNot(contains('Theirs')));
    });
  });

  group('POST /roles', () {
    test('adds a non-flier role owned by the principal', () async {
      final body = await create('  Timer ');

      expect(body['display_name'], 'Timer');
      expect(body['type'], 'NonFlier');
      expect(body['owner_account_id'], _owner.value);
      expect(body['revision'], 0);
    });

    test('repeating the request returns the same role', () async {
      final first = await create();

      expect(await create(), first);
    });

    test('the same id with another name is a 409', () async {
      await create('Timer');

      expect(
        await errorCode('POST', '/roles', {
          'id': _roleId,
          'display_name': 'Scorer',
        }),
        'already_stored',
      );
    });

    test('a name in use, ignoring case, is a 409', () async {
      expect(
        await errorCode('POST', '/roles', {
          'id': _roleId,
          'display_name': 'helper',
        }),
        'duplicate_role_name',
      );
    });

    test('a blank name is a 400', () async {
      final response = await api.send(
        'POST',
        '/roles',
        body: {'id': _roleId, 'display_name': '  '},
      );

      expect(response.statusCode, 400);
    });
  });

  group('PUT /roles/{id}', () {
    test('renames the role and bumps the revision', () async {
      await create('Timer');

      final response = await api.send(
        'PUT',
        '/roles/$_roleId',
        body: {'base_revision': 0, 'display_name': 'Scorer'},
      );

      expect(response.statusCode, 200);
      final body = await api.json(response);
      expect(body['display_name'], 'Scorer');
      expect(body['revision'], 1);
    });

    test('keeping the same name is allowed', () async {
      await create('Timer');

      final response = await api.send(
        'PUT',
        '/roles/$_roleId',
        body: {'base_revision': 0, 'display_name': 'Timer'},
      );

      expect(response.statusCode, 200);
    });

    test('a stale base revision is a 409', () async {
      await create();

      expect(
        await errorCode('PUT', '/roles/$_roleId', {
          'base_revision': 5,
          'display_name': 'Scorer',
        }),
        'stale_revision',
      );
    });

    test('a name in use is a 409', () async {
      await create();

      expect(
        await errorCode('PUT', '/roles/$_roleId', {
          'base_revision': 0,
          'display_name': 'Team Manager',
        }),
        'duplicate_role_name',
      );
    });

    test('the Pilot role cannot be renamed, and the reason says why', () async {
      final response = await api.send(
        'PUT',
        '/roles/${SystemRoles.pilotId.value}',
        body: {'base_revision': 1, 'display_name': 'Flier'},
      );

      expect(response.statusCode, 409);
      final error = await api.errorOf(response);
      expect(error['code'], 'system_role');
      expect(error['message'], contains('Pilot role is fixed'));
    });

    test('a system non-flier role cannot be renamed', () async {
      expect(
        await errorCode('PUT', '/roles/${SystemRoles.helperId.value}', {
          'base_revision': 1,
          'display_name': 'Aide',
        }),
        'system_role',
      );
    });

    test('an unknown role is a 404', () async {
      final response = await api.send(
        'PUT',
        '/roles/$_roleId',
        body: {'base_revision': 0, 'display_name': 'Scorer'},
      );

      expect(response.statusCode, 404);
    });
  });

  group('DELETE /roles/{id}', () {
    test('deletes a role no participant has', () async {
      await create();

      final response = await api.send('DELETE', '/roles/$_roleId');

      expect(response.statusCode, 204);
      final body = await api.json(await api.send('GET', '/roles'));
      expect(body.toString(), isNot(contains('Timer')));
    });

    test('a role a participant has is a 409', () async {
      await create();
      await useRole(_roleId);

      expect(await errorCode('DELETE', '/roles/$_roleId'), 'role_in_use');
    });

    test('the Pilot role cannot be deleted', () async {
      expect(
        await errorCode('DELETE', '/roles/${SystemRoles.pilotId.value}'),
        'system_role',
      );
    });
  });

  group('GET /roles/{id}/usage', () {
    test('is empty for a role nothing uses', () async {
      await create();

      final body = await api.json(
        await api.send('GET', '/roles/$_roleId/usage'),
      );

      expect(body['usage'], isEmpty);
    });

    test('names each contest and its participant count', () async {
      await create();
      await useRole(_roleId, contestName: 'Spring Open');

      final body = await api.json(
        await api.send('GET', '/roles/$_roleId/usage'),
      );

      expect(body['usage'], [
        {
          'contest_id': _contestId,
          'contest_name': 'Spring Open',
          'participant_count': 1,
        },
      ]);
    });

    test('an unknown role is a 404', () async {
      final response = await api.send('GET', '/roles/$_roleId/usage');

      expect(response.statusCode, 404);
    });
  });
}
