import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';
import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';
import 'recalculation_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');
const _contestId = matrixTestContestId;

const _flight = {
  'time_flown': 540,
  'launch_height': 200,
  'landing': 'points_50',
};

/// A recalculation that succeeds and counts how often it ran.
class CountingResults extends ResultsService {
  CountingResults(this._runs) : super(StubRepository(StubContestRepository()));

  final List<int> _runs;

  @override
  Future<ContestResults> recalculate(Id contestId) async {
    _runs.add(1);
    return ContestResults(isStale: false);
  }
}

void main() {
  Map<String, Object?> entry(
    Map<String, Object?> assignment,
    String mutation, {
    int base = 0,
    String? reason,
  }) => {
    'assignment_id': assignment['id'],
    'client_mutation_id': mutation,
    'base_score_revision': base,
    'components': _flight,
    'reason': ?reason,
  };

  Future<dynamic> bulk(
    HandlerHarness api,
    List<Map<String, Object?>> entries,
  ) => api.send(
    'POST',
    '/contests/$_contestId/scores/bulk',
    body: {'entries': entries},
  );

  group('bulk score entry', () {
    test('stores every entry and recalculates once', () async {
      final attempts = <int>[];
      final api = HandlerHarness(
        _owner,
        recalculation: RecalculationService(CountingResults(attempts)),
      );
      await drawnContest(api);
      final entries = [
        entry(await assignmentOfPilot(api, 1), 'bulk-1'),
        entry(await assignmentOfPilot(api, 2), 'bulk-2'),
        entry(await assignmentOfPilot(api, 3), 'bulk-3'),
      ];

      final response = await bulk(api, entries);
      final body = await api.json(response);

      expect(response.statusCode, 200, reason: '$body');
      final results = (body['results']! as List).cast<Map>();
      expect(results, hasLength(3));
      for (final result in results) {
        expect(
          ((result['result'] as Map)['official_score']
              as Map)['score_revision'],
          1,
        );
      }
      expect(api.repository.officialScores.stored, hasLength(3));
      expect(attempts, hasLength(1), reason: 'one recalculation, not three');
      expect(body['recalculation_warning'], isNull);
      final contest = await api.json(
        await api.send('GET', '/contests/$_contestId'),
      );
      expect(contest['lifecycle_state'], 'Running');
    });

    test('a stale entry is refused alone and the others save', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);
      final first = await assignmentOfPilot(api, 1);
      await api.send(
        'POST',
        '/contests/$_contestId/assignments/${first['id']}/scores',
        body: {
          'client_mutation_id': 'single-1',
          'base_score_revision': 0,
          'components': _flight,
        },
      );

      final body = await api.json(
        await bulk(api, [
          entry(first, 'bulk-1'),
          entry(await assignmentOfPilot(api, 2), 'bulk-2'),
        ]),
      );

      final results = (body['results']! as List).cast<Map>();
      expect((results[0]['error'] as Map)['code'], 'stale_revision');
      expect((results[0]['error'] as Map)['status'], 409);
      expect(results[1]['result'], isNotNull);
      expect(api.repository.officialScores.stored, hasLength(2));
    });

    test('a correction needs a reason, per entry', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);
      final first = await assignmentOfPilot(api, 1);
      await bulk(api, [entry(first, 'bulk-1')]);

      final body = await api.json(
        await bulk(api, [
          entry(first, 'bulk-2', base: 1),
          entry(await assignmentOfPilot(api, 2), 'bulk-3'),
        ]),
      );

      final results = (body['results']! as List).cast<Map>();
      expect((results[0]['error'] as Map)['status'], 400);
      expect(results[1]['result'], isNotNull);
    });

    test('repeating a request stores nothing twice', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);
      final entries = [
        entry(await assignmentOfPilot(api, 1), 'bulk-1'),
        entry(await assignmentOfPilot(api, 2), 'bulk-2'),
      ];

      await bulk(api, entries);
      final again = await api.json(await bulk(api, entries));

      expect(api.repository.officialScores.stored, hasLength(2));
      expect(
        (again['results']! as List).every((r) => (r as Map)['result'] != null),
        isTrue,
      );
    });

    test(
      'a repeated request recalculates again to finish an interrupted one',
      () async {
        final runs = <int>[];
        final api = HandlerHarness(
          _owner,
          recalculation: RecalculationService(CountingResults(runs)),
        );
        await drawnContest(api);
        final entries = [
          entry(await assignmentOfPilot(api, 1), 'bulk-1'),
          entry(await assignmentOfPilot(api, 2), 'bulk-2'),
        ];

        await bulk(api, entries);
        await bulk(api, entries);

        expect(runs, hasLength(2));
        expect(api.repository.officialScores.stored, hasLength(2));
      },
    );

    test('a conflict while storing falls back to one by one', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);
      api.repository.officialScores.conflictOnNextBulk = true;

      final body = await api.json(
        await bulk(api, [
          entry(await assignmentOfPilot(api, 1), 'bulk-1'),
          entry(await assignmentOfPilot(api, 2), 'bulk-2'),
        ]),
      );

      final results = (body['results']! as List).cast<Map>();
      expect(results.every((r) => r['result'] != null), isTrue);
      expect(api.repository.officialScores.stored, hasLength(2));
    });

    test('one mutation id used twice is refused on the second entry', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);

      final body = await api.json(
        await bulk(api, [
          entry(await assignmentOfPilot(api, 1), 'same'),
          entry(await assignmentOfPilot(api, 2), 'same'),
        ]),
      );

      final results = (body['results']! as List).cast<Map>();
      expect(results[0]['result'], isNotNull);
      expect((results[1]['error'] as Map)['status'], 400);
    });

    test('entries of two rounds are refused beyond the first round', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);

      final body = await api.json(
        await bulk(api, [
          entry(await assignmentOfPilot(api, 1), 'bulk-1'),
          entry(await assignmentOfPilot(api, 2, ordinal: 2), 'bulk-2'),
        ]),
      );

      final results = (body['results']! as List).cast<Map>();
      expect(results[0]['result'], isNotNull);
      expect((results[1]['error'] as Map)['status'], 400);
    });

    test('two entries for one slot: the second is refused', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);
      final first = await assignmentOfPilot(api, 1);

      final body = await api.json(
        await bulk(api, [entry(first, 'bulk-1'), entry(first, 'bulk-2')]),
      );

      final results = (body['results']! as List).cast<Map>();
      expect(results[0]['result'], isNotNull);
      expect((results[1]['error'] as Map)['status'], 400);
      expect(api.repository.officialScores.stored, hasLength(1));
    });

    test('a failing recalculation keeps the scores and warns once', () async {
      final api = HandlerHarness(
        _owner,
        recalculation: RecalculationService(AlwaysFailingResults()),
      );
      await drawnContest(api);

      final body = await api.json(
        await bulk(api, [
          entry(await assignmentOfPilot(api, 1), 'bulk-1'),
          entry(await assignmentOfPilot(api, 2), 'bulk-2'),
        ]),
      );

      expect(api.repository.officialScores.stored, hasLength(2));
      expect(body['recalculation_warning'], isNotNull);
    });

    test('an empty or oversized request is a 400', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);
      final one = entry(await assignmentOfPilot(api, 1), 'bulk-1');

      expect((await bulk(api, [])).statusCode, 400);
      expect((await bulk(api, List.filled(101, one))).statusCode, 400);
    });
  });
}
