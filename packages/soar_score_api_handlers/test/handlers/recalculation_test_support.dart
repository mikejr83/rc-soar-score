import 'package:soar_score_core/soar_score_core.dart' as core;

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

/// A [ResultsService] over a stub repository that always throws from
/// [recalculate], so the post-entry recalculation fails twice and the
/// handler reports a warning (ticket 297).
class AlwaysFailingResults extends core.ResultsService {
  AlwaysFailingResults()
    : super(
        StubRepository(StubContestRepository()),
      );

  @override
  Future<core.ContestResults> recalculate(core.Id contestId) async {
    throw StateError('the database is unreachable');
  }
}

/// A [ResultsService] that fails on the first [recalculate] call and
/// succeeds on the second, to prove the single retry and that a recovered
/// recalculation carries no warning.
class FlakyResults extends core.ResultsService {
  FlakyResults(this._attempts)
    : super(
        StubRepository(StubContestRepository()),
      );

  final List<int> _attempts;

  @override
  Future<core.ContestResults> recalculate(core.Id contestId) async {
    _attempts.add(1);
    if (_attempts.length < 2) {
      throw StateError('transient failure');
    }
    return core.ContestResults(isStale: false);
  }
}