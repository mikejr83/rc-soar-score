import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';
import 'recalculation_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

/// A saved configuration revision recalculates the results of a contest that
/// has official scores, so they do not read as stale until a score changes.
void main() {
  late List<int> recalculations;

  setUp(() => recalculations = []);

  Future<void> score(HandlerHarness api, int pilot) async {
    final slot = await assignmentOfPilot(api, pilot);
    final response = await api.send(
      'POST',
      '/contests/$_contestId/assignments/${slot['id']}/scores',
      body: {
        'client_mutation_id': 'entry-$pilot',
        'base_score_revision': 0,
        'components': {
          'time_flown': 600 - pilot * 10,
          'launch_height': 200,
          'landing': 'points_50',
        },
      },
    );
    expect(response.statusCode, 201, reason: '${await api.json(response)}');
  }

  Future<HandlerHarness> scoredContest({RecalculationService? service}) async {
    final api = HandlerHarness(_owner, recalculation: service);
    await drawnContest(api);
    for (var pilot = 1; pilot <= 3; pilot++) {
      await score(api, pilot);
    }
    recalculations.clear();
    return api;
  }

  Future<Map<String, Object?>> save(
    HandlerHarness api,
    Map<String, Object?> core, {
    int base = 1,
  }) async {
    final response = await api.send(
      'POST',
      '/contests/$_contestId/configuration',
      body: {
        'base_revision_number': base,
        'discipline_profile_id': SystemDisciplineProfiles.f5jId.value,
        'config': {
          'core': core,
          'discipline': {'working_time': 600},
        },
      },
    );
    final body = await api.json(response);
    expect(response.statusCode, 201, reason: '$body');
    return body;
  }

  Future<Map<String, Object?>> results(HandlerHarness api) async =>
      api.json(await api.send('GET', '/contests/$_contestId/results'));

  test('a recalculating change leaves the results current', () async {
    final api = await scoredContest();
    expect((await results(api))['stale'], isFalse);

    final saved = await save(api, {'decimal_places': 2});

    expect(saved['recalculation_warning'], isNull);
    final body = await results(api);
    expect(body['stale'], isFalse);
    // The standings carry the revision that was just saved.
    final revision = (saved['configuration']! as Map)['id'];
    final stamped = (body['standings']! as List).cast<Map>();
    expect(stamped, isNotEmpty);
    expect({for (final s in stamped) s['config_revision_id']}, {revision});
  });

  test('a change to the drop rule is in the standings at once', () async {
    final api = await scoredContest();
    final before = (await results(api))['standings']! as List;
    expect(
      before.cast<Map>().every((s) => (s['dropped_rounds']! as List).isEmpty),
      isTrue,
    );

    await save(api, {
      'drop_after_rounds': [1],
    });

    final after = (await results(api))['standings']! as List;
    expect(
      after.cast<Map>().any((s) => (s['dropped_rounds']! as List).isNotEmpty),
      isTrue,
    );
  });

  test('a presentation-only change leaves the results current too', () async {
    final api = await scoredContest();

    await save(api, {'review_requests_enabled': false});

    expect((await results(api))['stale'], isFalse);
  });

  test('a contest with no scores has nothing to recalculate', () async {
    final api = HandlerHarness(
      _owner,
      recalculation: RecalculationService(RefusingResults(recalculations)),
    );
    await drawnContest(api);
    recalculations.clear();

    final saved = await save(api, {'decimal_places': 2});

    expect(recalculations, isEmpty);
    expect(saved['recalculation_warning'], isNull);
  });

  test('the revision is stored and a warning says when it fails', () async {
    final api = await scoredContest(
      service: RecalculationService(AlwaysFailingResults()),
    );

    final saved = await save(api, {'decimal_places': 2});

    expect(
      saved['recalculation_warning'],
      'Recalculation failed after a configuration change; the results are '
      'stale',
    );
    final revisions = await api.json(
      await api.send('GET', '/contests/$_contestId/configuration'),
    );
    expect(revisions['revision_number'], 2);
  });

  test('a failure to read the scores after the save is a warning', () async {
    final api = await scoredContest();
    api.repository.scorePlaceholders.failListing = true;

    final saved = await save(api, {'decimal_places': 2});

    // The revision is stored, so the request succeeds with a warning.
    expect(
      saved['recalculation_warning'],
      'Recalculation could not be started after a configuration change; the '
      'results are stale',
    );
    api.repository.scorePlaceholders.failListing = false;
    final stored = await api.json(
      await api.send('GET', '/contests/$_contestId/configuration'),
    );
    expect(stored['revision_number'], 2);
  });
}
