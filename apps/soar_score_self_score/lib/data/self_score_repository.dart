import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_results.dart';
import '../models/guest_session.dart';
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

/// The invitation link is unknown, expired or replaced. The three look the
/// same on purpose, so a link never reveals whether a contest or pilot exists.
class InvalidInvitationException implements Exception {
  const InvalidInvitationException();

  @override
  String toString() => 'The invitation link is not valid.';
}

/// Everything the self-scoring pages read. Pages depend on this and not on
/// the API client, so the API-backed version can replace the sample one
/// without touching a page. Each method throws [SelfScoreLoadException] when
/// the data is unavailable or does not exist.
abstract interface class SelfScoreRepository {
  /// Trades the credential from an invitation link for a guest session.
  /// Throws [InvalidInvitationException] when the link does not work, and
  /// [SelfScoreLoadException] when the server could not be reached.
  Future<GuestSession> acceptInvitation(String credential);

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
