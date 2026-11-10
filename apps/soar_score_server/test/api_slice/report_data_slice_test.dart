import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';
const _pilots = 6;

String _profileId(int n) => '019c0000-0000-7000-8000-0000000001${_pad(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-0000000002${_pad(n)}';
String _pad(int n) => n.toString().padLeft(2, '0');

/// `GET /contests/{id}/participants` and `GET /contests/{id}/report-data`
/// answer exactly what the separate reads answer, on every backend: a
/// partly scored contest and a profile that is in no contest.
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

  setUp(() async {
    api = await SliceClient.open(backend);
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

  Future<void> addPilots() async {
    await api.expectOk(
      'POST',
      '/participants',
      status: 201,
      body: {
        'id': '019c0000-0000-7000-8000-000000000199',
        'first_name': 'Nobody',
        'last_name': 'InNoContest',
      },
    );
    for (var n = 1; n <= _pilots; n++) {
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {'id': _profileId(n), 'first_name': 'P$n', 'last_name': 'X'},
      );
      await api.expectOk(
        'POST',
        '/contests/$_contestId/participations',
        status: 201,
        body: {
          'id': _participationId(n),
          'participant_profile_id': _profileId(n),
          'role_id': core.SystemRoles.pilotId.value,
        },
      );
    }
  }

  test('the contest participants are only the contest\'s profiles', () async {
    await addPilots();
    final all = await api.expectOk('GET', '/participants');
    expect(all['participants'], hasLength(_pilots + 1));
    final scoped = await api.expectOk(
      'GET',
      '/contests/$_contestId/participants',
    );
    final ids = {
      for (final p in (scoped['participants']! as List).cast<Map>()) p['id'],
    };
    expect(ids, {for (var n = 1; n <= _pilots; n++) _profileId(n)});
    final missing = await api.send(
      'GET',
      '/contests/019c0000-0000-7000-8000-000000000999/participants',
    );
    expect(missing.status, 404);
  });

  test('report data carries what the separate reads carry', () async {
    // Before a configuration, a draw or any score.
    var data = await api.expectOk('GET', '/contests/$_contestId/report-data');
    expect(data['configuration'], isNull);
    expect(data['participations'], isEmpty);
    expect((data['scores']! as Map)['scores'], isEmpty);
    expect(data['results'], isNull);

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
    await addPilots();
    final matrix = await api.expectOk(
      'POST',
      '/contests/$_contestId/matrix/draws',
      status: 201,
      body: {
        'id': '019c0000-0000-7000-8000-000000000501',
        'rounds': 3,
        'groups_per_round': 2,
        'random_seed': 7,
      },
    );
    final rounds = (matrix['rounds']! as List).cast<Map<String, Object?>>();
    final assignments = (matrix['assignments']! as List)
        .cast<Map<String, Object?>>();
    // Round 1 fully scored, round 2 for the first three pilots only.
    var mutations = 0;
    for (final round in rounds.take(2)) {
      for (var n = 1; n <= _pilots; n++) {
        if (round == rounds[1] && n > 3) continue;
        final slot = assignments.singleWhere(
          (a) =>
              a['scheduled_round_id'] == round['id'] &&
              a['contest_participation_id'] == _participationId(n),
        );
        await api.expectOk(
          'POST',
          '/contests/$_contestId/assignments/${slot['id']}/scores',
          status: 201,
          body: {
            'client_mutation_id': 'entry-${mutations++}',
            'base_score_revision': 0,
            'components': {
              'time_flown': 600 - n * 10,
              'launch_height': 100,
              'landing': 'points_50',
            },
          },
        );
      }
    }

    data = await api.expectOk('GET', '/contests/$_contestId/report-data');
    expect(data['contest'], await api.expectOk('GET', '/contests/$_contestId'));
    expect(
      data['configuration'],
      await api.expectOk('GET', '/contests/$_contestId/configuration'),
    );
    expect(
      data['participations'],
      (await api.expectOk(
        'GET',
        '/contests/$_contestId/participations',
      ))['participations'],
    );
    expect(
      data['teams'],
      (await api.expectOk('GET', '/contests/$_contestId/teams'))['teams'],
    );
    expect(
      data['team_memberships'],
      (await api.expectOk(
        'GET',
        '/contests/$_contestId/team-memberships',
      ))['team_memberships'],
    );
    expect(
      data['matrix'],
      await api.expectOk('GET', '/contests/$_contestId/matrix'),
    );
    expect(
      data['scores'],
      await api.expectOk('GET', '/contests/$_contestId/scores'),
    );
    final scoped = await api.expectOk(
      'GET',
      '/contests/$_contestId/participants',
    );
    expect(
      _byId(data['participants']! as List),
      _byId(scoped['participants']! as List),
    );
    expect(data['results'], isNull, reason: 'standings were not asked for');

    // The standings and the rounds, in the same response.
    final withStandings = await api.expectOk(
      'GET',
      '/contests/$_contestId/report-data'
          '?include=standings,scores&asOfRound=2&rounds=1,2',
    );
    expect(withStandings['participants'], isNull, reason: 'facts left out');
    expect(
      withStandings['results'],
      await api.expectOk('GET', '/contests/$_contestId/results?asOfRound=2'),
    );
    expect(withStandings['round_results'], [
      await api.expectOk('GET', '/contests/$_contestId/results/rounds/1'),
      await api.expectOk('GET', '/contests/$_contestId/results/rounds/2'),
    ]);
    expect(
      withStandings['scores'],
      await api.expectOk('GET', '/contests/$_contestId/scores'),
    );

    // No standing stored as of round 3: absent, not an error.
    final none = await api.expectOk(
      'GET',
      '/contests/$_contestId/report-data?include=standings&asOfRound=3',
    );
    expect(none['results'], isNull);
    // A stored standing outlives a redraw that replaces its round (here the
    // round is cancelled, so it is no longer current): `/results` still reads
    // it, and so does report-data, instead of calling the round invalid.
    await api.database.customStatement(
      "UPDATE rounds SET status = 'Cancelled' WHERE ordinal = 2",
    );
    final outlived = await api.expectOk(
      'GET',
      '/contests/$_contestId/report-data?include=standings&asOfRound=2',
    );
    expect(
      outlived['results'],
      await api.expectOk('GET', '/contests/$_contestId/results?asOfRound=2'),
    );
    expect(outlived['results'], isNotNull);
    // A round the contest does not have is a 400, not "no standing".
    for (final asOf in [0, 9]) {
      final invalid = await api.send(
        'GET',
        '/contests/$_contestId/report-data?include=standings&asOfRound=$asOf',
      );
      expect(invalid.status, 400, reason: 'asOfRound=$asOf');
    }
    // A round that does not exist is refused like the per-round read.
    final bad = await api.send(
      'GET',
      '/contests/$_contestId/report-data?include=standings&rounds=9',
    );
    expect(bad.status, 400);
    final unknown = await api.send(
      'GET',
      '/contests/$_contestId/report-data?include=nonsense',
    );
    expect(unknown.status, 400);
  });
}

Map<Object?, Object?> _byId(List<Object?> items) => {
  for (final item in items.cast<Map>()) item['id']: item,
};
