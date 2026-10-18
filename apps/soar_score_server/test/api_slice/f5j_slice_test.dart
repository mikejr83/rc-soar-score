import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';
const _pilots = 6;

String _profileId(int n) => '019c0000-0000-7000-8000-0000000001${_pad(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-0000000002${_pad(n)}';
int _participationNumber(String id) => int.parse(id.substring(id.length - 2));
String _pad(int n) => n.toString().padLeft(2, '0');

/// The F5J slice through the deployed server's handler: create a contest,
/// add pilots, draw the matrix, enter scores, read the results, publish and
/// read the publication from the public endpoint. One real database per
/// test; no socket and no mocks.
void main() {
  final postgresMissing = PostgresConfig.fromEnvironment() == null;
  for (final backend in SliceBackend.values) {
    group(
      backend.name,
      () => _tests(backend),
      skip: backend == SliceBackend.postgres && postgresMissing
          ? 'POSTGRES_PASSWORD is not set'
          : false,
    );
  }
}

void _tests(SliceBackend backend) {
  late SliceClient api;

  setUp(() async => api = await SliceClient.open(backend));
  tearDown(() => api.close());

  test('create, draw, score, publish and read it publicly', () async {
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
    expect(rounds, hasLength(3));
    expect(assignments, hasLength(3 * _pilots));

    var mutations = 0;
    for (final round in rounds.take(2)) {
      for (var n = 1; n <= _pilots; n++) {
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
    final contest = await api.expectOk('GET', '/contests/$_contestId');
    expect(contest['lifecycle_state'], 'Running');
    final results = await api.expectOk(
      'POST',
      '/contests/$_contestId/results/recalculation',
    );
    final standings = (results['standings']! as List)
        .cast<Map<String, Object?>>();
    expect(results['as_of_round'], 2);
    expect(standings, hasLength(_pilots));
    expect(
      {for (final s in standings) s['contest_participation_id']},
      {for (var n = 1; n <= _pilots; n++) _participationId(n)},
    );
    final places = [for (final s in standings) s['place']! as int];
    expect(places.first, 1);
    expect(places, orderedEquals([...places]..sort()));
    for (final s in standings) {
      expect(s['overall_score'], inInclusiveRange(0, 2000));
    }
    final published = await api.expectOk(
      'POST',
      '/contests/$_contestId/publication',
      status: 201,
      body: {
        'client_mutation_id': 'publish-1',
        'source_contest_revision': contest['revision'],
      },
    );
    final publicationId = published['publication_id']! as String;
    expect(published['visibility'], 'Unlisted');
    expect(published['contest_id'], _contestId);

    // Unlisted: readable by its link, not in the public listing.
    expect(
      (await api.publicGet('/publications')).body['publications'],
      isEmpty,
    );
    final byLink = await api.publicGet('/publications/$publicationId');
    expect(byLink.status, 200, reason: '${byLink.body}');
    final projection = byLink.body;
    expect((projection['contest']! as Map)['name'], 'Spring Open');
    expect(projection['discipline_type'], 'F5J');
    expect(projection['participants'], hasLength(_pilots));
    expect(projection['scores'], hasLength(2 * _pilots));

    // The public standings are the director's standings, pilot for pilot.
    final nameOf = {
      for (final p in (projection['participants']! as List).cast<Map>())
        p['pilot_key']: (p['details'] as Map)['first_name'],
    };
    final publicRound = ((projection['standings']! as Map)['rounds']! as List)
        .cast<Map>()
        .singleWhere((r) => r['as_of_round'] == 2);
    final publicByName = {
      for (final p in (publicRound['pilots']! as List).cast<Map>())
        nameOf[p['pilot_key']]: (p['place'], p['overall_score']),
    };
    expect(publicByName, {
      for (final s in standings)
        'P${_participationNumber(s['contest_participation_id']! as String)}': (
          s['place'],
          s['overall_score'],
        ),
    });

    await api.expectOk(
      'PATCH',
      '/contests/$_contestId/publication/visibility',
      body: {'visibility': 'Public'},
    );
    final listing = (await api.publicGet('/publications')).body;
    expect(listing['publications'], [
      containsPair('publication_id', publicationId),
    ]);
  });
}
