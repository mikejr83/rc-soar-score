import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';
import 'recalculation_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

/// A retirement change recalculates the results of a contest that has
/// scores, and says so on the response when that fails.
void main() {
  late List<int> recalculations;

  Future<HandlerHarness> scoredContest(RecalculationService service) async {
    final api = HandlerHarness(_owner, recalculation: service);
    await drawnContest(api);
    final slot = await assignmentOfPilot(api, 1);
    await api.send(
      'POST',
      '/contests/$_contestId/assignments/${slot['id']}/scores',
      body: {
        'client_mutation_id': 'entry-1',
        'base_score_revision': 0,
        'components': {'time_flown': 540, 'launch_height': 200},
      },
    );
    recalculations.clear();
    return api;
  }

  // The draw numbers the pilots, which moves their revision.
  Future<int> revisionOf(HandlerHarness api) async {
    final body = await api.json(
      await api.send('GET', '/contests/$_contestId/participations'),
    );
    return (body['participations']! as List).cast<Map>().firstWhere(
          (p) => p['id'] == matrixTestParticipationId(2),
        )['revision']!
        as int;
  }

  Future<Map<String, Object?>> retire(
    HandlerHarness api, {
    int? round = 2,
  }) async {
    final revision = await revisionOf(api);
    final response = await api.send(
      'PUT',
      '/contests/$_contestId/participations/${matrixTestParticipationId(2)}',
      body: {'base_revision': revision, 'retired_at_round': round},
    );
    final body = await api.json(response);
    expect(response.statusCode, 200, reason: '$body');
    return body;
  }

  setUp(() => recalculations = []);

  test('a changed retirement recalculates the results', () async {
    final api = await scoredContest(
      RecalculationService(RefusingResults(recalculations)),
    );

    await retire(api);

    expect(recalculations, hasLength(1));
  });

  test('reversing a retirement recalculates the results', () async {
    final api = await scoredContest(
      RecalculationService(RefusingResults(recalculations)),
    );
    await retire(api);
    recalculations.clear();

    await retire(api, round: null);

    expect(recalculations, hasLength(1));
  });

  test('a change that leaves the retirement alone does not', () async {
    final api = await scoredContest(
      RecalculationService(RefusingResults(recalculations)),
    );

    final response = await api.send(
      'PUT',
      '/contests/$_contestId/participations/${matrixTestParticipationId(2)}',
      body: {
        'base_revision': await revisionOf(api),
        'classification': 'Expert',
      },
    );

    expect(response.statusCode, 200);
    expect(recalculations, isEmpty);
  });

  test('a refused recalculation is reported on the response', () async {
    final api = await scoredContest(
      RecalculationService(RefusingResults(recalculations)),
    );

    final body = await retire(api);

    expect(body['retired_at_round'], 2);
    expect(
      body['recalculation_warning'],
      'Recalculation was refused after a retirement change; the results are '
      'stale',
    );
  });

  test('a recalculation that keeps failing is reported too', () async {
    final api = await scoredContest(
      RecalculationService(AlwaysFailingResults()),
    );

    final body = await retire(api);

    expect(body['retired_at_round'], 2);
    expect(
      body['recalculation_warning'],
      'Recalculation failed after a retirement change; the results are stale',
    );
  });

  test('a recalculation that works carries no warning', () async {
    final api = await scoredContest(RecalculationService(FlakyResults([1])));

    final body = await retire(api);

    expect(body['recalculation_warning'], isNull);
  });
}
