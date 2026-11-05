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
}
