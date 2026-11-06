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
  String get openSourceLicencesLink => 'Open source licences';

  @override
  String get licencesInThisAppLink => 'Licences in this app';

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
  String get scoreExistingReadOnly =>
      'This flight already has a score, so it is read-only. See the group results for the score.';

  @override
  String get scoreRejectedValidation =>
      'Check your entries. The score was not sent.';

  @override
  String get scoreRejectedClosed =>
      'Scoring is closed for this flight. Ask your contest director.';

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
  String get unsupportedRoleTitle => 'This link is not for scoring yet';

  @override
  String get unsupportedRoleBody =>
      'Your link works, but this version of the app only supports pilots entering their own scores. Ask your contest director.';

  @override
  String get backToStart => 'Back to start';
}
