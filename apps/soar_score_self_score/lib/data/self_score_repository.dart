import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_results.dart';
import '../models/pilot_overview.dart';
import '../models/results_view.dart';
import '../models/team_overview.dart';

/// Why a page could not load, in words the person can read.
class SelfScoreLoadException implements Exception {
  const SelfScoreLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Everything the self-scoring pages read. Pages depend on this and not on
/// the API client, so the API-backed version can replace the sample one
/// without touching a page. Each method throws [SelfScoreLoadException] when
/// the data is unavailable or does not exist.
abstract interface class SelfScoreRepository {
  Future<ContestsView> contests();

  Future<TeamOverview> teamOverview(String contestId);

  Future<PilotOverview> pilotOverview(String contestId, String pilotId);

  Future<EntryContext> entryContext(
    String contestId,
    String pilotId,
    int round,
  );

  Future<GroupResults> groupResults(
    String contestId,
    String pilotId,
    int round,
  );

  /// Standings as of [asOfRound], or the latest round when null.
  Future<ResultsView> results(String contestId, {int? asOfRound});
}
