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

  /// Heading of the Settings card that picks the light or dark look.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceHeading;

  /// Explains the Appearance card on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Choose a light or dark look, or follow your device. This is saved on this device for your account and is not shared with other devices.'**
  String get appearanceDescription;

  /// Theme choice that follows the device's light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme choice for the light look.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme choice for the dark look.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Snackbar shown when the chosen theme could not be stored on the device.
  ///
  /// In en, this message translates to:
  /// **'The theme could not be saved. It applies until you close the app.'**
  String get themeSaveFailed;

  /// Heading of the Settings card that resets hidden or minimized panels.
  ///
  /// In en, this message translates to:
  /// **'Panels'**
  String get panelsHeading;

  /// Explains the Panels card on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Panels you hide or minimize, such as the matrix summary, stay that way on this device for your account, in every contest.'**
  String get panelsDescription;

  /// Button that brings back every hidden or minimized panel.
  ///
  /// In en, this message translates to:
  /// **'Reset panels to defaults'**
  String get panelsResetButton;

  /// Snackbar shown after the panels were reset.
  ///
  /// In en, this message translates to:
  /// **'Panels are back to their defaults.'**
  String get panelsResetDone;

  /// Snackbar shown when the panel reset could not be stored on the device.
  ///
  /// In en, this message translates to:
  /// **'The reset could not be saved. It applies until you close the app.'**
  String get panelsResetSaveFailed;

  /// Heading of the Settings card that sets the preferred time zone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZoneHeading;

  /// Explains the Time zone card on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Times shown to you in the app, such as when something was last saved or synced, use this time zone. Times pilots see always use the contest\'s own time zone. This follows your account.'**
  String get timeZoneDescription;

  /// Button that clears the preferred time zone so the device decides.
  ///
  /// In en, this message translates to:
  /// **'Use this device\'s time zone'**
  String get timeZoneDeviceButton;

  /// Shown on the Time zone card when no preferred zone is set.
  ///
  /// In en, this message translates to:
  /// **'Following this device.'**
  String get timeZoneFollowsDevice;

  /// Snackbar shown when the preferred time zone could not be stored.
  ///
  /// In en, this message translates to:
  /// **'The time zone could not be saved. It applies until you close the app.'**
  String get timeZoneSaveFailed;

  /// Heading of the Settings card that sets the preferred locale.
  ///
  /// In en, this message translates to:
  /// **'Language and formats'**
  String get localeHeading;

  /// Explains the locale card on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Sets the language and how dates and numbers are written for you. This follows your account.'**
  String get localeDescription;

  /// Label of the locale choice on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Language and format'**
  String get localeLabel;

  /// Choice that clears the preferred locale so the device decides.
  ///
  /// In en, this message translates to:
  /// **'Use this device\'s language'**
  String get localeDevice;

  /// Name of the en-US locale in the locale choice.
  ///
  /// In en, this message translates to:
  /// **'English (United States)'**
  String get localeEnUs;

  /// Snackbar shown when the preferred locale could not be stored.
  ///
  /// In en, this message translates to:
  /// **'The language could not be saved. It applies until you close the app.'**
  String get localeSaveFailed;

  /// Snackbar shown when a preference was changed while signed out, so it cannot be stored on an account.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep this on your account. It applies until you close the app.'**
  String get preferencesNeedSignIn;

  /// Shown when a contest file could not be saved or opened and no system error message is available.
  ///
  /// In en, this message translates to:
  /// **'Choose another place and try again.'**
  String get fileOperationRetryHint;

  /// Button that closes the export or import dialog without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Button on the contest detail pane that exports the contest to a file.
  ///
  /// In en, this message translates to:
  /// **'Export…'**
  String get exportContestButton;

  /// Title of the export dialog, with the name of the contest.
  ///
  /// In en, this message translates to:
  /// **'Export {name}'**
  String exportDialogTitle(String name);

  /// Explains what the export dialog saves.
  ///
  /// In en, this message translates to:
  /// **'Saves the whole contest to a .rcsoar file, for support or as a backup. Nothing is sent anywhere.'**
  String get exportDialogDescription;

  /// Checkbox that removes email addresses from the exported file.
  ///
  /// In en, this message translates to:
  /// **'Remove email addresses'**
  String get exportRedactionTitle;

  /// Explains the effect of the redaction checkbox.
  ///
  /// In en, this message translates to:
  /// **'Turn this off for a full backup. Names, clubs and scores are kept either way.'**
  String get exportRedactionSubtitle;

  /// Warning in the export dialog that the file is not encrypted.
  ///
  /// In en, this message translates to:
  /// **'The file is not encrypted. Anyone who has it can read the contest. Send it only to people you trust.'**
  String get exportNotice;

  /// Button that exports the contest and saves it to a file.
  ///
  /// In en, this message translates to:
  /// **'Save file…'**
  String get exportSaveButton;

  /// Snackbar shown after the contest file was saved, with the file name.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String exportSaved(String name);

  /// Snackbar shown when exporting failed and no reason is available.
  ///
  /// In en, this message translates to:
  /// **'The contest could not be exported.'**
  String get exportFailed;

  /// Snackbar shown when exporting failed, with the reason.
  ///
  /// In en, this message translates to:
  /// **'The contest could not be exported. {reason}'**
  String exportFailedWithReason(String reason);

  /// Snackbar shown when the chosen file dialog or file system failed, with the reason.
  ///
  /// In en, this message translates to:
  /// **'The contest could not be saved to a file. {reason}'**
  String exportFileSaveFailed(String reason);

  /// Button on the contests page that imports a contest file.
  ///
  /// In en, this message translates to:
  /// **'Import contest…'**
  String get importButton;

  /// Snackbar shown when the chosen file could not be opened, with the reason.
  ///
  /// In en, this message translates to:
  /// **'The file could not be opened. {reason}'**
  String importOpenFailed(String reason);

  /// Snackbar shown when the file is not a contest file, with its name and the reason.
  ///
  /// In en, this message translates to:
  /// **'{name} cannot be imported. {reason}'**
  String importFileRefused(String name, String reason);

  /// Snackbar shown when the import was refused, with the reason.
  ///
  /// In en, this message translates to:
  /// **'The contest was not imported. {reason}'**
  String importFailed(String reason);

  /// Title of the import dialog, with the name of the contest in the file.
  ///
  /// In en, this message translates to:
  /// **'Import {name}'**
  String importDialogTitle(String name);

  /// Button that imports the contest in the chosen mode.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importConfirmButton;

  /// Import dialog summary of the file, exported on the given date by the given source, with contact details removed.
  ///
  /// In en, this message translates to:
  /// **'Exported {exportedAt} from {source}. {participants} participants, {rounds} rounds, {scores} scores. Email addresses were removed.'**
  String importPreviewRedactedFromSource(
    String exportedAt,
    String source,
    int participants,
    int rounds,
    int scores,
  );

  /// Import dialog summary of the file, exported on the given date with no source, with contact details removed.
  ///
  /// In en, this message translates to:
  /// **'Exported {exportedAt}. {participants} participants, {rounds} rounds, {scores} scores. Email addresses were removed.'**
  String importPreviewRedacted(
    String exportedAt,
    int participants,
    int rounds,
    int scores,
  );

  /// Import dialog summary of the file, exported on the given date by the given source, with contact details kept.
  ///
  /// In en, this message translates to:
  /// **'Exported {exportedAt} from {source}. {participants} participants, {rounds} rounds, {scores} scores. Email addresses are included.'**
  String importPreviewIncludedFromSource(
    String exportedAt,
    String source,
    int participants,
    int rounds,
    int scores,
  );

  /// Import dialog summary of the file, exported on the given date with no source, with contact details kept.
  ///
  /// In en, this message translates to:
  /// **'Exported {exportedAt}. {participants} participants, {rounds} rounds, {scores} scores. Email addresses are included.'**
  String importPreviewIncluded(
    String exportedAt,
    int participants,
    int rounds,
    int scores,
  );

  /// Import mode that keeps a contest on this computer only.
  ///
  /// In en, this message translates to:
  /// **'Open as a local copy for inspection'**
  String get importModeInspectionTitle;

  /// Explains the inspection import mode.
  ///
  /// In en, this message translates to:
  /// **'Kept on this computer only. Nothing you do with it is sent to the service, whoever is signed in.'**
  String get importModeInspectionNotice;

  /// Import mode that owns the contest in the account in use.
  ///
  /// In en, this message translates to:
  /// **'Import as an editable copy'**
  String get importModeEditableTitle;

  /// Explains the editable import mode.
  ///
  /// In en, this message translates to:
  /// **'Owned by the account in use, like a contest made here. The original installation may still run the contest until it is moved here, and sync can be refused until then.'**
  String get importModeEditableNotice;

  /// Snackbar shown after a contest was imported as an inspection copy.
  ///
  /// In en, this message translates to:
  /// **'Imported as a local copy. It is not synced.'**
  String get importDoneInspection;

  /// Snackbar shown after a contest was imported as an editable copy.
  ///
  /// In en, this message translates to:
  /// **'Imported as an editable copy.'**
  String get importDoneEditable;

  /// Chip on the contest detail pane marking an imported inspection copy.
  ///
  /// In en, this message translates to:
  /// **'Imported copy, not synced'**
  String get inspectionChipLabel;

  /// Notice on the contest detail pane of an imported inspection copy.
  ///
  /// In en, this message translates to:
  /// **'This contest was imported for inspection. It stays on this computer: nothing in it is sent to the service, whoever is signed in.'**
  String get inspectionNotice;
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
