import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Tooltip of the app bar button that opens the menu with legal and licence links.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreMenuTooltip;

  /// Link to the public site page that lists the open source software this app uses.
  ///
  /// In en, this message translates to:
  /// **'Open source licences'**
  String get openSourceLicencesLink;

  /// Menu item that opens the licence list built into the app. It works without a network connection.
  ///
  /// In en, this message translates to:
  /// **'Licences in this app'**
  String get licencesInThisAppLink;

  /// Link to the Privacy Policy on the public site.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLink;

  /// Link to the Terms of Service on the public site.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsLink;

  /// Snackbar when a link to the public site could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link. Check your network connection and try again.'**
  String get linkOpenFailed;

  /// Spoken label while the invitation link is checked.
  ///
  /// In en, this message translates to:
  /// **'Opening your link'**
  String get invitationOpening;

  /// Heading on the invitation page once the link is checked. The name is the pilot the link belongs to.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String invitationHeading(String name);

  /// Explains what the invitation link does. Placeholder is the contest name.
  ///
  /// In en, this message translates to:
  /// **'You are scoring for {contest}. Continue as a guest to enter your scores. You can come back through the same link at any time.'**
  String invitationBody(String contest);

  /// Primary button on the invitation page.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// Button on the invitation page. Not connected yet.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// Button on the invitation page. Not connected yet.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// Shown under the Sign in and Create account buttons while they are not connected.
  ///
  /// In en, this message translates to:
  /// **'Accounts are coming soon. For now, continue as a guest.'**
  String get accountsComingSoon;

  /// Heading when an invitation link is unknown, expired or replaced.
  ///
  /// In en, this message translates to:
  /// **'This link does not work'**
  String get invalidLinkTitle;

  /// Tells the person what to do about a link that does not work. Does not say why, on purpose.
  ///
  /// In en, this message translates to:
  /// **'The link may have expired or been replaced. Ask your contest director for your link.'**
  String get invalidLinkBody;

  /// Shown when the server could not be reached while checking an invitation link.
  ///
  /// In en, this message translates to:
  /// **'Could not open your link. Check your network connection and try again.'**
  String get invitationLoadFailed;

  /// Shown on the Submit button while the score is on its way.
  ///
  /// In en, this message translates to:
  /// **'Sending your score'**
  String get scoreSending;

  /// Heading when a score could not reach the server.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get scoreQueuedTitle;

  /// Explains a score that has not reached the server.
  ///
  /// In en, this message translates to:
  /// **'Your score is saved on this phone and is not official yet. It will send again when the connection is back. You can also try now.'**
  String get scoreQueuedBody;

  /// Button that sends a waiting score again.
  ///
  /// In en, this message translates to:
  /// **'Try again now'**
  String get scoreRetryNow;

  /// Shown after the server accepted the score. The score is the server's calculation.
  ///
  /// In en, this message translates to:
  /// **'Official score: {score}'**
  String scoreAcceptedLine(String score);

  /// Shown after the server accepted the score, before it is official. The score is the server's calculation.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String scoreCalculatedLine(String score);

  /// The flight's score before normalising, from the server.
  ///
  /// In en, this message translates to:
  /// **'Raw score: {score}'**
  String scoreRawLine(String score);

  /// The pilot's score for the round, from the server.
  ///
  /// In en, this message translates to:
  /// **'Round score: {score}'**
  String scoreRoundLine(String score);

  /// The penalty points counted against the pilot so far, from the server.
  ///
  /// In en, this message translates to:
  /// **'Penalty so far: {score}'**
  String scorePenaltyLine(String score);

  /// Who entered the stored score.
  ///
  /// In en, this message translates to:
  /// **'Entered by {name}'**
  String scoreEnteredByLine(String name);

  /// Shown after the server accepted the score but gave no calculated value.
  ///
  /// In en, this message translates to:
  /// **'Your score was received.'**
  String get scoreAcceptedNoValue;

  /// Shown when the server already had a score for the flight.
  ///
  /// In en, this message translates to:
  /// **'This flight already has a score. The stored score stands.'**
  String get scoreAlreadyThere;

  /// Shown when the server already had a score for the flight. The score is the stored one.
  ///
  /// In en, this message translates to:
  /// **'This flight already has a score: {score}. The stored score stands.'**
  String scoreAlreadyThereWith(String score);

  /// Tooltip of the back button on the pilot overview, which goes to the team overview.
  ///
  /// In en, this message translates to:
  /// **'Back to pilots'**
  String get backToPilots;

  /// Button shown after a score is submitted; opens the results of the pilot's group for that round.
  ///
  /// In en, this message translates to:
  /// **'See group results'**
  String get seeGroupResults;

  /// Shown when the entry form opens for a flight that is already scored.
  ///
  /// In en, this message translates to:
  /// **'This flight already has a score, so it is read-only. See the group results for the score.'**
  String get scoreExistingReadOnly;

  /// Shown when the server refused the values.
  ///
  /// In en, this message translates to:
  /// **'Check your entries. The score was not sent.'**
  String get scoreRejectedValidation;

  /// Shown when the contest or round no longer takes scores.
  ///
  /// In en, this message translates to:
  /// **'Scoring is closed for this flight. Ask your contest director.'**
  String get scoreRejectedClosed;

  /// Shown when an earlier round has no score yet.
  ///
  /// In en, this message translates to:
  /// **'Score the earlier round first.'**
  String get scoreRejectedOutOfOrder;

  /// Shown when the draw changed after the form was opened.
  ///
  /// In en, this message translates to:
  /// **'The draw changed. Go back to your rounds and open this round again.'**
  String get scoreRejectedStaleDraw;

  /// Shown when the guest session is no longer valid.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Open your invitation link again.'**
  String get scoreRejectedSession;

  /// Shown for any other refusal.
  ///
  /// In en, this message translates to:
  /// **'The score was not accepted. Ask your contest director.'**
  String get scoreRejectedOther;

  /// Heading when an invitation link is valid but for a role this release does not support.
  ///
  /// In en, this message translates to:
  /// **'This link is not for scoring yet'**
  String get unsupportedRoleTitle;

  /// Explains a link for a role (such as a helper) that the app does not support yet.
  ///
  /// In en, this message translates to:
  /// **'Your link works, but this version of the app only supports pilots entering their own scores. Ask your contest director.'**
  String get unsupportedRoleBody;

  /// Button on a page whose session ended. Goes to the start page, where the person opens their link again.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get backToStart;

  /// The contest is taking scores.
  ///
  /// In en, this message translates to:
  /// **'Scoring open'**
  String get scoringOpen;

  /// Scoring has not opened.
  ///
  /// In en, this message translates to:
  /// **'Scoring not open yet'**
  String get scoringNotStarted;

  /// The contest is not taking scores now.
  ///
  /// In en, this message translates to:
  /// **'Scoring closed'**
  String get scoringClosed;

  /// The contest is over.
  ///
  /// In en, this message translates to:
  /// **'Contest completed'**
  String get scoringCompleted;

  /// Tooltip of the button that ends the guest session and returns to the start page.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @refreshResults.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshResults;

  /// No description provided for @refreshingResults.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get refreshingResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @resultsRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Refresh to see the latest scores'**
  String get resultsRefreshHint;

  /// Local time of the last successful results fetch, not the score submission time.
  ///
  /// In en, this message translates to:
  /// **'Last refreshed: {time}'**
  String resultsLastRefreshed(String time);

  /// Shown when a results refresh fails but an earlier successful fetch is available.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh; last updated {time}'**
  String resultsRefreshFailed(String time);

  /// Tooltip of the title bar button on the pilot overview that copies the pilot's invitation link.
  ///
  /// In en, this message translates to:
  /// **'Copy invitation link'**
  String get copyInvitationLink;

  /// Primary button at the bottom of the pilot overview that opens the contest results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get currentResults;

  /// Button at the bottom of the pilot overview that starts retiring the pilot.
  ///
  /// In en, this message translates to:
  /// **'Retire pilot'**
  String get retirePilot;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
