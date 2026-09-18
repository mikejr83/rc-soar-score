import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/src/repositories/contest_repository.dart';

/// In-memory [ContestRepository].
///
/// Used as the default backing store by the API server. A production
/// deployment would swap this for a persistent (e.g. SQLite)
/// implementation of the same interface without changing the server.
class InMemoryContestRepository extends ContestRepository {
  final Map<String, Contest> _contests = {};

  @override
  Future<List<Contest>> getContests() async {
    return _contests.values.toList()
      ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
  }

  @override
  Future<Contest?> getContest(String id) async {
    return _contests[id];
  }

  @override
  Future<void> saveContest(Contest contest) async {
    _contests[contest.id] = contest;
  }

  /// Remove a contest by [id]. Returns `true` if it existed.
  Future<bool> deleteContest(String id) async {
    return _contests.remove(id) != null;
  }

  /// Clears all stored contests.
  void clear() => _contests.clear();
}