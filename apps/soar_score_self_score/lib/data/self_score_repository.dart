import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_results.dart';
import '../models/guest_session.dart';
import '../models/pilot_overview.dart';
import '../models/results_view.dart';
import '../models/score_submission.dart';
import '../models/team_overview.dart';

/// Why a page could not load, in words the person can read.
class SelfScoreLoadException implements Exception {
  const SelfScoreLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The server could not be reached, or failed in a way that may pass. Used by
/// [SelfScoreRepository.submitScore] to tell a score that must be sent again
/// from one the server refused.
class SelfScoreOfflineException extends SelfScoreLoadException {
  const SelfScoreOfflineException(super.message);
}

/// The guest session is no longer valid: expired, replaced or revoked. The
/// stored session is dropped and the person opens their link again.
class SessionEndedException extends SelfScoreLoadException {
  const SessionEndedException()
    : super('Your session has ended. Open your invitation link again.');
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

  /// Sends a score. Resolves with what the server decided; a refusal is a
  /// [ScoreRejected] result, not an exception. Throws
  /// [SelfScoreOfflineException] when the server could not be reached, in
  /// which case the same [ScoreSubmission] can be sent again safely.
  Future<SubmitResult> submitScore(ScoreSubmission submission);

  /// The signed-in pilot's own invitation link, to copy to another device.
  /// Never log it. Throws [SelfScoreLoadException] when it cannot be had.
  Future<String> invitationLink();

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
