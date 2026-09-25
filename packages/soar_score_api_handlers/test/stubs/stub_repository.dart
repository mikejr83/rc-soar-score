import 'package:soar_score_core/soar_score_core.dart';

/// In-memory [ContestRepository] for handler tests.
///
/// The extracted routes are placeholder-level and never execute queries, so
/// this repository exists purely to satisfy the factory's required data
/// dependency without any data package.
class StubContestRepository implements ContestRepository {
  final Map<Id, Contest> _contests = {};

  @override
  Future<Contest?> findById(Id id) async => _contests[id];

  @override
  Future<List<Contest>> getAll() async => _contests.values.toList();

  @override
  Future<Contest> save(Contest contest) async {
    _contests[contest.id] = contest;
    return contest;
  }

  @override
  Future<bool> delete(Id id) async => _contests.remove(id) != null;

  @override
  Future<void> close() async {}
}
