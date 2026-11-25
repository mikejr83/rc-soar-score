// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get moreMenuTooltip => 'More';

  @override
  String get copyInvitationLink => 'Copy invitation link';

  @override
  String get appInfoLink => 'Application info';

  @override
  String get appInfoTitle => 'Application info';

  @override
  String get backLabel => 'Back';

  @override
  String get openSourceLicencesLink => 'Open source licences';

  @override
  String get licencesInThisAppLink => 'Licences in this app';

  @override
  String get supportLink => 'Get support';

  @override
  String get privacyPolicyLink => 'Privacy Policy';

  @override
  String get termsLink => 'Terms';

  @override
  String get linkOpenFailed =>
      'Could not open the link. Check your network connection and try again.';

  @override
  String get invitationOpening => 'Opening your link';

  @override
  String invitationHeading(String name) {
    return 'Hello, $name';
  }

  @override
  String invitationBody(String contest) {
    return 'You are scoring for $contest. Continue as a guest to enter your scores. You can come back through the same link at any time.';
  }

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get signInButton => 'Sign in';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get accountsComingSoon =>
      'Accounts are coming soon. For now, continue as a guest.';

  @override
  String invitationClaimBody(String contest) {
    return 'You are scoring for $contest. Continue with your account to keep this pilot\'s scores with it, including any you entered as a guest.';
  }

  @override
  String continueAsName(String name) {
    return 'Continue as $name';
  }

  @override
  String get continueAsAccount => 'Continue with my account';

  @override
  String get invitationKeepScores =>
      'Sign in or create an account to keep your scores with it. Scores you enter as a guest come along.';

  @override
  String get claimAlreadyLinked =>
      'This pilot is already linked to another account. You can continue as a guest.';

  @override
  String get claimInvalid =>
      'This link no longer works. Ask the contest director for a new one.';

  @override
  String get claimSignInExpired =>
      'Your sign-in has expired. Go to the landing page, sign in again, then open this link again.';

  @override
  String get claimCannotLink =>
      'Your account cannot be linked to this pilot. You can continue as a guest.';

  @override
  String get claimFailed =>
      'Could not continue with your account. Try again, or continue as a guest.';

  @override
  String get invalidLinkTitle => 'This link does not work';

  @override
  String get invalidLinkBody =>
      'The link may have expired or been replaced. Ask your contest director for your link.';

  @override
  String get invitationLoadFailed =>
      'Could not open your link. Check your network connection and try again.';

  @override
  String get scoreSending => 'Sending your score';

  @override
  String get scoreQueuedTitle => 'Not sent yet';

  @override
  String get scoreQueuedBody =>
      'Your score is saved on this phone and is not official yet. It will send again when the connection is back. You can also try now.';

  @override
  String get scoreRetryNow => 'Try again now';

  @override
  String scoreAcceptedLine(String score) {
    return 'Official score: $score';
  }

  @override
  String scoreCalculatedLine(String score) {
    return 'Score: $score';
  }

  @override
  String scoreRawLine(String score) {
    return 'Raw score: $score';
  }

  @override
  String scoreRoundLine(String score) {
    return 'Round score: $score';
  }

  @override
  String scorePenaltyLine(String score) {
    return 'Penalty so far: $score';
  }

  @override
  String scoreEnteredByLine(String name) {
    return 'Entered by $name';
  }

  @override
  String get scoreAcceptedNoValue => 'Your score was received.';

  @override
  String get scoreAlreadyThere =>
      'This flight already has a score. The stored score stands.';

  @override
  String scoreAlreadyThereWith(String score) {
    return 'This flight already has a score: $score. The stored score stands.';
  }

  @override
  String get backToPilots => 'Back to pilots';

  @override
  String get flightResults => 'Flight Results';

  @override
  String get seeGroupResults => 'See group results';

  @override
  String get scoreExistingReadOnly =>
      'This flight already has a score, so it is read-only. See the group results for the score.';

  @override
  String get scoreRejectedValidation =>
      'Check your entries. The score was not sent.';

  @override
  String get scoreRejectedClosed =>
      'Scoring is closed for this flight. Ask your contest director.';

  @override
  String get scoreRejectedLocked =>
      'This score is locked. Ask your contest director.';

  @override
  String get scoreRejectedOutOfOrder => 'Score the earlier round first.';

  @override
  String get scoreRejectedStaleDraw =>
      'The draw changed. Go back to your rounds and open this round again.';

  @override
  String get scoreRejectedSession =>
      'Your session has ended. Open your invitation link again.';

  @override
  String get scoreRejectedOther =>
      'The score was not accepted. Ask your contest director.';

  @override
  String get scoreFieldRefused => 'The server did not accept this value.';

  @override
  String get unsupportedRoleTitle => 'This link is not for scoring yet';

  @override
  String get unsupportedRoleBody =>
      'Your link works, but this version of the app only supports pilots entering their own scores. Ask your contest director.';

  @override
  String get backToStart => 'Back to start';

  @override
  String get scoringOpen => 'Scoring open';

  @override
  String get scoringNotStarted => 'Scoring not open yet';

  @override
  String get scoringClosed => 'Scoring closed';

  @override
  String get scoringCompleted => 'Contest completed';

  @override
  String get endSession => 'End session';

  @override
  String get refreshResults => 'Refresh';

  @override
  String get refreshingResults => 'Refreshing…';

  @override
  String get loading => 'Loading';

  @override
  String get resultsRefreshHint => 'Refresh to see the latest scores';

  @override
  String resultsLastRefreshed(String time) {
    return 'Last refreshed: $time';
  }

  @override
  String resultsRefreshFailed(String time) {
    return 'Couldn\'t refresh; last updated $time';
  }

  @override
  String get invitationLinkCopied => 'Invitation link copied';

  @override
  String get invitationLinkCopyFailed =>
      'Couldn\'t copy the invitation link. Check your connection and try again.';

  @override
  String get invitationLinkDialogTitle => 'Your invitation link';

  @override
  String get invitationLinkDialogBody =>
      'Your browser would not copy it. Select the link and copy it yourself.';

  @override
  String get invitationLinkDialogClose => 'Close';

  @override
  String get currentResults => 'Results';

  @override
  String get retirePilot => 'Retire pilot';

  @override
  String get preliminaryNoteGeneral =>
      'Scores are preliminary until the contest makes them official. Until then they can change.';

  @override
  String get preliminaryNoteEndOfRound =>
      'These scores are preliminary. Each score becomes official when all required scores for its round have been submitted. Until then it can change.';

  @override
  String get preliminaryNoteEndOfGroup =>
      'These scores are preliminary. Each score becomes official when all required scores for its group have been submitted. Until then it can change.';

  @override
  String get preliminaryNoteManual =>
      'These scores are preliminary. Each score becomes official when the director makes it official. Until then it can change.';

  @override
  String get preliminaryNoteReviewHold =>
      'A score under review is held: it stays as entered and is not made official until the review is decided.';

  @override
  String get groupZeroRecorded => 'Zero recorded';

  @override
  String groupZeroWithReason(String reason) {
    return 'Zero: $reason';
  }

  @override
  String get zeroReasonOutOfBounds => 'out of bounds';

  @override
  String get zeroReasonMotorRestart => 'motor restart';

  @override
  String get zeroReasonNoAltitudeRecorded => 'no altitude recorded';

  @override
  String get zeroReasonOverflight => 'overflight over one minute';

  @override
  String get homeHeadline => 'Score your flights at the field';

  @override
  String get homeIntro =>
      'This is the self-scoring app for RC Soar Score. Open the link your contest director sent you to start scoring.';

  @override
  String get homeSignUpButton => 'Sign up';

  @override
  String get homeAccountsComingSoon =>
      'Sign in and sign up are coming in a future release, when pilots can create accounts that track their results over time.';

  @override
  String get homeAccountsUnavailableHint =>
      'Sign in and sign up are not available yet. Use the link your contest director sent you.';

  @override
  String homeSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get homeSignedIn => 'You are signed in.';

  @override
  String get contestsTitle => 'Contests';

  @override
  String get contestsSignedOutMessage =>
      'Sign in to see the contests you are in.';

  @override
  String get contestsEmptyTitle => 'No contests yet';

  @override
  String get contestsEmptyBody =>
      'When a contest director invites you, the contest shows up here. You can also open the link or scan the QR code on your score card.';

  @override
  String get contestPhaseInvited => 'Invited';

  @override
  String get contestPhaseInProgress => 'In progress';

  @override
  String get contestPhaseCompleted => 'Completed';

  @override
  String get contestsCompletedNote =>
      'Completed contests stay on this list for a day.';

  @override
  String contestDatesRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String get contestPublicResults => 'Public results';

  @override
  String get contestOpenFailed =>
      'Could not open this contest. Check your connection and try again.';

  @override
  String get contestNotOnList => 'This contest is no longer on your list.';

  @override
  String get contestSignInEnded =>
      'Your sign-in has ended. Sign in again to open this contest.';

  @override
  String get homeMyContests => 'My contests';

  @override
  String get homeSignOutButton => 'Sign out';

  @override
  String get homeSignInFailed => 'Sign-in could not be started. Try again.';

  @override
  String get homeLostLink =>
      'Lost your link? Ask your contest director to send your link again.';

  @override
  String get homeSignOutFailed => 'Sign-out could not be completed. Try again.';

  @override
  String get isThisYouTitle => 'Is this you?';

  @override
  String isThisYouMatches(String name) {
    return 'The email on your account matches the pilot $name.';
  }

  @override
  String isThisYouContest(String contest, String dates) {
    return '$contest, $dates';
  }

  @override
  String get isThisYouConfirm => 'Yes, that\'s me';

  @override
  String get isThisYouDecline => 'Not me';

  @override
  String get isThisYouFailed => 'Could not save your answer. Try again.';

  @override
  String get isThisYouAlreadyLinked =>
      'This pilot is already linked to another account.';

  @override
  String get isThisYouNoLongerAvailable => 'This match is no longer available.';

  @override
  String get isThisYouLoadFailed => 'Could not check for matching pilots.';

  @override
  String get isThisYouRetry => 'Try again';
}
