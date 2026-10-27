import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';

/// The contest-ownership authorization over a real database: an account that
/// is not the director of a contest gets a 403 `not_director` on every
/// contest-scoped route and its list scoping hides the contest, on every
/// backend. One fresh database per test; two accounts against it.
void main() {
  final postgresMissing = PostgresConfig.fromEnvironment() == null;
  for (final backend in SliceBackend.values) {
    group(
      backend.name,
      () => _tests(backend),
      skip: backend == SliceBackend.postgres && postgresMissing
          ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD)'
          : false,
    );
  }
}

void _tests(SliceBackend backend) {
  late SliceClient api;
  late core.Id outsider;

  setUp(() async {
    api = await SliceClient.open(backend);
    outsider = core.Id.create();
    await api.expectOk(
      'POST',
      '/contests',
      status: 201,
      body: {
        'id': _contestId,
        'name': 'Spring Open',
        'start_date_time': '2026-10-17T14:00:00.000Z',
        'end_date_time': '2026-10-18T22:00:00.000Z',
        'timezone': 'America/Denver',
      },
    );
  });
  tearDown(() => api.close());

  test('a foreign account is denied on every contest-scoped route', () async {
    await api.expectForeignDenied(outsider, 'GET', '/contests/$_contestId');
    await api.expectForeignDenied(
      outsider,
      'PUT',
      '/contests/$_contestId',
      body: {
        'base_revision': 0,
        'name': 'Renamed',
        'start_date_time': '2026-10-17T14:00:00.000Z',
        'end_date_time': '2026-10-18T22:00:00.000Z',
        'city': 'Boulder',
      },
    );
    await api.expectForeignDenied(
      outsider,
      'POST',
      '/contests/$_contestId/actions',
      body: {'action': 'lock', 'base_revision': 0},
    );
    await api.expectForeignDenied(
      outsider,
      'GET',
      '/contests/$_contestId/audit-events',
    );
    await api.expectForeignDenied(
      outsider,
      'GET',
      '/contests/$_contestId/configuration',
    );
    await api.expectForeignDenied(
      outsider,
      'POST',
      '/contests/$_contestId/configuration',
      body: {
        'base_revision_number': 0,
        'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
        'config': {
          'core': <String, Object?>{},
          'discipline': {'working_time': 600},
        },
      },
    );
    await api.expectForeignDenied(
      outsider,
      'GET',
      '/contests/$_contestId/matrix',
    );
    await api.expectForeignDenied(
      outsider,
      'POST',
      '/contests/$_contestId/matrix/draws',
      body: {
        'id': '019c0000-0000-7000-8000-000000000501',
        'rounds': 1,
        'groups_per_round': 1,
        'random_seed': 7,
      },
    );
    await api.expectForeignDenied(
      outsider,
      'GET',
      '/contests/$_contestId/participations',
    );
    await api.expectForeignDenied(
      outsider,
      'POST',
      '/contests/$_contestId/participations',
      body: {
        'id': '019c0000-0000-7000-8000-000000000201',
        'participant_profile_id': '019c0000-0000-7000-8000-000000000101',
        'role_id': core.SystemRoles.pilotId.value,
      },
    );
    await api.expectForeignDenied(
      outsider,
      'GET',
      '/contests/$_contestId/teams',
    );
    await api.expectForeignDenied(
      outsider,
      'POST',
      '/contests/$_contestId/teams',
      body: {'id': '019c0000-0000-7000-8000-000000000401', 'name': 'Team One'},
    );
    await api.expectForeignDenied(
      outsider,
      'GET',
      '/contests/$_contestId/scores',
    );
    await api.expectForeignDenied(
      outsider,
      'GET',
      '/contests/$_contestId/results',
    );
    await api.expectForeignDenied(
      outsider,
      'POST',
      '/contests/$_contestId/results/recalculation',
    );

    // The list scoping hides the contest too.
    final list = await api.actAs(outsider, 'GET', '/contests');
    expect(list.status, 200);
    final contestIds = {
      for (final c in (list.body['contests']! as List).cast<Map>()) c['id'],
    };
    expect(contestIds, isNot(contains(_contestId)));
  });

  test('the director keeps access to the same routes', () async {
    await api.expectOk('GET', '/contests/$_contestId');
    await api.expectOk(
      'PUT',
      '/contests/$_contestId',
      body: {
        'base_revision': 0,
        'name': 'Renamed',
        'start_date_time': '2026-10-17T14:00:00.000Z',
        'end_date_time': '2026-10-18T22:00:00.000Z',
        'city': 'Boulder',
      },
    );
    // A contest with a saved configuration answers, unlike the 403 above.
    await api.expectOk(
      'POST',
      '/contests/$_contestId/configuration',
      status: 201,
      body: {
        'base_revision_number': 0,
        'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
        'config': {
          'core': <String, Object?>{},
          'discipline': {'working_time': 600},
        },
      },
    );
    await api.expectOk('GET', '/contests/$_contestId/configuration');
  });
}
