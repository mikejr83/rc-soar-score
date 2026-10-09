import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';
import 'recalculation_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

Future<Map<String, Object?>> _enterScore(
  HandlerHarness api,
  String mutationId,
) async {
  final response = await api.send(
    'POST',
    '/contests/$_contestId/assignments/'
    '${(await assignmentOfPilot(api, 1))['id']}/scores',
    body: {
      'client_mutation_id': mutationId,
      'base_score_revision': 0,
      'components': {
        'time_flown': 540,
        'launch_height': 200,
        'landing': 'points_50',
      },
    },
  );
  return api.json(response);
}

void main() {
  group('recalculation after a score entry', () {
    test('a failing recalculation warns on the entry response', () async {
      final api = HandlerHarness(
        _owner,
        recalculation: RecalculationService(AlwaysFailingResults()),
      );
      await drawnContest(api);

      final body = await _enterScore(api, 'entry-1');

      // 201, not an error: the score is still stored and the results read as
      // stale until a later recalculation succeeds.
      expect(api.repository.officialScores.stored, hasLength(1));
      final stale = await api.json(
        await api.send('GET', '/contests/$_contestId/results'),
      );
      expect(stale['stale'], isTrue);
      // The warning is on the entry response, not only in the log.
      expect(body['recalculation_warning'], isNotNull);
    });

    test('a recalculation that fails once and succeeds on retry carries no '
        'warning', () async {
      final attempts = <int>[];
      final api = HandlerHarness(
        _owner,
        recalculation: RecalculationService(FlakyResults(attempts)),
      );
      await drawnContest(api);

      final body = await _enterScore(api, 'entry-1');

      expect(body['recalculation_warning'], isNull);
      expect(attempts, hasLength(2));
    });

    test('a successful recalculation carries no warning', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);

      final body = await _enterScore(api, 'entry-1');

      expect(body['recalculation_warning'], isNull);
    });
  });
}