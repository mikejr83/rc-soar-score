import 'package:soar_score_core/soar_score_core.dart';

/// Repository interface for contest data.
abstract class ContestRepository {
  Future<Contest?> getContest();
  Future<void> saveContest(Contest contest);
}