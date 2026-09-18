import 'package:soar_score_core/soar_score_core.dart';

/// Repository interface for contest data.
abstract class ContestRepository {
  Future<List<Contest>> getContests();
  Future<Contest?> getContest(String id);
  Future<void> saveContest(Contest contest);
}