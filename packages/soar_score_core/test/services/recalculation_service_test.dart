import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../support/memory_repositories.dart';

void main() {
  group('ScoreEntryResult', () {
    test('carries no warning by default', () {
      final result = ScoreEntryResult(
        officialScore: OfficialScore(
          id: Id.create(),
          contestId: Id.create(),
          scorePlaceholderId: Id.create(),
          scoreAttemptId: Id.create(),
          scoreRevision: 1,
          components: const {},
          setAt: DateTime.utc(2026, 10, 17),
          setBy: Id.create(),
          reason: 'Entered by the director',
        ),
        placeholder: ScorePlaceholder(
          id: Id.create(),
          contestId: Id.create(),
          contestParticipationId: Id.create(),
          assignmentId: Id.create(),
          state: ScorePlaceholderState.official,
          scoreRevision: 1,
        ),
        contest: Contest(
          id: Id.create(),
          name: 'Spring Open',
          startDateTime: DateTime.utc(2026, 10, 17, 14),
          endDateTime: DateTime.utc(2026, 10, 18, 22),
          timezone: 'America/Denver',
          createdAt: DateTime.utc(2026, 9),
          updatedAt: DateTime.utc(2026, 9),
        ),
        calculated: const CalculatedFlight(
          outcome: FlightOutcome.scored,
          rawScore: 0,
        ),
      );

      expect(result.recalculationWarning, isNull);
      expect(result.toJson()['recalculation_warning'], isNull);
      expect(ScoreEntryResult.fromJson(result.toJson()), result);
    });

    test('round-trips a warning', () {
      final result = ScoreEntryResult(
        officialScore: OfficialScore(
          id: Id.create(),
          contestId: Id.create(),
          scorePlaceholderId: Id.create(),
          scoreAttemptId: Id.create(),
          scoreRevision: 1,
          components: const {},
          setAt: DateTime.utc(2026, 10, 17),
          setBy: Id.create(),
          reason: 'Entered by the director',
        ),
        placeholder: ScorePlaceholder(
          id: Id.create(),
          contestId: Id.create(),
          contestParticipationId: Id.create(),
          assignmentId: Id.create(),
          state: ScorePlaceholderState.official,
          scoreRevision: 1,
        ),
        contest: Contest(
          id: Id.create(),
          name: 'Spring Open',
          startDateTime: DateTime.utc(2026, 10, 17, 14),
          endDateTime: DateTime.utc(2026, 10, 18, 22),
          timezone: 'America/Denver',
          createdAt: DateTime.utc(2026, 9),
          updatedAt: DateTime.utc(2026, 9),
        ),
        calculated: const CalculatedFlight(
          outcome: FlightOutcome.scored,
          rawScore: 0,
        ),
        recalculationWarning:
            'Recalculation failed after a score entry; the results are stale',
      );

      expect(
        ScoreEntryResult.fromJson(result.toJson()).recalculationWarning,
        result.recalculationWarning,
      );
    });
  });

  group('RecalculationService', () {
    test('returns null when the recalculation succeeds', () async {
      final service = RecalculationService(_SuccessfulResults());

      expect(await service.recalculateAfterEntry(Id.create()), isNull);
    });

    test('retries once and returns a warning when it fails twice', () async {
      final attempts = <int>[];
      final service = RecalculationService(_AlwaysFailingResults(attempts));

      final warning =
          await service.recalculateAfterEntry(Id.create());

      expect(warning, isNotNull);
      expect(attempts, hasLength(2));
    });

    test('returns a warning for a ContestStateError without retrying', () async {
      final attempts = <int>[];
      final service = RecalculationService(_RefusingResults(attempts));

      final warning = await service.recalculateAfterEntry(Id.create());

      expect(warning, contains('refused'));
      expect(attempts, hasLength(1));
    });
  });
}

class _SuccessfulResults extends ResultsService {
  _SuccessfulResults()
    : super(FakeRepository(contestRepository: MemoryContestRepository()));

  @override
  Future<ContestResults> recalculate(Id contestId) async =>
      ContestResults(isStale: false);
}

class _AlwaysFailingResults extends ResultsService {
  _AlwaysFailingResults(this._attempts)
    : super(FakeRepository(contestRepository: MemoryContestRepository()));

  final List<int> _attempts;

  @override
  Future<ContestResults> recalculate(Id contestId) async {
    _attempts.add(1);
    throw StateError('the database is unreachable');
  }
}

class _RefusingResults extends ResultsService {
  _RefusingResults(this._attempts)
    : super(FakeRepository(contestRepository: MemoryContestRepository()));

  final List<int> _attempts;

  @override
  Future<ContestResults> recalculate(Id contestId) async {
    _attempts.add(1);
    throw ContestStateError(
      'not_configured',
      'the contest has no configuration yet',
    );
  }
}