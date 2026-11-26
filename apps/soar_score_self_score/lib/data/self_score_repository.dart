import '../models/account_link.dart';
import '../models/contests_view.dart';
import '../models/entry_context.dart';
import '../models/group_results.dart';
import '../models/guest_session.dart';
import '../models/link_candidate.dart';
import '../models/own_directory.dart';
import '../models/past_contests.dart';
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

/// Why an "Is this you?" answer was refused for good.
enum LinkCandidateGoneReason {
  /// Another account already holds the pilot.
  alreadyLinked,

  /// The match is not (or no longer) one.
  notAvailable,
}

/// An "Is this you?" answer the server refused for good: retrying will not
/// help, so the card goes away.
class LinkCandidateGoneException extends SelfScoreLoadException {
  const LinkCandidateGoneException(this.reason)
    : super('This match is no longer available.');

  final LinkCandidateGoneReason reason;
}

/// The guest session is no longer valid: expired, replaced or revoked. The
/// stored session is dropped and the person opens their link again.
class SessionEndedException extends SelfScoreLoadException {
  const SessionEndedException()
    : super('Your session has ended. Open your invitation link again.');
}

/// The signed-in person's sign-in is no longer accepted by the server: the
/// token expired or the account was signed out elsewhere. Not a guest session
/// problem, so the guest session is left alone.
class SignedOutException extends SelfScoreLoadException {
  const SignedOutException()
    : super('Your sign-in has ended. Sign in again to continue.');
}

/// The contest is not on the signed-in person's list any more: the link was
/// ended, or the contest finished more than a day ago.
class ContestNotOnListException extends SelfScoreLoadException {
  const ContestNotOnListException()
    : super('This contest is no longer on your list.');
}

/// The invitation link is unknown, expired or replaced. The three look the
/// same on purpose, so a link never reveals whether a contest or pilot exists.
class InvalidInvitationException implements Exception {
  const InvalidInvitationException();

  @override
  String toString() => 'The invitation link is not valid.';
}

/// A signed-in pilot tried to claim an invitation for a pilot that another
/// account already holds. The link still works as a guest.
class PilotAlreadyLinkedException implements Exception {
  const PilotAlreadyLinkedException();

  @override
  String toString() => 'The pilot is already linked to another account.';
}

/// The signed-in pilot's access token was refused while claiming a link.
class AccountSignInExpiredException implements Exception {
  const AccountSignInExpiredException();

  @override
  String toString() => 'The account sign-in has expired.';
}

/// The server cannot link the signed-in account to this pilot (for example,
/// its email is not verified). The link itself is fine.
class AccountCannotLinkException implements Exception {
  const AccountCannotLinkException();

  @override
  String toString() => 'The account cannot be linked to this pilot.';
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

  /// The signed-in pilot opens the invitation link as themselves: the account
  /// is linked to the pilot the link is for, the entries made as a guest are
  /// kept under the account, and the session returned acts as the account.
  /// Throws [InvalidInvitationException] for a link that does not open and
  /// [PilotAlreadyLinkedException] when another account holds the pilot,
  /// [AccountSignInExpiredException] when the sign-in was refused and
  /// [AccountCannotLinkException] when the account cannot be linked.
  Future<GuestSession> claimInvitation(String credential);

  /// Sends a score. Resolves with what the server decided; a refusal is a
  /// [ScoreRejected] result, not an exception. Throws
  /// [SelfScoreOfflineException] when the server could not be reached, in
  /// which case the same [ScoreSubmission] can be sent again safely.
  Future<SubmitResult> submitScore(ScoreSubmission submission);

  /// The signed-in pilot's own invitation link, to copy to another device.
  /// Never log it. Throws [SelfScoreLoadException] when it cannot be had.
  Future<String> invitationLink();

  /// The contests the signed-in person reaches through their linked pilots.
  /// Throws [SignedOutException] when the server no longer accepts the
  /// sign-in.
  Future<ContestsView> contests();

  /// One page of the signed-in person's finished contests, newest first,
  /// starting after [offset] contests (#1048). A contest appears here once it
  /// has left [contests]. Throws [SignedOutException] when the server no
  /// longer accepts the sign-in and [SelfScoreLoadException] when the page
  /// could not be had.
  Future<PastContestsPage> pastContests({int offset = 0});

  /// Opens a contest of [contests] for the signed-in person: a session that
  /// acts as their account, like the one an invitation link gives. Throws
  /// [ContestNotOnListException] when it is no longer on their list.
  Future<GuestSession> openContest(String participationId);

  /// The pilots the signed-in account's verified email matches ("Is this
  /// you?"); empty when there are none. Needs the account token.
  Future<List<LinkCandidate>> linkCandidates();

  /// Says the pilot behind [candidateId] is the signed-in account. Repeating
  /// it is harmless. Throws [LinkCandidateGoneException] when the pilot is
  /// held by another account or the match is gone, and
  /// [SelfScoreLoadException] when the answer could not be sent.
  Future<void> confirmLinkCandidate(String candidateId);

  /// Says the pilot behind [candidateId] is not the signed-in account, so it
  /// is not offered again. Same failures as [confirmLinkCandidate].
  Future<void> declineLinkCandidate(String candidateId);

  /// The signed-in pilot's directory entry, or their account name with the
  /// defaults when they have none (#652). Throws [SelfScoreLoadException]
  /// when it cannot be had.
  Future<OwnDirectory> ownDirectory();

  /// Creates the signed-in pilot's directory entry or replaces its details.
  /// Throws [SelfScoreLoadException] when it could not be saved.
  Future<void> saveOwnDirectory(DirectoryDetails details);

  /// Removes the signed-in pilot's directory entry. Nothing already published
  /// changes. Throws [SelfScoreLoadException] when it could not be removed.
  Future<void> deleteOwnDirectory();

  /// The pilots the signed-in account is linked to (#654). Throws
  /// [SelfScoreLoadException] when they cannot be had.
  Future<List<AccountLink>> accountLinks();

  /// Ends the link [linkId]: the contest leaves the pilot's list, and nothing
  /// already published changes. Ending a link that is already ended or gone
  /// is not an error. Throws [SelfScoreLoadException] when it could not be
  /// sent.
  Future<void> endAccountLink(String linkId);

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
