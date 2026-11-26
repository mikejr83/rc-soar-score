// ignore_for_file: deprecated_member_use
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

  /// Heading of the Settings card that picks how large text is.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeHeading;

  /// Explains the Text size card on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Make text larger on this device. This is saved for your account and is not shared with other devices. Your device\'s own text size setting still applies on top.'**
  String get textSizeDescription;

  /// Text size choice that keeps the app's own sizes.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textSizeDefault;

  /// Text size choice for somewhat larger text.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// Text size choice for the largest text.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeExtraLarge;

  /// A line of sample text on the Text size card, shown at the chosen size.
  ///
  /// In en, this message translates to:
  /// **'Sample: Round 3, Group B, Pilot 12'**
  String get textSizePreview;

  /// Snackbar shown when the chosen text size could not be stored on the device.
  ///
  /// In en, this message translates to:
  /// **'The text size could not be saved. It applies until you close the app.'**
  String get textSizeSaveFailed;

  /// Splash message on the first run, while the local database is created.
  ///
  /// In en, this message translates to:
  /// **'Initializing system...'**
  String get startupInitializing;

  /// Splash message on a normal start.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get startupStarting;

  /// Splash message after an app update, while the local database is upgraded.
  ///
  /// In en, this message translates to:
  /// **'Updating system...'**
  String get startupUpdating;

  /// Heading of the Settings card for the startup splash.
  ///
  /// In en, this message translates to:
  /// **'Startup screen'**
  String get startupSplashHeading;

  /// Explains the startup screen switch on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Takes effect the next time the app starts.'**
  String get startupSplashDescription;

  /// Label of the switch that turns the startup splash on or off.
  ///
  /// In en, this message translates to:
  /// **'Show startup screen'**
  String get startupSplashSwitch;

  /// Shown under the startup screen switch when saving the choice fails.
  ///
  /// In en, this message translates to:
  /// **'The setting could not be saved. It stays as it was.'**
  String get startupSplashSaveFailed;

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

  /// Heading of the Settings card that resets the report viewer's remembered options.
  ///
  /// In en, this message translates to:
  /// **'Report options'**
  String get reportOptionsHeading;

  /// Explains the Report options card on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'Report options are remembered each time you change them. You can reset them all to the default.'**
  String get reportOptionsDescription;

  /// Button that brings every report's options back to their defaults.
  ///
  /// In en, this message translates to:
  /// **'Reset report options'**
  String get reportOptionsResetButton;

  /// Snackbar shown after the report options were reset.
  ///
  /// In en, this message translates to:
  /// **'Report options are back to their defaults.'**
  String get reportOptionsResetDone;

  /// Snackbar shown when the report options reset could not be stored on the device.
  ///
  /// In en, this message translates to:
  /// **'The reset could not be saved.'**
  String get reportOptionsResetSaveFailed;

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

  /// Checkbox that exports the contest together with the app log, for the developers to debug a problem.
  ///
  /// In en, this message translates to:
  /// **'Export for support'**
  String get exportForSupportTitle;

  /// Explains that an export for support is not redacted and carries the app log.
  ///
  /// In en, this message translates to:
  /// **'For finding a problem. The file keeps email addresses and all other contest data and includes the app log and details of this installation.'**
  String get exportForSupportSubtitle;

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
  /// **'Exported {exportedAt} from {source}. {participants, plural, one{1 participant} other{{participants} participants}}, {rounds, plural, one{1 round} other{{rounds} rounds}}, {scores, plural, one{1 score} other{{scores} scores}}. Email addresses were removed.'**
  String importPreviewRedactedFromSource(
    String exportedAt,
    String source,
    num participants,
    num rounds,
    num scores,
  );

  /// Import dialog summary of the file, exported on the given date with no source, with contact details removed.
  ///
  /// In en, this message translates to:
  /// **'Exported {exportedAt}. {participants, plural, one{1 participant} other{{participants} participants}}, {rounds, plural, one{1 round} other{{rounds} rounds}}, {scores, plural, one{1 score} other{{scores} scores}}. Email addresses were removed.'**
  String importPreviewRedacted(
    String exportedAt,
    num participants,
    num rounds,
    num scores,
  );

  /// Import dialog summary of the file, exported on the given date by the given source, with contact details kept.
  ///
  /// In en, this message translates to:
  /// **'Exported {exportedAt} from {source}. {participants, plural, one{1 participant} other{{participants} participants}}, {rounds, plural, one{1 round} other{{rounds} rounds}}, {scores, plural, one{1 score} other{{scores} scores}}. Email addresses are included.'**
  String importPreviewIncludedFromSource(
    String exportedAt,
    String source,
    num participants,
    num rounds,
    num scores,
  );

  /// Import dialog summary of the file, exported on the given date with no source, with contact details kept.
  ///
  /// In en, this message translates to:
  /// **'Exported {exportedAt}. {participants, plural, one{1 participant} other{{participants} participants}}, {rounds, plural, one{1 round} other{{rounds} rounds}}, {scores, plural, one{1 score} other{{scores} scores}}. Email addresses are included.'**
  String importPreviewIncluded(
    String exportedAt,
    num participants,
    num rounds,
    num scores,
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

  /// Label of the round entry in the contest status panel.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get shellRoundLabel;

  /// Round entry value: the round being scored out of the total.
  ///
  /// In en, this message translates to:
  /// **'{round} of {total}'**
  String shellRoundValue(int round, int total);

  /// Round entry value with the group being scored, shown by its letter.
  ///
  /// In en, this message translates to:
  /// **'{round} of {total}, group {group}'**
  String shellRoundGroupValue(int round, int total, String group);

  /// Round entry value when a drawn contest has no scores yet.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get shellRoundNotStarted;

  /// Round entry value when the contest is completed.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get shellRoundFinished;

  /// Accessible name of the round entry button.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}. Go to scoring'**
  String shellRoundSemantics(String label, String value);

  /// Heading of the warning shown each time the app opens in an alpha build.
  ///
  /// In en, this message translates to:
  /// **'Alpha release'**
  String get alphaNoticeTitle;

  /// Opening line of the alpha release warning.
  ///
  /// In en, this message translates to:
  /// **'RC Soar Score is an early release. Please read this before you continue.'**
  String get alphaNoticeIntro;

  /// Alpha warning: contest data may be lost.
  ///
  /// In en, this message translates to:
  /// **'Contest directors should not expect this application to store contest data for the long term. The next release may require the database to be reset.'**
  String get alphaNoticeStorage;

  /// Alpha warning: results need manual checking.
  ///
  /// In en, this message translates to:
  /// **'The scoring system should be correct, but manual checks should be performed.'**
  String get alphaNoticeScoring;

  /// Alpha warning: features that are not finished.
  ///
  /// In en, this message translates to:
  /// **'Major functionality such as pilot self-scoring and contest results sharing has not been completed.'**
  String get alphaNoticeMissing;

  /// Alpha warning: do not rely on the app alone.
  ///
  /// In en, this message translates to:
  /// **'The software is still in an early release and should not be your primary method for tracking a contest and scoring.'**
  String get alphaNoticePrimary;

  /// Label of the checkbox that must be ticked to continue past the alpha warning.
  ///
  /// In en, this message translates to:
  /// **'I understand this, and I will not hold the application developers responsible.'**
  String get alphaNoticeAcknowledge;

  /// Button that closes the alpha warning once the checkbox is ticked.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get alphaNoticeContinue;

  /// Name of the status bar indicator for the storage on this device, and title of its detail dialog.
  ///
  /// In en, this message translates to:
  /// **'Local storage'**
  String get storageIndicatorName;

  /// Local storage status: it can be read.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get storageStatusAvailable;

  /// Local storage status: a check is running.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get storageStatusChecking;

  /// Local storage status: it could not be read.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get storageStatusUnavailable;

  /// Tooltip and accessible text of the storage indicator.
  ///
  /// In en, this message translates to:
  /// **'{name}: {status}'**
  String storageIndicatorTooltip(String name, String status);

  /// Status line of the storage detail dialog.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String storageDetailStatus(String status);

  /// Line of the storage detail dialog with when the storage last answered.
  ///
  /// In en, this message translates to:
  /// **'Last observed: {time}'**
  String storageDetailLastObserved(String time);

  /// Shown instead of a time when the storage has not answered yet.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get storageNeverObserved;

  /// Explains the storage detail dialog.
  ///
  /// In en, this message translates to:
  /// **'Where this device keeps contests and scores. When it is unavailable, changes cannot be saved.'**
  String get storageDetailNote;

  /// Line of the storage detail dialog with why the last check failed.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String storageDetailError(String error);

  /// Button of the storage detail dialog that checks the storage again.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get storageRetry;

  /// Button that closes the storage detail dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get storageDetailClose;

  /// Status bar sync entry before the engine has looked at the scope.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get syncStatusChecking;

  /// Status bar sync entry while a sync runs.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusSyncing;

  /// Status bar sync entry for data with no account behind it.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get syncStatusLocalOnly;

  /// Status bar sync entry before the first sync.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncStatusNotSynced;

  /// Status bar sync entry when the last sync worked and nothing needs the director.
  ///
  /// In en, this message translates to:
  /// **'Sync successful'**
  String get syncStatusSuccessful;

  /// Status bar sync entry when changes made here wait to be sent.
  ///
  /// In en, this message translates to:
  /// **'Changes pending'**
  String get syncStatusPending;

  /// Status bar sync entry when the last sync attempt failed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncStatusFailed;

  /// Status bar sync entry when a conflict waits for a decision.
  ///
  /// In en, this message translates to:
  /// **'Sync conflicts'**
  String get syncStatusConflicts;

  /// Status bar sync entry when the service refused changes.
  ///
  /// In en, this message translates to:
  /// **'Changes refused'**
  String get syncStatusRefused;

  /// Tooltip line of the status bar sync entry: when the scope last synced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String syncTooltipLastSynced(String time);

  /// Tooltip line of the status bar sync entry: changes not yet sent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to be sent} other{{count} changes waiting to be sent}}'**
  String syncTooltipPending(int count);

  /// Tooltip line of the status bar sync entry: refused changes and conflicts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change needs your attention} other{{count} changes need your attention}}'**
  String syncTooltipAttention(int count);

  /// Tooltip line of the status bar sync entry for data with no account behind it.
  ///
  /// In en, this message translates to:
  /// **'This data is only on this device and is not backed up.'**
  String get syncTooltipLocalOnly;

  /// Tooltip line of the status bar sync entry: what a click does.
  ///
  /// In en, this message translates to:
  /// **'Click to sync now'**
  String get syncTooltipAction;

  /// Status bar entry of the web app: the label that reloads the data on screen.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshStatusReady;

  /// Status bar refresh entry while it checks the service.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get refreshStatusRefreshing;

  /// Status bar refresh entry when the service could not be asked.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshStatusFailed;

  /// Tooltip line of the status bar refresh entry: when the data was last checked.
  ///
  /// In en, this message translates to:
  /// **'Last refreshed {time}'**
  String refreshTooltipLast(String time);

  /// Tooltip line of the status bar refresh entry: what a click does and that the page refreshes by itself.
  ///
  /// In en, this message translates to:
  /// **'Click to refresh now. The page also refreshes by itself every few minutes when something changed.'**
  String get refreshTooltipAction;

  /// Screen reader label of the status bar refresh entry.
  ///
  /// In en, this message translates to:
  /// **'Refresh: {status}'**
  String refreshSemanticsLabel(String status);

  /// Screen reader label of the status bar sync entry.
  ///
  /// In en, this message translates to:
  /// **'Sync: {status}'**
  String syncSemanticsLabel(String status);

  /// Title of the warning shown before an action that would lose changes that have not reached the service.
  ///
  /// In en, this message translates to:
  /// **'Changes have not synced'**
  String get unsyncedWarningTitle;

  /// Body of the unsynced-changes warning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change has} other{{count} changes have}} not been sent to the service. If you continue, {count, plural, =1{it} other{they}} cannot be recovered.'**
  String unsyncedWarningBody(int count);

  /// Button of the unsynced-changes warning that goes on with the action.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get unsyncedWarningContinue;

  /// Button of the unsynced-changes warning that stops the action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get unsyncedWarningCancel;

  /// Progress line under the Draw matrix button while a draw runs, with the percent done and which seed is being improved.
  ///
  /// In en, this message translates to:
  /// **'Drawing the matrix: {percent}% (seed {seed} of {seedCount})'**
  String drawProgress(int percent, int seed, int seedCount);

  /// Progress line shown before the server has reported any progress of a draw.
  ///
  /// In en, this message translates to:
  /// **'Starting the draw…'**
  String get drawProgressStarting;

  /// Hint beside the progress of a running draw.
  ///
  /// In en, this message translates to:
  /// **'You can cancel the draw. Nothing changes until it finishes.'**
  String get drawRunningNote;

  /// Button that stops a running matrix draw.
  ///
  /// In en, this message translates to:
  /// **'Cancel draw'**
  String get drawCancelButton;

  /// Label of the cancel button after it was pressed, until the draw stopped.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get drawCancelling;

  /// Snackbar shown after a matrix draw was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Draw cancelled. Nothing was changed.'**
  String get drawCancelled;

  /// Shown beside the Cancel button when stopping a matrix draw failed several times in a row.
  ///
  /// In en, this message translates to:
  /// **'Cancel could not reach the server. The draw is still running. Try Cancel again.'**
  String get drawCancelFailed;

  /// Button on the Matrix page that adds rounds after the last one.
  ///
  /// In en, this message translates to:
  /// **'Add rounds'**
  String get matrixAddRoundsButton;

  /// Button on the Matrix page that draws the rounds without scores again.
  ///
  /// In en, this message translates to:
  /// **'Redraw unscored rounds'**
  String get matrixRedrawButton;

  /// Why adding or redrawing rounds is off while the contest is locked.
  ///
  /// In en, this message translates to:
  /// **'Administration is locked. Unlock the contest to add or redraw rounds.'**
  String get matrixActionLocked;

  /// Why adding or redrawing rounds is off before the first draw or after completion.
  ///
  /// In en, this message translates to:
  /// **'Rounds can be added or redrawn from the first draw until the contest is complete.'**
  String get matrixActionNotEditable;

  /// Why Redraw unscored rounds is off when every round has a score.
  ///
  /// In en, this message translates to:
  /// **'Every round has scores, so there is nothing to redraw.'**
  String get matrixRedrawAllScored;

  /// Why Redraw unscored rounds is off when a round to replace is locked.
  ///
  /// In en, this message translates to:
  /// **'Round {round} is locked. Unlock it before redrawing.'**
  String matrixRedrawRoundLocked(int round);

  /// Why Redraw unscored rounds is off when a group to replace is locked.
  ///
  /// In en, this message translates to:
  /// **'A group of round {round} is locked. Unlock it before redrawing.'**
  String matrixRedrawGroupLocked(int round);

  /// Heading of the form that adds rounds.
  ///
  /// In en, this message translates to:
  /// **'Add rounds'**
  String get matrixAddTitle;

  /// Intro of the add rounds form.
  ///
  /// In en, this message translates to:
  /// **'The new rounds continue after round {last}. Pilots who already met are kept apart as in the first draw, and the fairness summary counts every round. Retired pilots are not drawn.'**
  String matrixAddIntro(int last);

  /// Heading of the form that redraws the rounds without scores.
  ///
  /// In en, this message translates to:
  /// **'Redraw unscored rounds'**
  String get matrixRedrawTitle;

  /// Intro of the redraw form.
  ///
  /// In en, this message translates to:
  /// **'Replaces the unscored {span}. Earlier rounds stay as they are and count toward who has met whom. Retired pilots are not drawn. Each redraw uses a new random seed unless you set one under Advanced.'**
  String matrixRedrawIntro(String span);

  /// Label of the rounds field when adding rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds to add'**
  String get matrixRoundsToAdd;

  /// Label of the rounds field when redrawing.
  ///
  /// In en, this message translates to:
  /// **'Rounds to draw'**
  String get matrixRoundsToDraw;

  /// Note under the rounds field of the add rounds form.
  ///
  /// In en, this message translates to:
  /// **'Draws {span}.'**
  String matrixAddRoundsNote(String span);

  /// Note under the rounds field of the redraw form.
  ///
  /// In en, this message translates to:
  /// **'Draws {span} in place of the unscored rounds.'**
  String matrixRedrawRoundsNote(String span);

  /// Note under the rounds field of the redraw form when fewer rounds are drawn than replaced; removed names the rounds that go.
  ///
  /// In en, this message translates to:
  /// **'Draws {span}. {removed} will be removed.'**
  String matrixRedrawRoundsRemoved(String span, String removed);

  /// Note under the groups field when it is filled from the current matrix.
  ///
  /// In en, this message translates to:
  /// **'From round {round} of the current matrix.'**
  String matrixGroupsFromRound(int round);

  /// Label of the optional reason field of the add rounds and redraw forms.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get matrixReasonLabel;

  /// Hint of the reason field.
  ///
  /// In en, this message translates to:
  /// **'Kept in the matrix history'**
  String get matrixReasonHint;

  /// Button that leaves the add rounds or redraw form.
  ///
  /// In en, this message translates to:
  /// **'Back to matrix'**
  String get matrixBackToMatrix;

  /// Submit button of the add rounds form.
  ///
  /// In en, this message translates to:
  /// **'Add rounds'**
  String get matrixAddAction;

  /// Submit button of the add rounds form while it works.
  ///
  /// In en, this message translates to:
  /// **'Adding rounds…'**
  String get matrixAddActionBusy;

  /// Submit button of the redraw form.
  ///
  /// In en, this message translates to:
  /// **'Redraw rounds'**
  String get matrixRedrawAction;

  /// Submit button of the redraw form while it works.
  ///
  /// In en, this message translates to:
  /// **'Redrawing rounds…'**
  String get matrixRedrawActionBusy;

  /// Title of the confirmation before rounds are added.
  ///
  /// In en, this message translates to:
  /// **'Add rounds?'**
  String get matrixAddConfirmTitle;

  /// Title of the confirmation before rounds are redrawn.
  ///
  /// In en, this message translates to:
  /// **'Redraw unscored rounds?'**
  String get matrixRedrawConfirmTitle;

  /// Confirmation line naming the rounds that are added.
  ///
  /// In en, this message translates to:
  /// **'Adds {span}'**
  String matrixConfirmAdds(String span);

  /// Confirmation line naming the rounds that are replaced.
  ///
  /// In en, this message translates to:
  /// **'Redraws {span}'**
  String matrixConfirmReplaces(String span);

  /// Confirmation line with the revision of the matrix that is changed.
  ///
  /// In en, this message translates to:
  /// **'Current matrix revision {revision}'**
  String matrixConfirmRevision(int revision);

  /// Warning in the add rounds confirmation.
  ///
  /// In en, this message translates to:
  /// **'Rounds can be added again later. The new rounds can be redrawn until they have scores.'**
  String get matrixConfirmAddNote;

  /// Warning in the redraw confirmation.
  ///
  /// In en, this message translates to:
  /// **'The replaced rounds can’t be restored. Rounds with scores are not touched.'**
  String get matrixConfirmRedrawNote;

  /// Snackbar after rounds were added.
  ///
  /// In en, this message translates to:
  /// **'Rounds added.'**
  String get matrixRoundsAdded;

  /// Snackbar after rounds were redrawn.
  ///
  /// In en, this message translates to:
  /// **'Rounds redrawn.'**
  String get matrixRoundsRedrawn;

  /// Body of the banner when the server could not be reached while adding or redrawing rounds.
  ///
  /// In en, this message translates to:
  /// **'The matrix wasn’t changed and the page hasn’t changed. Your values are kept.'**
  String get matrixRoundsNetworkFailure;

  /// Title of the banner when the server refused to add or redraw rounds.
  ///
  /// In en, this message translates to:
  /// **'The server did not change the matrix'**
  String get matrixRoundsRejected;

  /// Body of the banner when adding or redrawing rounds met a newer matrix.
  ///
  /// In en, this message translates to:
  /// **'The matrix changed on the server. Reload to see the current state. Your values stay until you reload.'**
  String get matrixRoundsConflict;

  /// Seeded contests: status line when the preliminary scores are complete.
  ///
  /// In en, this message translates to:
  /// **'Seeded Man on Man: {rounds} preliminary rounds, all scored. A seeded round also needs official scores and current standings; the server checks this when you draw.'**
  String matrixSeededStatusDone(int rounds);

  /// Seeded contests: status line when preliminary scores are missing.
  ///
  /// In en, this message translates to:
  /// **'Seeded Man on Man: {rounds} preliminary rounds, {missing} flights still need a score. A seeded round can be drawn once they are official.'**
  String matrixSeededStatusWaiting(int rounds, int missing);

  /// Error when more than one seeded round is asked for.
  ///
  /// In en, this message translates to:
  /// **'Seeded rounds are drawn one at a time.'**
  String get matrixSeededOneRound;

  /// Body of the banner that says the contest configuration changed since the draw.
  ///
  /// In en, this message translates to:
  /// **'{differences} The matrix is unchanged. Redraw the unscored rounds to apply these changes; rounds with scores keep their draw.'**
  String matrixDriftBanner(String differences);

  /// Body of the configuration-changed banner when redrawing is not possible.
  ///
  /// In en, this message translates to:
  /// **'{differences} The matrix is unchanged. {reason}'**
  String matrixDriftBannerBlocked(String differences, String reason);

  /// A round or a run of rounds, in the middle of a sentence.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{round {first}} other{rounds {first} to {last}}}'**
  String matrixRoundSpan(int count, int first, int last);

  /// Confirmation line with the number of pilots who are drawn.
  ///
  /// In en, this message translates to:
  /// **'{count} scoring pilots'**
  String matrixConfirmPilots(int count);

  /// Confirmation line with the groups of each drawn round and their sizes.
  ///
  /// In en, this message translates to:
  /// **'{groups} groups per round ({sizes} pilots)'**
  String matrixConfirmGroups(int groups, String sizes);

  /// Confirmation line with the configuration revision; revision is a number or a dash.
  ///
  /// In en, this message translates to:
  /// **'Configuration revision {revision}'**
  String matrixConfirmConfiguration(String revision);

  /// Button that closes the add rounds or redraw confirmation without changing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get matrixConfirmCancel;

  /// Email cell of a participant row: the profile has an email address.
  ///
  /// In en, this message translates to:
  /// **'Has email'**
  String get participantEmailHas;

  /// Tooltip for the Has email status.
  ///
  /// In en, this message translates to:
  /// **'Email on the profile'**
  String get participantEmailHasExplanation;

  /// Email cell of a participant row: the profile has no email address.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get participantEmailNone;

  /// Tooltip for the None email status.
  ///
  /// In en, this message translates to:
  /// **'No email on the profile'**
  String get participantEmailNoneExplanation;

  /// Email cell of a participant row: the person has not allowed their email to be shown.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get participantEmailPrivate;

  /// Tooltip for the Private email status.
  ///
  /// In en, this message translates to:
  /// **'This person hasn’t allowed their email to be shown.'**
  String get participantEmailPrivateExplanation;

  /// Heading of the workspace card that lists the latest events of the contest.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get activityHeading;

  /// Button on the Recent activity card that opens the full activity page.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get activityViewAll;

  /// Recent activity card text when the contest has no events.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened yet'**
  String get activityEmpty;

  /// Recent activity card text while the events load.
  ///
  /// In en, this message translates to:
  /// **'Loading recent activity…'**
  String get activityLoading;

  /// Recent activity card text when reading the events failed.
  ///
  /// In en, this message translates to:
  /// **'Recent activity could not be loaded.'**
  String get activityFailed;

  /// Button on the Recent activity card that reads the events again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get activityRetry;

  /// Text under the heading of the Activity page.
  ///
  /// In en, this message translates to:
  /// **'Everything the contest\'s directors did, newest first. Times are in the contest\'s time zone.'**
  String get activityPageIntro;

  /// Label of the filter on the Activity page that narrows the list to one kind of event.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get activityFilterLabel;

  /// Activity page filter: every kind of event.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get activityFilterAll;

  /// Activity page filter: contest actions (scoring opened or closed, lock, complete) and pilot retirements.
  ///
  /// In en, this message translates to:
  /// **'Contest and pilots'**
  String get activityFilterContest;

  /// Activity page filter: corrections of official scores.
  ///
  /// In en, this message translates to:
  /// **'Score corrections'**
  String get activityFilterScores;

  /// Activity page filter: saved contest configurations.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get activityFilterConfiguration;

  /// Activity page filter: matrix draws.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get activityFilterMatrix;

  /// Activity page filter: published results.
  ///
  /// In en, this message translates to:
  /// **'Publication'**
  String get activityFilterPublication;

  /// Activity page text while the first events load.
  ///
  /// In en, this message translates to:
  /// **'Loading activity…'**
  String get activityPageLoading;

  /// Activity page title when the contest has no events.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened yet'**
  String get activityPageEmpty;

  /// Activity page title when the chosen filter matches no events.
  ///
  /// In en, this message translates to:
  /// **'No activity of this kind'**
  String get activityPageEmptyFiltered;

  /// Activity page text under the title when the chosen filter matches no events.
  ///
  /// In en, this message translates to:
  /// **'Choose another kind, or show everything.'**
  String get activityPageEmptyFilteredBody;

  /// Button on the Activity page that clears the filter.
  ///
  /// In en, this message translates to:
  /// **'Show everything'**
  String get activityPageShowEverything;

  /// Activity page title when reading the events failed.
  ///
  /// In en, this message translates to:
  /// **'Activity could not be loaded'**
  String get activityPageFailed;

  /// Text under the Activity list when reading the next page of events failed.
  ///
  /// In en, this message translates to:
  /// **'More activity could not be loaded.'**
  String get activityPageMoreFailed;

  /// Banner on the Activity page when the device has no internet connection.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing what was loaded; Retry works once you are back online.'**
  String get activityPageOffline;

  /// Banner on the Activity page when the server that publishes results did not answer; the rest of the list is shown. Retry reads the list again.
  ///
  /// In en, this message translates to:
  /// **'Published results could not be loaded, so publications may be missing from this list.'**
  String get activityPageIncomplete;

  /// Button under the Activity list that reads the next page of events.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get activityPageLoadMore;

  /// Text under the last page of the Activity list.
  ///
  /// In en, this message translates to:
  /// **'That is everything'**
  String get activityPageEnd;

  /// Activity page title when the contest does not exist.
  ///
  /// In en, this message translates to:
  /// **'This contest was not found'**
  String get activityPageNotFound;

  /// Activity page: the acting account is the signed-in one. Shown beside the time.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get activityActorYou;

  /// Activity page: the system acted, not an account. Shown beside the time.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get activityActorSystem;

  /// Activity page: another account acted. id is the last characters of its account id, since the audit trail holds no name. Shown beside the time.
  ///
  /// In en, this message translates to:
  /// **'Account {id}'**
  String activityActorAccount(String id);

  /// Recent activity line: the contest was completed. actor is "you" when the signed-in account did it.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You completed the contest. Participant scoring closed.} other{The contest was completed. Participant scoring closed.}}'**
  String activityComplete(String actor);

  /// Recent activity line: participant scoring was opened.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You opened participant scoring} other{Participant scoring was opened}}'**
  String activityOpenScoring(String actor);

  /// Recent activity line: participant scoring was closed.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You closed participant scoring} other{Participant scoring was closed}}'**
  String activityCloseScoring(String actor);

  /// Recent activity line: administration was locked.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You locked administration} other{Administration was locked}}'**
  String activityLock(String actor);

  /// Recent activity line: administration was unlocked.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You unlocked administration} other{Administration was unlocked}}'**
  String activityUnlock(String actor);

  /// Recent activity line: the contest was published or its publication changed.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You updated the published results} other{The published results were updated}}'**
  String activityPublication(String actor);

  /// Recent activity line: a configuration revision was saved.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You saved the contest configuration} other{The contest configuration was saved}}'**
  String activityConfigurationSaved(String actor);

  /// Recent activity line: the matrix was drawn or redrawn.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You drew the matrix} other{The matrix was drawn}}'**
  String activityMatrixDrawn(String actor);

  /// Recent activity line: a director corrected an official score. actor is "you" when the signed-in account did it; pilot is the participant number, or "none" when the event names none.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You corrected a score for {pilot, select, none{a pilot} other{pilot {pilot}}} in round {round}} other{A score was corrected for {pilot, select, none{a pilot} other{pilot {pilot}}} in round {round}}}'**
  String activityScoreCorrected(String actor, String pilot, int round);

  /// Recent activity line: a pilot was retired from a round on. actor is "you" when the signed-in account did it; pilot is the participant number, or "none" when the event names none.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You retired {pilot, select, none{a pilot} other{pilot {pilot}}} from round {round}} other{{pilot, select, none{A pilot} other{Pilot {pilot}}} was retired from round {round}}}'**
  String activityPilotRetired(String actor, String pilot, int round);

  /// Recent activity line: a retired pilot was reinstated. actor is "you" when the signed-in account did it; pilot is the participant number, or "none" when the event names none.
  ///
  /// In en, this message translates to:
  /// **'{actor, select, you{You reinstated {pilot, select, none{a pilot} other{pilot {pilot}}}} other{{pilot, select, none{A pilot} other{Pilot {pilot}}} was reinstated}}'**
  String activityPilotReinstated(String actor, String pilot);

  /// Navigation rail destination, page title and breadcrumb: main page.
  ///
  /// In en, this message translates to:
  /// **'Contests'**
  String get shellNavContests;

  /// Navigation rail destination, page title and breadcrumb: main page and contest.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get shellNavParticipants;

  /// Navigation rail destination, page title and breadcrumb: main page.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get shellNavRoles;

  /// Navigation rail destination, page title and breadcrumb: main page.
  ///
  /// In en, this message translates to:
  /// **'Landings'**
  String get shellNavLandings;

  /// Navigation rail destination, page title and breadcrumb: contest.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get shellNavWorkspace;

  /// Navigation rail destination, page title and breadcrumb: contest.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get shellNavConfiguration;

  /// Navigation rail destination, page title and breadcrumb: contest.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get shellNavMatrix;

  /// Navigation rail destination, page title and breadcrumb: contest.
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get shellNavScoring;

  /// Navigation rail destination, page title and breadcrumb: contest.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get shellNavReports;

  /// Navigation rail destination, page title and breadcrumb: the contest's full activity list.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get shellNavActivity;

  /// Navigation rail destination, page title and breadcrumb: contest, native builds.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get shellNavSync;

  /// Navigation rail destination, page title and breadcrumb: breadcrumb and title of the Settings page and the account menu item.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shellNavSettings;

  /// Button on the rail while on a participant page.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get shellAddParticipant;

  /// Button on the rail while on the Landings page.
  ///
  /// In en, this message translates to:
  /// **'New landing'**
  String get shellNewLanding;

  /// Button on the rail while on the Roles page.
  ///
  /// In en, this message translates to:
  /// **'New role'**
  String get shellNewRole;

  /// Button that opens the New Contest wizard before a draft exists.
  ///
  /// In en, this message translates to:
  /// **'Create contest'**
  String get createContestLabel;

  /// Button that returns to the New Contest wizard while a draft is underway.
  ///
  /// In en, this message translates to:
  /// **'Continue configuration'**
  String get continueConfigurationLabel;

  /// Tooltip of the rail button that narrows the navigation rail.
  ///
  /// In en, this message translates to:
  /// **'Collapse navigation'**
  String get shellCollapseNav;

  /// Tooltip of the rail button that widens the navigation rail.
  ///
  /// In en, this message translates to:
  /// **'Expand navigation'**
  String get shellExpandNav;

  /// Last breadcrumb and page title on a page that creates a participant or landing.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get shellCrumbNew;

  /// Last breadcrumb and page title on the participant editor.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get shellCrumbEdit;

  /// Last breadcrumb and page title of the New Contest wizard.
  ///
  /// In en, this message translates to:
  /// **'New contest'**
  String get shellCrumbNewContest;

  /// Stands in for the contest name in the header until it has loaded.
  ///
  /// In en, this message translates to:
  /// **'Contest'**
  String get shellContestFallback;

  /// Tooltip of the account menu when working offline.
  ///
  /// In en, this message translates to:
  /// **'Settings and sign in'**
  String get shellAccountSettingsAndSignIn;

  /// Account menu item that returns to the sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get shellSignIn;

  /// Account menu item that ends the session.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get shellSignOut;

  /// Shown as the account name when the identity provider gives none.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get shellSignedIn;

  /// Tooltip of the account menu while signed in.
  ///
  /// In en, this message translates to:
  /// **'Account: {name}'**
  String shellAccountTooltip(String name);

  /// Accessible name of the account picture.
  ///
  /// In en, this message translates to:
  /// **'Account menu'**
  String get shellAccountMenu;

  /// Explains a page that is only a placeholder.
  ///
  /// In en, this message translates to:
  /// **'This page has not been built yet. Please check back soon.'**
  String get shellNotBuiltDetail;

  /// Accessible name of the contest status panel.
  ///
  /// In en, this message translates to:
  /// **'Contest status'**
  String get shellStatusPanelLabel;

  /// Label of the lifecycle state in the contest status panel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get shellStatusLifecycle;

  /// Label of the participant scoring state in the contest status panel.
  ///
  /// In en, this message translates to:
  /// **'Participant scoring'**
  String get shellStatusScoring;

  /// Label of the administration lock state in the contest status panel.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get shellStatusAdministration;

  /// Participant scoring is open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get shellScoringOpen;

  /// Participant scoring is closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get shellScoringClosed;

  /// Administration is locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get shellAdminLocked;

  /// Administration is unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get shellAdminUnlocked;

  /// Accessible name of a button in the contest status panel; target names the control it opens.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}. {target, select, lifecycle{Go to the status control} scoring{Go to the participant scoring control} administration{Go to the administration control} other{Go to the control}}'**
  String shellStatusSemantics(String label, String value, String target);

  /// Contest lifecycle state "created".
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get lifecycleCreated;

  /// Contest lifecycle state "configuring".
  ///
  /// In en, this message translates to:
  /// **'Configuring'**
  String get lifecycleConfiguring;

  /// Contest lifecycle state "ready".
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get lifecycleReady;

  /// Contest lifecycle state "running".
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get lifecycleRunning;

  /// Contest lifecycle state "completed".
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lifecycleCompleted;

  /// Window or browser tab title while a contest is selected; app is the application name.
  ///
  /// In en, this message translates to:
  /// **'{app}: {contest}'**
  String windowTitleContest(String app, String contest);

  /// Heading of the contest list.
  ///
  /// In en, this message translates to:
  /// **'Contests'**
  String get contestListHeading;

  /// Number of contests beside the list heading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contest} other{{count} contests}}'**
  String contestListCount(int count);

  /// Start and end dates of a contest that spans days.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String contestDateRange(String start, String end);

  /// Title of the error shown when the contest list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Contests could not be loaded.'**
  String get contestsLoadFailed;

  /// Accessible name of the loading indicator on the main page.
  ///
  /// In en, this message translates to:
  /// **'Loading contests'**
  String get contestsLoading;

  /// Shown on the main page when there are no contests.
  ///
  /// In en, this message translates to:
  /// **'No contests yet.'**
  String get contestsEmpty;

  /// Shown in the Models cell of a pilot who has no models. A notice only: the contest goes ahead without models.
  ///
  /// In en, this message translates to:
  /// **'No models entered'**
  String get modelsCellNone;

  /// Tooltip on the notice that a pilot has no models.
  ///
  /// In en, this message translates to:
  /// **'A pilot without a model is fine. Add models any time.'**
  String get modelsCellNoneTooltip;

  /// Tooltip and accessible name of the button that opens a pilot's models.
  ///
  /// In en, this message translates to:
  /// **'Edit models for {name}'**
  String modelsEditTooltip(String name);

  /// Title of the window where a pilot's models are added, edited and removed.
  ///
  /// In en, this message translates to:
  /// **'Models for {name}'**
  String modelsDialogTitle(String name);

  /// Shown in the models window when the pilot has no models.
  ///
  /// In en, this message translates to:
  /// **'No models yet. The contest can go ahead without them.'**
  String get modelsDialogEmpty;

  /// Label of the menu that picks a model the person already has on their profile.
  ///
  /// In en, this message translates to:
  /// **'Pick one of their models'**
  String get modelsPickLabel;

  /// Hint under the profile model menu.
  ///
  /// In en, this message translates to:
  /// **'Or type a new one below'**
  String get modelsPickHint;

  /// Label of the required model name field.
  ///
  /// In en, this message translates to:
  /// **'Model name *'**
  String get modelsFieldName;

  /// Label of the optional model manufacturer field.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get modelsFieldManufacturer;

  /// Label of the optional field for the identifier the pilot put on the model.
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get modelsFieldModelId;

  /// Helper text under the Model ID field.
  ///
  /// In en, this message translates to:
  /// **'The marking the pilot put on the model'**
  String get modelsFieldModelIdHelper;

  /// Label of the optional field for the identifier the director applied for this contest.
  ///
  /// In en, this message translates to:
  /// **'Contest identifier'**
  String get modelsFieldContestId;

  /// Helper text under the Contest identifier field.
  ///
  /// In en, this message translates to:
  /// **'Applied by you for this contest, such as a serial number'**
  String get modelsFieldContestIdHelper;

  /// Button that opens the form to add a model.
  ///
  /// In en, this message translates to:
  /// **'Add a model'**
  String get modelsAddButton;

  /// Button that adds the model in the form.
  ///
  /// In en, this message translates to:
  /// **'Add model'**
  String get modelsSaveAdd;

  /// Button that saves changes to the model in the form.
  ///
  /// In en, this message translates to:
  /// **'Save model'**
  String get modelsSaveEdit;

  /// Button that closes the model form without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get modelsFormCancel;

  /// Button that closes the models window.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get modelsDone;

  /// Tooltip of the button that edits one model.
  ///
  /// In en, this message translates to:
  /// **'Edit {model}'**
  String modelsEditEntry(String model);

  /// Tooltip of the button that removes one model.
  ///
  /// In en, this message translates to:
  /// **'Remove {model}'**
  String modelsRemoveEntry(String model);

  /// Error under the model name field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a model name.'**
  String get modelsNameRequired;

  /// Warning in the model form when the model matches one the pilot already has.
  ///
  /// In en, this message translates to:
  /// **'This pilot already has a model with the same name, manufacturer and ID.'**
  String get modelsDuplicate;

  /// Shown when a model change is refused because the model changed since it was read.
  ///
  /// In en, this message translates to:
  /// **'This pilot\'s models were changed elsewhere. Close this window to refresh them, then try again.'**
  String get modelsStale;

  /// Shown when saving a model fails.
  ///
  /// In en, this message translates to:
  /// **'The model could not be saved. {error}'**
  String modelsSaveFailed(String error);

  /// Detail line of a model: the identifier the pilot put on it.
  ///
  /// In en, this message translates to:
  /// **'ID {value}'**
  String modelsDetailModelId(String value);

  /// Detail line of a model: the identifier the director applied for this contest.
  ///
  /// In en, this message translates to:
  /// **'Contest {value}'**
  String modelsDetailContestId(String value);

  /// Models cell of a pilot with several models: how many.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 model} other{{count} models}}'**
  String modelsCellCount(int count);

  /// Warning in the models form when the pilot's saved models could not be read, as opposed to there being none.
  ///
  /// In en, this message translates to:
  /// **'Their saved models could not be loaded. You can still type a model.'**
  String get modelsProfileUnavailable;

  /// Button that tries again to load the pilot's saved models.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get modelsProfileRetry;

  /// Tooltip of the menu button on the highlighted pilot in the matrix grid.
  ///
  /// In en, this message translates to:
  /// **'Pilot actions'**
  String get matrixPilotActions;

  /// Menu item and accessibility action that moves a pilot to another group.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get matrixMoveMenu;

  /// Why moving a pilot is off while the contest is locked.
  ///
  /// In en, this message translates to:
  /// **'Administration is locked. Unlock the contest to move a pilot.'**
  String get matrixMoveLocked;

  /// Why moving a pilot is off before the first draw or after completion.
  ///
  /// In en, this message translates to:
  /// **'Pilots can be moved once the matrix is drawn and until the contest is complete.'**
  String get matrixMoveNotEditable;

  /// Title of the dialog that moves a pilot.
  ///
  /// In en, this message translates to:
  /// **'Move {name}'**
  String matrixMoveTitle(String name);

  /// Where the pilot flies now, in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Now flying round {round}, group {group}.'**
  String matrixMoveFrom(int round, String group);

  /// Where the pilot flies now when the contest has lanes, in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Now flying round {round}, group {group}, lane {lane}.'**
  String matrixMoveFromLane(int round, String group, int lane);

  /// Warning in the move dialog when the pilot's flight has a score.
  ///
  /// In en, this message translates to:
  /// **'This flight has a score. Moving the pilot discards it: the score stays in the history as a reset and no longer counts. This is not the standard way to correct a flight, so check that you want this before you continue.'**
  String get matrixMoveScoredWarning;

  /// Why a pilot cannot be moved out of a locked group.
  ///
  /// In en, this message translates to:
  /// **'The pilot\'s group is locked. Unlock the group before moving the pilot.'**
  String get matrixMoveSourceGroupLocked;

  /// Why a pilot with a locked score cannot be moved.
  ///
  /// In en, this message translates to:
  /// **'The pilot\'s score is locked. Unlock the score before moving the pilot.'**
  String get matrixMoveSourceScoreLocked;

  /// Label of the round picker in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get matrixMoveRound;

  /// One round in the move dialog's round picker.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String matrixMoveRoundOption(int round);

  /// Heading of the group list in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Move to group'**
  String get matrixMoveGroupHeading;

  /// One group in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Group {group}'**
  String matrixMoveGroupLabel(String group);

  /// Mark on a group that is a good place to move a pilot to.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get matrixMoveRecommended;

  /// Mark on a group that is allowed but a poor place to move a pilot to.
  ///
  /// In en, this message translates to:
  /// **'Not ideal'**
  String get matrixMoveNotIdeal;

  /// Why a group is not ideal as a move target.
  ///
  /// In en, this message translates to:
  /// **'Pilots in this group already have scores.'**
  String get matrixMoveReasonHasScores;

  /// Why a group is not ideal as a move target.
  ///
  /// In en, this message translates to:
  /// **'This round appears to be completed.'**
  String get matrixMoveReasonRoundCompleted;

  /// Why a group is not ideal as a move target.
  ///
  /// In en, this message translates to:
  /// **'A teammate flies in this group.'**
  String get matrixMoveReasonTeammate;

  /// Why the pilot's current group cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'The pilot flies in this group now.'**
  String get matrixMoveBlockCurrent;

  /// Why a group the pilot is already part of cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'The pilot already flies in this group in round {round}.'**
  String matrixMoveBlockAlready(int round);

  /// Why a locked group cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'This group is locked. Unlock the group first.'**
  String get matrixMoveBlockGroupLocked;

  /// Why a group of a locked round cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'This round is locked. Unlock the round first.'**
  String get matrixMoveBlockRoundLocked;

  /// Why a group with a teammate cannot be chosen when team protection is on.
  ///
  /// In en, this message translates to:
  /// **'Team protection is on and a teammate flies in this group.'**
  String get matrixMoveBlockTeam;

  /// Label of the lane picker in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Lane'**
  String get matrixMoveLane;

  /// One free lane in the lane picker.
  ///
  /// In en, this message translates to:
  /// **'Lane {lane}'**
  String matrixMoveLaneFree(int lane);

  /// One taken lane in the lane picker.
  ///
  /// In en, this message translates to:
  /// **'Lane {lane}, taken by {name}'**
  String matrixMoveLaneTaken(int lane, String name);

  /// Label of the reason field in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get matrixMoveReasonLabel;

  /// Help under the reason field in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Required. Kept with the move in the history.'**
  String get matrixMoveReasonHelp;

  /// Error when the move reason is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason.'**
  String get matrixMoveReasonRequired;

  /// Error when no group is chosen in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose a group to move the pilot to.'**
  String get matrixMoveGroupRequired;

  /// Error when no lane is chosen in the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose a lane.'**
  String get matrixMoveLaneRequired;

  /// Button that closes the move dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get matrixMoveCancel;

  /// Button that moves the pilot.
  ///
  /// In en, this message translates to:
  /// **'Move pilot'**
  String get matrixMoveConfirm;

  /// Button that moves a pilot whose flight has a score.
  ///
  /// In en, this message translates to:
  /// **'Discard score and move'**
  String get matrixMoveConfirmDiscard;

  /// Shown on the button while the move is sent.
  ///
  /// In en, this message translates to:
  /// **'Moving…'**
  String get matrixMoveWorking;

  /// Shown in the move dialog when the server cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Soar Score can\'t reach the server. Nothing was moved. Try again.'**
  String get matrixMoveNetwork;

  /// Shown in the move dialog when the server says the matrix changed.
  ///
  /// In en, this message translates to:
  /// **'The matrix or the contest changed since this page loaded. Nothing was moved. Reload to see the current matrix.'**
  String get matrixMoveChanged;

  /// Button that reloads the matrix after a move was refused because it changed.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get matrixMoveReload;

  /// Snackbar when the scores could not be read before a move.
  ///
  /// In en, this message translates to:
  /// **'The scores could not be checked, so the pilot was not moved. {error}'**
  String matrixMoveScoresFailed(String error);

  /// Snackbar after a pilot was moved.
  ///
  /// In en, this message translates to:
  /// **'{name} moved.'**
  String matrixPilotMoved(String name);

  /// Label on a pilot in the grid whom a director moved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get matrixMovedLabel;

  /// Heading in the pilot panel of the moves of the pilot.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get matrixMovedHeading;

  /// One move of the pilot in the pilot panel, with the reason.
  ///
  /// In en, this message translates to:
  /// **'Round {round}: {reason}'**
  String matrixMovedLine(int round, String reason);

  /// Why a retired pilot cannot be moved.
  ///
  /// In en, this message translates to:
  /// **'This pilot has retired and cannot be moved.'**
  String get matrixMoveSourceRetired;

  /// Snackbar while the scores are read before the move dialog opens.
  ///
  /// In en, this message translates to:
  /// **'Checking scores…'**
  String get matrixMoveChecking;

  /// Text while the matrix loads.
  ///
  /// In en, this message translates to:
  /// **'Loading matrix…'**
  String get matrixLoading;

  /// Semantics label while the matrix loads.
  ///
  /// In en, this message translates to:
  /// **'Loading matrix'**
  String get matrixLoadingLabel;

  /// Title of the load-failure state.
  ///
  /// In en, this message translates to:
  /// **'The matrix could not be loaded.'**
  String get matrixLoadFailed;

  /// Title of the offline state.
  ///
  /// In en, this message translates to:
  /// **'Matrix unavailable'**
  String get matrixUnavailableTitle;

  /// Body of the offline state.
  ///
  /// In en, this message translates to:
  /// **'Soar Score can’t reach the server, so the matrix can’t be shown. Nothing on this contest has changed.'**
  String get matrixUnavailableBody;

  /// Snackbar after the first draw.
  ///
  /// In en, this message translates to:
  /// **'Matrix drawn.'**
  String get matrixDrawn;

  /// Where the configured rounds came from.
  ///
  /// In en, this message translates to:
  /// **'contest configuration'**
  String get matrixSourceConfiguration;

  /// Where the configured groups came from.
  ///
  /// In en, this message translates to:
  /// **'the New Contest wizard'**
  String get matrixSourceWizard;

  /// Label of the rounds field for a seeded draw.
  ///
  /// In en, this message translates to:
  /// **'Preliminary seeded rounds'**
  String get matrixSeededRoundsLabel;

  /// Label of the rounds field.
  ///
  /// In en, this message translates to:
  /// **'Number of rounds'**
  String get matrixRoundsLabel;

  /// Label of the groups field.
  ///
  /// In en, this message translates to:
  /// **'Groups per round'**
  String get matrixGroupsLabel;

  /// One problem in the draw error list.
  ///
  /// In en, this message translates to:
  /// **'Groups per round: {error}'**
  String matrixGroupsErrorLabel(String error);

  /// Note when the configuration holds no value for a field.
  ///
  /// In en, this message translates to:
  /// **'Contest configuration has no value. Enter one here, or set it in Configuration.'**
  String get matrixNoteNoValue;

  /// Note naming where a field value came from.
  ///
  /// In en, this message translates to:
  /// **'From {source}: {text}'**
  String matrixNoteFrom(String source, String text);

  /// Note when a field differs from the suggested value.
  ///
  /// In en, this message translates to:
  /// **'Differs from the suggested value ({configured}). Changing it here doesn’t change the contest configuration.'**
  String matrixNoteEdited(int configured);

  /// Rounds value text for a seeded draw.
  ///
  /// In en, this message translates to:
  /// **'{count} preliminary seeded rounds'**
  String matrixSeededRoundsText(int count);

  /// Rounds value text.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String matrixRoundsText(int count);

  /// Groups value text.
  ///
  /// In en, this message translates to:
  /// **'{count} groups per round'**
  String matrixGroupsText(int count);

  /// Reset action label of a draw number field.
  ///
  /// In en, this message translates to:
  /// **'Reset to {value}'**
  String matrixResetTo(String value);

  /// Chip on a field that differs from its configured value.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get matrixEdited;

  /// Action to open the configuration page from a draw field.
  ///
  /// In en, this message translates to:
  /// **'Open Configuration'**
  String get matrixOpenConfiguration;

  /// Fallback reset label of a draw number field.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get matrixReset;

  /// Title of the first-draw card.
  ///
  /// In en, this message translates to:
  /// **'No matrix drawn yet'**
  String get matrixNoMatrixTitle;

  /// Intro of the first-draw card.
  ///
  /// In en, this message translates to:
  /// **'No flight matrix has been drawn for this contest. Draw the first matrix here; afterwards you can add rounds and redraw the rounds without scores.'**
  String get matrixNoMatrixIntro;

  /// Heading of the first-draw form.
  ///
  /// In en, this message translates to:
  /// **'Draw the first matrix'**
  String get matrixDrawFirstTitle;

  /// Title of the draw-error list after a server rejection.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the draw'**
  String get matrixServerRejected;

  /// Title of the draw-error list when fields must be fixed.
  ///
  /// In en, this message translates to:
  /// **'Fix {count} field{plural} before drawing'**
  String matrixFixFields(int count, String plural);

  /// Body of the draw-error list.
  ///
  /// In en, this message translates to:
  /// **'Your values are kept. Nothing was drawn.'**
  String get matrixErrorsKept;

  /// Title of the network-failure banner.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach the server'**
  String get matrixNetworkTitle;

  /// Body of the network-failure banner for the first draw.
  ///
  /// In en, this message translates to:
  /// **'The matrix wasn’t drawn and the page hasn’t changed. Your values are kept.'**
  String get matrixNetworkFirstBody;

  /// Action of the network-failure banner.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get matrixTryAgain;

  /// Title of the conflict banner.
  ///
  /// In en, this message translates to:
  /// **'This contest changed on the server'**
  String get matrixConflictTitle;

  /// Body of the conflict banner for the first draw.
  ///
  /// In en, this message translates to:
  /// **'A matrix has already been drawn for this contest, or the contest can no longer be drawn. Reload to see the current state. Your values stay until you reload.'**
  String get matrixConflictFirstBody;

  /// Action of the conflict banner.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get matrixReload;

  /// Reason the draw button is off while there is a conflict.
  ///
  /// In en, this message translates to:
  /// **'Reload the contest before drawing.'**
  String get matrixActionReload;

  /// Semantics label of a link to Configuration.
  ///
  /// In en, this message translates to:
  /// **'Change {label} in Configuration'**
  String matrixChangeInConfig(String label);

  /// Visible label of a link to Configuration.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get matrixChange;

  /// Title of the advanced section.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get matrixAdvancedTitle;

  /// Subtitle of the advanced section.
  ///
  /// In en, this message translates to:
  /// **'Random seed, attempts per round, seed count'**
  String get matrixAdvancedSubtitle;

  /// Semantics label of the fairness panel.
  ///
  /// In en, this message translates to:
  /// **'Draw details'**
  String get matrixDrawDetails;

  /// Semantics label of an attention list.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get matrixNeedsAttention;

  /// Snackbar after copying the random seed.
  ///
  /// In en, this message translates to:
  /// **'Random seed copied.'**
  String get matrixSeedCopied;

  /// Action to jump to the first pilot match.
  ///
  /// In en, this message translates to:
  /// **'Jump to first'**
  String get matrixJumpFirst;

  /// Filter option for every team.
  ///
  /// In en, this message translates to:
  /// **'All teams'**
  String get matrixAllTeams;

  /// Search hint when pilot numbers are shown.
  ///
  /// In en, this message translates to:
  /// **'Find pilot by name or number'**
  String get matrixFindNameOrNumber;

  /// Search hint when pilot numbers are hidden.
  ///
  /// In en, this message translates to:
  /// **'Find pilot by name'**
  String get matrixFindName;

  /// Tooltip of the clear-search button.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get matrixClearSearch;

  /// Result of the search when there are matches.
  ///
  /// In en, this message translates to:
  /// **'{count} pilot{plural} match{es}'**
  String matrixPilotsMatch(int count, String plural, String es);

  /// Result of the search when there are no matches.
  ///
  /// In en, this message translates to:
  /// **'No pilot matches “{query}”'**
  String matrixNoPilotMatches(String query);

  /// Label of the team filter when a team is chosen.
  ///
  /// In en, this message translates to:
  /// **'Team: {name}'**
  String matrixTeamFilterLabel(String name);

  /// Tooltip of the clear-team-filter button.
  ///
  /// In en, this message translates to:
  /// **'Clear team filter'**
  String get matrixClearTeamFilter;

  /// Note about outlined team markers.
  ///
  /// In en, this message translates to:
  /// **'Teams 13 and up use outlined markers. Their letters stay unique.'**
  String get matrixTeamsOutlinedNote;

  /// Title of the banner when configuration changed after a draw.
  ///
  /// In en, this message translates to:
  /// **'Configuration changed since this draw'**
  String get matrixConfigChangedBanner;

  /// Live region when a pilot is selected.
  ///
  /// In en, this message translates to:
  /// **'{name} highlighted in {rounds} rounds. Opponent panel open.'**
  String matrixLiveSelected(String name, int rounds);

  /// Live region when a team filter is active.
  ///
  /// In en, this message translates to:
  /// **'Showing {name} only: {count} pilots in each round.'**
  String matrixLiveTeamFilter(String name, int count);

  /// Live region when a query has matches.
  ///
  /// In en, this message translates to:
  /// **'{count} pilots match.'**
  String matrixLiveMatches(int count);

  /// Live region when a query has no matches.
  ///
  /// In en, this message translates to:
  /// **'No pilot matches.'**
  String get matrixLiveNoMatches;

  /// Column heading of the matrix grid.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get matrixGridGroups;

  /// Semantics label of the matrix grid.
  ///
  /// In en, this message translates to:
  /// **'Matrix grid, scrolls in both directions'**
  String get matrixGridLabel;

  /// Group size when groups vary.
  ///
  /// In en, this message translates to:
  /// **'up to {count} pilots'**
  String matrixGridUpToPilots(int count);

  /// Group size when all groups are the same size.
  ///
  /// In en, this message translates to:
  /// **'{count} pilots'**
  String matrixGridPilots(int count);

  /// Semantics label of a grid cell.
  ///
  /// In en, this message translates to:
  /// **'Round {round}, group {group}, {count} pilots'**
  String matrixGridCellSemantics(int round, String group, int count);

  /// Semantics label of a pilot's opponents.
  ///
  /// In en, this message translates to:
  /// **'Opponents of {name}'**
  String matrixOpponentsOf(String name);

  /// Title of the opponents section.
  ///
  /// In en, this message translates to:
  /// **'Opponents ({met} of {total})'**
  String matrixOpponentsCount(int met, int total);

  /// Sub of the opponents section.
  ///
  /// In en, this message translates to:
  /// **'Most meetings first. Repeats are marked.'**
  String get matrixOpponentsSub;

  /// Title of the never-meets section.
  ///
  /// In en, this message translates to:
  /// **'Never meets ({count})'**
  String matrixNeverMeets(int count);

  /// Sub when the pilot meets everyone.
  ///
  /// In en, this message translates to:
  /// **'Meets every other pilot at least once.'**
  String get matrixMeetsAll;

  /// Sub when the pilot never meets some pilots.
  ///
  /// In en, this message translates to:
  /// **'Pilots in no group with {name}.'**
  String matrixNoGroupWith(String name);

  /// Pilot number in the panel header.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String matrixPilotNo(String number);

  /// Team shown when the pilot has none.
  ///
  /// In en, this message translates to:
  /// **'No team'**
  String get matrixNoTeam;

  /// Tooltip of the clear-highlight button.
  ///
  /// In en, this message translates to:
  /// **'Clear highlight (Esc)'**
  String get matrixClearHighlight;

  /// Note under the panel on a tablet.
  ///
  /// In en, this message translates to:
  /// **'Select the pilot again or press Esc to clear.'**
  String get matrixSelectAgain;

  /// Meeting count of one.
  ///
  /// In en, this message translates to:
  /// **'once'**
  String get matrixOpponentOnce;

  /// Meeting count of more than one.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String matrixOpponentTimes(int count);

  /// A pilot's place in a round and group.
  ///
  /// In en, this message translates to:
  /// **'R{round} · {group}'**
  String matrixPlace(int round, String group);

  /// A pilot's place with a lane.
  ///
  /// In en, this message translates to:
  /// **'{place} · L{lane}'**
  String matrixPlaceLane(String place, int lane);

  /// Semantics: a pilot with a number.
  ///
  /// In en, this message translates to:
  /// **'Pilot {number}, {name}'**
  String matrixRowPilot(String number, String name);

  /// Semantics: a pilot with no team.
  ///
  /// In en, this message translates to:
  /// **'no team'**
  String get matrixRowNoTeam;

  /// Semantics: a pilot's lane.
  ///
  /// In en, this message translates to:
  /// **', lane {lane}'**
  String matrixRowLane(int lane);

  /// Semantics: a pilot's round and group.
  ///
  /// In en, this message translates to:
  /// **', round {round}, group {group}'**
  String matrixRowRoundGroup(int round, String group);

  /// Semantics: a highlighted pilot.
  ///
  /// In en, this message translates to:
  /// **', highlighted'**
  String get matrixRowHighlighted;

  /// Semantics: a pilot matching the search.
  ///
  /// In en, this message translates to:
  /// **', search match'**
  String get matrixRowMatched;

  /// Short lane label on a row.
  ///
  /// In en, this message translates to:
  /// **'L{lane}'**
  String matrixRowLaneShort(int lane);

  /// Title of a round column.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String matrixRoundTitle(int round);

  /// Tooltip and semantics label of a locked round.
  ///
  /// In en, this message translates to:
  /// **'Round locked'**
  String get matrixRoundLocked;

  /// Tooltip for a round that starts a drop.
  ///
  /// In en, this message translates to:
  /// **'Drop {dropNumber}: the lowest round score is dropped once this round is complete'**
  String matrixDropTooltip(int dropNumber);

  /// Semantics for a round that starts a drop.
  ///
  /// In en, this message translates to:
  /// **'Drop {dropNumber} starts after this round'**
  String matrixDropSemantics(int dropNumber);

  /// Count when every scoring pilot flies exactly once.
  ///
  /// In en, this message translates to:
  /// **'{count} pilots, each once'**
  String matrixPilotsOnce(int count);

  /// Count when pilots fly more than once.
  ///
  /// In en, this message translates to:
  /// **'{distinct} of {total}'**
  String matrixDistinctOf(int distinct, int total);

  /// Tooltip explaining the exactly-once check.
  ///
  /// In en, this message translates to:
  /// **'Every scoring pilot appears exactly once in this round'**
  String get matrixExactlyOnce;

  /// Prefix of a server rejection message.
  ///
  /// In en, this message translates to:
  /// **'Server: '**
  String get matrixServerPrefix;

  /// Snackbar when the advanced section choice cannot be saved.
  ///
  /// In en, this message translates to:
  /// **'The section choice could not be saved. It applies until you close the app.'**
  String get matrixAdvancedSaveFailed;

  /// Label of the random seed field.
  ///
  /// In en, this message translates to:
  /// **'Random seed'**
  String get matrixSeedLabel;

  /// Hint of the random seed field.
  ///
  /// In en, this message translates to:
  /// **'Pick one for me'**
  String get matrixSeedHint;

  /// Help of the random seed field.
  ///
  /// In en, this message translates to:
  /// **'Same seed and settings give the same matrix. Leave blank and the server picks one.'**
  String get matrixSeedHelp;

  /// Label of the attempts-per-round field.
  ///
  /// In en, this message translates to:
  /// **'Attempts per round'**
  String get matrixAttemptsLabel;

  /// Help of the attempts-per-round field.
  ///
  /// In en, this message translates to:
  /// **'Groupings the server tries for each round. More attempts can improve fairness.'**
  String get matrixAttemptsHelp;

  /// Label of the seed-count field.
  ///
  /// In en, this message translates to:
  /// **'Seed count'**
  String get matrixSeedCountLabel;

  /// Help of the seed-count field.
  ///
  /// In en, this message translates to:
  /// **'Independent starts the server runs. The fairest result is kept.'**
  String get matrixSeedCountHelp;

  /// Heading of the read-only configuration rows.
  ///
  /// In en, this message translates to:
  /// **'From contest configuration'**
  String get matrixConfigFromTitle;

  /// Note under the read-only configuration rows.
  ///
  /// In en, this message translates to:
  /// **'Read-only here. Change these in Configuration.'**
  String get matrixConfigReadOnlyNote;

  /// Value for a setting that is on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get matrixValueOn;

  /// Value for a setting that is off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get matrixValueOff;

  /// Label of the back-to-back row.
  ///
  /// In en, this message translates to:
  /// **'Back-to-back flights'**
  String get matrixBackToBackLabel;

  /// Note when back-to-back flights are avoided.
  ///
  /// In en, this message translates to:
  /// **'No pilot flies the last group of one round and the first group of the next.'**
  String get matrixBackToBackOffNote;

  /// Label of the lane mode row.
  ///
  /// In en, this message translates to:
  /// **'Lane mode'**
  String get matrixLaneModeLabel;

  /// Lane mode value: random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get matrixLaneRandom;

  /// Lane mode value: none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get matrixLaneNone;

  /// Note for the random lane mode.
  ///
  /// In en, this message translates to:
  /// **'Each pilot gets a lane in every group.'**
  String get matrixLaneRandomNote;

  /// Note for the none lane mode.
  ///
  /// In en, this message translates to:
  /// **'Pilots are not given lanes.'**
  String get matrixLaneNoneNote;

  /// Label of the pilots-in-the-draw row.
  ///
  /// In en, this message translates to:
  /// **'Pilots in the draw'**
  String get matrixPilotsInDrawLabel;

  /// Value of the pilots-in-the-draw row.
  ///
  /// In en, this message translates to:
  /// **'{count} scoring pilot{plural}'**
  String matrixPilotsInDrawValue(int count, String plural);

  /// Note for non-flying participants excluded from the draw.
  ///
  /// In en, this message translates to:
  /// **'{count} non-flying participant{plural} excluded.'**
  String matrixNonFlyingExcluded(int count, String plural);

  /// Label of the configuration revision row.
  ///
  /// In en, this message translates to:
  /// **'Configuration revision'**
  String get matrixConfigRevisionLabel;

  /// Note when team protection is on.
  ///
  /// In en, this message translates to:
  /// **'Teammates never fly in the same group.'**
  String get matrixTeamProtectionNote;

  /// Note when team protection is off because the draw is seeded.
  ///
  /// In en, this message translates to:
  /// **'Off because Seeded order is on.'**
  String get matrixTeamProtectionSeededOffNote;

  /// Note for the seeded draw mode.
  ///
  /// In en, this message translates to:
  /// **'Only the {count} preliminary rounds are drawn now.'**
  String matrixSeededPrelimNote(int count);

  /// Title of the first-draw confirmation.
  ///
  /// In en, this message translates to:
  /// **'Draw the matrix?'**
  String get matrixDrawConfirmTitle;

  /// Rounds line of the first-draw confirmation.
  ///
  /// In en, this message translates to:
  /// **'{count} {rounds}'**
  String matrixDrawConfirmRounds(int count, String rounds);

  /// Rounds word for a seeded first draw.
  ///
  /// In en, this message translates to:
  /// **'preliminary seeded rounds'**
  String get matrixDrawConfirmSeededRounds;

  /// Rounds word for a first draw.
  ///
  /// In en, this message translates to:
  /// **'rounds'**
  String get matrixDrawConfirmRoundsWord;

  /// Groups line of the first-draw confirmation.
  ///
  /// In en, this message translates to:
  /// **'{groups} groups per round ({sizes} pilots)'**
  String matrixDrawConfirmGroups(int groups, String sizes);

  /// Note when the draw assigns pilot numbers.
  ///
  /// In en, this message translates to:
  /// **'Contest pilot numbers are assigned by this draw.'**
  String get matrixDrawConfirmNumbers;

  /// Warning of the first-draw confirmation.
  ///
  /// In en, this message translates to:
  /// **'The matrix can’t be undone. Unscored rounds can be redrawn afterwards.'**
  String get matrixDrawConfirmWarning;

  /// Confirm button of the first-draw confirmation.
  ///
  /// In en, this message translates to:
  /// **'Draw matrix'**
  String get matrixDrawConfirmAction;

  /// First-draw button label.
  ///
  /// In en, this message translates to:
  /// **'Draw matrix'**
  String get matrixDrawAction;

  /// First-draw button label while drawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing matrix…'**
  String get matrixDrawActionBusy;

  /// Fallback link label to open a page.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get matrixOpen;

  /// Title of the group-size preview.
  ///
  /// In en, this message translates to:
  /// **'{groups} group{groupsPlural}: {sizes} pilot{pilotsPlural}'**
  String matrixGroupSizesTitle(
    int groups,
    String groupsPlural,
    String sizes,
    String pilotsPlural,
  );

  /// Title when there are more groups than pilots.
  ///
  /// In en, this message translates to:
  /// **'More groups than scoring pilots'**
  String get matrixGroupSizesMore;

  /// Title when no groups are entered yet.
  ///
  /// In en, this message translates to:
  /// **'Enter groups per round to see the group sizes.'**
  String get matrixGroupSizesEnter;

  /// Heading of one group in the preview.
  ///
  /// In en, this message translates to:
  /// **'Group {letter}'**
  String matrixGroupLabel(String letter);

  /// Pilot count of one group in the preview.
  ///
  /// In en, this message translates to:
  /// **'{count} pilot{plural}'**
  String matrixGroupPilots(int count, String plural);

  /// Note of the team-protection minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum {min} groups. Team protection keeps teammates apart, and the largest team{team} has {min} scoring pilots.'**
  String matrixGroupMinimum(int min, String team);

  /// Note of the seeded preliminary rounds.
  ///
  /// In en, this message translates to:
  /// **'Seeded Man on Man: only the {rounds} preliminary rounds are drawn now. Seeded rounds are drawn later from the preliminary results.'**
  String matrixGroupSeeded(int rounds);

  /// Snackbar when the summary choice cannot be saved.
  ///
  /// In en, this message translates to:
  /// **'The summary choice could not be saved. It applies until you close the app.'**
  String get matrixSummarySaveFailed;

  /// Button to show the fairness summary.
  ///
  /// In en, this message translates to:
  /// **'Show summary'**
  String get matrixShowSummary;

  /// Button to hide the fairness summary.
  ///
  /// In en, this message translates to:
  /// **'Hide summary'**
  String get matrixHideSummary;

  /// Heading of the fairness score.
  ///
  /// In en, this message translates to:
  /// **'FAIRNESS SCORE'**
  String get matrixFairnessScore;

  /// Note under the fairness score.
  ///
  /// In en, this message translates to:
  /// **'0% is the average of random draws, 100% is the best possible.'**
  String get matrixFairnessScale;

  /// Label of the unmet opponents figure.
  ///
  /// In en, this message translates to:
  /// **'Unmet opponents'**
  String get matrixUnmetLabel;

  /// Sub of the unmet opponents figure.
  ///
  /// In en, this message translates to:
  /// **'pairs who never meet'**
  String get matrixUnmetSub;

  /// Label of the max repeats figure.
  ///
  /// In en, this message translates to:
  /// **'Max repeats'**
  String get matrixMaxRepeatsLabel;

  /// Sub of the max repeats figure.
  ///
  /// In en, this message translates to:
  /// **'most meetings of one pair'**
  String get matrixMaxRepeatsSub;

  /// Label of the lane uniformity figure.
  ///
  /// In en, this message translates to:
  /// **'Lane uniformity'**
  String get matrixLaneUniformityLabel;

  /// Sub of the lane uniformity figure.
  ///
  /// In en, this message translates to:
  /// **'spread of lane use, lower is more even; lanes are random within each group'**
  String get matrixLaneUniformitySub;

  /// Title of the pairs histogram.
  ///
  /// In en, this message translates to:
  /// **'Pilot pairs by number of meetings'**
  String get matrixFairnessPairsTitle;

  /// Mean absolute deviation line of the histogram.
  ///
  /// In en, this message translates to:
  /// **'Mean absolute deviation {value}'**
  String matrixMeanAbsDeviation(String value);

  /// Compact fairness score line.
  ///
  /// In en, this message translates to:
  /// **'Fairness {score}'**
  String matrixFairnessCompact(String score);

  /// Compact fairness statistics line.
  ///
  /// In en, this message translates to:
  /// **'{unmet} unmet pairs · max {maxRepeats}× · MAD {mad}'**
  String matrixFairnessCompactStats(
    String unmet,
    String maxRepeats,
    String mad,
  );

  /// Label in the draw details.
  ///
  /// In en, this message translates to:
  /// **'Matrix revision'**
  String get matrixDetailMatrixRevision;

  /// Label in the draw details.
  ///
  /// In en, this message translates to:
  /// **'Configuration revision'**
  String get matrixDetailConfigurationRevision;

  /// Label in the draw details.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get matrixDetailAlgorithm;

  /// Label in the draw details.
  ///
  /// In en, this message translates to:
  /// **'Random seed'**
  String get matrixDetailRandomSeed;

  /// Label in the draw details.
  ///
  /// In en, this message translates to:
  /// **'Drawn'**
  String get matrixDetailDrawn;

  /// Tooltip of the copy-seed button.
  ///
  /// In en, this message translates to:
  /// **'Copy random seed'**
  String get matrixCopySeedTooltip;

  /// Title of the lifecycle control card.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle'**
  String get workspaceControlLifecycle;

  /// Title of the participant-scoring control card.
  ///
  /// In en, this message translates to:
  /// **'Participant scoring'**
  String get workspaceControlScoring;

  /// Title of the overall-results control card.
  ///
  /// In en, this message translates to:
  /// **'Overall results'**
  String get workspaceControlResults;

  /// Title of the administration control card.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get workspaceControlAdministration;

  /// Title of the publication control card.
  ///
  /// In en, this message translates to:
  /// **'Publication'**
  String get workspaceControlPublication;

  /// Title of the archive control card.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get workspaceControlArchive;

  /// Placeholder under a control card that has no widget yet.
  ///
  /// In en, this message translates to:
  /// **'{label} goes here'**
  String workspaceControlGoesHere(String label);

  /// Label of the next-step section.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get workspaceSectionNextStep;

  /// Label of the setup-checklist section.
  ///
  /// In en, this message translates to:
  /// **'Setup checklist'**
  String get workspaceSectionChecklist;

  /// Label of the pilot-invitations section.
  ///
  /// In en, this message translates to:
  /// **'Pilot invitations'**
  String get workspaceSectionInvitations;

  /// Label of the needs-attention section.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get workspaceSectionAttention;

  /// Label of the round-progress section.
  ///
  /// In en, this message translates to:
  /// **'Round progress'**
  String get workspaceSectionProgress;

  /// Label of the contest-controls section.
  ///
  /// In en, this message translates to:
  /// **'Contest controls'**
  String get workspaceSectionControls;

  /// Label of the contest-facts section.
  ///
  /// In en, this message translates to:
  /// **'Contest facts'**
  String get workspaceSectionFacts;

  /// Label of the recent-activity section.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get workspaceSectionActivity;

  /// Placeholder under a section that has no widget yet.
  ///
  /// In en, this message translates to:
  /// **'{label} goes here'**
  String workspaceSectionGoesHere(String label);

  /// Banner after a rejected change.
  ///
  /// In en, this message translates to:
  /// **'Your change to {change} wasn\'t applied. This page is out of date.'**
  String workspaceBannerStaleChange(String change);

  /// Action of the stale-change banner.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get workspaceBannerStaleRefresh;

  /// Banner when the server is unreachable but a local copy is shown.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the Soar Score server. Showing this device\'s copy from {copyTime}. Scoring still works here and will sync; publishing, visibility and delisting are off until the server is back.'**
  String workspaceBannerUnreachable(String copyTime);

  /// Action of the unreachable-server banner.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get workspaceBannerTryAgain;

  /// Offline banner on a native installation that keeps local data.
  ///
  /// In en, this message translates to:
  /// **'Offline. Scoring and the other controls keep working on this device and sync when you\'re back. Publishing, visibility and delisting need a connection.'**
  String get workspaceBannerOfflineLocal;

  /// Offline banner on the web build, which keeps no local data.
  ///
  /// In en, this message translates to:
  /// **'Offline. Changes can\'t be saved until you\'re back online; what is on screen may be out of date.'**
  String get workspaceBannerOfflineNoLocal;

  /// Title of the contest-facts details.
  ///
  /// In en, this message translates to:
  /// **'Contest'**
  String get workspaceFactsTitle;

  /// Label of the dates fact.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get workspaceFactsDates;

  /// Label of the time-zone fact.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get workspaceFactsTimezone;

  /// Label of the host fact.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get workspaceFactsHost;

  /// Label of the location fact.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get workspaceFactsLocation;

  /// Loading text of the needs-attention section.
  ///
  /// In en, this message translates to:
  /// **'Checking what needs attention…'**
  String get workspaceAttentionLoading;

  /// Title of the needs-attention card.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get workspaceAttentionTitle;

  /// Note when a needs-attention source could not be read and there are items.
  ///
  /// In en, this message translates to:
  /// **'This list may be incomplete'**
  String get workspaceAttentionIncomplete;

  /// Note when needs-attention could not be worked out at all.
  ///
  /// In en, this message translates to:
  /// **'Needs attention could not be worked out'**
  String get workspaceAttentionUnknown;

  /// Retry button in a workspace section placeholder.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get workspaceRetry;

  /// Title of the setup-checklist card.
  ///
  /// In en, this message translates to:
  /// **'Setup checklist'**
  String get workspaceChecklistTitle;

  /// Heading of the optional checklist rows.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get workspaceChecklistOptional;

  /// Note beside the optional heading.
  ///
  /// In en, this message translates to:
  /// **'Not needed to run the contest'**
  String get workspaceChecklistOptionalNote;

  /// Loading text of the setup-checklist section.
  ///
  /// In en, this message translates to:
  /// **'Loading the setup checklist…'**
  String get workspaceChecklistLoading;

  /// Failed text of the setup-checklist section.
  ///
  /// In en, this message translates to:
  /// **'The setup checklist could not be loaded.'**
  String get workspaceChecklistLoadFailed;

  /// Current value when the contest is archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get workspaceArchiveArchived;

  /// Current value when the contest is not archived.
  ///
  /// In en, this message translates to:
  /// **'Not archived'**
  String get workspaceArchiveNotArchived;

  /// What the archive control reaches.
  ///
  /// In en, this message translates to:
  /// **'Archiving moves a contest out of the way on this installation.'**
  String get workspaceArchiveScope;

  /// Why the archive button is disabled.
  ///
  /// In en, this message translates to:
  /// **'Archiving is not available yet: the server has no archive action.'**
  String get workspaceArchiveUnavailable;

  /// Label of the archive button.
  ///
  /// In en, this message translates to:
  /// **'Archive contest'**
  String get workspaceArchiveButton;

  /// Prefix of the current value in a control card.
  ///
  /// In en, this message translates to:
  /// **'Now: '**
  String get workspaceControlNow;

  /// Title of the complete-contest dialog.
  ///
  /// In en, this message translates to:
  /// **'Complete contest?'**
  String get workspaceCompleteTitle;

  /// Confirm button of the complete-contest dialog.
  ///
  /// In en, this message translates to:
  /// **'Complete contest'**
  String get workspaceCompleteButton;

  /// Lifecycle line in the complete-contest dialog.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle: Running → Completed'**
  String get workspaceCompleteLifecycle;

  /// Body of the complete-contest dialog.
  ///
  /// In en, this message translates to:
  /// **'Completing closes participant scoring and ends results hiding. There is no way back to Running. Authorized score corrections stay possible.'**
  String get workspaceCompleteBody;

  /// Note in the complete dialog when the scores could not be read.
  ///
  /// In en, this message translates to:
  /// **'The scores could not be loaded, so the missing scores and unflown rounds are not listed.'**
  String get workspaceCompleteScoresUnknown;

  /// Note in the complete dialog when nothing is open.
  ///
  /// In en, this message translates to:
  /// **'Every flight has a score and every round has been flown.'**
  String get workspaceCompleteAllClear;

  /// Heading above the open items in the complete dialog.
  ///
  /// In en, this message translates to:
  /// **'Still open:'**
  String get workspaceCompleteStillOpen;

  /// Open item: flights without a score.
  ///
  /// In en, this message translates to:
  /// **'• {count} {word} no score'**
  String workspaceCompleteMissingScores(int count, String word);

  /// Open item: rounds nobody flew.
  ///
  /// In en, this message translates to:
  /// **'• {word} {rounds} not flown'**
  String workspaceCompleteUnflownRounds(String word, String rounds);

  /// Snackbar when a transition has no API client.
  ///
  /// In en, this message translates to:
  /// **'No API client is available.'**
  String get workspaceNoApiClient;

  /// Title of the lock-administration dialog.
  ///
  /// In en, this message translates to:
  /// **'Lock administration?'**
  String get workspaceLockTitle;

  /// Lifecycle line in the lock dialog.
  ///
  /// In en, this message translates to:
  /// **'Administration: Unlocked → Locked'**
  String get workspaceLockLifecycle;

  /// Intro of the rejected-changes list in the lock dialog.
  ///
  /// In en, this message translates to:
  /// **'While locked, these changes are rejected:'**
  String get workspaceLockRejected;

  /// Rejected-change item: configuration.
  ///
  /// In en, this message translates to:
  /// **'• Contest configuration'**
  String get workspaceLockConfigItem;

  /// Rejected-change item: participants and roles.
  ///
  /// In en, this message translates to:
  /// **'• Participants and their roles'**
  String get workspaceLockParticipantsItem;

  /// Rejected-change item: the matrix.
  ///
  /// In en, this message translates to:
  /// **'• The matrix and its assignments'**
  String get workspaceLockMatrixItem;

  /// Rejected-change item: scores.
  ///
  /// In en, this message translates to:
  /// **'• Scores'**
  String get workspaceLockScoresItem;

  /// Body of the lock-administration dialog.
  ///
  /// In en, this message translates to:
  /// **'The contest can still be viewed and published. Locking does not complete it or close participant scoring.'**
  String get workspaceLockBody;

  /// Confirm button of the lock dialog.
  ///
  /// In en, this message translates to:
  /// **'Lock administration'**
  String get workspaceLockButton;

  /// Title of the status summary card.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get workspaceStatusTitle;

  /// Current value when participant scoring is open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get workspaceScoringOpen;

  /// What closing scoring reaches.
  ///
  /// In en, this message translates to:
  /// **'Closing stops pilots and helpers from entering their own scores.'**
  String get workspaceScoringCloseScope;

  /// Current value when participant scoring is closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get workspaceScoringClosed;

  /// What opening scoring reaches.
  ///
  /// In en, this message translates to:
  /// **'Opening lets pilots and helpers enter their own scores.'**
  String get workspaceScoringOpenScope;

  /// Current value when administration is locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get workspaceAdminLocked;

  /// What unlocking administration reaches.
  ///
  /// In en, this message translates to:
  /// **'Unlocking allows changes to configuration, participants, the matrix and scores again.'**
  String get workspaceAdminUnlockScope;

  /// Current value when administration is unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get workspaceAdminUnlocked;

  /// What locking administration reaches.
  ///
  /// In en, this message translates to:
  /// **'Locking blocks changes to configuration, participants, the matrix and scores.'**
  String get workspaceAdminLockScope;

  /// What completing the contest reaches.
  ///
  /// In en, this message translates to:
  /// **'Completing ends the contest: scoring closes and the results are final.'**
  String get workspaceCompleteScope;

  /// Undo button of an in-place action.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get workspaceActionUndo;

  /// Refresh button of a rejected in-place action.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get workspaceActionRefresh;

  /// Note in the next-step card when part of the facts failed.
  ///
  /// In en, this message translates to:
  /// **'Some information could not be loaded.'**
  String get workspaceNextStepUnavailable;

  /// Loading text of the next-step section.
  ///
  /// In en, this message translates to:
  /// **'Working out the next step…'**
  String get workspaceNextStepLoading;

  /// Failed text of the next-step section.
  ///
  /// In en, this message translates to:
  /// **'The next step could not be worked out.'**
  String get workspaceNextStepFailed;

  /// Snackbar after dismissing a completion suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion dismissed. It returns if another 48 hours pass without scores.'**
  String get workspaceSuggestionDismissed;

  /// Semantics label of the loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading contest'**
  String get workspaceLoadingLabel;

  /// Title of the load-failed state.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this contest'**
  String get workspaceLoadFailedTitle;

  /// Body of the load-failed state.
  ///
  /// In en, this message translates to:
  /// **'{message} Nothing has changed.'**
  String workspaceLoadFailedBody(String message);

  /// Action of the load-failed state.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get workspaceLoadFailedRetry;

  /// Title of the not-found state.
  ///
  /// In en, this message translates to:
  /// **'Contest not found'**
  String get workspaceNotFoundTitle;

  /// Body of the not-found state.
  ///
  /// In en, this message translates to:
  /// **'This link doesn\'t match a contest on this device or the server. It may have been deleted, or the link is incomplete.'**
  String get workspaceNotFoundBody;

  /// Action of the not-found state.
  ///
  /// In en, this message translates to:
  /// **'Back to Contests'**
  String get workspaceNotFoundBack;

  /// Title and semantics of the reports context strip.
  ///
  /// In en, this message translates to:
  /// **'Reports are built from'**
  String get reportsBuiltFrom;

  /// Label of the lifecycle fact.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle'**
  String get reportsFactLifecycle;

  /// Lifecycle value of a completed contest.
  ///
  /// In en, this message translates to:
  /// **'Completed · Results are final'**
  String get reportsFactCompleted;

  /// Label of the matrix fact.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get reportsFactMatrix;

  /// Matrix value when none is drawn.
  ///
  /// In en, this message translates to:
  /// **'No matrix drawn'**
  String get reportsFactNoMatrix;

  /// Label of the configuration fact.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get reportsFactConfiguration;

  /// Configuration value when none is saved.
  ///
  /// In en, this message translates to:
  /// **'None saved'**
  String get reportsFactNoneSaved;

  /// Label of the scoring-progress fact.
  ///
  /// In en, this message translates to:
  /// **'Scoring progress'**
  String get reportsFactScoringProgress;

  /// Lead of the result-status fact.
  ///
  /// In en, this message translates to:
  /// **'Standings produced now would be'**
  String get reportsResultStatusLead;

  /// Semantics label of the result-status chip.
  ///
  /// In en, this message translates to:
  /// **'Result status: {status}'**
  String reportsResultStatusLabel(String status);

  /// Offline note with no pending changes.
  ///
  /// In en, this message translates to:
  /// **'Based on local data.'**
  String get reportsOfflineLocalOnly;

  /// Offline note with pending changes.
  ///
  /// In en, this message translates to:
  /// **'Based on local data, {count} {change} not yet synced.'**
  String reportsOfflinePending(int count, String change);

  /// Suffix of the offline note.
  ///
  /// In en, this message translates to:
  /// **'Reports show what this device has.'**
  String get reportsOfflineSuffix;

  /// Link to the sync page in the offline note.
  ///
  /// In en, this message translates to:
  /// **'Open Sync'**
  String get reportsOpenSync;

  /// Semantics label of the reports loading state.
  ///
  /// In en, this message translates to:
  /// **'Loading reports'**
  String get reportsLoadingLabel;

  /// Text of the reports loading state.
  ///
  /// In en, this message translates to:
  /// **'Loading reports…'**
  String get reportsLoadingText;

  /// Title of the reports unavailable state.
  ///
  /// In en, this message translates to:
  /// **'Can’t read this contest’s data'**
  String get reportsUnavailableTitle;

  /// Body of the reports unavailable state.
  ///
  /// In en, this message translates to:
  /// **'The reports list needs the contest’s matrix and scores, and they couldn’t be loaded from this device or the server. Nothing has changed.'**
  String get reportsUnavailableBody;

  /// Retry button of the reports unavailable state.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get reportsUnavailableRetry;

  /// Open button of a report card.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get reportCardOpen;

  /// Note after a report opened in a new tab.
  ///
  /// In en, this message translates to:
  /// **'Opened in a new tab'**
  String get reportCardOpened;

  /// Notice when the browser blocked the new tab.
  ///
  /// In en, this message translates to:
  /// **'Your browser blocked the new tab. Allow pop-ups for Soar Score, or open the report here and use Back to return.'**
  String get reportCardBlocked;

  /// Action to open the report in this window.
  ///
  /// In en, this message translates to:
  /// **'Open here'**
  String get reportCardOpenHere;

  /// Fact: the report needs scores.
  ///
  /// In en, this message translates to:
  /// **'Needs scores'**
  String get reportCardNeedsScores;

  /// Fact: the report needs no scores.
  ///
  /// In en, this message translates to:
  /// **'No scores needed'**
  String get reportCardNoScoresNeeded;

  /// Fact: the report needs a matrix.
  ///
  /// In en, this message translates to:
  /// **'Needs a matrix'**
  String get reportCardNeedsMatrix;

  /// Button that opens the result-status definitions.
  ///
  /// In en, this message translates to:
  /// **'What do these mean?'**
  String get resultStatusHelpButton;

  /// Title of the result-status popover.
  ///
  /// In en, this message translates to:
  /// **'Result status'**
  String get resultStatusHelpTitle;

  /// Definition of the official status.
  ///
  /// In en, this message translates to:
  /// **'Every round up to the last round shown is complete: each pilot has an official score and no reviews are open. Printed pages carry no stamp.'**
  String get resultStatusOfficial;

  /// Definition of the preliminary status.
  ///
  /// In en, this message translates to:
  /// **'A round up to the last round shown has a missing score, a score not yet marked official, or an open review. Every page is stamped PRELIMINARY.'**
  String get resultStatusPreliminary;

  /// Footer of the result-status popover.
  ///
  /// In en, this message translates to:
  /// **'Each printed page repeats the status in its footer.'**
  String get resultStatusHelpFooter;

  /// Viewer app bar button that downloads the sheet as a PDF.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get viewerSaveAsPdf;

  /// Viewer app bar back button when the report was opened in place.
  ///
  /// In en, this message translates to:
  /// **'Back to Reports'**
  String get viewerBackToReports;

  /// Viewer app bar primary button that prints the sheet.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get viewerPrint;

  /// Viewer app bar menu entry and panel switch that hide screen-only marks.
  ///
  /// In en, this message translates to:
  /// **'Print preview'**
  String get viewerPrintPreview;

  /// Viewer app bar menu entry that opens the page setup.
  ///
  /// In en, this message translates to:
  /// **'Page setup…'**
  String get viewerPageSetup;

  /// Viewer app bar menu entry that clears filters and options.
  ///
  /// In en, this message translates to:
  /// **'Reset filters and options'**
  String get viewerResetFilters;

  /// Keyboard shortcut shown beside the print menu entry.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+P'**
  String get viewerShortcutPrint;

  /// Tooltip of the viewer app bar overflow button.
  ///
  /// In en, this message translates to:
  /// **'Page setup and more'**
  String get viewerOverflowTooltip;

  /// Lead of the offline banner above the sheet.
  ///
  /// In en, this message translates to:
  /// **'Offline.'**
  String get viewerOffline;

  /// Offline banner text when no changes are pending.
  ///
  /// In en, this message translates to:
  /// **'Produced from data on this device.'**
  String get viewerOfflineLocalOnly;

  /// Offline banner text when changes are still pending.
  ///
  /// In en, this message translates to:
  /// **'Produced from data on this device. {count} {change} not yet synced.'**
  String viewerOfflinePending(int count, String change);

  /// Offline banner action that opens the sync page.
  ///
  /// In en, this message translates to:
  /// **'Open Sync'**
  String get viewerOpenSync;

  /// Heading of the viewer's Page control group.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get viewerPageGroup;

  /// Label of the paper size segments.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get viewerPaper;

  /// Label of the page orientation segments.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get viewerOrientation;

  /// Help line under the orientation segments.
  ///
  /// In en, this message translates to:
  /// **'This report’s default is {orientation}.'**
  String viewerOrientationDefault(String orientation);

  /// Subtitle of the print preview switch.
  ///
  /// In en, this message translates to:
  /// **'Hide screen-only marks and page-break labels'**
  String get viewerHideScreenMarks;

  /// Label of the pages-to-print field.
  ///
  /// In en, this message translates to:
  /// **'Pages to print'**
  String get viewerPagesToPrint;

  /// Hint of the pages-to-print field when it is blank.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String viewerPagesToPrintHint(int count);

  /// Helper shown when every page will print.
  ///
  /// In en, this message translates to:
  /// **'All {count} {word}. Type 1 or 2-4 to print only some.'**
  String viewerPagesToPrintAll(int count, String word);

  /// Helper shown when a subset of pages will print.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} {word} will print.'**
  String viewerPagesToPrintSome(int count, int total, String word);

  /// Compact viewer toolbar button that opens the filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get viewerFiltersButton;

  /// Accessibility label of the viewer zoom controls.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get viewerZoom;

  /// Tooltip of the zoom out button.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get viewerZoomOut;

  /// Tooltip of the zoom in button.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get viewerZoomIn;

  /// Accessibility label of the zoom toggle while fitting the width.
  ///
  /// In en, this message translates to:
  /// **'Zoom: fit width. Switch to 100 percent.'**
  String get viewerZoomFitSwitchTo;

  /// Accessibility label of the zoom toggle at a fixed zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom {percent}. Switch to fit width.'**
  String viewerZoomFixedSwitchTo(String percent);

  /// Zoom toggle label while fitting the width.
  ///
  /// In en, this message translates to:
  /// **'Fit · {percent}'**
  String viewerZoomFitPrefix(String percent);

  /// Default label of the viewer loading state.
  ///
  /// In en, this message translates to:
  /// **'Loading contest data…'**
  String get viewerLoadingLabel;

  /// Viewer label while a report builds its pages.
  ///
  /// In en, this message translates to:
  /// **'Building pages…'**
  String get viewerBuildingPages;

  /// Title of the viewer not-found state.
  ///
  /// In en, this message translates to:
  /// **'This contest can’t be found'**
  String get viewerNotFoundTitle;

  /// Body of the viewer not-found state.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or the link points to a contest you no longer have access to. There is nothing to print.'**
  String get viewerNotFoundBody;

  /// Not-found action when the report was opened in a new tab.
  ///
  /// In en, this message translates to:
  /// **'Back to Contests'**
  String get viewerBackToContests;

  /// Title of the viewer unavailable state.
  ///
  /// In en, this message translates to:
  /// **'Can’t read the contest data'**
  String get viewerUnavailableTitle;

  /// Body of the viewer unavailable state.
  ///
  /// In en, this message translates to:
  /// **'The scores for this report couldn’t be loaded from this device or the server. Your filters are kept.'**
  String get viewerUnavailableBody;

  /// Action label on the viewer error states.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get viewerTryAgain;

  /// Title of the viewer data-unavailable state.
  ///
  /// In en, this message translates to:
  /// **'Can’t read the scores for this report'**
  String get viewerDataUnavailableTitle;

  /// Body of the viewer data-unavailable state.
  ///
  /// In en, this message translates to:
  /// **'They couldn’t be loaded from this device or the server. Your filters are kept.'**
  String get viewerDataUnavailableBody;

  /// Accessibility label of the report sheet area.
  ///
  /// In en, this message translates to:
  /// **'Report pages'**
  String get viewerReportPages;

  /// Label of the on-screen page break separator.
  ///
  /// In en, this message translates to:
  /// **'Page break · Page {page}'**
  String viewerPageBreak(int page);

  /// Window title of the viewer for a named contest.
  ///
  /// In en, this message translates to:
  /// **'{title} — {name}'**
  String viewerPageWindow(String title, String name);

  /// App bar title of the viewer.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get viewerReportWord;

  /// Accessibility label of a printed sheet page.
  ///
  /// In en, this message translates to:
  /// **'{reportName}, page {page} of {count}'**
  String viewerSheetPageLabel(String reportName, int page, int count);

  /// Page number in the sheet footer.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String viewerPageOf(int page, int count);

  /// Official stamp word in the sheet footer.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL'**
  String get viewerStatusOfficial;

  /// Preliminary stamp word on the page and in the footer.
  ///
  /// In en, this message translates to:
  /// **'PRELIMINARY'**
  String get viewerStatusPreliminary;

  /// Accessibility label of the result stamp.
  ///
  /// In en, this message translates to:
  /// **'{text} result'**
  String viewerResultStampSemantics(String text);

  /// Second line of the preliminary result stamp.
  ///
  /// In en, this message translates to:
  /// **'Not final · scores incomplete'**
  String get viewerStampNotFinal;

  /// Subtitle of a data report that has nothing to show yet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get viewerNothingToShow;

  /// Footer line of a printed page naming when it was produced.
  ///
  /// In en, this message translates to:
  /// **'Generated {time}'**
  String viewerGenerated(String time);

  /// Print job title for a named contest.
  ///
  /// In en, this message translates to:
  /// **'{title} – {name}'**
  String viewerPrintTitle(String title, String name);

  /// Heading of the filters and options panel and bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Filter and options'**
  String get viewerFilterOptions;

  /// Button that closes the filter bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get viewerDone;

  /// Lead of the official status banner.
  ///
  /// In en, this message translates to:
  /// **'Official.'**
  String get viewerOfficialLead;

  /// Text of the official status banner.
  ///
  /// In en, this message translates to:
  /// **'Every score is official, no reviews are open, and the standings are current. Printed pages carry no stamp.'**
  String get viewerOfficialDefault;

  /// Lead of the preliminary status banner.
  ///
  /// In en, this message translates to:
  /// **'Preliminary:'**
  String get viewerPreliminaryLead;

  /// Text of the preliminary status banner.
  ///
  /// In en, this message translates to:
  /// **'Some scores are not final.'**
  String get viewerPreliminaryDefault;

  /// Lead of the crowded-sheet notice banner.
  ///
  /// In en, this message translates to:
  /// **'Crowded.'**
  String get viewerCrowdedLead;

  /// Lead of the out-of-date sheet banner.
  ///
  /// In en, this message translates to:
  /// **'Out of date.'**
  String get viewerOutdatedLead;

  /// Text of the out-of-date sheet banner.
  ///
  /// In en, this message translates to:
  /// **'Scores, the matrix or the configuration changed after this report was produced. The sheet hasn’t changed.'**
  String get viewerOutdatedText;

  /// Action on the out-of-date sheet banner.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get viewerRefresh;

  /// Lead of the data-failure banner.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the scores for these rounds.'**
  String get viewerDataLoadFailedLead;

  /// Text of the data-failure banner.
  ///
  /// In en, this message translates to:
  /// **'The sheet still shows the last rounds that loaded.'**
  String get viewerDataLoadFailedText;

  /// Lead of the print-failure banner.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t print.'**
  String get viewerPrintFailedLead;

  /// Text of the print-failure banner.
  ///
  /// In en, this message translates to:
  /// **'The system reported a printer error. Your filters and options are unchanged.'**
  String get viewerPrintFailedText;

  /// Lead when printing is unavailable but saving a PDF is.
  ///
  /// In en, this message translates to:
  /// **'Printing isn’t available here.'**
  String get viewerPrintingUnavailableLead;

  /// Lead when neither printing nor saving a PDF is available.
  ///
  /// In en, this message translates to:
  /// **'This browser can’t print or save PDFs.'**
  String get viewerPdfUnavailableLead;

  /// Text when printing is unavailable but saving a PDF is.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF, then print or email the file from another device.'**
  String get viewerPrintingUnavailableText;

  /// Text when neither printing nor saving a PDF is available.
  ///
  /// In en, this message translates to:
  /// **'Copy the link and open it on a browser that can print.'**
  String get viewerPdfUnavailableText;

  /// Action that copies the link to this report.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get viewerCopyLink;

  /// Action on the empty-filters state that clears the filters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get viewerClearFilters;

  /// Legend when print preview is on.
  ///
  /// In en, this message translates to:
  /// **'Print preview: the white pages are exactly what prints.'**
  String get viewerPrintPreviewLegend;

  /// Legend of a compact window.
  ///
  /// In en, this message translates to:
  /// **'White pages print as shown'**
  String get viewerPrintAsShownCompact;

  /// Legend of a wide window.
  ///
  /// In en, this message translates to:
  /// **'The white pages print exactly as shown. Everything around them is screen only.'**
  String get viewerPrintAsShown;

  /// Page indicator when there are no pages.
  ///
  /// In en, this message translates to:
  /// **'No pages'**
  String get viewerNoPages;

  /// Page indicator of the toolbar.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String viewerPageIndicator(int page, int count);

  /// Legend and setup text when there is nothing to print.
  ///
  /// In en, this message translates to:
  /// **'Nothing to print'**
  String get viewerNothingToPrint;

  /// Compact toolbar button label with the active filters.
  ///
  /// In en, this message translates to:
  /// **'Filters · {summary}'**
  String viewerFiltersSummary(String summary);

  /// Title when the route's report is unknown.
  ///
  /// In en, this message translates to:
  /// **'This report doesn’t exist'**
  String get viewerUnknownReportTitle;

  /// Body when the route's report is unknown.
  ///
  /// In en, this message translates to:
  /// **'The link doesn’t match one of the contest’s reports. There is nothing to print.'**
  String get viewerUnknownReportBody;

  /// Setup text when printing is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Printing unavailable'**
  String get viewerSetupPrintingUnavailable;

  /// Setup text showing paper, orientation and page count.
  ///
  /// In en, this message translates to:
  /// **'{setup} · {count} {word}'**
  String viewerSetupSummary(String setup, int count, String word);

  /// Subtitle under the panel heading.
  ///
  /// In en, this message translates to:
  /// **'Changes update the sheet straight away.'**
  String get viewerPanelSubtitle;

  /// Separator between items in the collapsed panel summary.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get viewerPanelSummarySeparator;

  /// Heading of the standings round-range group.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get standingsFilter;

  /// Label of the from-round dropdown.
  ///
  /// In en, this message translates to:
  /// **'From round'**
  String get standingsFromRound;

  /// Label of the to-round dropdown.
  ///
  /// In en, this message translates to:
  /// **'To round'**
  String get standingsToRound;

  /// Message when no rounds can be shown.
  ///
  /// In en, this message translates to:
  /// **'No rounds can be shown yet.'**
  String get standingsNoRounds;

  /// Message explaining what the standings show.
  ///
  /// In en, this message translates to:
  /// **'Rank and total are the standings as of round {to}. Only rounds with scores are listed.'**
  String standingsRangeText(int to);

  /// Heading of the standings column group.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get standingsOptions;

  /// Label of the percentage column option.
  ///
  /// In en, this message translates to:
  /// **'Percentage of total'**
  String get standingsPercentage;

  /// Help for the percentage column option.
  ///
  /// In en, this message translates to:
  /// **'Each total as a percentage of the winner’s'**
  String get standingsPercentageHelp;

  /// Label of the raw score column option.
  ///
  /// In en, this message translates to:
  /// **'Raw score'**
  String get standingsRaw;

  /// Help for the raw score column option.
  ///
  /// In en, this message translates to:
  /// **'Total plus the dropped rounds. Not the score of each round.'**
  String get standingsRawHelp;

  /// Label of the team column option.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get standingsTeam;

  /// Label of the pilot number column option.
  ///
  /// In en, this message translates to:
  /// **'Pilot number'**
  String get standingsPilotNumber;

  /// Label of the pilot class column option.
  ///
  /// In en, this message translates to:
  /// **'Pilot class'**
  String get standingsPilotClass;

  /// Heading of the standings detail group.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get standingsDetail;

  /// Label of the flight details option.
  ///
  /// In en, this message translates to:
  /// **'Flight details'**
  String get standingsFlightDetails;

  /// Help for flight details in an F5J contest.
  ///
  /// In en, this message translates to:
  /// **'Adds flight time, landing points and launch height under each round score.'**
  String get standingsFlightDetailsF5J;

  /// Help for flight details in an F3J contest.
  ///
  /// In en, this message translates to:
  /// **'Adds flight time and landing points under each round score.'**
  String get standingsFlightDetailsF3J;

  /// Label of the provisional option.
  ///
  /// In en, this message translates to:
  /// **'Provisional'**
  String get standingsProvisional;

  /// Dropdown label of a fully scored round.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String standingsRoundLabel(int round);

  /// Dropdown label of a partly scored round.
  ///
  /// In en, this message translates to:
  /// **'Round {round} (partly scored)'**
  String standingsRoundLabelPartial(int round);

  /// Provisional help when no round is partly scored.
  ///
  /// In en, this message translates to:
  /// **'Shows rounds up to the last with any score.'**
  String get standingsProvHelpNone;

  /// Provisional help when a round is partly scored.
  ///
  /// In en, this message translates to:
  /// **'Round {partial} is partly scored. Shows rounds up to the last with any score.'**
  String standingsProvHelpPartial(int partial);

  /// Provisional help when no round is fully scored.
  ///
  /// In en, this message translates to:
  /// **'No round is fully scored yet.'**
  String get standingsProvHelpNoFull;

  /// Provisional help when some rounds are fully scored.
  ///
  /// In en, this message translates to:
  /// **'Only fully scored rounds (1 to {full}) are official.'**
  String standingsProvHelpFull(int full);

  /// Heading of the key line under the standings table.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get standingsKeyHeading;

  /// Rank column heading.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get standingsColRank;

  /// Pilot column heading.
  ///
  /// In en, this message translates to:
  /// **'Pilot'**
  String get standingsColPilot;

  /// Total column heading.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get standingsColTotal;

  /// Percentage column heading.
  ///
  /// In en, this message translates to:
  /// **'Pct'**
  String get standingsColPct;

  /// Accessibility label of the percentage column.
  ///
  /// In en, this message translates to:
  /// **'Percentage of winner'**
  String get standingsColPctSemantic;

  /// Raw score column heading.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get standingsColRaw;

  /// Accessibility label of the raw score column.
  ///
  /// In en, this message translates to:
  /// **'Raw score'**
  String get standingsColRawSemantic;

  /// Team column heading.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get standingsColTeam;

  /// Pilot number column heading.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get standingsColNo;

  /// Accessibility label of the pilot number column.
  ///
  /// In en, this message translates to:
  /// **'Pilot number'**
  String get standingsColNoSemantic;

  /// Pilot class column heading.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get standingsColClass;

  /// Accessibility label of the flight detail column.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get standingsColLineSemantic;

  /// Round column heading.
  ///
  /// In en, this message translates to:
  /// **'R{round}'**
  String standingsRoundColumn(int round);

  /// Round column heading for a partly scored round.
  ///
  /// In en, this message translates to:
  /// **'R{round} partial'**
  String standingsRoundColumnPartial(int round);

  /// Accessibility label of a round column.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String standingsRoundSemantic(int round);

  /// Penalty column heading.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get standingsColPenalty;

  /// Sub-line of the penalty column heading.
  ///
  /// In en, this message translates to:
  /// **'Deducted from total; not dropped'**
  String get standingsPenaltySub;

  /// Accessibility label of a standings table page.
  ///
  /// In en, this message translates to:
  /// **'Overall Results, page {page}'**
  String standingsTableSemantics(int page);

  /// Cell label of the flight detail column.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get standingsScoreCell;

  /// Accessibility label of a pilot's rank cell.
  ///
  /// In en, this message translates to:
  /// **'Rank {place}'**
  String standingsRankCell(int place);

  /// Accessibility label of an unscored round cell.
  ///
  /// In en, this message translates to:
  /// **'no score'**
  String get standingsNoScore;

  /// Accessibility label of a dropped round cell.
  ///
  /// In en, this message translates to:
  /// **'Dropped round, {score}'**
  String standingsDroppedLabel(String score);

  /// Screen-only chip beside a pilot with an open review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get standingsReviewChip;

  /// Accessibility label of the review chip.
  ///
  /// In en, this message translates to:
  /// **'Screen only. Review open.'**
  String get standingsReviewChipSemantic;

  /// Dropdown label of a drawn round.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String matrixRoundLabel(int round);

  /// Dropdown label of a round the contest has not drawn.
  ///
  /// In en, this message translates to:
  /// **'Round {round} · not drawn'**
  String matrixRoundLabelNotDrawn(int round);

  /// Button that shows every drawn round.
  ///
  /// In en, this message translates to:
  /// **'Show all drawn rounds'**
  String get matrixShowAllDrawn;

  /// Button that shows every round.
  ///
  /// In en, this message translates to:
  /// **'Show all rounds'**
  String get matrixShowAllRounds;

  /// Heading of the draw matrix column group.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get matrixColumns;

  /// Label of the compact mode option.
  ///
  /// In en, this message translates to:
  /// **'Compact mode'**
  String get matrixCompactMode;

  /// Help for the compact mode option.
  ///
  /// In en, this message translates to:
  /// **'Two columns per page, 9 pt text'**
  String get matrixCompactHelp;

  /// Label of the additional pilot info option.
  ///
  /// In en, this message translates to:
  /// **'Additional pilot info'**
  String get matrixAdditionalInfo;

  /// Help when additional pilot info is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available in compact mode'**
  String get matrixAdditionalUnavailable;

  /// Help when additional pilot info is on.
  ///
  /// In en, this message translates to:
  /// **'Adds a column for each item you tick'**
  String get matrixAdditionalChosenHelp;

  /// Help when additional pilot info is off.
  ///
  /// In en, this message translates to:
  /// **'Club, FAI ID and National ID columns'**
  String get matrixAdditionalDefaultHelp;

  /// Label of the club column option.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get matrixClub;

  /// Label of the FAI ID column option.
  ///
  /// In en, this message translates to:
  /// **'FAI ID'**
  String get matrixFaiId;

  /// Label of the National ID column option.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get matrixNationalId;

  /// Note when the additional columns are kept during compact mode.
  ///
  /// In en, this message translates to:
  /// **'Kept as set. They apply again when Compact mode is off.'**
  String get matrixAdditionalKept;

  /// Screen-reader name of a draw matrix table on one page.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String matrixTableLabel(int page);

  /// Screen-reader name of a table in compact mode (two per page).
  ///
  /// In en, this message translates to:
  /// **'Page {page}, column {column}'**
  String matrixTableLabelColumn(int page, int column);

  /// Heading of a round row in the draw matrix.
  ///
  /// In en, this message translates to:
  /// **'Round {ordinal}'**
  String matrixRoundRow(int ordinal);

  /// Suffix of a round or group row that continues on this page.
  ///
  /// In en, this message translates to:
  /// **' (continued)'**
  String get matrixContinued;

  /// Heading of a group row in the draw matrix.
  ///
  /// In en, this message translates to:
  /// **'Group {label}'**
  String matrixGroupRow(String label);

  /// Group size in the draw matrix row heading.
  ///
  /// In en, this message translates to:
  /// **'{size} {word}'**
  String matrixGroupSize(int size, String word);

  /// Heading of the Settings card with the version, licences and legal links.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutHeading;

  /// Settings entry that opens the public site's open source licences page in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open source licences'**
  String get aboutOpenSourceLicences;

  /// Explains that the open source licences entry opens the website.
  ///
  /// In en, this message translates to:
  /// **'Opens the list on the RC Soar Score website'**
  String get aboutOpenSourceLicencesHint;

  /// Settings entry that shows the licences bundled with the app, which works without a network.
  ///
  /// In en, this message translates to:
  /// **'Licences on this device'**
  String get aboutLicencesOnThisDevice;

  /// Explains that the bundled licences page needs no network.
  ///
  /// In en, this message translates to:
  /// **'Works without a network connection'**
  String get aboutLicencesOnThisDeviceHint;

  /// Settings entry that opens the source code repository; the app is licensed under the AGPL-3.0.
  ///
  /// In en, this message translates to:
  /// **'Source code (AGPL-3.0)'**
  String get aboutSourceCode;

  /// Settings entry that opens the Privacy Policy on the public site.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacyPolicy;

  /// Settings entry that opens the support request form on the public site.
  ///
  /// In en, this message translates to:
  /// **'Get support'**
  String get aboutSupport;

  /// Settings entry that opens the Terms of Service on the public site.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutTermsOfService;

  /// Snackbar when a link in the About card could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link. Check your network connection and try again.'**
  String get aboutLinkFailed;

  /// Button on the participants page that imports pilots from a GliderScore database file.
  ///
  /// In en, this message translates to:
  /// **'Import pilots from GliderScore…'**
  String get pilotImportButton;

  /// Title of the pilot import dialog.
  ///
  /// In en, this message translates to:
  /// **'Import pilots from GliderScore'**
  String get pilotImportTitle;

  /// Shown in the pilot import dialog before a file is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a GliderScore database (.mdb) to read the pilots from.'**
  String get pilotImportChoosing;

  /// Button that opens the file chooser in the pilot import dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose file…'**
  String get pilotImportChooseButton;

  /// Shown while the GliderScore file is read.
  ///
  /// In en, this message translates to:
  /// **'Reading {file}…'**
  String pilotImportReading(String file);

  /// Introduction above the list of pilots found in a GliderScore file.
  ///
  /// In en, this message translates to:
  /// **'Choose which pilots to add to your participants. Pilots already in your list get any new details; their names are never changed.'**
  String get pilotImportReviewIntro;

  /// Heading of the pilots that are not in the participants yet.
  ///
  /// In en, this message translates to:
  /// **'New ({count})'**
  String pilotImportNewHeading(int count);

  /// Heading of the pilots that match a participant.
  ///
  /// In en, this message translates to:
  /// **'Already in your list ({count})'**
  String pilotImportUpdateHeading(int count);

  /// Heading of the pilots that might be a participant already in the list.
  ///
  /// In en, this message translates to:
  /// **'Maybe the same person ({count})'**
  String pilotImportMaybeHeading(int count);

  /// Hint under the heading of pilots that might be a participant already, explaining the Link choice.
  ///
  /// In en, this message translates to:
  /// **'Link adds missing details from GliderScore to the participant you pick. Names and registration numbers are never overwritten.'**
  String get pilotImportMaybeHint;

  /// Row text naming the details an import adds to an existing participant.
  ///
  /// In en, this message translates to:
  /// **'Will update: {fields}'**
  String pilotImportWillUpdate(String fields);

  /// Row text when an existing participant already has everything the file holds.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to add'**
  String get pilotImportNothingNew;

  /// A previously confirmed GliderScore pilot link.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String pilotImportLinkedTo(String name);

  /// Explains why a remembered pilot needs approval again.
  ///
  /// In en, this message translates to:
  /// **'GliderScore details changed. Select to approve this import.'**
  String get pilotImportSourceChanged;

  /// A source pilot field changed since the last confirmed import.
  ///
  /// In en, this message translates to:
  /// **'{field}: {before} → {after}'**
  String pilotImportSourceFieldChange(
    String field,
    String before,
    String after,
  );

  /// Name of the first-name field in a pilot import review.
  ///
  /// In en, this message translates to:
  /// **'first name'**
  String get pilotImportFieldFirstName;

  /// Name of the last-name field in a pilot import review.
  ///
  /// In en, this message translates to:
  /// **'last name'**
  String get pilotImportFieldLastName;

  /// Row text when the identifiers of a pilot point at different participants.
  ///
  /// In en, this message translates to:
  /// **'Their email and registration numbers match different people in your list.'**
  String get pilotImportConflict;

  /// Row text when a pilot is the same person as an earlier row of the file.
  ///
  /// In en, this message translates to:
  /// **'Looks like another pilot earlier in this file.'**
  String get pilotImportDuplicateInFile;

  /// Choice for a pilot that might be an existing participant: leave out.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get pilotImportChoiceSkip;

  /// Choice for a pilot that might be an existing participant: add a new one.
  ///
  /// In en, this message translates to:
  /// **'Add as new'**
  String get pilotImportChoiceAdd;

  /// Choice for a pilot that might be an existing participant: link the GliderScore pilot to that participant and fill in details it lacks.
  ///
  /// In en, this message translates to:
  /// **'Link to {name}'**
  String pilotImportChoiceUpdate(String name);

  /// Name of a participant detail in the list of details an import updates.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get pilotImportFieldEmail;

  /// Name of a participant detail in the list of details an import updates.
  ///
  /// In en, this message translates to:
  /// **'FAI number'**
  String get pilotImportFieldFai;

  /// Name of a participant detail in the list of details an import updates.
  ///
  /// In en, this message translates to:
  /// **'national ID'**
  String get pilotImportFieldNationalId;

  /// Name of a participant detail in the list of details an import updates.
  ///
  /// In en, this message translates to:
  /// **'club'**
  String get pilotImportFieldClub;

  /// Name of a participant detail in the list of details an import updates.
  ///
  /// In en, this message translates to:
  /// **'city'**
  String get pilotImportFieldCity;

  /// Name of a participant detail in the list of details an import updates.
  ///
  /// In en, this message translates to:
  /// **'state'**
  String get pilotImportFieldState;

  /// Name of a participant detail in the list of details an import updates.
  ///
  /// In en, this message translates to:
  /// **'country'**
  String get pilotImportFieldCountry;

  /// Note on the pilot import review about GliderScore test pilots that were left out.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 GliderScore test pilot (last name starting ZZ) was left out.} other{{count} GliderScore test pilots (last name starting ZZ) were left out.}}'**
  String pilotImportTestPilots(int count);

  /// Note on the pilot import review about rows that were skipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row could not be used (no name or pilot number).} other{{count} rows could not be used (no name or pilot number).}}'**
  String pilotImportSkippedRows(int count);

  /// Note on the pilot import review naming GliderScore columns that are not imported.
  ///
  /// In en, this message translates to:
  /// **'Not imported, because participants have no place for them: {columns}.'**
  String pilotImportDroppedDetails(String columns);

  /// Note on the pilot import review about pilots without a usable country.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pilot has no recognised country.} other{{count} pilots have no recognised country.}}'**
  String pilotImportCountryNote(int count);

  /// Warning on the pilot import review when the file was too large to read fully.
  ///
  /// In en, this message translates to:
  /// **'The file has more pilots than could be read. Some are missing.'**
  String get pilotImportTruncated;

  /// Shown when the GliderScore file holds no pilots to import.
  ///
  /// In en, this message translates to:
  /// **'No pilots were found in this file.'**
  String get pilotImportNoPilots;

  /// Summary line above the import button of the pilot import.
  ///
  /// In en, this message translates to:
  /// **'{added} to add, {updated} to update, {unchanged} unchanged, {skipped} left out'**
  String pilotImportPlan(int added, int updated, int unchanged, int skipped);

  /// Button that saves the pilot import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get pilotImportConfirm;

  /// Shown while the pilots are saved.
  ///
  /// In en, this message translates to:
  /// **'Saving pilots…'**
  String get pilotImportSaving;

  /// Result of a pilot import.
  ///
  /// In en, this message translates to:
  /// **'Added {added}, updated {updated}, unchanged {unchanged}, left out {skipped}.'**
  String pilotImportDone(int added, int updated, int unchanged, int skipped);

  /// Button that closes the finished pilot import.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pilotImportDoneButton;

  /// Shown when the pilot import fails.
  ///
  /// In en, this message translates to:
  /// **'The import did not work. {reason}'**
  String pilotImportFailed(String reason);

  /// Shown when the GliderScore reader is missing.
  ///
  /// In en, this message translates to:
  /// **'Importing from GliderScore is not available on this computer.'**
  String get pilotImportUnavailable;

  /// Row text for a GliderScore pilot whose remembered link is under review, so it cannot be imported yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your decision in Account sync: two devices linked this pilot to different participants.'**
  String get pilotImportLinkReview;

  /// Shown when an import is stopped because a pilot's link needs a decision first.
  ///
  /// In en, this message translates to:
  /// **'A pilot in this import was linked to different participants on two devices. Decide the link in Account sync, then review again.'**
  String get pilotImportLinkReviewPending;

  /// Shown above the pilot review when another installation manages the remembered pilot links.
  ///
  /// In en, this message translates to:
  /// **'Another computer manages the remembered GliderScore pilot links for this account, so this import cannot reuse or change them. You can import without remembered links: you confirm each match yourself and the saved links stay as they are.'**
  String get pilotImportManagedElsewhere;

  /// Shown when a save was stopped because another installation manages the remembered pilot links.
  ///
  /// In en, this message translates to:
  /// **'Another computer now manages the remembered pilot links, so nothing was saved. Review again, then import without remembered links.'**
  String get pilotImportManagedElsewhereNow;

  /// Button that reviews the same file without the remembered pilot links.
  ///
  /// In en, this message translates to:
  /// **'Import without remembered links'**
  String get pilotImportWithoutLinks;

  /// Shown above the pilot review during a one-time import without remembered links.
  ///
  /// In en, this message translates to:
  /// **'Importing without remembered links: confirm each match below. The saved links stay as they are.'**
  String get pilotImportWithoutLinksActive;

  /// Label of the participant picker in the pilot link review.
  ///
  /// In en, this message translates to:
  /// **'Or choose another participant'**
  String get pilotLinkReviewPick;

  /// Button that links the pilot to the participant picked in the review.
  ///
  /// In en, this message translates to:
  /// **'Use this participant'**
  String get pilotLinkReviewUsePicked;

  /// Shown when the participant picked for a pilot link was deleted before the choice was saved.
  ///
  /// In en, this message translates to:
  /// **'That participant is no longer available. Pick another participant.'**
  String get pilotLinkReviewPickRefused;

  /// Breadcrumb and heading of the page that lists what the account's sync needs from the director.
  ///
  /// In en, this message translates to:
  /// **'Account sync'**
  String get shellNavAccountSync;

  /// Introduction under the Account sync heading.
  ///
  /// In en, this message translates to:
  /// **'Decisions your devices could not make on their own wait here.'**
  String get accountSyncIntro;

  /// Names the GliderScore pilot whose link is being reviewed.
  ///
  /// In en, this message translates to:
  /// **'GliderScore pilot {number}'**
  String pilotLinkReviewTitle(int number);

  /// Explains the pilot link review.
  ///
  /// In en, this message translates to:
  /// **'Two devices linked this pilot to different participants. Choose the participant this pilot is linked to on every device.'**
  String get pilotLinkReviewIntro;

  /// The participant the account's link names.
  ///
  /// In en, this message translates to:
  /// **'Link the account has now: {name}'**
  String pilotLinkReviewKept(String name);

  /// The participant the other device's latest link names.
  ///
  /// In en, this message translates to:
  /// **'Link from the other device: {name}'**
  String pilotLinkReviewOther(String name);

  /// Shown instead of a name when the participant is not in the list.
  ///
  /// In en, this message translates to:
  /// **'a participant who is not in your list'**
  String get pilotLinkReviewNoParticipant;

  /// Button that keeps the account's link.
  ///
  /// In en, this message translates to:
  /// **'Keep {name}'**
  String pilotLinkReviewKeep(String name);

  /// Button that takes the other device's link.
  ///
  /// In en, this message translates to:
  /// **'Use {name}'**
  String pilotLinkReviewUse(String name);

  /// Shown when the link under review changed before the decision arrived.
  ///
  /// In en, this message translates to:
  /// **'This pilot\'s link changed while you were reviewing. The comparison is refreshed; decide again.'**
  String get pilotLinkReviewChanged;

  /// Shown when a participant was edited during the pilot import review.
  ///
  /// In en, this message translates to:
  /// **'Your participants changed while you were reviewing. Review again before importing.'**
  String get pilotImportChangedDuringReview;

  /// Button that opens the file chooser again after it failed.
  ///
  /// In en, this message translates to:
  /// **'Choose a file again'**
  String get pilotImportChooseAgain;

  /// Button that rebuilds the pilot import review.
  ///
  /// In en, this message translates to:
  /// **'Review again'**
  String get pilotImportReviewAgain;

  /// Navigation rail destination, page title and breadcrumb: contest publication.
  ///
  /// In en, this message translates to:
  /// **'Publication'**
  String get shellNavPublication;

  /// Title of the publication card on the contest workspace and of the Publication page.
  ///
  /// In en, this message translates to:
  /// **'Publication'**
  String get publicationCardTitle;

  /// Current publication state: the contest was never published.
  ///
  /// In en, this message translates to:
  /// **'Unpublished'**
  String get publicationStateUnpublished;

  /// Current publication state: published with the given visibility.
  ///
  /// In en, this message translates to:
  /// **'Published, {visibility}'**
  String publicationStatePublished(String visibility);

  /// Current publication state when it could not be read.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get publicationStateUnknown;

  /// Current publication state when nobody is signed in, so the hosted server cannot be asked.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get publicationStateSignIn;

  /// Reason publishing is disabled while nobody is signed in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to publish. Publishing goes through the hosted server.'**
  String get publicationSignInReason;

  /// Shown when publishing was refused because nobody is signed in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to publish this contest.'**
  String get publicationFailSignIn;

  /// Shown when the server refused a publication call although the director was signed in.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in expired. Sign in again to publish this contest.'**
  String get publicationFailSignInExpired;

  /// Shown when the hosted server does not know the contest because it has not synced.
  ///
  /// In en, this message translates to:
  /// **'The server does not have this contest yet. Wait for it to sync, then publish again.'**
  String get publicationFailNotSynced;

  /// Current publication state when the server does not publish contests.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get publicationStateUnavailable;

  /// Visibility of a publication that only people with the link can see.
  ///
  /// In en, this message translates to:
  /// **'Unlisted'**
  String get publicationVisibilityUnlisted;

  /// Visibility of a publication listed on the public site.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicationVisibilityPublic;

  /// Visibility of a publication removed from public view.
  ///
  /// In en, this message translates to:
  /// **'Delisted'**
  String get publicationVisibilityDelisted;

  /// What publishing does, shown on the publication card before the first publish.
  ///
  /// In en, this message translates to:
  /// **'Publishing puts a copy of the results on the public site. It starts Unlisted: only people with the link can see it.'**
  String get publicationScopeUnpublished;

  /// Publication card: when the results were last published.
  ///
  /// In en, this message translates to:
  /// **'Last published {time}.'**
  String publicationScopePublished(String time);

  /// The public update policy Automatic, read only.
  ///
  /// In en, this message translates to:
  /// **'Public updates: automatic after each score.'**
  String get publicationPolicyAutomatic;

  /// The public update policy RoundCompletion, read only.
  ///
  /// In en, this message translates to:
  /// **'Public updates: after each completed round.'**
  String get publicationPolicyRoundCompletion;

  /// The public update policy Manual, read only.
  ///
  /// In en, this message translates to:
  /// **'Public updates: only when you publish.'**
  String get publicationPolicyManual;

  /// Shown when the contest has no saved public update policy.
  ///
  /// In en, this message translates to:
  /// **'Public updates: not set yet.'**
  String get publicationPolicyUnknown;

  /// Link from the publication card to the configuration page where the update policy is set.
  ///
  /// In en, this message translates to:
  /// **'Change in Configuration'**
  String get publicationChangePolicy;

  /// Button that starts publishing a contest for the first time.
  ///
  /// In en, this message translates to:
  /// **'Publish results'**
  String get publicationActionPublish;

  /// Button that publishes the contest's current results again.
  ///
  /// In en, this message translates to:
  /// **'Publish update'**
  String get publicationActionUpdate;

  /// Button that lists the publication on the public site.
  ///
  /// In en, this message translates to:
  /// **'Make public'**
  String get publicationActionMakePublic;

  /// Button that removes the publication from the public list but keeps its link working.
  ///
  /// In en, this message translates to:
  /// **'Make unlisted'**
  String get publicationActionMakeUnlisted;

  /// Button on the workspace card that opens the Publication page.
  ///
  /// In en, this message translates to:
  /// **'Open Publication page'**
  String get publicationActionOpenPage;

  /// Button that reads the publication again after a failed read.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get publicationActionRetry;

  /// Reason a publication action is disabled while offline.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection.'**
  String get publicationNeedsConnection;

  /// Reason publishing is disabled on an embedded server.
  ///
  /// In en, this message translates to:
  /// **'This server does not publish contests.'**
  String get publicationUnavailableReason;

  /// Reason publishing is disabled when reading the publication failed.
  ///
  /// In en, this message translates to:
  /// **'The publication could not be read, so its state is not shown.'**
  String get publicationUnknownReason;

  /// Hint shown on the Publication page for a contest that is not completed.
  ///
  /// In en, this message translates to:
  /// **'You can publish at any time. Most directors publish once the contest is completed.'**
  String get publicationNotCompletedHint;

  /// Title of the confirmation dialog for publishing.
  ///
  /// In en, this message translates to:
  /// **'Publish results?'**
  String get publishDialogTitle;

  /// First line of the publish confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This copies the contest as it is now to the public site.'**
  String get publishDialogBody;

  /// Publish dialog: the contest revision that will be published.
  ///
  /// In en, this message translates to:
  /// **'Contest revision: {revision}'**
  String publishDialogRevision(String revision);

  /// Publish dialog: who can see the publication afterwards.
  ///
  /// In en, this message translates to:
  /// **'Visibility: {visibility}'**
  String publishDialogVisibility(String visibility);

  /// Confirm button of the publish dialog.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishDialogConfirm;

  /// Title of the confirmation dialog for making a publication Public.
  ///
  /// In en, this message translates to:
  /// **'Make results public?'**
  String get publicDialogTitle;

  /// Body of the make public dialog.
  ///
  /// In en, this message translates to:
  /// **'The results will be listed on the public site, where anyone can find them.'**
  String get publicDialogBody;

  /// Confirm button of the make public dialog.
  ///
  /// In en, this message translates to:
  /// **'Make public'**
  String get publicDialogConfirm;

  /// Cancel button of the publication dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get publicationDialogCancel;

  /// Snackbar after a successful publish.
  ///
  /// In en, this message translates to:
  /// **'Results published.'**
  String get publicationPublishedDone;

  /// Snackbar after a visibility change.
  ///
  /// In en, this message translates to:
  /// **'Visibility is now {visibility}.'**
  String publicationVisibilityDone(String visibility);

  /// Publish refused because the contest moved on.
  ///
  /// In en, this message translates to:
  /// **'The contest changed since you opened this page. Review it and publish again.'**
  String get publicationFailStaleContest;

  /// Publish refused because results are stale.
  ///
  /// In en, this message translates to:
  /// **'The results are out of date. Recalculate them and publish again.'**
  String get publicationFailStaleResults;

  /// Publish refused for another conflict.
  ///
  /// In en, this message translates to:
  /// **'The contest is not ready to publish yet.'**
  String get publicationFailNotReady;

  /// Change refused because the publication is delisted.
  ///
  /// In en, this message translates to:
  /// **'This publication was delisted and can no longer change.'**
  String get publicationFailDelisted;

  /// Change refused because the server cannot publish.
  ///
  /// In en, this message translates to:
  /// **'This server does not publish contests.'**
  String get publicationFailUnavailable;

  /// Change refused because the caller is not the director.
  ///
  /// In en, this message translates to:
  /// **'Only the contest\'s director can publish it.'**
  String get publicationFailNotDirector;

  /// Change failed because of a network error.
  ///
  /// In en, this message translates to:
  /// **'The server could not be reached. Check your connection and try again.'**
  String get publicationFailNetwork;

  /// Change failed for an unknown reason.
  ///
  /// In en, this message translates to:
  /// **'Publishing failed. Try again.'**
  String get publicationFailOther;

  /// Current publication state: published with the given visibility and a delisting request waiting for a system administrator.
  ///
  /// In en, this message translates to:
  /// **'Published, {visibility}. Delisting requested.'**
  String publicationStatePublishedDelistPending(String visibility);

  /// Button that asks a system administrator to remove the publication from public view.
  ///
  /// In en, this message translates to:
  /// **'Request delisting'**
  String get publicationActionRequestDelisting;

  /// Button that withdraws the pending delisting request.
  ///
  /// In en, this message translates to:
  /// **'Withdraw delisting request'**
  String get publicationActionWithdrawDelisting;

  /// Title of the confirmation dialog for requesting delisting.
  ///
  /// In en, this message translates to:
  /// **'Request delisting?'**
  String get delistDialogTitle;

  /// Body of the request delisting dialog.
  ///
  /// In en, this message translates to:
  /// **'Delisting removes the publication from public view. A system administrator approves or denies the request, and you can withdraw it while it is pending. Nothing in the contest becomes read-only while a request is pending.'**
  String get delistDialogBody;

  /// Label of the optional reason field in the request delisting dialog.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get delistDialogReasonLabel;

  /// Confirm button of the request delisting dialog.
  ///
  /// In en, this message translates to:
  /// **'Request delisting'**
  String get delistDialogConfirm;

  /// Snackbar after a delisting request was made.
  ///
  /// In en, this message translates to:
  /// **'Delisting requested.'**
  String get publicationDelistRequestedDone;

  /// Snackbar after a delisting request was withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Delisting request withdrawn.'**
  String get publicationDelistWithdrawnDone;

  /// Delisting refused because the publication is not Public.
  ///
  /// In en, this message translates to:
  /// **'Delisting can only be requested for a Public publication.'**
  String get publicationFailNotPublic;

  /// Withdrawing refused because no request is pending.
  ///
  /// In en, this message translates to:
  /// **'There is no pending delisting request any more.'**
  String get publicationFailNothingPending;

  /// Publication page: a delisting request is waiting.
  ///
  /// In en, this message translates to:
  /// **'Delisting requested {time}. A system administrator will decide.'**
  String publicationPageDelistPending(String time);

  /// Heading of the list of every published copy on the Publication page.
  ///
  /// In en, this message translates to:
  /// **'Publication history'**
  String get publicationPageHistoryTitle;

  /// One published copy in the history list.
  ///
  /// In en, this message translates to:
  /// **'Copy {number}, from contest revision {revision}, {time}'**
  String publicationPageHistoryEntry(
    String number,
    String revision,
    String time,
  );

  /// History list: the director published this copy.
  ///
  /// In en, this message translates to:
  /// **'Published by you'**
  String get publicationPageHistoryByYou;

  /// Publication history attribution when the publisher is not known to be the current account.
  ///
  /// In en, this message translates to:
  /// **'Published by a director'**
  String get publicationPageHistoryByDirector;

  /// History list: the update policy published this copy after a score.
  ///
  /// In en, this message translates to:
  /// **'Updated automatically'**
  String get publicationPageHistoryAutomatic;

  /// Shown instead of the history list when reading it failed.
  ///
  /// In en, this message translates to:
  /// **'The publication history could not be read.'**
  String get publicationPageHistoryFailed;

  /// Heading on the Publication page for the current projection.
  ///
  /// In en, this message translates to:
  /// **'Latest published copy'**
  String get publicationPageLatestCopy;

  /// Publication page: the projection revision.
  ///
  /// In en, this message translates to:
  /// **'Copy {number}'**
  String publicationPageCopyNumber(String number);

  /// Publication page: contest revision of the latest copy.
  ///
  /// In en, this message translates to:
  /// **'Made from contest revision {revision}'**
  String publicationPageFromRevision(String revision);

  /// Publication page: when the latest copy was made.
  ///
  /// In en, this message translates to:
  /// **'Published {time}'**
  String publicationPagePublishedAt(String time);

  /// Publication page: empty state before the first publish.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been published yet.'**
  String get publicationPageNoCopy;

  /// Publication page: failure to load the contest.
  ///
  /// In en, this message translates to:
  /// **'The contest could not be loaded.'**
  String get publicationPageLoadFailed;

  /// Shown instead of the public update policy when the contest's configuration could not be read.
  ///
  /// In en, this message translates to:
  /// **'Public updates: the policy could not be read.'**
  String get publicationPolicyUnreadable;

  /// Overall results card: current value when results are shown.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get resultsCardVisible;

  /// Overall results card: current value while results are hidden. The time is in the contest time zone.
  ///
  /// In en, this message translates to:
  /// **'Hidden through round {round}, ends at {time}'**
  String resultsCardHidden(int round, String time);

  /// Overall results card: what hiding does, shown while results are visible.
  ///
  /// In en, this message translates to:
  /// **'Hiding removes overall scores and placing from the public site and participant views. Round scores stay visible.'**
  String get resultsCardScopeVisible;

  /// Overall results card: what is hidden and when hiding ends, shown while results are hidden.
  ///
  /// In en, this message translates to:
  /// **'Overall scores and placing are hidden from the public site and participant views. Hiding ends by itself 24 hours after it was turned on, or when the contest completes. Showing results ends it now.'**
  String get resultsCardScopeHidden;

  /// Overall results card: countdown while hidden. The time is a phrase such as 5 hours.
  ///
  /// In en, this message translates to:
  /// **'{time} left before results show again.'**
  String resultsCardRemaining(String time);

  /// Duration in whole hours for the results hiding countdown.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String resultsCardRemainingHours(int hours);

  /// Duration in whole minutes for the results hiding countdown, under an hour.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String resultsCardRemainingMinutes(int minutes);

  /// Button that hides overall results.
  ///
  /// In en, this message translates to:
  /// **'Hide results'**
  String get resultsCardHide;

  /// Button that shows overall results again.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get resultsCardShow;

  /// Button label while results are being hidden.
  ///
  /// In en, this message translates to:
  /// **'Hiding…'**
  String get resultsCardHideBusy;

  /// Button label while results are being shown.
  ///
  /// In en, this message translates to:
  /// **'Showing…'**
  String get resultsCardShowBusy;

  /// Snackbar after hiding results.
  ///
  /// In en, this message translates to:
  /// **'Results hidden. They show again after 24 hours, or when you show them or the contest completes.'**
  String get resultsCardHiddenMessage;

  /// Snackbar after showing results.
  ///
  /// In en, this message translates to:
  /// **'Results are visible again.'**
  String get resultsCardShownMessage;

  /// Overall results card: reason the button is disabled while offline.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection.'**
  String get resultsCardNeedsConnection;

  /// Overall results card: reason the button is disabled when the contest is not running.
  ///
  /// In en, this message translates to:
  /// **'Results can be hidden only while the contest is running.'**
  String get resultsCardNotRunning;

  /// Overall results card: snackbar when there is no server connection object.
  ///
  /// In en, this message translates to:
  /// **'No API client is available.'**
  String get resultsCardNoApi;

  /// Names the change in the stale-page banner: Your change to results hiding was not applied.
  ///
  /// In en, this message translates to:
  /// **'results hiding'**
  String get resultsCardWhat;

  /// Next to the disabled Save row button while a zero score has not been confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm the zero above to enable Save row.'**
  String get scoreSaveNeedsZeroConfirm;

  /// Title of the dialog shown before Save rows records unconfirmed zeros.
  ///
  /// In en, this message translates to:
  /// **'Confirm zero scores'**
  String get scoreSaveAllZeroTitle;

  /// Body of the confirm-zeros dialog; pilots is a comma separated list of names.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{This row will be saved as a zero: {pilots}.} other{These {count} rows will be saved as zeros: {pilots}.}}'**
  String scoreSaveAllZeroBody(int count, String pilots);

  /// Button that confirms the zeros and saves every row.
  ///
  /// In en, this message translates to:
  /// **'Confirm and save'**
  String get scoreSaveAllZeroConfirm;

  /// Button that closes the confirm-zeros dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get scoreSaveAllZeroCancel;

  /// Shown on the scoring toolbar while rows are being saved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Saving 1 row…} other{Saving {count} rows…}}'**
  String scoreSavingRows(int count);

  /// Button on the Contests page that imports competitions from a GliderScore database as contests.
  ///
  /// In en, this message translates to:
  /// **'Import from GliderScore…'**
  String get competitionImportButton;

  /// Title of the dialog that imports competitions from a GliderScore database.
  ///
  /// In en, this message translates to:
  /// **'Import GliderScore competitions'**
  String get competitionImportTitle;

  /// Shown while the file chooser is open.
  ///
  /// In en, this message translates to:
  /// **'Choose a GliderScore file…'**
  String get competitionImportChoosing;

  /// Shown while the GliderScore file is read.
  ///
  /// In en, this message translates to:
  /// **'Reading {file}…'**
  String competitionImportReading(String file);

  /// Button that stops reading the GliderScore file.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get competitionImportCancelReading;

  /// Introduction above the list of competitions found in a GliderScore file.
  ///
  /// In en, this message translates to:
  /// **'Choose the competitions to import. Each becomes a contest with its settings, participants, draw and scores, as GliderScore last held them. Importing the same competition again replaces what was imported before.'**
  String get competitionImportIntro;

  /// Shown when none of the competitions in the file can be imported.
  ///
  /// In en, this message translates to:
  /// **'This file has no competition that can be imported.'**
  String get competitionImportNothingImportable;

  /// Chooses every competition that can be imported.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get competitionImportSelectAll;

  /// Drops the choice of every competition.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get competitionImportSelectNone;

  /// Details under a competition name: date, GliderScore class and number of participants.
  ///
  /// In en, this message translates to:
  /// **'{date} · {className} · {count, plural, =1{1 participant} other{{count} participants}}'**
  String competitionImportRowDetails(String date, String className, int count);

  /// Note on a competition whose teams get generated names.
  ///
  /// In en, this message translates to:
  /// **'Teams are named Team 1, Team 2 and so on, because GliderScore has no team names. You can rename them afterwards.'**
  String get competitionImportWarningTeamNames;

  /// Note on a competition that has other import warnings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more note: a setting was adjusted} other{{count} more notes: settings were adjusted}}'**
  String competitionImportWarningOther(int count);

  /// Why a competition of a class that will be supported later cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'This class is not imported yet.'**
  String get competitionImportReasonClassNotSupportedYet;

  /// Why a competition of an unsupported class cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'Soar Score does not support this class.'**
  String get competitionImportReasonClassOutOfScope;

  /// Why a competition of an unknown class cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'This class is not known.'**
  String get competitionImportReasonClassUnknown;

  /// Why a competition without settings cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'The settings of this competition are missing from the file.'**
  String get competitionImportReasonConfigMissing;

  /// Why a competition without a date cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'This competition has no date.'**
  String get competitionImportReasonDateMissing;

  /// Why a competition with invalid settings cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'The settings of this competition are not valid.'**
  String get competitionImportReasonConfigInvalid;

  /// Why a competition without importable participants cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'Nobody in this competition can be imported.'**
  String get competitionImportReasonNoParticipants;

  /// Why a competition for an unlisted reason cannot be chosen.
  ///
  /// In en, this message translates to:
  /// **'This competition cannot be imported.'**
  String get competitionImportReasonOther;

  /// Button that moves to the next step of the competition import.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get competitionImportContinue;

  /// Button that returns to the previous step of the competition import.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get competitionImportBack;

  /// Number of competitions chosen so far.
  ///
  /// In en, this message translates to:
  /// **'{count} chosen'**
  String competitionImportChosenCount(int count);

  /// Introduction on the last step before the competitions are written.
  ///
  /// In en, this message translates to:
  /// **'Check what will be written, then import.'**
  String get competitionImportConfirmIntro;

  /// Summary line: number of contests the import creates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contest will be created.} other{{count} contests will be created.}}'**
  String competitionImportSummaryContests(int count);

  /// Summary line: participants the import adds and updates.
  ///
  /// In en, this message translates to:
  /// **'{added} participants will be added and {updated} updated.'**
  String competitionImportSummaryPilots(int added, int updated);

  /// Button that writes the chosen competitions.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get competitionImportConfirm;

  /// Shown while the competitions are written.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get competitionImportSaving;

  /// Note under an imported competition about participants that were left out.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant was left out because no pilot was chosen for them.} other{{count} participants were left out because no pilot was chosen for them.}}'**
  String competitionImportResultSkippedPilots(int count);

  /// Result line for a competition that could not be imported.
  ///
  /// In en, this message translates to:
  /// **'{name}: not imported. {reason}'**
  String competitionImportResultFailed(String name, String reason);

  /// Button that opens an imported contest.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get competitionImportOpen;

  /// Button that closes the competition import after it finished.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get competitionImportDoneButton;

  /// Why a competition could not be imported: no account.
  ///
  /// In en, this message translates to:
  /// **'There is no account to own the contest.'**
  String get competitionImportFailNoAccount;

  /// Why a competition could not be imported: it is blocked or skipped.
  ///
  /// In en, this message translates to:
  /// **'This competition cannot be imported.'**
  String get competitionImportFailNotImportable;

  /// Why a competition could not be imported: no discipline profile.
  ///
  /// In en, this message translates to:
  /// **'No scoring rules are available for this class.'**
  String get competitionImportFailProfileUnavailable;

  /// Why a competition could not be imported: invalid settings.
  ///
  /// In en, this message translates to:
  /// **'Its settings are not valid for the scoring rules.'**
  String get competitionImportFailConfigInvalid;

  /// Why a competition could not be imported: a participant profile is gone.
  ///
  /// In en, this message translates to:
  /// **'A participant you chose is no longer in your list.'**
  String get competitionImportFailProfileMissing;

  /// Why a competition could not be imported: pilots of the draw were skipped.
  ///
  /// In en, this message translates to:
  /// **'Pilots who flew or were drawn were not chosen in the pilot step (GliderScore pilot numbers {pilots}). Import again and add them.'**
  String competitionImportFailDrawParticipant(String pilots);

  /// Why a competition could not be imported: any other reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong and nothing of this competition was kept.'**
  String get competitionImportFailOther;

  /// Shown when reading the file or saving the pilots failed.
  ///
  /// In en, this message translates to:
  /// **'The import failed: {error}'**
  String competitionImportFailed(String error);

  /// Number of scored flights a competition has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no scored flights} =1{1 scored flight} other{{count} scored flights}}'**
  String competitionImportRowFlights(int count);

  /// Checkbox on a chosen competition: finish the contest.
  ///
  /// In en, this message translates to:
  /// **'Mark the contest Completed'**
  String get competitionImportCompleted;

  /// Explains the Completed checkbox.
  ///
  /// In en, this message translates to:
  /// **'Closes the contest: rounds are locked and rounds that were not flown are cancelled. Leave it off to carry on scoring in Soar Score.'**
  String get competitionImportCompletedHint;

  /// Note on a competition with retired pilots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pilot is marked retired. The round they retired from is taken from their last score.} other{{count} pilots are marked retired. The round they retired from is taken from their last score.}}'**
  String competitionImportWarningRetirement(int count);

  /// Note on a competition with re-flights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 re-flight is imported as an extra group after the regular groups of its round.} other{{count} re-flights are imported as extra groups after the regular groups of their rounds.}}'**
  String competitionImportWarningReflights(int count);

  /// Note on motor restarts kept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 flight has a motor restart that GliderScore did not count. Its score is kept.} other{{count} flights have a motor restart that GliderScore did not count. Their scores are kept.}}'**
  String competitionImportWarningRestart(int count);

  /// Note on rounds only partly flown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round has flights without a score.} other{{count} rounds have flights without a score.}}'**
  String competitionImportWarningUnflown(int count);

  /// Note on flights with nothing recorded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 flight has no time, landing or penalty and is imported as a zero.} other{{count} flights have no time, landing or penalty and are imported as zeros.}}'**
  String competitionImportWarningZero(int count);

  /// Note on landing values that match no table entry.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 landing value is not in the landing table and is left out.} other{{count} landing values are not in the landing table and are left out.}}'**
  String competitionImportWarningLanding(int count);

  /// Shown on a competition that was imported before.
  ///
  /// In en, this message translates to:
  /// **'Imported before as \"{name}\". Importing replaces that contest and keeps its place in your list.'**
  String competitionImportTargetReplaces(String name);

  /// Shown on a competition already up to date.
  ///
  /// In en, this message translates to:
  /// **'Imported before, and the file has not changed. Nothing will be written.'**
  String get competitionImportTargetUnchanged;

  /// Shown when the contest was changed after the import.
  ///
  /// In en, this message translates to:
  /// **'Changed in Soar Score since: {scores, plural, =0{no scores entered} =1{1 score entered} other{{scores} scores entered}}. Importing replaces them.'**
  String competitionImportTargetChanges(int scores);

  /// Shown when a replace is refused because the contest synced.
  ///
  /// In en, this message translates to:
  /// **'This contest has been sent to the server and cannot be replaced yet. Delete it to import the competition again.'**
  String get competitionImportTargetSynced;

  /// Shown when a replace is refused because the results are published.
  ///
  /// In en, this message translates to:
  /// **'Its results are published. Unpublish them before importing again.'**
  String get competitionImportTargetPublished;

  /// Shown on a competition without an id whose number matches an earlier import.
  ///
  /// In en, this message translates to:
  /// **'A contest imported from competition number {number} exists: \"{name}\", {date}. This competition has no id to tell whether it is the same one.'**
  String competitionImportTargetNumberMatch(
    int number,
    String name,
    String date,
  );

  /// Switch on the number-match note.
  ///
  /// In en, this message translates to:
  /// **'It is the same competition: replace \"{name}\"'**
  String competitionImportTargetSame(String name);

  /// Summary: contests replaced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contest will be replaced.} other{{count} contests will be replaced.}}'**
  String competitionImportSummaryReplaced(int count);

  /// Summary: contests with nothing to write.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contest is already up to date.} other{{count} contests are already up to date.}}'**
  String competitionImportSummaryUnchanged(int count);

  /// Summary: scored flights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No scored flights will be imported.} =1{1 scored flight will be imported.} other{{count} scored flights will be imported.}}'**
  String competitionImportSummaryFlights(int count);

  /// Summary: contests completed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contest will be marked Completed.} other{{count} contests will be marked Completed.}}'**
  String competitionImportSummaryCompleted(int count);

  /// Summary: explains the check.
  ///
  /// In en, this message translates to:
  /// **'Soar Score recalculates every flight and compares it with GliderScore\'s score. If one differs, nothing of that competition is kept.'**
  String get competitionImportSummaryCheck;

  /// Checkbox before replacing changed contests.
  ///
  /// In en, this message translates to:
  /// **'I understand that what I changed in these contests after the last import is replaced.'**
  String get competitionImportConfirmReplace;

  /// Result line for a competition imported.
  ///
  /// In en, this message translates to:
  /// **'{name}: imported. {flights, plural, =0{No scored flights.} =1{1 scored flight.} other{{flights} scored flights.}}'**
  String competitionImportResultRestored(String name, int flights);

  /// Result line for a competition that replaced an earlier import.
  ///
  /// In en, this message translates to:
  /// **'{name}: replaced with the file\'s content. {flights, plural, =0{No scored flights.} =1{1 scored flight.} other{{flights} scored flights.}}'**
  String competitionImportResultReplaced(String name, int flights);

  /// Result line for a competition with nothing to write.
  ///
  /// In en, this message translates to:
  /// **'{name}: already up to date. Nothing was changed.'**
  String competitionImportResultUnchanged(String name);

  /// Result line for a refused competition.
  ///
  /// In en, this message translates to:
  /// **'{name}: not imported. {reason}'**
  String competitionImportResultRefused(String name, String reason);

  /// Result: the check against GliderScore failed.
  ///
  /// In en, this message translates to:
  /// **'Soar Score could not reproduce GliderScore\'s scores for {count, plural, =1{1 flight} other{{count} flights}}, so nothing of this competition was kept. First: {flights}.'**
  String competitionImportFailComparison(int count, String flights);

  /// One flight named in a failed check.
  ///
  /// In en, this message translates to:
  /// **'round {round}, group {group}, pilot {pilot}'**
  String competitionImportMismatchFlight(int round, int group, int pilot);

  /// Reason: a partial re-flight.
  ///
  /// In en, this message translates to:
  /// **'This competition has a re-flight that does not cover a whole group. Those cannot be imported.'**
  String get competitionImportReasonReflights;

  /// Reason: flights cannot be represented.
  ///
  /// In en, this message translates to:
  /// **'Some scores cannot be turned into Soar Score scores: {detail}'**
  String competitionImportReasonFlights(String detail);

  /// Reason: scores table missing.
  ///
  /// In en, this message translates to:
  /// **'The scores of this competition are not in the file.'**
  String get competitionImportReasonNoScores;

  /// Reason: credit moved.
  ///
  /// In en, this message translates to:
  /// **'A flight was moved to another round in GliderScore. Moved flights cannot be imported.'**
  String get competitionImportReasonMoved;

  /// Reason: draw not importable.
  ///
  /// In en, this message translates to:
  /// **'The rounds or flights of this competition are not in a form that can be imported.'**
  String get competitionImportReasonRounds;

  /// Refusal: synced.
  ///
  /// In en, this message translates to:
  /// **'This contest has been sent to the server and cannot be replaced yet.'**
  String get competitionImportRefuseSynced;

  /// Refusal: published.
  ///
  /// In en, this message translates to:
  /// **'Its results are published. Unpublish them first.'**
  String get competitionImportRefusePublished;

  /// Refusal: needs confirmation.
  ///
  /// In en, this message translates to:
  /// **'The contest was changed in Soar Score. Confirm the replace and try again.'**
  String get competitionImportRefuseConfirm;

  /// Refusal: not restorable.
  ///
  /// In en, this message translates to:
  /// **'The contest to replace is not one made by an import.'**
  String get competitionImportRefuseNotRestorable;

  /// Title of the banner on a contest that was imported from GliderScore.
  ///
  /// In en, this message translates to:
  /// **'Imported from GliderScore on {date}'**
  String importedContestNoteTitle(String date);

  /// Banner text: what an imported contest holds and what importing again does.
  ///
  /// In en, this message translates to:
  /// **'The draw, scores, re-flights and retirements are as GliderScore held them when the file was made. Importing the competition again replaces them.'**
  String get importedContestNoteBody;

  /// Banner text on an imported draw without lanes.
  ///
  /// In en, this message translates to:
  /// **'GliderScore used no lanes, so none are set.'**
  String get importedContestNoteNoLanes;

  /// Chip on the detail of a contest that was imported from GliderScore.
  ///
  /// In en, this message translates to:
  /// **'Imported from GliderScore'**
  String get importedChipLabel;

  /// Tooltip of the imported chip.
  ///
  /// In en, this message translates to:
  /// **'Imported from GliderScore on {date}'**
  String importedChipTooltip(String date);

  /// Title of the dialog that confirms creating the QR codes on the pilot cards.
  ///
  /// In en, this message translates to:
  /// **'Send invitations?'**
  String get pilotCardsSendTitle;

  /// Body of the confirmation before invitations are sent: links and QR codes are created, and pilots with an address are emailed.
  ///
  /// In en, this message translates to:
  /// **'A link and QR code will be created for each of these pilots who has none, so the cards can carry them. Pilots with an email address on file are also emailed their link.'**
  String get pilotCardsSendBody;

  /// How many QR codes will be created.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 QR code} other{{count} QR codes}}'**
  String pilotCardsQrCount(int count);

  /// Follows the QR code count in the confirmation.
  ///
  /// In en, this message translates to:
  /// **' — one per pilot, the same on every reprint.'**
  String get pilotCardsSendCountNote;

  /// Cancel button of the pilot cards dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pilotCardsCancel;

  /// Confirm button that creates the QR codes on the pilot cards.
  ///
  /// In en, this message translates to:
  /// **'Send invitations'**
  String get pilotCardsSendConfirm;

  /// Title of the reminder shown before printing cards that have no QR code.
  ///
  /// In en, this message translates to:
  /// **'Some cards will print without QR codes.'**
  String get pilotCardsReminderTitle;

  /// Reminder body when none of the selected cards has a QR code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This card doesn’t have a QR code yet.} other{None of these {count} cards have a QR code yet.}} Pilots without one can’t scan to enter scores.'**
  String pilotCardsReminderNone(int count);

  /// Reminder body when some of the selected cards have no QR code.
  ///
  /// In en, this message translates to:
  /// **'{missing} of {selected, plural, =1{1 card} other{{selected} cards}} {missing, plural, =1{doesn’t} other{don’t}} have a QR code yet. Pilots without one can’t scan to enter scores.'**
  String pilotCardsReminderSome(int missing, int selected);

  /// Reason beside the print reminder when the contest was organized offline and has not synchronized.
  ///
  /// In en, this message translates to:
  /// **'This contest hasn’t synchronized, so QR codes can’t be made yet.'**
  String get pilotCardsReminderUnsynced;

  /// Reason beside the print reminder when the device is offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline, so invitations can’t be sent now. QR codes already issued still print.'**
  String get pilotCardsReminderOffline;

  /// Button in the print reminder that creates the QR codes, then prints.
  ///
  /// In en, this message translates to:
  /// **'Send invitations and print'**
  String get pilotCardsReminderSend;

  /// Button in the print reminder that prints the cards as they are.
  ///
  /// In en, this message translates to:
  /// **'Print without QR codes'**
  String get pilotCardsReminderWithout;

  /// Reason invitations cannot be sent: nobody is signed in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send invitations.'**
  String get pilotCardsUnavailableSignIn;

  /// Reason invitations cannot be sent: the server issues none.
  ///
  /// In en, this message translates to:
  /// **'This server doesn’t issue invitations, so QR codes can’t be made.'**
  String get pilotCardsUnavailableServer;

  /// Reason invitations cannot be sent: existing links cannot be reproduced.
  ///
  /// In en, this message translates to:
  /// **'Some invitations can’t be shown as QR codes because the server’s invitation secret changed after they were issued.'**
  String get pilotCardsUnavailableLinks;

  /// Reason invitations cannot be sent: this build has no invitation support.
  ///
  /// In en, this message translates to:
  /// **'Sending invitations isn’t available in this version of the app yet.'**
  String get pilotCardsUnavailableVersion;

  /// Lead of the banner while QR codes are being created.
  ///
  /// In en, this message translates to:
  /// **'Creating QR codes.'**
  String get pilotCardsSendingLead;

  /// Text of the banner while QR codes are being created.
  ///
  /// In en, this message translates to:
  /// **'Creating {count, plural, =1{1 QR code} other{{count} QR codes}}. Print is paused until the codes are ready; you can keep changing options.'**
  String pilotCardsSendingText(int count);

  /// Lead of the banner after creating QR codes failed.
  ///
  /// In en, this message translates to:
  /// **'QR codes could not be created.'**
  String get pilotCardsFailedLead;

  /// Text of the banner after creating QR codes failed.
  ///
  /// In en, this message translates to:
  /// **'No QR codes were added. Check the connection and try again, or print without QR codes.'**
  String get pilotCardsFailedText;

  /// Retry button on the pilot cards banners.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get pilotCardsRetry;

  /// Lead of the banner when the codes were created but could not be loaded back.
  ///
  /// In en, this message translates to:
  /// **'QR codes were created.'**
  String get pilotCardsNotLoadedLead;

  /// Text of the banner when the codes were created but could not be loaded back.
  ///
  /// In en, this message translates to:
  /// **'The QR codes could not be loaded, so the cards do not show them yet. No need to create them again: they already exist.'**
  String get pilotCardsNotLoadedText;

  /// Button that loads the QR codes again.
  ///
  /// In en, this message translates to:
  /// **'Load QR codes'**
  String get pilotCardsLoadCodes;

  /// Lead of the banner after the QR codes were created.
  ///
  /// In en, this message translates to:
  /// **'QR codes created.'**
  String get pilotCardsSentLead;

  /// Text of the banner after the QR codes were created.
  ///
  /// In en, this message translates to:
  /// **'The cards now carry them.'**
  String get pilotCardsSentText;

  /// Dismiss button on the QR codes created banner.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get pilotCardsDismiss;

  /// Lead of the banner when the invitations could not be read.
  ///
  /// In en, this message translates to:
  /// **'QR codes could not be loaded.'**
  String get pilotCardsLoadFailedLead;

  /// Text of the banner when the invitations could not be read.
  ///
  /// In en, this message translates to:
  /// **'The cards print without QR codes until they load. Check the connection and retry.'**
  String get pilotCardsLoadFailedText;

  /// Lead of the banner for a contest that has not synchronized.
  ///
  /// In en, this message translates to:
  /// **'No QR codes yet.'**
  String get pilotCardsUnsyncedLead;

  /// Text of the banner for a contest that has not synchronized.
  ///
  /// In en, this message translates to:
  /// **'This contest was organized offline and hasn’t synchronized. Sync it first to create QR codes. Cards print without them.'**
  String get pilotCardsUnsyncedText;

  /// Lead of the banner when the device is offline.
  ///
  /// In en, this message translates to:
  /// **'Offline.'**
  String get pilotCardsOfflineLead;

  /// Text of the banner when the device is offline.
  ///
  /// In en, this message translates to:
  /// **'Connect to send invitations. QR codes already issued still print.'**
  String get pilotCardsOfflineText;

  /// Lead of the banner for cards that have no QR code.
  ///
  /// In en, this message translates to:
  /// **'No QR code.'**
  String get pilotCardsMissingLead;

  /// Banner text when no selected card has a QR code.
  ///
  /// In en, this message translates to:
  /// **'Some cards have no QR code. Send invitations to add them.'**
  String get pilotCardsMissingAll;

  /// Banner text when some selected cards have no QR code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 card has} other{{count} cards have}} no QR code. Send invitations to add them.'**
  String pilotCardsMissingCount(int count);

  /// Added to the banner text when invitations cannot be sent, with the reason.
  ///
  /// In en, this message translates to:
  /// **'{reason} You can still print without QR codes.'**
  String pilotCardsMissingReason(String reason);

  /// Button on the banner that creates the QR codes.
  ///
  /// In en, this message translates to:
  /// **'Send invitations'**
  String get pilotCardsSendAction;

  /// Title of the workspace card that sends pilot invitations.
  ///
  /// In en, this message translates to:
  /// **'Pilot invitations'**
  String get invitationsSectionTitle;

  /// Shown while the workspace invitations card loads.
  ///
  /// In en, this message translates to:
  /// **'Loading invitations…'**
  String get invitationsLoading;

  /// Shown when the workspace invitations card could not load.
  ///
  /// In en, this message translates to:
  /// **'The invitations could not be loaded. Check the connection and retry.'**
  String get invitationsLoadFailed;

  /// Workspace invitations card text when the contest has no pilots.
  ///
  /// In en, this message translates to:
  /// **'Add pilots to the contest to send invitations.'**
  String get invitationsNoPilots;

  /// Workspace invitations card text when some pilots have no invitation.
  ///
  /// In en, this message translates to:
  /// **'{have} of {total, plural, =1{1 pilot has} other{{total} pilots have}} a QR code. Sending creates the rest and emails the pilots who have an address.'**
  String invitationsCoverage(int have, int total);

  /// Workspace invitations card text when every pilot has an invitation.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{The pilot has} other{All {total} pilots have}} a QR code. Print the pilot cards to hand them out, or send again to email the link again.'**
  String invitationsCoverageAll(int total);

  /// Button on the workspace invitations card that opens the pilot cards report.
  ///
  /// In en, this message translates to:
  /// **'Open pilot cards'**
  String get invitationsOpenCards;

  /// Workspace button that sends invitations to the pilots who have none and emails those who have an address.
  ///
  /// In en, this message translates to:
  /// **'Send invitations ({count})'**
  String invitationsSendMissing(int count);

  /// Snack bar after invitations were sent: how many pilots were sent one and how many were emailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invitation sent} other{{count} invitations sent}}. {emailed, plural, =0{Nobody was emailed.} =1{1 pilot emailed.} other{{emailed} pilots emailed.}}'**
  String invitationsSentSnack(int count, int emailed);

  /// Snack bar after sending when the outcome of some emails is unknown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invitation sent} other{{count} invitations sent}}. {emailed} confirmed emailed, {unknown} not confirmed: they may or may not have been emailed, so check before sending again.'**
  String invitationsSentUnconfirmedSnack(int count, int emailed, int unknown);

  /// Shown in the send result dialog for pilots whose names are not known, so they are still counted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pilot whose name could not be loaded} other{{count} pilots whose names could not be loaded}}'**
  String invitationsResultUnnamed(int count);

  /// Added to the snack bar after sending when some pilots have no email address, so only their link exists.
  ///
  /// In en, this message translates to:
  /// **' {count, plural, =1{1 pilot has no email address on file.} other{{count} pilots have no email address on file.}}'**
  String invitationsSentNoAddressNote(int count);

  /// Heading above the names of the pilots in the send invitations confirmation.
  ///
  /// In en, this message translates to:
  /// **'Sending to'**
  String get invitationsSendNamesTitle;

  /// Note in the send invitations confirmation about how the email is sent and that the link never depends on it.
  ///
  /// In en, this message translates to:
  /// **'Pilots with an email address on file are emailed their link from the notifications address. Replies to that address are not read. The link and QR code work whatever happens to the email.'**
  String get invitationsSendEmailNote;

  /// Note in the send invitations confirmation when some pilots were already emailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 of these pilots was emailed before and will be emailed again.} other{{count} of these pilots were emailed before and will be emailed again.}}'**
  String invitationsSendAgainNote(int count);

  /// Title of the dialog after sending when some pilots could not be emailed.
  ///
  /// In en, this message translates to:
  /// **'Some pilots were not emailed'**
  String get invitationsResultTitle;

  /// Lead of the dialog listing the pilots who were not emailed.
  ///
  /// In en, this message translates to:
  /// **'The links and QR codes are ready. Copy these pilots\' links or print their cards to hand them over.'**
  String get invitationsResultLead;

  /// Dialog text when the server could not send email at all after the links were created.
  ///
  /// In en, this message translates to:
  /// **'Email could not be sent right now, so nobody was emailed. The links and QR codes are ready: copy them or print the cards, or send again later.'**
  String get invitationsResultServiceDown;

  /// Heading above the pilots who have no email address in the send result.
  ///
  /// In en, this message translates to:
  /// **'No email address on file'**
  String get invitationsResultNoAddress;

  /// Heading above the pilots whose email the mail service refused or could not send.
  ///
  /// In en, this message translates to:
  /// **'Email not sent'**
  String get invitationsResultNotSent;

  /// Heading above the pilots who were not emailed because the hourly limit was reached.
  ///
  /// In en, this message translates to:
  /// **'Hourly limit of emails reached. Send again later'**
  String get invitationsResultLimit;

  /// Heading above the pilots whose email has an unknown outcome.
  ///
  /// In en, this message translates to:
  /// **'May or may not have been sent'**
  String get invitationsResultUnknown;

  /// Button that closes the send result dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get invitationsResultClose;

  /// Snack bar after invitations were created but could not be read back.
  ///
  /// In en, this message translates to:
  /// **'The invitations were created, but could not be loaded back. Reload the page to see them.'**
  String get invitationsSentNotLoadedSnack;

  /// Snack bar after creating invitations failed.
  ///
  /// In en, this message translates to:
  /// **'The invitations could not be created. Nothing was sent. Try again.'**
  String get invitationsSendFailedSnack;

  /// Participants toolbar button that opens the invitations menu.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitationsMenu;

  /// Participants invitations menu item that sends invitations to the selected pilots: creates links for those who have none and emails every pilot with an address.
  ///
  /// In en, this message translates to:
  /// **'Send invitations'**
  String get invitationsMenuSend;

  /// Participants invitations menu item with the number of selected pilots it sends to.
  ///
  /// In en, this message translates to:
  /// **'Send invitations ({count})'**
  String invitationsMenuSendCount(int count);

  /// Snack bar after a pilot's invitation link was copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get invitationsLinkCopied;

  /// Reason the invitations menu cannot send: nothing selected.
  ///
  /// In en, this message translates to:
  /// **'Select pilots to send invitations.'**
  String get invitationsSelectPilots;

  /// Reason the copy link item is off: not exactly one pilot selected.
  ///
  /// In en, this message translates to:
  /// **'Select one pilot to copy a link.'**
  String get invitationsSelectOne;

  /// Reason the copy link item is off: the pilot has no invitation.
  ///
  /// In en, this message translates to:
  /// **'This pilot has no invitation yet. Send one first.'**
  String get invitationsNoLinkYet;

  /// Reason the invitations menu is off: the selection holds no pilot.
  ///
  /// In en, this message translates to:
  /// **'Only pilots get invitations.'**
  String get invitationsOnlyPilots;

  /// Reason the invitations menu is off until the invitations were read.
  ///
  /// In en, this message translates to:
  /// **'Invitations are still loading.'**
  String get invitationsNotReady;

  /// Snack bar when copying an invitation link to the clipboard failed.
  ///
  /// In en, this message translates to:
  /// **'The link could not be copied.'**
  String get invitationsCopyFailed;

  /// Reason invitations cannot be sent: the device is offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline, so invitations can’t be sent now.'**
  String get invitationsOffline;

  /// Reason invitations cannot be sent: the internet is up but the server is unreachable.
  ///
  /// In en, this message translates to:
  /// **'The server can’t be reached, so invitations can’t be sent now.'**
  String get invitationsServerUnreachable;

  /// Participant row menu action that removes this participant from the contest.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get participantActionRemove;

  /// Participant menu action that creates an invitation for one pilot.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get participantActionSend;

  /// Participant menu action that copies one pilot’s invitation URL.
  ///
  /// In en, this message translates to:
  /// **'Copy invitation URL'**
  String get participantActionCopy;

  /// Tooltip for the participant row three-dot menu.
  ///
  /// In en, this message translates to:
  /// **'Participant actions'**
  String get participantActions;

  /// Reason Remove is off in a participant row menu: the pilot has flights.
  ///
  /// In en, this message translates to:
  /// **'Pilots with flights can’t be removed.'**
  String get participantRemoveHasFlights;

  /// Reason Remove is off in a participant row menu: the contest is locked, completed or saving.
  ///
  /// In en, this message translates to:
  /// **'Participants can’t be removed from this contest now.'**
  String get participantRemoveUnavailable;

  /// Indicator chip on a score row whose values a pilot or helper entered, whether or not the director has made them official.
  ///
  /// In en, this message translates to:
  /// **'Pilot entry'**
  String get scorePilotEntryChip;

  /// Tooltip of the Pilot entry chip.
  ///
  /// In en, this message translates to:
  /// **'Entered by a pilot or helper.'**
  String get scorePilotEntryTooltip;

  /// Tooltip of a Raw or Group score that is a preview of typed values not yet saved.
  ///
  /// In en, this message translates to:
  /// **'Preview. Saved when you save the row.'**
  String get scorePreviewTooltip;

  /// Short note under the Raw score of a row that is only partly entered, so no score can be shown yet.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get scoreIncomplete;

  /// Red line under the status chip of a row the director left with a mistake that blocks saving it.
  ///
  /// In en, this message translates to:
  /// **'Fix to save'**
  String get scoreFixToSave;

  /// Indicator chip on a score row whose review request waits for the director. Hidden until review decisions exist.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get scoreReviewChip;

  /// Tooltip of the Review chip.
  ///
  /// In en, this message translates to:
  /// **'A review request is pending. The review panel comes in a later release.'**
  String get scoreReviewTooltip;

  /// Name of the contest setting that chooses when submitted scores become official: the wizard option, its summary line and the Configuration page row.
  ///
  /// In en, this message translates to:
  /// **'Scores become official'**
  String get scoresBecomeOfficialLabel;

  /// Help text under the Scores become official setting.
  ///
  /// In en, this message translates to:
  /// **'Submitted scores are preliminary until they become official. This does not change when results are published.'**
  String get scoresBecomeOfficialHelp;

  /// Option of the Scores become official setting: the contest accepts a round's submitted scores once every required score of the round is submitted.
  ///
  /// In en, this message translates to:
  /// **'At end of round'**
  String get scoresBecomeOfficialEndOfRound;

  /// Explains the At end of round option.
  ///
  /// In en, this message translates to:
  /// **'When every score of a round has been submitted, the contest accepts them. This is the default for a new contest.'**
  String get scoresBecomeOfficialEndOfRoundHelp;

  /// Option of the Scores become official setting: the contest accepts a flight group's submitted scores once every required score of the group is submitted.
  ///
  /// In en, this message translates to:
  /// **'At end of flight group'**
  String get scoresBecomeOfficialEndOfGroup;

  /// Explains the At end of flight group option.
  ///
  /// In en, this message translates to:
  /// **'When every score of a flight group has been submitted, the contest accepts them.'**
  String get scoresBecomeOfficialEndOfGroupHelp;

  /// Option of the Scores become official setting: only the director makes scores official.
  ///
  /// In en, this message translates to:
  /// **'Manually'**
  String get scoresBecomeOfficialManual;

  /// Explains the Manually option.
  ///
  /// In en, this message translates to:
  /// **'Only you make scores official, one pilot or one group at a time.'**
  String get scoresBecomeOfficialManualHelp;

  /// Count in the scoring page's context strip: flights with a score entered (official or waiting for the director) out of the group's flights, then how many of them are official.
  ///
  /// In en, this message translates to:
  /// **'{entered} of {total} entered · {official} official'**
  String scoringEnteredOfficialCount(int entered, int total, int official);

  /// Button on a scoring row that accepts the pilot's own entry as the official score.
  ///
  /// In en, this message translates to:
  /// **'Mark official'**
  String get scoreMarkOfficial;

  /// Tooltip of the Mark official button of a row.
  ///
  /// In en, this message translates to:
  /// **'Accept {pilot}\'s entry as the official score.'**
  String scoreMarkOfficialTooltip(String pilot);

  /// Label of the Mark official button while the request is out.
  ///
  /// In en, this message translates to:
  /// **'Marking…'**
  String get scoreMarkOfficialMarking;

  /// Why Mark official is off on a row the director typed over.
  ///
  /// In en, this message translates to:
  /// **'Save or revert your edits first.'**
  String get scoreMarkOfficialEdited;

  /// Why Mark official is off on a locked row.
  ///
  /// In en, this message translates to:
  /// **'Entry is closed for this row.'**
  String get scoreMarkOfficialClosed;

  /// Banner after Mark official was refused because the row changed meanwhile.
  ///
  /// In en, this message translates to:
  /// **'Not marked official: the pilot\'s entry or the score changed since you opened this row. Check the values shown and mark it official again.'**
  String get scoreMarkOfficialChanged;

  /// Banner after the server refused Mark official (for example a locked score).
  ///
  /// In en, this message translates to:
  /// **'Not marked official: {message}'**
  String scoreMarkOfficialRefused(String message);

  /// Banner after the server refused Mark official without a reason.
  ///
  /// In en, this message translates to:
  /// **'Not marked official: the server refused it.'**
  String get scoreMarkOfficialRefusedNoReason;

  /// Banner after Mark official met a busy or unreachable server; Retry asks again.
  ///
  /// In en, this message translates to:
  /// **'Not marked official. The server is busy or could not be reached. Nothing was changed; try again.'**
  String get scoreMarkOfficialTryAgain;

  /// Button on the Mark official banner that asks the server again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scoreMarkOfficialRetry;

  /// Button on the Mark official banner that reads the page again.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get scoreMarkOfficialRefresh;

  /// Banner when Mark official was refused as changed and re-reading the row failed.
  ///
  /// In en, this message translates to:
  /// **'Not marked official: the pilot\'s entry or the score changed, and the newer values could not be read. Refresh to see them.'**
  String get scoreMarkOfficialReloadFailed;

  /// Banner after Mark official failed with a server error.
  ///
  /// In en, this message translates to:
  /// **'Not marked official. {message}'**
  String scoreMarkOfficialFailed(String message);

  /// Toolbar button that accepts every waiting pilot entry of the group as official.
  ///
  /// In en, this message translates to:
  /// **'Mark all valid rows official'**
  String get scoreMarkAllOfficial;

  /// Tooltip of the disabled Mark all button when every waiting entry is held back.
  ///
  /// In en, this message translates to:
  /// **'No row is ready to mark official. Save or revert edited rows, wait for a save in progress, or open a review first.'**
  String get scoreMarkAllNoneValid;

  /// Part of the Mark all dialog and result.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row with unsaved edits is left out.} other{{count} rows with unsaved edits are left out.}}'**
  String scoreMarkAllSkipEdited(int count);

  /// Part of the Mark all dialog and result.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row with an open review is left out.} other{{count} rows with an open review are left out.}}'**
  String scoreMarkAllSkipReview(int count);

  /// Part of the Mark all dialog and result.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 locked row is left out.} other{{count} locked rows are left out.}}'**
  String scoreMarkAllSkipClosed(int count);

  /// Part of the Mark all dialog and result.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 retired pilot is left out.} other{{count} retired pilots are left out.}}'**
  String scoreMarkAllSkipRetired(int count);

  /// Snackbar after Mark all.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Marked 1 row official.} other{Marked {count} rows official.}}'**
  String scoreMarkAllDone(int count);

  /// Snackbar when Mark all made no row official.
  ///
  /// In en, this message translates to:
  /// **'Nothing was marked official.'**
  String get scoreMarkAllNothing;

  /// Part of the Mark all result.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row changed since you opened it.} other{{count} rows changed since you opened them.}}'**
  String scoreMarkAllChanged(int count);

  /// Part of the Mark all result.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row was refused.} other{{count} rows were refused.}}'**
  String scoreMarkAllRefused(int count);

  /// Part of the Mark all result for rows to try again.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row was not marked; try it again.} other{{count} rows were not marked; try them again.}}'**
  String scoreMarkAllRetry(int count);

  /// Part of the Mark all result for rows whose adoption is queued on this device until the service decides it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row is waiting to sync.} other{{count} rows are waiting to sync.}}'**
  String scoreMarkAllQueued(int count);

  /// Part of the Mark all result for rows whose Mark official is already queued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 row already waiting to sync is left out.} other{{count} rows already waiting to sync are left out.}}'**
  String scoreMarkAllSkipWaiting(int count);

  /// Why Mark official is off on a row whose adoption is queued for the service.
  ///
  /// In en, this message translates to:
  /// **'Queued; the service decides it when this device syncs.'**
  String get scoreMarkOfficialWaiting;

  /// Snackbar after Mark official was queued instead of applied.
  ///
  /// In en, this message translates to:
  /// **'Mark official for {pilot} is queued and will be reviewed when this device syncs.'**
  String scoreMarkOfficialQueued(String pilot);

  /// Status chip of a scoring row whose official score the contest accepted on its own and the director has not confirmed.
  ///
  /// In en, this message translates to:
  /// **'Official · auto'**
  String get scoreAcceptedAutomatically;

  /// Explanation under the Official · automatic chip of a scoring row.
  ///
  /// In en, this message translates to:
  /// **'Confirm it to close it to review.'**
  String get scoreAutomaticNote;

  /// Note on a scoring row whose automatically accepted score is locked, so review and Confirm no longer apply.
  ///
  /// In en, this message translates to:
  /// **'Official (auto). This score is locked.'**
  String get scoreAutomaticLocked;

  /// Status chip of a scoring row with typed values that are not saved yet.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get scoreStatusUnsaved;

  /// Status chip of a scoring row with no score yet.
  ///
  /// In en, this message translates to:
  /// **'Not entered'**
  String get scoreStatusNotEntered;

  /// Status chip of a scoring row with a preliminary pilot entry.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get scoreStatusSubmitted;

  /// Status chip of a scoring row with an official score.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get scoreStatusOfficial;

  /// Status chip of a scoring row that is locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get scoreStatusLocked;

  /// Status chip of a scoring row whose pilot is retired from the round.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get scoreStatusRetired;

  /// Context strip chip: the round has no scores yet.
  ///
  /// In en, this message translates to:
  /// **'Round not flown'**
  String get scoreRoundNotFlown;

  /// Context strip chip: some, not all, scores of the round are in.
  ///
  /// In en, this message translates to:
  /// **'Round in progress'**
  String get scoreRoundInProgress;

  /// Context strip chip: every score of the round is in.
  ///
  /// In en, this message translates to:
  /// **'Round scored'**
  String get scoreRoundScored;

  /// Context strip chip when the group is not locked.
  ///
  /// In en, this message translates to:
  /// **'Open for entry'**
  String get scoreOpenForEntry;

  /// Context strip chip counting rows with unsaved scores.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsaved row} other{{count} unsaved rows}}'**
  String scoreUnsavedRows(int count);

  /// Tooltip of the round or group picker button.
  ///
  /// In en, this message translates to:
  /// **'Go to…'**
  String get scorePickerGoTo;

  /// Title of the flight penalty card.
  ///
  /// In en, this message translates to:
  /// **'Flight penalty'**
  String get scoreFlightPenaltyTitle;

  /// Title of the cumulative penalty card.
  ///
  /// In en, this message translates to:
  /// **'Cumulative penalty'**
  String get scoreCumulativePenaltyTitle;

  /// Lead of the flight penalty help line; the bold word and the rest follow in their own keys.
  ///
  /// In en, this message translates to:
  /// **'Deducted from '**
  String get scorePenaltyFlightHelp1;

  /// Bold word in the flight penalty help line.
  ///
  /// In en, this message translates to:
  /// **'this flight'**
  String get scorePenaltyFlightThisFlight;

  /// Middle of the flight penalty help line.
  ///
  /// In en, this message translates to:
  /// **' (never below 0). '**
  String get scorePenaltyFlightHelp2;

  /// Bold word in the flight penalty help line.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get scorePenaltyFlightDropped;

  /// Tail of the flight penalty help line.
  ///
  /// In en, this message translates to:
  /// **' if this round is dropped.'**
  String get scorePenaltyFlightHelp3;

  /// Lead of the cumulative penalty help line; the bold word and the rest follow in their own keys.
  ///
  /// In en, this message translates to:
  /// **'Deducted from the '**
  String get scorePenaltyCumulativeHelp1;

  /// Bold word in the cumulative penalty help line.
  ///
  /// In en, this message translates to:
  /// **'contest total'**
  String get scorePenaltyCumulativeContestTotal;

  /// Middle of the cumulative penalty help line.
  ///
  /// In en, this message translates to:
  /// **'. '**
  String get scorePenaltyCumulativeHelp2;

  /// Bold word in the cumulative penalty help line.
  ///
  /// In en, this message translates to:
  /// **'Never dropped'**
  String get scorePenaltyCumulativeNeverDropped;

  /// Tail of the cumulative penalty help line.
  ///
  /// In en, this message translates to:
  /// **', and still counts if this flight is re-flown.'**
  String get scorePenaltyCumulativeHelp3;

  /// State of the cumulative penalty field while it is empty.
  ///
  /// In en, this message translates to:
  /// **'No cumulative penalty.'**
  String get scorePenaltyCumulativeNone;

  /// State of the cumulative penalty field when its value is not a whole number of 0 or more.
  ///
  /// In en, this message translates to:
  /// **'A whole number of points, 0 or more.'**
  String get scorePenaltyCumulativeInvalid;

  /// State of the cumulative penalty field when it was set to 0.
  ///
  /// In en, this message translates to:
  /// **'Removed. Removing is recorded as an official correction.'**
  String get scorePenaltyCumulativeRemoved;

  /// State of the cumulative penalty field when a positive value is set.
  ///
  /// In en, this message translates to:
  /// **'Applied: {count} points from the contest total.'**
  String scorePenaltyCumulativeApplied(String count);

  /// Banner under a score row whose save failed; message is the reason.
  ///
  /// In en, this message translates to:
  /// **'Not saved. {message} Your values are kept.'**
  String scoreSaveNotSaved(String message);

  /// Banner under a score row whose save was refused; reason is the server's text or a fallback.
  ///
  /// In en, this message translates to:
  /// **'Refused: {reason}. Your values are kept.'**
  String scoreSaveRefused(String reason);

  /// Fallback reason when the server refuses a save without a message.
  ///
  /// In en, this message translates to:
  /// **'the entry was not accepted'**
  String get scoreSaveRefusedNoReason;

  /// Stale-row banner action that keeps the director's typed values.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get scoreSaveKeepMine;

  /// Stale-row banner action that takes the newer stored values.
  ///
  /// In en, this message translates to:
  /// **'Take the newer'**
  String get scoreSaveTakeNewer;

  /// Stale-row banner text naming the director's and the newer stored values.
  ///
  /// In en, this message translates to:
  /// **'This row changed since you opened it. Yours: {mine}. Newer: {newer}.'**
  String scoreSaveStaleText(String mine, String newer);

  /// Value summary when a row or its other side has no values.
  ///
  /// In en, this message translates to:
  /// **'nothing entered'**
  String get scoreSaveNothingEntered;

  /// Save-failed banner action that retries the save.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scoreSaveRetry;

  /// Save-failed or refused banner action that re-reads the row.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get scoreSaveRefresh;

  /// Note on a row whose Confirm is queued for the service.
  ///
  /// In en, this message translates to:
  /// **'Confirm is queued; the service decides it when this device syncs.'**
  String get scoreConfirmQueuedNote;

  /// Button on a scoring row that confirms a score the contest accepted automatically.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get scoreConfirm;

  /// Label of the Confirm button while the request is out.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get scoreConfirming;

  /// Tooltip of the Confirm button of a row.
  ///
  /// In en, this message translates to:
  /// **'Confirm {pilot}\'s automatically accepted score as the director\'s decision.'**
  String scoreConfirmTooltip(String pilot);

  /// Line under the status chip of a row whose Confirm is queued until the service decides it.
  ///
  /// In en, this message translates to:
  /// **'Confirm is queued'**
  String get scoreConfirmWaiting;

  /// Banner after Confirm was refused because the row changed meanwhile.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed: the score changed since you opened this row. Check the values shown and confirm again.'**
  String get scoreConfirmChanged;

  /// Banner when Confirm was refused as changed and re-reading the row failed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed: the score changed, and the newer values could not be read. Refresh to see them.'**
  String get scoreConfirmReloadFailed;

  /// Snackbar after Confirm was queued instead of applied.
  ///
  /// In en, this message translates to:
  /// **'Confirm for {pilot} is queued and will be decided when this device syncs.'**
  String scoreConfirmQueued(String pilot);

  /// Banner after the server refused Confirm.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed: {message}'**
  String scoreConfirmRefused(String message);

  /// Banner after Confirm met a busy or unreachable server; Retry asks again.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm. The server was busy or could not be reached, so the confirmation may or may not have been recorded. Check the row, then try again.'**
  String get scoreConfirmTryAgain;

  /// Who made a score official in the score history when the contest accepted it on its own.
  ///
  /// In en, this message translates to:
  /// **'System (automatic)'**
  String get scoreHistoryAutomatic;

  /// Line on a score history entry naming who made it official.
  ///
  /// In en, this message translates to:
  /// **'Made official by {who}'**
  String scoreHistoryMadeOfficialBy(String who);

  /// Who made a stored submission official in the score history when a director did it.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get scoreHistoryDirector;

  /// Line on a score history entry adopted by a director, naming who sent it.
  ///
  /// In en, this message translates to:
  /// **'Submitted by {who}'**
  String scoreHistorySubmittedBy(String who);

  /// Note on the current version in the score history when the director confirmed an automatically accepted score.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by the director'**
  String get scoreHistoryConfirmed;

  /// Line under the status chip of a row whose Mark official is queued until the service decides it.
  ///
  /// In en, this message translates to:
  /// **'Mark official is queued'**
  String get scoreAdoptionWaiting;

  /// Row on the sync page: queued changes the service cannot take until it is updated.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a newer service'**
  String get syncWaitingForNewerService;

  /// Name of a refused Mark official change on the sync page.
  ///
  /// In en, this message translates to:
  /// **'Mark official'**
  String get syncRefusedScorePromotion;

  /// Button that closes the Score check result panel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get scoreCheckClose;

  /// Header of the Score check panel when the check found nothing.
  ///
  /// In en, this message translates to:
  /// **'All {count} pilots entered, nothing out of range.'**
  String scoreCheckClean(int count);

  /// Header of the Score check panel when the check found problems.
  ///
  /// In en, this message translates to:
  /// **'{findings} to look at for {pilots} of {checked} pilots.'**
  String scoreCheckFindings(int findings, int pilots, int checked);

  /// Button that closes a dialog or panel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Button that saves the current values.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Dialog button that keeps the app open instead of closing it.
  ///
  /// In en, this message translates to:
  /// **'Keep open'**
  String get commonKeepOpen;

  /// Snackbar after saving rows.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} {count, plural, =1{row} other{rows}}.'**
  String scoreSavedRows(int count);

  /// Title of a pilot's score history dialog.
  ///
  /// In en, this message translates to:
  /// **'Score history · {pilot}'**
  String scoreHistoryTitle(String pilot);

  /// Title of the group score history dialog.
  ///
  /// In en, this message translates to:
  /// **'Group history'**
  String get scoreHistoryGroupTitle;

  /// Snackbar after a pilot was retired.
  ///
  /// In en, this message translates to:
  /// **'{pilot} retired from round {round}.'**
  String scoreRetiredFromRound(String pilot, int round);

  /// Snackbar after a pilot was reinstated.
  ///
  /// In en, this message translates to:
  /// **'{pilot} reinstated.'**
  String scoreReinstated(String pilot);

  /// Page state when there is no API client.
  ///
  /// In en, this message translates to:
  /// **'No API client is available.'**
  String get scoreNoApiClient;

  /// Title of the load-failed view on the scoring page.
  ///
  /// In en, this message translates to:
  /// **'The scores could not be loaded.'**
  String get scoreLoadFailed;

  /// Loading label while the scoring page reads its data.
  ///
  /// In en, this message translates to:
  /// **'Loading the scores'**
  String get scoreLoading;

  /// Empty-state title on the scoring page before the matrix is drawn.
  ///
  /// In en, this message translates to:
  /// **'This contest has no matrix yet.'**
  String get scoreNoMatrixTitle;

  /// Empty-state body on the scoring page before the matrix is drawn.
  ///
  /// In en, this message translates to:
  /// **'Draw the matrix first. Then scores can be entered here.'**
  String get scoreNoMatrixBody;

  /// Action on the empty scoring state that opens the Matrix page.
  ///
  /// In en, this message translates to:
  /// **'Open the matrix'**
  String get scoreOpenMatrix;

  /// Button on the recalculation-warning banner that re-reads the page.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get scoreRefresh;

  /// Empty-state title when the group has no pilots.
  ///
  /// In en, this message translates to:
  /// **'No pilots in this group.'**
  String get scoreNoPilotsTitle;

  /// Empty-state body when the group has no pilots.
  ///
  /// In en, this message translates to:
  /// **'Every pilot assigned here is absent or retired.'**
  String get scoreNoPilotsBody;

  /// Label of the time field.
  ///
  /// In en, this message translates to:
  /// **'Time flown (m:ss)'**
  String get scoreTimeLabel;

  /// Label of the launch height field.
  ///
  /// In en, this message translates to:
  /// **'Launch height (m)'**
  String get scoreHeightLabel;

  /// Label of the landing field.
  ///
  /// In en, this message translates to:
  /// **'Landing (pts)'**
  String get scoreLandingLabel;

  /// Note under a valid launch height: its height penalty in points.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String scorePointsNote(String points);

  /// Caption of the landing field on a late landing.
  ///
  /// In en, this message translates to:
  /// **'0 · late'**
  String get scoreLandingLate;

  /// Caption of the landing field when the contest has no landing table.
  ///
  /// In en, this message translates to:
  /// **'No landing table'**
  String get scoreNoLandingTable;

  /// Error caption when the typed landing points are not in the table.
  ///
  /// In en, this message translates to:
  /// **'{value} isn’t in the landing table. Use {hint}'**
  String scoreLandingBad(String value, String hint);

  /// Caption of an empty landing field that has focus.
  ///
  /// In en, this message translates to:
  /// **'Type table points: {hint}'**
  String scoreLandingTypeHint(String hint);

  /// Caption of a focused landing field whose band is chosen.
  ///
  /// In en, this message translates to:
  /// **'{display} · {points} pts'**
  String scoreLandingSelected(String display, int points);

  /// Caption of a landing field whose band is chosen, not focused.
  ///
  /// In en, this message translates to:
  /// **'{display} · {points}'**
  String scoreLandingBand(String display, int points);

  /// Status chip of a late landing.
  ///
  /// In en, this message translates to:
  /// **'Late landing'**
  String get scoreFlagLateLanding;

  /// Status chip of a motor restart.
  ///
  /// In en, this message translates to:
  /// **'Motor restart'**
  String get scoreFlagMotorRestart;

  /// Status chip of an out-of-bounds flight.
  ///
  /// In en, this message translates to:
  /// **'Out of bounds'**
  String get scoreFlagOutOfBounds;

  /// Status chip of a flight with no recorded altitude.
  ///
  /// In en, this message translates to:
  /// **'No altitude'**
  String get scoreFlagNoAltitude;

  /// Label of the penalties column.
  ///
  /// In en, this message translates to:
  /// **'Penalties'**
  String get scorePenaltiesLabel;

  /// Penalty cell value for a flight penalty.
  ///
  /// In en, this message translates to:
  /// **'{count} flight'**
  String scoreFlightPenalty(int count);

  /// Penalty cell when there is no penalty.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get scorePenaltyNone;

  /// Penalty cell when an applied cumulative penalty was removed.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get scorePenaltyRemoved;

  /// Penalty cell value for a cumulative penalty.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String scoreCumulativePenalty(int count);

  /// Label of the indicators column.
  ///
  /// In en, this message translates to:
  /// **'Indicators'**
  String get scoreIndicatorsLabel;

  /// Status line naming how many Score check findings a row has.
  ///
  /// In en, this message translates to:
  /// **'Check: {count}'**
  String scoreCheckCount(int count);

  /// Status line of a retired row, naming the first round the pilot does not fly.
  ///
  /// In en, this message translates to:
  /// **'Retired from round {round}'**
  String scoreRetiredNote(int round);

  /// Tooltip of the row three-dot menu.
  ///
  /// In en, this message translates to:
  /// **'More for {pilot}'**
  String scoreMoreTooltip(String pilot);

  /// Row menu action that opens the score history.
  ///
  /// In en, this message translates to:
  /// **'Score history'**
  String get scoreHistoryMenu;

  /// Row menu action that retires the pilot.
  ///
  /// In en, this message translates to:
  /// **'Retire pilot from this round on'**
  String get scoreRetireMenu;

  /// Row menu action that takes a retirement back.
  ///
  /// In en, this message translates to:
  /// **'Reinstate pilot (retired from round {round})'**
  String scoreReinstateMenu(int round);

  /// Disabled row menu action for correcting a locked score.
  ///
  /// In en, this message translates to:
  /// **'Correct a locked score · Later release'**
  String get scoreLockedLater;

  /// Tooltip of the team badge when the pilot has no team.
  ///
  /// In en, this message translates to:
  /// **'No team'**
  String get scoreNoTeam;

  /// Line under a pilot's name: their pilot number.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String scorePilotNo(int number);

  /// Label of the raw score cell.
  ///
  /// In en, this message translates to:
  /// **'Raw score'**
  String get scoreRawLabel;

  /// Label of the group score cell.
  ///
  /// In en, this message translates to:
  /// **'Group score'**
  String get scoreGroupLabel;

  /// Accessibility status word for a row with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'unsaved changes'**
  String get scoreSemUnsaved;

  /// Accessibility status word for a row with no score.
  ///
  /// In en, this message translates to:
  /// **'not entered'**
  String get scoreSemNotEntered;

  /// Accessibility status word for a row with a waiting submission.
  ///
  /// In en, this message translates to:
  /// **'submitted by a participant'**
  String get scoreSemSubmitted;

  /// Accessibility status word for a row whose score was accepted automatically.
  ///
  /// In en, this message translates to:
  /// **'accepted automatically'**
  String get scoreSemAcceptedAuto;

  /// Accessibility status word for an official score.
  ///
  /// In en, this message translates to:
  /// **'official'**
  String get scoreSemOfficial;

  /// Accessibility status word for a locked row.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get scoreSemLocked;

  /// Accessibility status word for a retired row.
  ///
  /// In en, this message translates to:
  /// **'retired'**
  String get scoreSemRetired;

  /// Note when the typed launch height is unusually high.
  ///
  /// In en, this message translates to:
  /// **'{height} m is a high launch. Is this correct? You can still save.'**
  String scoreHighLaunch(int height);

  /// Note when the launch height is 0.
  ///
  /// In en, this message translates to:
  /// **'0 m is not a launch height. Saving it as No altitude recorded scores 0.'**
  String get scoreZeroHeight;

  /// Action of the zero-height note.
  ///
  /// In en, this message translates to:
  /// **'Turn on No altitude recorded'**
  String get scoreTurnOnNoAltitude;

  /// Heading of the landing section in the entry band.
  ///
  /// In en, this message translates to:
  /// **'Landing'**
  String get scoreLandingHeading;

  /// Tag on the landing choice while the Landing field has focus.
  ///
  /// In en, this message translates to:
  /// **'Follows the Landing field · type table points, ↑↓ to step'**
  String get scoreLandingFollows;

  /// Note in the entry band when the contest has no landing table.
  ///
  /// In en, this message translates to:
  /// **'The contest has no landing table. Choose one on the Configuration page.'**
  String get scoreNoLandingTableBand;

  /// Toggle label for a late landing.
  ///
  /// In en, this message translates to:
  /// **'Late landing'**
  String get scoreLateLanding;

  /// Note under the Late landing toggle.
  ///
  /// In en, this message translates to:
  /// **'Landing bonus is not given.'**
  String get scoreLateLandingNote;

  /// Toggle label for a motor restart.
  ///
  /// In en, this message translates to:
  /// **'Motor restart'**
  String get scoreMotorRestart;

  /// Note under the Motor restart toggle.
  ///
  /// In en, this message translates to:
  /// **'Scores 0.'**
  String get scoreMotorRestartZero;

  /// Note under the Motor restart toggle when the zero cannot be dropped.
  ///
  /// In en, this message translates to:
  /// **'Scores 0, and the zero cannot be dropped.'**
  String get scoreMotorRestartNonDroppable;

  /// Toggle label for an out-of-bounds flight.
  ///
  /// In en, this message translates to:
  /// **'Out of bounds'**
  String get scoreOutOfBounds;

  /// Note under the Out of bounds toggle.
  ///
  /// In en, this message translates to:
  /// **'Landed more than 75 m from the marker. Scores 0.'**
  String get scoreOutOfBoundsNote;

  /// Toggle label for a flight with no recorded altitude.
  ///
  /// In en, this message translates to:
  /// **'No altitude recorded'**
  String get scoreNoAltitude;

  /// Note under the No altitude recorded toggle.
  ///
  /// In en, this message translates to:
  /// **'Scores 0.'**
  String get scoreNoAltitudeNote;

  /// Label of the Save row button while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get scoreSaving;

  /// Button that saves the active row.
  ///
  /// In en, this message translates to:
  /// **'Save row'**
  String get scoreSaveRow;

  /// Button that reverts the active row's edits.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get scoreRevert;

  /// Hint of the entry band about the Enter key.
  ///
  /// In en, this message translates to:
  /// **'Enter moves on. Enter on the penalty saves and opens the next pilot.'**
  String get scoreEnterHint;

  /// Zero-confirmation note when the row is blank.
  ///
  /// In en, this message translates to:
  /// **'Nothing is entered. Saving records No flight, a zero.'**
  String get scoreZeroWhyBlank;

  /// Zero-confirmation note when the row scores 0.
  ///
  /// In en, this message translates to:
  /// **'Saving scores 0 for this pilot.'**
  String get scoreZeroWhy;

  /// Note after the zero was confirmed.
  ///
  /// In en, this message translates to:
  /// **'Zero confirmed. Save the row to record it.'**
  String get scoreZeroConfirmed;

  /// Action of the zero-confirmation note.
  ///
  /// In en, this message translates to:
  /// **'Confirm zero'**
  String get scoreConfirmZero;

  /// Empty state of the score history.
  ///
  /// In en, this message translates to:
  /// **'No scores have been entered yet.'**
  String get scoreHistoryEmpty;

  /// Footer of the score history naming the zone.
  ///
  /// In en, this message translates to:
  /// **'Times are in the contest time zone ({zone}).'**
  String scoreHistoryTimesZone(String zone);

  /// Author of a score history entry: the director.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get scoreHistoryAuthorityDirector;

  /// Author of a score history entry: the pilot.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get scoreHistoryAuthorityParticipant;

  /// Author of a score history entry: a helper.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get scoreHistoryAuthorityHelper;

  /// Author of a score history entry: the system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get scoreHistoryAuthoritySystem;

  /// Author of a score history entry: an administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get scoreHistoryAuthorityAdmin;

  /// Outcome chip of the current score history entry.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get scoreHistoryCurrent;

  /// Outcome chip of a superseded entry.
  ///
  /// In en, this message translates to:
  /// **'Replaced'**
  String get scoreHistoryReplaced;

  /// Outcome chip of an entry the contest did not adopt.
  ///
  /// In en, this message translates to:
  /// **'Not adopted'**
  String get scoreHistoryNotAdopted;

  /// Outcome chip of an entry awaiting a review decision.
  ///
  /// In en, this message translates to:
  /// **'Awaiting decision'**
  String get scoreHistoryPending;

  /// Heading of a score history entry with no revision.
  ///
  /// In en, this message translates to:
  /// **'Submission'**
  String get scoreHistorySubmission;

  /// Heading of a score history entry naming its revision.
  ///
  /// In en, this message translates to:
  /// **'Revision {revision}'**
  String scoreHistoryRevision(int revision);

  /// Line of a score history entry naming the correction reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String scoreHistoryReason(String reason);

  /// Title of the round picker.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String scoreToolbarRoundTitle(int current, int total);

  /// Choice in the round picker.
  ///
  /// In en, this message translates to:
  /// **'Round {ordinal}'**
  String scoreToolbarRoundChoice(int ordinal);

  /// Sub-line of a round picker choice: its number of groups.
  ///
  /// In en, this message translates to:
  /// **'{count} groups'**
  String scoreToolbarGroups(int count);

  /// Title of the group picker.
  ///
  /// In en, this message translates to:
  /// **'Group {letter} of {count}'**
  String scoreToolbarGroupTitle(String letter, int count);

  /// Sub-line of a round or group picker choice: its number of pilots.
  ///
  /// In en, this message translates to:
  /// **'{count} pilots'**
  String scoreToolbarPilots(int count);

  /// Choice in the group picker.
  ///
  /// In en, this message translates to:
  /// **'Group {letter}'**
  String scoreToolbarGroupChoice(String letter);

  /// Primary action when entry is closed.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get scoreToolbarSave;

  /// Primary action naming how many rows save.
  ///
  /// In en, this message translates to:
  /// **'Save {count} {count, plural, =1{row} other{rows}}'**
  String scoreToolbarSaveRows(int count);

  /// Primary action when nothing is dirty (locking not built).
  ///
  /// In en, this message translates to:
  /// **'Lock…'**
  String get scoreToolbarLock;

  /// Tooltip of the group three-dot menu.
  ///
  /// In en, this message translates to:
  /// **'More group actions'**
  String get scoreToolbarMoreTooltip;

  /// Group menu item that toggles the keyboard path numbers.
  ///
  /// In en, this message translates to:
  /// **'Show keyboard order'**
  String get scoreToolbarShowFocusOrder;

  /// Group menu item that opens the group history.
  ///
  /// In en, this message translates to:
  /// **'Group history'**
  String get scoreToolbarGroupHistory;

  /// Disabled group menu action for a group re-flight.
  ///
  /// In en, this message translates to:
  /// **'Re-flight group · Later release'**
  String get scoreToolbarReflightGroup;

  /// Disabled group menu action for a round re-flight.
  ///
  /// In en, this message translates to:
  /// **'Re-flight round · Later release'**
  String get scoreToolbarReflightRound;

  /// Tooltip of the first-round navigation button.
  ///
  /// In en, this message translates to:
  /// **'First round'**
  String get scoreToolbarFirstRound;

  /// Tooltip of the previous-round navigation button.
  ///
  /// In en, this message translates to:
  /// **'Previous round'**
  String get scoreToolbarPrevRound;

  /// Tooltip of the next-round navigation button.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get scoreToolbarNextRound;

  /// Tooltip of the last-round navigation button.
  ///
  /// In en, this message translates to:
  /// **'Last round'**
  String get scoreToolbarLastRound;

  /// Tooltip of the first-group navigation button.
  ///
  /// In en, this message translates to:
  /// **'First group'**
  String get scoreToolbarFirstGroup;

  /// Tooltip of the previous-group navigation button.
  ///
  /// In en, this message translates to:
  /// **'Previous group'**
  String get scoreToolbarPrevGroup;

  /// Tooltip of the next-group navigation button.
  ///
  /// In en, this message translates to:
  /// **'Next group'**
  String get scoreToolbarNextGroup;

  /// Tooltip of the last-group navigation button.
  ///
  /// In en, this message translates to:
  /// **'Last group'**
  String get scoreToolbarLastGroup;

  /// Button that runs the Score check.
  ///
  /// In en, this message translates to:
  /// **'Score check'**
  String get scoreToolbarScoreCheck;

  /// Tooltip of the disabled lock action.
  ///
  /// In en, this message translates to:
  /// **'Locking is not available in this build yet.'**
  String get scoreToolbarLockHint;

  /// Title of the penalty removal dialog for one pilot.
  ///
  /// In en, this message translates to:
  /// **'Remove {pilot}\'s penalty?'**
  String scorePenaltyRemoveTitleOne(String pilot);

  /// Title of the penalty removal dialog for several pilots.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} penalties?'**
  String scorePenaltyRemoveTitleMany(int count);

  /// Body of the penalty removal dialog.
  ///
  /// In en, this message translates to:
  /// **'Removal is an official score correction. Enter the reason to record it.'**
  String get scorePenaltyRemoveBody;

  /// Label of the correction reason field.
  ///
  /// In en, this message translates to:
  /// **'Correction reason'**
  String get scorePenaltyRemoveReason;

  /// Button that removes the penalties.
  ///
  /// In en, this message translates to:
  /// **'Remove penalty'**
  String get scorePenaltyRemoveButton;

  /// Title of the retire dialog.
  ///
  /// In en, this message translates to:
  /// **'Retire {pilot}?'**
  String scoreRetireTitle(String pilot);

  /// Title of the reinstate dialog.
  ///
  /// In en, this message translates to:
  /// **'Reinstate {pilot}?'**
  String scoreReinstateTitle(String pilot);

  /// Body of the retire dialog.
  ///
  /// In en, this message translates to:
  /// **'{pilot} retires from round {round} on. Their unscored flights from then on are not missing, and score entry is closed for them.'**
  String scoreRetireBody(String pilot, int round);

  /// Body of the reinstate dialog.
  ///
  /// In en, this message translates to:
  /// **'{pilot} will fly again from round {round} on. Their unscored flights count as missing again.'**
  String scoreReinstateBody(String pilot, int round);

  /// Line of the retire dialog when no round count changes.
  ///
  /// In en, this message translates to:
  /// **'No round count changes.'**
  String get scoreRetireNoChanges;

  /// Line of the retire dialog naming scores that stay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 score already entered from round {round} on stays and still counts.} other{{count} scores already entered from round {round} on stay and still count.}}'**
  String scoreRetireKeptScores(int count, int round);

  /// Button that retires the pilot.
  ///
  /// In en, this message translates to:
  /// **'Retire pilot'**
  String get scoreRetireButton;

  /// Button that reinstates the pilot.
  ///
  /// In en, this message translates to:
  /// **'Reinstate pilot'**
  String get scoreReinstateButton;

  /// Title of the unsaved-edits dialog.
  ///
  /// In en, this message translates to:
  /// **'Unsaved scores'**
  String get scoreUnsavedTitle;

  /// Title of the unsaved-edits dialog when closing the app.
  ///
  /// In en, this message translates to:
  /// **'Close RC Soar Score?'**
  String get scoreUnsavedCloseTitle;

  /// Body of the unsaved-edits dialog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row has scores that are not saved. Save them before you {action}?} other{{count} rows have scores that are not saved. Save them before you {action}?}}'**
  String scoreUnsavedBody(int count, String action);

  /// Action word in the unsaved-edits dialog when closing the app.
  ///
  /// In en, this message translates to:
  /// **'close the app'**
  String get scoreUnsavedActionClose;

  /// Action word in the unsaved-edits dialog when leaving the group.
  ///
  /// In en, this message translates to:
  /// **'leave this group'**
  String get scoreUnsavedActionLeave;

  /// Dialog button that stays on the group.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get scoreUnsavedStay;

  /// Dialog button that discards the unsaved rows.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get scoreUnsavedDiscard;

  /// Wizard step 1 title.
  ///
  /// In en, this message translates to:
  /// **'Details & copy source'**
  String get wizardStepDetailsCopySource;

  /// Wizard step 2 title.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get wizardStepDiscipline;

  /// Wizard step 3 title.
  ///
  /// In en, this message translates to:
  /// **'Participant options'**
  String get wizardStepParticipantOptions;

  /// Wizard step 4 title.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get wizardStepParticipants;

  /// Wizard step 5 title.
  ///
  /// In en, this message translates to:
  /// **'Scoring & publication'**
  String get wizardStepScoringPublication;

  /// Wizard step 6 title.
  ///
  /// In en, this message translates to:
  /// **'Draw options'**
  String get wizardStepDrawOptions;

  /// Wizard step 7 title.
  ///
  /// In en, this message translates to:
  /// **'Summary & create'**
  String get wizardStepSummaryCreate;

  /// Wizard step 1 intro.
  ///
  /// In en, this message translates to:
  /// **'Name the contest and say where it’s held. You can also start from an earlier contest.'**
  String get wizardIntroDetailsCopySource;

  /// Wizard step 2 intro.
  ///
  /// In en, this message translates to:
  /// **'Choose one discipline. It sets the default task, landing bonus and scoring rules.'**
  String get wizardIntroDiscipline;

  /// Wizard step 3 intro.
  ///
  /// In en, this message translates to:
  /// **'Turn on only what this contest needs. Each option adds columns to the Participants step.'**
  String get wizardIntroParticipantOptions;

  /// Wizard step 4 intro.
  ///
  /// In en, this message translates to:
  /// **'Add pilots and helpers. Every scoring pilot needs the columns marked with *.'**
  String get wizardIntroParticipants;

  /// Wizard step 5 intro.
  ///
  /// In en, this message translates to:
  /// **'Review the defaults for this discipline and change anything this contest does differently.'**
  String get wizardIntroScoringPublication;

  /// Wizard step 6 intro.
  ///
  /// In en, this message translates to:
  /// **'Set how pilots are grouped. You draw the matrix after the contest is created.'**
  String get wizardIntroDrawOptions;

  /// Wizard step 7 intro.
  ///
  /// In en, this message translates to:
  /// **'Check each section, then create the contest.'**
  String get wizardIntroSummaryCreate;

  /// Message when the draft couldn't be deleted after creating.
  ///
  /// In en, this message translates to:
  /// **'Contest created, but its saved draft couldn’t be deleted. You may be offered it again; choose Start fresh.'**
  String get wizardDraftNotDeleted;

  /// Message shown after leaving the wizard.
  ///
  /// In en, this message translates to:
  /// **'Left the wizard. Your draft is kept.'**
  String get wizardLeftMessage;

  /// Message when trying to leave while creating.
  ///
  /// In en, this message translates to:
  /// **'The contest is being created. Wait for it to finish.'**
  String get wizardCreatingContest;

  /// Title of the leave-confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Leave new contest?'**
  String get wizardLeaveTitle;

  /// Body of the leave-confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Your draft is kept on this device. You can finish it later from Contests.'**
  String get wizardLeaveBody;

  /// Warning in the leave dialog when save failed.
  ///
  /// In en, this message translates to:
  /// **'Your latest changes couldn’t be saved and will be lost.'**
  String get wizardLeaveSaveFailed;

  /// Warning in the leave dialog when fields have errors.
  ///
  /// In en, this message translates to:
  /// **'Fields with errors on this step need fixing before the contest can be created.'**
  String get wizardLeaveErrors;

  /// Cancel label in the leave dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get wizardKeepEditing;

  /// Confirm label in the leave dialog.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get wizardLeave;

  /// Title of the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'Change discipline to {discipline}?'**
  String wizardChangeDisciplineTitle(String discipline);

  /// Body of the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'Some values set for {current} don’t apply to {target} and will be cleared:'**
  String wizardChangeDisciplineBody(String current, String target);

  /// Item in the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'{discipline} landing-bonus table'**
  String wizardChangeDisciplineLanding(String discipline);

  /// Item in the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'{discipline}-specific rules ({rules})'**
  String wizardChangeDisciplineRules(String discipline, String rules);

  /// Item in the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'Group-score mode and precision, reset to the new defaults'**
  String get wizardChangeDisciplineGroupScore;

  /// Footnote in the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'Details, participants and draw options stay as they are.'**
  String get wizardChangeDisciplineFootnote;

  /// Cancel label in the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep {discipline}'**
  String wizardChangeDisciplineCancel(String discipline);

  /// Confirm label in the discipline-change dialog.
  ///
  /// In en, this message translates to:
  /// **'Change and clear'**
  String get wizardChangeDisciplineConfirm;

  /// Message after changing the discipline.
  ///
  /// In en, this message translates to:
  /// **'Discipline changed to {discipline}. Incompatible values were cleared.'**
  String wizardDisciplineChanged(String discipline);

  /// Title of the turn-off-teams dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn off teams?'**
  String get wizardTurnOffTeams;

  /// Item in the turn-off-teams dialog.
  ///
  /// In en, this message translates to:
  /// **'Team assignments are removed from {count} participant{plural} ({teams} team{teamPlural}).'**
  String wizardTurnOffTeamsAssignments(
    int count,
    String plural,
    int teams,
    String teamPlural,
  );

  /// Item in the turn-off-teams dialog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant who isn’t a pilot is removed from the contest.} other{{count} participants who aren’t pilots are removed from the contest.}}'**
  String wizardTurnOffTeamsNonPilots(int count);

  /// Item in the turn-off-teams dialog.
  ///
  /// In en, this message translates to:
  /// **'Check the group size in Draw options. Team protection no longer sets a minimum.'**
  String get wizardTurnOffTeamsGroupSize;

  /// Cancel label in the turn-off-teams dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep teams'**
  String get wizardKeepTeams;

  /// Confirm label in the turn-off-teams dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn off and remove'**
  String get wizardTurnOffAndRemove;

  /// Message after turning off teams.
  ///
  /// In en, this message translates to:
  /// **'Teams turned off. Team assignments and non-pilots were removed.'**
  String get wizardTeamsTurnedOff;

  /// Banner title when save failed.
  ///
  /// In en, this message translates to:
  /// **'Draft not saved'**
  String get wizardDraftNotSaved;

  /// Banner body when save failed.
  ///
  /// In en, this message translates to:
  /// **'Your last changes weren’t saved. Everything you entered is still on screen.'**
  String get wizardDraftNotSavedBody;

  /// Action label in the save-failed banner.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get wizardRetrySave;

  /// Message after a successful save retry.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get wizardDraftSaved;

  /// Generic cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wizardCancel;

  /// Banner title on step 5.
  ///
  /// In en, this message translates to:
  /// **'Created unpublished and private'**
  String get wizardCreatedUnpublished;

  /// Banner body on step 5.
  ///
  /// In en, this message translates to:
  /// **'Nobody outside the contest team can see it. You publish it later from the contest configuration page.'**
  String get wizardCreatedUnpublishedBody;

  /// Banner title when create failed.
  ///
  /// In en, this message translates to:
  /// **'The contest wasn’t created'**
  String get wizardNotCreated;

  /// Banner body when create failed.
  ///
  /// In en, this message translates to:
  /// **'{error} Everything you entered is kept in the draft.'**
  String wizardNotCreatedBody(String error);

  /// Action label in the create-failed banner.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get wizardRetry;

  /// Banner title on step 6.
  ///
  /// In en, this message translates to:
  /// **'The matrix isn’t drawn here'**
  String get wizardMatrixNotDrawn;

  /// Banner body on step 6.
  ///
  /// In en, this message translates to:
  /// **'After creating the contest, draw the matrix from contest configuration. It will use these settings.'**
  String get wizardMatrixNotDrawnBody;

  /// Validation banner title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 field needs attention before you continue} other{{count} fields need attention before you continue}}'**
  String wizardFieldsNeedAttention(int count);

  /// Label for the first drop field.
  ///
  /// In en, this message translates to:
  /// **'Drop after round'**
  String get wizardDropAfterRound;

  /// Label for the second drop field.
  ///
  /// In en, this message translates to:
  /// **'Second drop after round'**
  String get wizardSecondDropAfterRound;

  /// Label for the groups field.
  ///
  /// In en, this message translates to:
  /// **'Groups per round'**
  String get wizardGroupsPerRound;

  /// Label for the rounds field.
  ///
  /// In en, this message translates to:
  /// **'Preliminary rounds'**
  String get wizardPreliminaryRounds;

  /// Label for the seeded rounds field.
  ///
  /// In en, this message translates to:
  /// **'Seeded rounds'**
  String get wizardSeededRounds;

  /// Field label for team pilot count.
  ///
  /// In en, this message translates to:
  /// **'Pilots counted for team score *'**
  String get wizardTeamPilotCountLabel;

  /// Accessibility announcement when navigating steps.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}, {title}.'**
  String wizardStepOf(int step, int total, String title);

  /// Step number header above the title.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF {total}'**
  String wizardStepHeader(int step, int total);

  /// Primary button label when not on the last step.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String wizardNext(String title);

  /// Primary button label while creating.
  ///
  /// In en, this message translates to:
  /// **'Creating contest…'**
  String get wizardCreating;

  /// Primary button label on the last step.
  ///
  /// In en, this message translates to:
  /// **'Create contest'**
  String get wizardCreateContest;

  /// Accessibility announcement when creating.
  ///
  /// In en, this message translates to:
  /// **'Creating contest.'**
  String get wizardCreatingAnnouncement;

  /// Accessibility announcement after creating.
  ///
  /// In en, this message translates to:
  /// **'Contest created.'**
  String get wizardCreatedAnnouncement;

  /// Blocked-reason text.
  ///
  /// In en, this message translates to:
  /// **'Can’t create yet: {reason}'**
  String wizardCannotCreate(String reason);

  /// Reason when a step is invalid.
  ///
  /// In en, this message translates to:
  /// **'{title} needs attention.'**
  String wizardNeedsAttention(String title);

  /// Reason when too few scoring pilots.
  ///
  /// In en, this message translates to:
  /// **'add at least 2 scoring pilots.'**
  String get wizardAddScoringPilots;

  /// Reason when participants need fixing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant needs fixing.} other{{count} participants need fixing.}}'**
  String wizardParticipantsNeedFixing(int count);

  /// Fix label in the blocked footer.
  ///
  /// In en, this message translates to:
  /// **'Go to {title}'**
  String wizardGoToStep(String title);

  /// Back button in the wizard footer.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wizardBack;

  /// DetailsField label for name.
  ///
  /// In en, this message translates to:
  /// **'Contest name'**
  String get wizardDetailsFieldContestName;

  /// DetailsField label for venue.
  ///
  /// In en, this message translates to:
  /// **'Venue / host'**
  String get wizardDetailsFieldVenue;

  /// DetailsField label for start date.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get wizardDetailsFieldStartDate;

  /// DetailsField label for end date.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get wizardDetailsFieldEndDate;

  /// Validation error for empty name.
  ///
  /// In en, this message translates to:
  /// **'Enter a contest name.'**
  String get wizardValidationEnterName;

  /// Validation error for empty venue.
  ///
  /// In en, this message translates to:
  /// **'Enter the venue or host club.'**
  String get wizardValidationEnterVenue;

  /// Validation error for empty start date.
  ///
  /// In en, this message translates to:
  /// **'Enter a start date.'**
  String get wizardValidationEnterStartDate;

  /// Validation error for invalid start date.
  ///
  /// In en, this message translates to:
  /// **'Use a date like Nov 14, 2026.'**
  String get wizardValidationStartDateFormat;

  /// Validation error for empty end date.
  ///
  /// In en, this message translates to:
  /// **'Enter an end date.'**
  String get wizardValidationEnterEndDate;

  /// Validation error for invalid end date.
  ///
  /// In en, this message translates to:
  /// **'Use a date like Nov 15, 2026.'**
  String get wizardValidationEndDateFormat;

  /// Validation error when end is before start.
  ///
  /// In en, this message translates to:
  /// **'End date can’t be before the start date ({start}).'**
  String wizardValidationEndDateBeforeStart(String start);

  /// Validation error when no discipline chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a discipline.'**
  String get wizardValidationChooseDiscipline;

  /// Validation error for non-positive integer.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number above 0.'**
  String get wizardValidationWholeNumber;

  /// Validation error for second drop.
  ///
  /// In en, this message translates to:
  /// **'Must be after round {round}.'**
  String wizardValidationMustBeAfterRound(int round);

  /// Validation error for too many groups.
  ///
  /// In en, this message translates to:
  /// **'Use {max} or fewer so every group has at least 2 scoring pilots.'**
  String wizardValidationGroupsMax(int max);

  /// Validation error for too few groups.
  ///
  /// In en, this message translates to:
  /// **'Team protection needs at least {min} groups.'**
  String wizardValidationGroupsMin(int min);

  /// Validation error for seeded rounds.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 or more.'**
  String get wizardValidationSeededRounds;

  /// DropPolicy label for disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get wizardDropDisabled;

  /// DropPolicy label for one dropped.
  ///
  /// In en, this message translates to:
  /// **'One dropped'**
  String get wizardDropOne;

  /// DropPolicy label for two dropped.
  ///
  /// In en, this message translates to:
  /// **'Two dropped'**
  String get wizardDropTwo;

  /// CopyMode label for none.
  ///
  /// In en, this message translates to:
  /// **'Don’t copy'**
  String get wizardCopyModeNone;

  /// CopyMode description for none.
  ///
  /// In en, this message translates to:
  /// **'Start with a blank configuration and no pilots.'**
  String get wizardCopyModeNoneDesc;

  /// CopyMode label for configuration only.
  ///
  /// In en, this message translates to:
  /// **'Configuration only'**
  String get wizardCopyModeConfiguration;

  /// CopyMode description for configuration only.
  ///
  /// In en, this message translates to:
  /// **'Discipline, options, scoring and draw settings.'**
  String get wizardCopyModeConfigurationDesc;

  /// CopyMode label for all pilots.
  ///
  /// In en, this message translates to:
  /// **'Configuration + all pilots'**
  String get wizardCopyModeAllPilots;

  /// CopyMode description for all pilots.
  ///
  /// In en, this message translates to:
  /// **'Every pilot in the source contest, with their class.'**
  String get wizardCopyModeAllPilotsDesc;

  /// CopyMode label for selected pilots.
  ///
  /// In en, this message translates to:
  /// **'Configuration + selected pilots'**
  String get wizardCopyModeSelectedPilots;

  /// CopyMode description for selected pilots.
  ///
  /// In en, this message translates to:
  /// **'Pick some pilots, with their class, for example for a fly-off.'**
  String get wizardCopyModeSelectedPilotsDesc;

  /// ParticipantOption title for teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get wizardOptionTeamsTitle;

  /// ParticipantOption description for teams.
  ///
  /// In en, this message translates to:
  /// **'Group pilots into teams for a team score.'**
  String get wizardOptionTeamsDesc;

  /// ParticipantOption effect for teams.
  ///
  /// In en, this message translates to:
  /// **'Adds a Team column. Type a name to create a team. Pilots with no team are unassigned. Team protection becomes available in Draw options.'**
  String get wizardOptionTeamsEffect;

  /// ParticipantOption title for pilot numbers.
  ///
  /// In en, this message translates to:
  /// **'Contest pilot numbers'**
  String get wizardOptionPilotNumbersTitle;

  /// ParticipantOption description for pilot numbers.
  ///
  /// In en, this message translates to:
  /// **'Give each pilot a number for this contest.'**
  String get wizardOptionPilotNumbersDesc;

  /// ParticipantOption effect for pilot numbers.
  ///
  /// In en, this message translates to:
  /// **'Adds a Pilot no. column. Numbers are assigned at the first draw.'**
  String get wizardOptionPilotNumbersEffect;

  /// ParticipantOption note for pilot numbers.
  ///
  /// In en, this message translates to:
  /// **'Any number shown before the first draw is labelled provisional.'**
  String get wizardOptionPilotNumbersNote;

  /// ParticipantOption title for classes.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get wizardOptionClassesTitle;

  /// ParticipantOption description for classes.
  ///
  /// In en, this message translates to:
  /// **'Score pilots in classes such as Open or Sportsman.'**
  String get wizardOptionClassesDesc;

  /// ParticipantOption effect for classes.
  ///
  /// In en, this message translates to:
  /// **'Adds a required Class column for every scoring pilot.'**
  String get wizardOptionClassesEffect;

  /// ParticipantOption title for roles.
  ///
  /// In en, this message translates to:
  /// **'Contest roles'**
  String get wizardOptionRolesTitle;

  /// ParticipantOption description for roles.
  ///
  /// In en, this message translates to:
  /// **'Include non-flying people such as timers and the CD.'**
  String get wizardOptionRolesDesc;

  /// ParticipantOption effect for roles.
  ///
  /// In en, this message translates to:
  /// **'Adds a Role column. New people start as Pilot. Non-flying roles get no score rows.'**
  String get wizardOptionRolesEffect;

  /// ParticipantOption title for models.
  ///
  /// In en, this message translates to:
  /// **'Pilot models'**
  String get wizardOptionModelsTitle;

  /// ParticipantOption description for models.
  ///
  /// In en, this message translates to:
  /// **'Record the models each pilot flies.'**
  String get wizardOptionModelsDesc;

  /// ParticipantOption effect for models.
  ///
  /// In en, this message translates to:
  /// **'Adds a Models column for scoring pilots.'**
  String get wizardOptionModelsEffect;

  /// ParticipantOption note for models.
  ///
  /// In en, this message translates to:
  /// **'Add models any time. A pilot without a model never holds up the contest.'**
  String get wizardOptionModelsNote;

  /// Label for unsupported disciplines.
  ///
  /// In en, this message translates to:
  /// **'Not supported yet'**
  String get wizardDisciplineUnsupported;

  /// GroupScoreMode label for raw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get wizardGroupScoreRaw;

  /// GroupScoreMode label for normalized.
  ///
  /// In en, this message translates to:
  /// **'Normalized'**
  String get wizardGroupScoreNormalized;

  /// GroupScoreMode label for time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get wizardGroupScoreTime;

  /// RoundingMode label for round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get wizardRoundingRound;

  /// RoundingMode label for truncate.
  ///
  /// In en, this message translates to:
  /// **'Truncate'**
  String get wizardRoundingTruncate;

  /// PublicUpdateMode label for automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get wizardPublicUpdateAutomatic;

  /// PublicUpdateMode label for round completion.
  ///
  /// In en, this message translates to:
  /// **'On round completion'**
  String get wizardPublicUpdateRoundCompletion;

  /// PublicUpdateMode label for manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get wizardPublicUpdateManual;

  /// PublicUpdateMode description for automatic.
  ///
  /// In en, this message translates to:
  /// **'Public results update as scores are entered.'**
  String get wizardPublicUpdateAutomaticDesc;

  /// PublicUpdateMode description for round completion.
  ///
  /// In en, this message translates to:
  /// **'Public results update when a round is complete.'**
  String get wizardPublicUpdateRoundCompletionDesc;

  /// PublicUpdateMode description for manual.
  ///
  /// In en, this message translates to:
  /// **'Public results update only when you publish.'**
  String get wizardPublicUpdateManualDesc;

  /// Draw mode card title.
  ///
  /// In en, this message translates to:
  /// **'Draw mode'**
  String get wizardDrawMode;

  /// Draw mode name for man on man.
  ///
  /// In en, this message translates to:
  /// **'Man on Man'**
  String get wizardDrawModeManOnMan;

  /// Draw mode description for man on man.
  ///
  /// In en, this message translates to:
  /// **'Random groups each round, mixed so pilots meet as many others as possible.'**
  String get wizardDrawModeManOnManDesc;

  /// Draw mode name for seeded.
  ///
  /// In en, this message translates to:
  /// **'Seeded Man on Man'**
  String get wizardDrawModeSeeded;

  /// Draw mode description for seeded.
  ///
  /// In en, this message translates to:
  /// **'After the seeded rounds, pilots with similar scores fly together.'**
  String get wizardDrawModeSeededDesc;

  /// Why seeded and team protection are exclusive.
  ///
  /// In en, this message translates to:
  /// **'Seeded draws place pilots by ranking, so they can’t also keep teammates in separate groups.'**
  String get wizardDrawModeWhyExclusive;

  /// Disabled reason for seeded mode.
  ///
  /// In en, this message translates to:
  /// **'Unavailable while team protection is on. {reason} Turn off team protection to choose it.'**
  String wizardDrawModeUnavailable(String reason);

  /// Card title for groups and rounds.
  ///
  /// In en, this message translates to:
  /// **'Groups and rounds'**
  String get wizardGroupsAndRounds;

  /// Hint below groups field.
  ///
  /// In en, this message translates to:
  /// **'Minimum {min}: team protection keeps the {team} pilots of your largest team in separate groups.'**
  String wizardMinimumGroups(int min, int team);

  /// Hint below groups field.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max} for {scoring} scoring pilots.'**
  String wizardGroupsRange(int min, int max, int scoring);

  /// Note below preliminary rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds can be appended after the contest starts.'**
  String get wizardRoundsAppendNote;

  /// Description for seeded rounds setting.
  ///
  /// In en, this message translates to:
  /// **'Man-on-man rounds flown before seeding starts. Minimum 1.'**
  String get wizardSeededRoundsDesc;

  /// Error title for seeded rounds.
  ///
  /// In en, this message translates to:
  /// **'At least 1 seeded round'**
  String get wizardSeededRoundsAtLeast1;

  /// Setting label for lane mode.
  ///
  /// In en, this message translates to:
  /// **'Lane mode'**
  String get wizardLaneMode;

  /// Description for lane mode.
  ///
  /// In en, this message translates to:
  /// **'Whether pilots get a launch lane within their group.'**
  String get wizardLaneModeDesc;

  /// LaneMode label for none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get wizardLaneNone;

  /// LaneMode label for random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get wizardLaneRandom;

  /// Setting label for team protection.
  ///
  /// In en, this message translates to:
  /// **'Team protection'**
  String get wizardTeamProtection;

  /// Description for team protection when teams on.
  ///
  /// In en, this message translates to:
  /// **'Keeps teammates out of the same group. Needs at least as many groups as your largest team has pilots ({count}).'**
  String wizardTeamProtectionDesc(int count);

  /// Description for team protection when teams off.
  ///
  /// In en, this message translates to:
  /// **'Keeps teammates out of the same group.'**
  String get wizardTeamProtectionDescOff;

  /// Note title when teams off.
  ///
  /// In en, this message translates to:
  /// **'Teams are off'**
  String get wizardTeamsOffNote;

  /// Note body when teams off.
  ///
  /// In en, this message translates to:
  /// **'Turn on Teams in Participant options to use team protection.'**
  String get wizardTeamsOffNoteBody;

  /// Note title when seeded.
  ///
  /// In en, this message translates to:
  /// **'Unavailable with Seeded Man on Man'**
  String get wizardSeededUnavailableNote;

  /// Note body when seeded.
  ///
  /// In en, this message translates to:
  /// **'{reason} Choose Man on Man to use team protection.'**
  String wizardSeededUnavailableNoteBody(String reason);

  /// Note title when protection on.
  ///
  /// In en, this message translates to:
  /// **'Seeded Man on Man is now unavailable'**
  String get wizardSeededUnavailableNote2;

  /// Note body when protection on.
  ///
  /// In en, this message translates to:
  /// **'The two can’t be combined. Turn this off if you want a seeded draw.'**
  String get wizardSeededUnavailableNote2Body;

  /// Setting label for back-to-back.
  ///
  /// In en, this message translates to:
  /// **'Allow back-to-back flights'**
  String get wizardBackToBack;

  /// Description for back-to-back.
  ///
  /// In en, this message translates to:
  /// **'A pilot may fly the last group of one round and the first group of the next.'**
  String get wizardBackToBackDesc;

  /// Warning title for back-to-back off.
  ///
  /// In en, this message translates to:
  /// **'Draw fairness decreases'**
  String get wizardBackToBackFairness;

  /// Warning body for back-to-back off.
  ///
  /// In en, this message translates to:
  /// **'Keeping pilots out of consecutive flights limits how the draw can mix pilots, so some match-ups repeat more often.'**
  String get wizardBackToBackFairnessBody;

  /// Error title when too few groups.
  ///
  /// In en, this message translates to:
  /// **'This contest is too small for the constraint'**
  String get wizardBackToBackTooSmall;

  /// Error body when too few groups.
  ///
  /// In en, this message translates to:
  /// **'With {groups} group{plural}, a pilot in the last group of one round would also fly in the first group of the next. Use at least 3 groups or allow back-to-back flights.'**
  String wizardBackToBackTooSmallBody(int groups, String plural);

  /// Card title for constraints.
  ///
  /// In en, this message translates to:
  /// **'Constraints'**
  String get wizardConstraints;

  /// Title of the group calculation panel.
  ///
  /// In en, this message translates to:
  /// **'PILOTS PER GROUP · UPDATES AS YOU EDIT'**
  String get wizardPilotsPerGroupTitle;

  /// OK message in group panel.
  ///
  /// In en, this message translates to:
  /// **'every group has at least 2 scoring pilots.'**
  String get wizardPilotsPerGroupOk;

  /// Blocked message in group panel.
  ///
  /// In en, this message translates to:
  /// **'with {groups} groups some would have fewer than 2 scoring pilots. Use {max} or fewer.'**
  String wizardPilotsPerGroupBlocked(int groups, int max);

  /// Blocked message when no groups.
  ///
  /// In en, this message translates to:
  /// **'enter at least 1 group.'**
  String get wizardPilotsPerGroupEnter1;

  /// Protection message in group panel.
  ///
  /// In en, this message translates to:
  /// **'team protection needs at least {min} groups. Your largest team has {team} scoring pilots.'**
  String wizardPilotsPerGroupProtection(int min, int team);

  /// Message when protection off.
  ///
  /// In en, this message translates to:
  /// **'Team protection is off, so teammates can share a group.'**
  String get wizardPilotsPerGroupProtectionOff;

  /// Count line in group panel.
  ///
  /// In en, this message translates to:
  /// **'{scoring} scoring pilots in {groups} group{plural} · smallest group {min}, largest {max}'**
  String wizardPilotsPerGroupCount(
    int scoring,
    int groups,
    String plural,
    int min,
    int max,
  );

  /// Count line when no groups.
  ///
  /// In en, this message translates to:
  /// **'{scoring} scoring pilots'**
  String wizardPilotsPerGroupCountNoGroups(int scoring);

  /// Card title for scoring settings.
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get wizardScoringCard;

  /// Setting label for group score.
  ///
  /// In en, this message translates to:
  /// **'Group score'**
  String get wizardGroupScoreLabel;

  /// Description for raw group score.
  ///
  /// In en, this message translates to:
  /// **'Raw: flight points plus landing bonus, not normalized.'**
  String get wizardGroupScoreRawDesc;

  /// Description for normalized group score.
  ///
  /// In en, this message translates to:
  /// **'Normalized: flight points plus landing bonus, normalized to 1000 in each group.'**
  String get wizardGroupScoreNormalizedDesc;

  /// Description for time group score.
  ///
  /// In en, this message translates to:
  /// **'Time: flight time is normalized to 1000 in each group, then the landing bonus is added.'**
  String get wizardGroupScoreTimeDesc;

  /// Warning title for non-traditional scoring.
  ///
  /// In en, this message translates to:
  /// **'No longer a traditional {discipline} contest'**
  String wizardGroupScoreTraditional(String discipline);

  /// Warning body for non-traditional scoring.
  ///
  /// In en, this message translates to:
  /// **'{discipline} uses {mode} group scoring by default.'**
  String wizardGroupScoreTraditionalBody(String discipline, String mode);

  /// Setting label for rounding.
  ///
  /// In en, this message translates to:
  /// **'Rounding'**
  String get wizardRoundingLabel;

  /// Description for rounding.
  ///
  /// In en, this message translates to:
  /// **'What happens to digits beyond the chosen precision.'**
  String get wizardRoundingDesc;

  /// Setting label for precision.
  ///
  /// In en, this message translates to:
  /// **'Total score decimal precision'**
  String get wizardPrecisionLabel;

  /// Description for precision.
  ///
  /// In en, this message translates to:
  /// **'Digits shown and stored after the decimal point.'**
  String get wizardPrecisionDesc;

  /// Hint example for precision.
  ///
  /// In en, this message translates to:
  /// **'Example: 987.4567 → {result}'**
  String wizardPrecisionExample(String result);

  /// Setting label for dropped rounds.
  ///
  /// In en, this message translates to:
  /// **'Dropped rounds'**
  String get wizardDroppedRoundsLabel;

  /// Description for dropped rounds.
  ///
  /// In en, this message translates to:
  /// **'Worst rounds left out of each pilot’s total.'**
  String get wizardDroppedRoundsDesc;

  /// Label for first drop.
  ///
  /// In en, this message translates to:
  /// **'First drop after round'**
  String get wizardFirstDropLabel;

  /// Description for drop after round.
  ///
  /// In en, this message translates to:
  /// **'Once this many rounds are complete, each pilot’s worst round is left out.'**
  String get wizardDropAfterRoundDesc;

  /// Description for second drop.
  ///
  /// In en, this message translates to:
  /// **'Once this many rounds are complete, the second worst round is also left out. Must be later than the first.'**
  String get wizardSecondDropDesc;

  /// Note when second drop is later.
  ///
  /// In en, this message translates to:
  /// **'The second drop has to come later than the first.'**
  String get wizardSecondDropLater;

  /// Card title for participants and publication.
  ///
  /// In en, this message translates to:
  /// **'Participants and publication'**
  String get wizardParticipantsPublication;

  /// Setting label for review requests.
  ///
  /// In en, this message translates to:
  /// **'Score-review requests'**
  String get wizardReviewRequestsLabel;

  /// Description for review requests.
  ///
  /// In en, this message translates to:
  /// **'Let pilots ask the contest director to review a score.'**
  String get wizardReviewRequestsDesc;

  /// Setting label for public update.
  ///
  /// In en, this message translates to:
  /// **'Public update policy'**
  String get wizardPublicUpdateLabel;

  /// Description for public update.
  ///
  /// In en, this message translates to:
  /// **'When public results refresh once the contest is published.'**
  String get wizardPublicUpdateDesc;

  /// Default label when no discipline.
  ///
  /// In en, this message translates to:
  /// **'Platform default'**
  String get wizardPlatformDefault;

  /// Suffix for discipline default labels.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get wizardDisciplineDefault;

  /// Changed-from label.
  ///
  /// In en, this message translates to:
  /// **'Changed from {value}'**
  String wizardChangedFrom(String value);

  /// Reset button in setting rows.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get wizardResetToDefault;

  /// Tooltip for the minus stepper.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get wizardFewer;

  /// Tooltip for the plus stepper.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get wizardMore;

  /// Title in the step list.
  ///
  /// In en, this message translates to:
  /// **'New contest'**
  String get wizardNewContest;

  /// Progress text in the step list.
  ///
  /// In en, this message translates to:
  /// **'{complete} of {total} steps complete'**
  String wizardStepsComplete(int complete, int total);

  /// Note at the bottom of the step list.
  ///
  /// In en, this message translates to:
  /// **'Configuration in process is kept until the app is closed or the contest is created.'**
  String get wizardDraftKeptNote;

  /// Note below the discipline cards.
  ///
  /// In en, this message translates to:
  /// **'These are starting defaults. You can override task times, landing bonuses and rules after the contest is created, on the contest configuration page.'**
  String get wizardDisciplineNote;

  /// Badge text for selected discipline.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get wizardSelected;

  /// Table label in discipline card.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get wizardTimeLabel;

  /// Table label in discipline card.
  ///
  /// In en, this message translates to:
  /// **'Landing'**
  String get wizardLandingLabel;

  /// Card title for contest details.
  ///
  /// In en, this message translates to:
  /// **'Contest details'**
  String get wizardContestDetails;

  /// Trailing text on the details card.
  ///
  /// In en, this message translates to:
  /// **'* Required'**
  String get wizardRequired;

  /// Field label for contest name.
  ///
  /// In en, this message translates to:
  /// **'Contest name *'**
  String get wizardContestNameLabel;

  /// Field label for venue.
  ///
  /// In en, this message translates to:
  /// **'Venue / host *'**
  String get wizardVenueLabel;

  /// Helper text for venue.
  ///
  /// In en, this message translates to:
  /// **'Field name or host club as it should appear on results.'**
  String get wizardVenueHelper;

  /// Field label for start date.
  ///
  /// In en, this message translates to:
  /// **'Start date *'**
  String get wizardStartDateLabel;

  /// Field label for end date.
  ///
  /// In en, this message translates to:
  /// **'End date *'**
  String get wizardEndDateLabel;

  /// Hint for date fields.
  ///
  /// In en, this message translates to:
  /// **'MMM D, YYYY'**
  String get wizardDateHint;

  /// Tooltip for the start date picker.
  ///
  /// In en, this message translates to:
  /// **'Choose the start date'**
  String get wizardChooseStartDate;

  /// Tooltip for the end date picker.
  ///
  /// In en, this message translates to:
  /// **'Choose the end date'**
  String get wizardChooseEndDate;

  /// Field label for city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get wizardCityLabel;

  /// Field label for region.
  ///
  /// In en, this message translates to:
  /// **'State / province'**
  String get wizardRegionLabel;

  /// Field label for country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get wizardCountryLabel;

  /// Label for the time zone picker.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get wizardTimeZoneLabel;

  /// Helper for time zone when unset.
  ///
  /// In en, this message translates to:
  /// **'Defaults from the country, else this device’s time zone.'**
  String get wizardTimeZoneDefault;

  /// Card title for copy source.
  ///
  /// In en, this message translates to:
  /// **'Copy from an existing contest'**
  String get wizardCopyFromContest;

  /// Trailing text on the copy source card.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get wizardOptional;

  /// Note about what copying never brings.
  ///
  /// In en, this message translates to:
  /// **'Copying never brings scores, the flight matrix, publication history, invitations or audit history.'**
  String get wizardCopyNeverBrings;

  /// Section label for source contest.
  ///
  /// In en, this message translates to:
  /// **'Source contest'**
  String get wizardSourceContest;

  /// Button to remove the source.
  ///
  /// In en, this message translates to:
  /// **'Remove source'**
  String get wizardRemoveSource;

  /// Subtitle while loading a source.
  ///
  /// In en, this message translates to:
  /// **'Loading configuration and pilot list…'**
  String get wizardLoadingSource;

  /// Error title when source fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load “{name}”'**
  String wizardSourceFailed(String name);

  /// Error body when source fails.
  ///
  /// In en, this message translates to:
  /// **'The contest didn’t load. Retry, or remove the source and continue without copying.'**
  String get wizardSourceFailedBody;

  /// Message after removing the source.
  ///
  /// In en, this message translates to:
  /// **'Source removed. You can continue without copying.'**
  String get wizardSourceRemoved;

  /// Semantics label for the copy mode picker.
  ///
  /// In en, this message translates to:
  /// **'Copy mode'**
  String get wizardCopyModeLabel;

  /// Label for local contests (web).
  ///
  /// In en, this message translates to:
  /// **'Your contests'**
  String get wizardYourContests;

  /// Label for local contests (native).
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get wizardOnThisDevice;

  /// Tab label when offline.
  ///
  /// In en, this message translates to:
  /// **'Public (needs connection)'**
  String get wizardPublicNeedsConnection;

  /// Tab label when online.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get wizardPublic;

  /// Note when offline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Public contests can be searched when you’re back online. {local} are still available.'**
  String wizardOfflineNote(String local);

  /// Note when public search unavailable.
  ///
  /// In en, this message translates to:
  /// **'Searching public contests isn’t available yet. Copy from {local} for now.'**
  String wizardPublicUnavailable(String local);

  /// Error when local contests fail to load.
  ///
  /// In en, this message translates to:
  /// **'Contests could not be loaded.'**
  String get wizardContestsLoadFailed;

  /// Empty state for local contests.
  ///
  /// In en, this message translates to:
  /// **'There are no contests to copy yet.'**
  String get wizardNoContests;

  /// Action text on a contest tile.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get wizardUse;

  /// Count in the pilot subset.
  ///
  /// In en, this message translates to:
  /// **'{chosen} of {total} pilots selected'**
  String wizardPilotsSelected(int chosen, int total);

  /// Text when no pilots chosen.
  ///
  /// In en, this message translates to:
  /// **'No pilots chosen yet'**
  String get wizardNoPilotsChosen;

  /// Suffix for extra pilots.
  ///
  /// In en, this message translates to:
  /// **' and {count} more'**
  String wizardAndMore(int count);

  /// Button to choose pilots.
  ///
  /// In en, this message translates to:
  /// **'Choose pilots'**
  String get wizardChoosePilots;

  /// Title of the copy summary.
  ///
  /// In en, this message translates to:
  /// **'COPY SUMMARY'**
  String get wizardCopySummaryTitle;

  /// Semantics label for the copy summary.
  ///
  /// In en, this message translates to:
  /// **'Copy summary'**
  String get wizardCopySummaryLabel;

  /// Row label in copy summary.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get wizardCopySourceLabel;

  /// Row label in copy summary.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get wizardCopyCopiesLabel;

  /// Row label in copy summary.
  ///
  /// In en, this message translates to:
  /// **'Pilots'**
  String get wizardCopyPilotsLabel;

  /// Value when all pilots.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String wizardCopyAllPilots(int count);

  /// Value when no pilots.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get wizardCopyNone;

  /// Row label in copy summary.
  ///
  /// In en, this message translates to:
  /// **'Per pilot'**
  String get wizardCopyPerPilot;

  /// Value for per-pilot.
  ///
  /// In en, this message translates to:
  /// **'Participation and class'**
  String get wizardCopyPerPilotValue;

  /// Row label in copy summary.
  ///
  /// In en, this message translates to:
  /// **'Not copied'**
  String get wizardCopyNotCopied;

  /// Value for not copied.
  ///
  /// In en, this message translates to:
  /// **'Teams, models, non-flying participants, scores, matrix, publication history, invitations, audit history'**
  String get wizardCopyNotCopiedValue;

  /// Title of the choose-pilots dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose pilots to copy'**
  String get wizardChoosePilotsTitle;

  /// Body of the choose-pilots dialog.
  ///
  /// In en, this message translates to:
  /// **'Each pilot is copied with their class. {selected} of {total} selected.'**
  String wizardChoosePilotsBody(int selected, int total);

  /// Checkbox label in the choose-pilots dialog.
  ///
  /// In en, this message translates to:
  /// **'All pilots'**
  String get wizardAllPilots;

  /// Confirm button in the choose-pilots dialog.
  ///
  /// In en, this message translates to:
  /// **'Use these pilots'**
  String get wizardUseThesePilots;

  /// Title of the resume-draft dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue your draft?'**
  String get wizardContinueDraft;

  /// Title of the discard-draft dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard your draft?'**
  String get wizardDiscardDraft;

  /// Body of the resume-draft dialog.
  ///
  /// In en, this message translates to:
  /// **'You started a contest that isn’t created yet{when}. Continue it, or start fresh and delete it.'**
  String wizardContinueDraftBody(String when);

  /// Body of the discard-draft dialog.
  ///
  /// In en, this message translates to:
  /// **'A draft saved{when} can’t be opened by this version of the app. Discard it to start a new contest.'**
  String wizardDiscardDraftBody(String when);

  /// Button in the resume-draft dialog.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get wizardStartFresh;

  /// Button in the discard-draft dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get wizardDiscardDraftButton;

  /// Button in the resume-draft dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue draft'**
  String get wizardContinueDraftButton;

  /// Semantics label for the participant options step.
  ///
  /// In en, this message translates to:
  /// **'Participant options'**
  String get wizardParticipantsStepLabel;

  /// Helper for team pilot count.
  ///
  /// In en, this message translates to:
  /// **'Best N pilots per team make the team score.'**
  String get wizardTeamPilotCountHelper;

  /// Note when teams turned on.
  ///
  /// In en, this message translates to:
  /// **'Team protection is now available in Draw options. It keeps teammates out of the same group.'**
  String get wizardTeamProtectionAvailable;

  /// Label for the columns preview.
  ///
  /// In en, this message translates to:
  /// **'Columns in the Participants step'**
  String get wizardColumnsPreview;

  /// Badge text when option is from source.
  ///
  /// In en, this message translates to:
  /// **'From source'**
  String get wizardFromSource;

  /// Prefix when option is on.
  ///
  /// In en, this message translates to:
  /// **'In Participants: '**
  String get wizardInParticipants;

  /// Prefix when option is off.
  ///
  /// In en, this message translates to:
  /// **'If on: '**
  String get wizardIfOn;

  /// Column preview label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get wizardColumnName;

  /// Column preview label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get wizardColumnEmail;

  /// Column preview label.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get wizardColumnRole;

  /// Column preview label.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get wizardColumnClass;

  /// Column preview label.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get wizardColumnTeam;

  /// Column preview label.
  ///
  /// In en, this message translates to:
  /// **'Pilot no.'**
  String get wizardColumnPilotNo;

  /// Column preview label.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get wizardColumnModels;

  /// Column requirement text.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get wizardColumnRequired;

  /// Column requirement text.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get wizardColumnOptional;

  /// Column requirement text.
  ///
  /// In en, this message translates to:
  /// **'provisional'**
  String get wizardColumnProvisional;

  /// Button to add a participant.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get wizardAddParticipant;

  /// Title in the add-participant dialog.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get wizardAddParticipantTitle;

  /// Message when adding a duplicate.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in the contest.'**
  String wizardAlreadyInContest(String name);

  /// Message after adding a pilot.
  ///
  /// In en, this message translates to:
  /// **'{name} is added as Pilot.'**
  String wizardAddedAsPilot(String name);

  /// Short message after adding a pilot.
  ///
  /// In en, this message translates to:
  /// **'{name} added as Pilot.'**
  String wizardAddedAsPilotShort(String name);

  /// Message after removing participants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant removed from this contest.} other{{count} participants removed from this contest.}}'**
  String wizardParticipantsRemoved(int count);

  /// Banner title for participants needing fixes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant needs fixing before you continue} other{{count} participants need fixing before you continue}}'**
  String wizardParticipantsNeedFixingBanner(int count);

  /// Banner title for too few pilots.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 scoring pilots'**
  String get wizardMinPilotsBanner;

  /// Banner body for too few pilots.
  ///
  /// In en, this message translates to:
  /// **'A contest needs 2 or more scoring pilots. Non-flying roles don’t count.'**
  String get wizardMinPilotsBannerBody;

  /// Banner title for few pilots.
  ///
  /// In en, this message translates to:
  /// **'Only {count} scoring pilots'**
  String wizardFewPilotsBanner(int count);

  /// Banner body for few pilots.
  ///
  /// In en, this message translates to:
  /// **'You can continue. With fewer than 3 pilots, use 1 group per round.'**
  String get wizardFewPilotsBannerBody;

  /// Chip text for people count.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String wizardPeopleCount(int count);

  /// Chip text for scoring pilots.
  ///
  /// In en, this message translates to:
  /// **'{count} scoring pilots'**
  String wizardScoringPilotsCount(int count);

  /// Chip text for non-flying.
  ///
  /// In en, this message translates to:
  /// **'{count} non-flying'**
  String wizardNonFlyingCount(int count);

  /// Chip text for pilots (no roles).
  ///
  /// In en, this message translates to:
  /// **'{count} pilots'**
  String wizardPilotsCount(int count);

  /// Filter chip label.
  ///
  /// In en, this message translates to:
  /// **'Needs fixing ({count})'**
  String wizardNeedsFixingFilter(int count);

  /// Message after setting team.
  ///
  /// In en, this message translates to:
  /// **'Team set for {count} participants.'**
  String wizardTeamSet(int count);

  /// Message after setting class.
  ///
  /// In en, this message translates to:
  /// **'Class set to {value} for {count} participants.'**
  String wizardClassSet(String value, int count);

  /// Message after setting role.
  ///
  /// In en, this message translates to:
  /// **'Role set to {value} for {count} participants.'**
  String wizardRoleSet(String value, int count);

  /// Filter note text.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} matching “{query}”'**
  String wizardShowingMatching(int shown, int total, String query);

  /// Empty filter text.
  ///
  /// In en, this message translates to:
  /// **'No one in this contest matches “{query}”.'**
  String wizardNoMatch(String query);

  /// Semantics label for the participants list.
  ///
  /// In en, this message translates to:
  /// **'Contest participants'**
  String get wizardContestParticipantsLabel;

  /// Keyboard help text.
  ///
  /// In en, this message translates to:
  /// **'Tab moves between cells · Enter confirms and moves down · Space selects a row · Esc closes a menu'**
  String get wizardKeyboardHelp;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get wizardNoParticipants;

  /// Empty state body.
  ///
  /// In en, this message translates to:
  /// **'Find people by name or email above, or add someone new. The contest needs at least 2 scoring pilots.'**
  String get wizardNoParticipantsBody;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get wizardVisibility;

  /// Summary issue text.
  ///
  /// In en, this message translates to:
  /// **'Dropped rounds need fixing'**
  String get wizardDroppedRoundsNeedFixing;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Lanes'**
  String get wizardLanes;

  /// Summary value.
  ///
  /// In en, this message translates to:
  /// **'No lane assignment'**
  String get wizardNoLaneAssignment;

  /// Summary value.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get wizardAllowed;

  /// Summary value.
  ///
  /// In en, this message translates to:
  /// **'Avoided'**
  String get wizardAvoided;

  /// Summary section title.
  ///
  /// In en, this message translates to:
  /// **'Rounds and groups'**
  String get wizardRoundsGroups;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get wizardRounds;

  /// Summary issue text.
  ///
  /// In en, this message translates to:
  /// **'Group settings are blocked'**
  String get wizardGroupSettingsBlocked;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Pilots per group'**
  String get wizardPilotsPerGroup;

  /// Summary section title.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get wizardDetails;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get wizardName;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get wizardDates;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Venue / host'**
  String get wizardVenueHost;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get wizardLocation;

  /// Summary section title.
  ///
  /// In en, this message translates to:
  /// **'Copy source'**
  String get wizardCopySourceSection;

  /// Summary value.
  ///
  /// In en, this message translates to:
  /// **'Not copying'**
  String get wizardNotCopying;

  /// Summary section title.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get wizardDisciplineSection;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get wizardTask;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Landing'**
  String get wizardLanding;

  /// Summary section title.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get wizardParticipantsSection;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get wizardPeople;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Scoring pilots'**
  String get wizardScoringPilots;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Non-flying'**
  String get wizardNonFlying;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Pilots'**
  String get wizardPilots;

  /// Summary issue text.
  ///
  /// In en, this message translates to:
  /// **'Needs at least 2 scoring pilots'**
  String get wizardNeedsAtLeast2;

  /// Summary section title.
  ///
  /// In en, this message translates to:
  /// **'Enabled options'**
  String get wizardEnabledOptions;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get wizardOn;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get wizardOff;

  /// Summary section title.
  ///
  /// In en, this message translates to:
  /// **'Teams and classes'**
  String get wizardTeamsClasses;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get wizardTeams;

  /// Summary value.
  ///
  /// In en, this message translates to:
  /// **'None assigned yet'**
  String get wizardNoneAssigned;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get wizardClasses;

  /// Summary row label.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get wizardModels;

  /// Summary value.
  ///
  /// In en, this message translates to:
  /// **'{count} entered; pilots without one are fine'**
  String wizardModelsEntered(int count);

  /// Summary value.
  ///
  /// In en, this message translates to:
  /// **'{count} entered'**
  String wizardModelsEnteredSimple(int count);

  /// Section title after create.
  ///
  /// In en, this message translates to:
  /// **'After you create'**
  String get wizardAfterCreate;

  /// After-create note.
  ///
  /// In en, this message translates to:
  /// **'The contest configuration page is opened.'**
  String get wizardAfterCreateConfig;

  /// After-create note.
  ///
  /// In en, this message translates to:
  /// **'It stays unpublished and private until you publish it.'**
  String get wizardAfterCreatePrivate;

  /// After-create note.
  ///
  /// In en, this message translates to:
  /// **'A flight matrix hasn’t been drawn. The draw can be created from the next screen.'**
  String get wizardAfterCreateMatrix;

  /// After-create note.
  ///
  /// In en, this message translates to:
  /// **'Review {discipline} discipline overrides and the remaining settings there.'**
  String wizardAfterCreateReview(String discipline);

  /// Edit button in summary section.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get wizardEdit;

  /// Summary issue for details.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 field needs attention} other{{count} fields need attention}}'**
  String wizardFieldsNeedAttentionSummary(int count);

  /// Filter chip label.
  ///
  /// In en, this message translates to:
  /// **'Needs fixing ({count})'**
  String wizardNeedsFixing(int count);

  /// Filter note text.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} matching “{query}”'**
  String wizardShowing(int shown, int total, String query);

  /// Semantics label for the participants list.
  ///
  /// In en, this message translates to:
  /// **'Contest participants'**
  String get wizardParticipantsLabel;

  /// Empty state body.
  ///
  /// In en, this message translates to:
  /// **'Find people by name or email above, or add someone new. The contest needs at least 2 scoring pilots.'**
  String get wizardNoParticipantsHelp;

  /// Semantics label for the step list.
  ///
  /// In en, this message translates to:
  /// **'Wizard steps'**
  String get wizardStepListLabel;

  /// Count of selected rows in the participants step.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String wizardRowsSelected(int count);

  /// Semantics label for the bulk edit bar.
  ///
  /// In en, this message translates to:
  /// **'Bulk edit selected participants'**
  String get wizardBulkEditLabel;

  /// Menu label for setting team.
  ///
  /// In en, this message translates to:
  /// **'Set team'**
  String get wizardBulkSetTeam;

  /// Menu title for setting team.
  ///
  /// In en, this message translates to:
  /// **'Set team for {count}'**
  String wizardBulkSetTeamTitle(int count);

  /// Menu label for setting class.
  ///
  /// In en, this message translates to:
  /// **'Set class'**
  String get wizardBulkSetClass;

  /// Menu title for setting class.
  ///
  /// In en, this message translates to:
  /// **'Set class for {count}'**
  String wizardBulkSetClassTitle(int count);

  /// Menu label for setting role.
  ///
  /// In en, this message translates to:
  /// **'Set role'**
  String get wizardBulkSetRole;

  /// Menu title for setting role.
  ///
  /// In en, this message translates to:
  /// **'Set role for {count}'**
  String wizardBulkSetRoleTitle(int count);

  /// Button to remove selected rows.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get wizardBulkRemove;

  /// Tooltip for clearing the selection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get wizardBulkClear;

  /// Step status: complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get wizardStepComplete;

  /// Step status: current.
  ///
  /// In en, this message translates to:
  /// **'Current step'**
  String get wizardStepCurrent;

  /// Step status: current with errors.
  ///
  /// In en, this message translates to:
  /// **'Current · needs attention'**
  String get wizardStepCurrentNeedsAttention;

  /// Step status: needs attention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get wizardStepNeedsAttention;

  /// Step status: visited.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get wizardStepVisited;

  /// Step status: not started.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get wizardStepNotStarted;

  /// Tooltip explaining the draft status.
  ///
  /// In en, this message translates to:
  /// **'One draft at a time. It is kept on this device and isn’t listed with contests.'**
  String get wizardDraftExplanation;

  /// Short draft status with time.
  ///
  /// In en, this message translates to:
  /// **'Draft saved {time}'**
  String wizardDraftSavedAt(String time);

  /// Draft status with time.
  ///
  /// In en, this message translates to:
  /// **'Draft saved · {time}'**
  String wizardDraftSavedDot(String time);

  /// Help text for the start date picker.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get wizardStartDateHelp;

  /// Help text for the end date picker.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get wizardEndDateHelp;

  /// Team count in the summary.
  ///
  /// In en, this message translates to:
  /// **'{count} count for team score'**
  String wizardTeamCount(String count);

  /// Pilot count in the copy source line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pilot} other{{count} pilots}}'**
  String wizardPilotsCountShort(int count);

  /// Page title.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get rolesTitle;

  /// Count of roles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 role} other{{count} roles}}'**
  String rolesCount(int count);

  /// Subtitle for a system role.
  ///
  /// In en, this message translates to:
  /// **'System role'**
  String get rolesSystemRole;

  /// Subtitle for a director's role.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get rolesYourRole;

  /// Dialog title for creating a role.
  ///
  /// In en, this message translates to:
  /// **'New role'**
  String get rolesNew;

  /// Confirm button in the create dialog.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get rolesCreate;

  /// Dialog title for renaming a role.
  ///
  /// In en, this message translates to:
  /// **'Rename role'**
  String get rolesRename;

  /// Button to rename a role.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rolesRenameButton;

  /// Dialog title for deleting a role.
  ///
  /// In en, this message translates to:
  /// **'Delete role?'**
  String get rolesDeleteTitle;

  /// Dialog body for deleting a role.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from your roles. Contests are not affected.'**
  String rolesDeleteBody(String name);

  /// Confirm button in the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get rolesDelete;

  /// Title when the role list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Roles could not be loaded.'**
  String get rolesLoadFailed;

  /// Loading label.
  ///
  /// In en, this message translates to:
  /// **'Loading roles'**
  String get rolesLoading;

  /// Field label in the name dialog.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get rolesNameLabel;

  /// Validation error for a blank name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the role.'**
  String get rolesNameError;

  /// Tooltip for the back button.
  ///
  /// In en, this message translates to:
  /// **'Back to roles'**
  String get rolesBackToRoles;

  /// Tooltip for the delete button.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String rolesDeleteTooltip(String name);

  /// Tooltip when delete is off.
  ///
  /// In en, this message translates to:
  /// **'In use, cannot delete'**
  String get rolesInUseTooltip;

  /// Detail label for role type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get rolesType;

  /// Role type: pilot.
  ///
  /// In en, this message translates to:
  /// **'Pilot'**
  String get rolesPilot;

  /// Role type: non-flier.
  ///
  /// In en, this message translates to:
  /// **'Non-flier'**
  String get rolesNonFlier;

  /// Detail label for role owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get rolesOwner;

  /// Owner: system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get rolesOwnerSystem;

  /// Owner: the director.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get rolesOwnerYou;

  /// Detail label for scoring.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get rolesScores;

  /// Pilot receives scores.
  ///
  /// In en, this message translates to:
  /// **'Receives scores'**
  String get rolesReceivesScores;

  /// Non-flier has no scores.
  ///
  /// In en, this message translates to:
  /// **'No scores'**
  String get rolesNoScores;

  /// Why the Pilot role cannot be changed.
  ///
  /// In en, this message translates to:
  /// **'The Pilot role is fixed. Every participant starts as a pilot, and only pilots fly and receive scores, so it cannot be renamed or deleted.'**
  String get rolesPilotExplanation;

  /// Why a system role cannot be changed.
  ///
  /// In en, this message translates to:
  /// **'This is a system role shared by every director, so it cannot be renamed or deleted.'**
  String get rolesSystemExplanation;

  /// Why an in-use role cannot be deleted.
  ///
  /// In en, this message translates to:
  /// **'A role that participants have cannot be deleted. Change those participants to another role first.'**
  String get rolesInUseExplanation;

  /// Title of the usage card.
  ///
  /// In en, this message translates to:
  /// **'Where it is used'**
  String get rolesUsageTitle;

  /// Error text when usage fails to load.
  ///
  /// In en, this message translates to:
  /// **'Usage could not be loaded. {error}'**
  String rolesUsageLoadFailed(String error);

  /// Empty state in the usage card.
  ///
  /// In en, this message translates to:
  /// **'No contest uses this role yet.'**
  String get rolesUsageEmpty;

  /// One usage line.
  ///
  /// In en, this message translates to:
  /// **'{contest}: {count, plural, =1{1 participant} other{{count} participants}}'**
  String rolesUsageItem(String contest, int count);

  /// Title of the Landings page list pane.
  ///
  /// In en, this message translates to:
  /// **'Landings'**
  String get landingsTitle;

  /// Number of landing tables.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 table} other{{count} tables}}'**
  String landingsCount(int count);

  /// Label for a system landing table.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get landingsSystem;

  /// Label for a director-owned landing table.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get landingsYours;

  /// Number of entries in a landing table.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String landingsEntries(int count);

  /// Landing input unit: meters.
  ///
  /// In en, this message translates to:
  /// **'Meters'**
  String get landingsUnitMeters;

  /// Landing input unit: feet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get landingsUnitFeet;

  /// Landing input unit: points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get landingsUnitPoints;

  /// Reason a system table cannot be deleted.
  ///
  /// In en, this message translates to:
  /// **'System tables are read-only and cannot be removed.'**
  String get landingsLockedSystem;

  /// Reason a table in use cannot be deleted.
  ///
  /// In en, this message translates to:
  /// **'Locked: a contest uses this table, so it cannot be removed.'**
  String get landingsLockedInUse;

  /// Notice under a locked table.
  ///
  /// In en, this message translates to:
  /// **'{reason} A table never changes; create a copy to make a different one.'**
  String landingsLockedNote(String reason);

  /// Tooltip for the back arrow in the detail pane.
  ///
  /// In en, this message translates to:
  /// **'Back to landings'**
  String get landingsBackToLandings;

  /// Button label for creating a copy of a landing table.
  ///
  /// In en, this message translates to:
  /// **'Create copy'**
  String get landingsCreateCopy;

  /// Tooltip for the delete button.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String landingsDeleteTooltip(String name);

  /// Column heading for entry labels.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get landingsLabelHeading;

  /// Column heading for entry points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get landingsPointsHeading;

  /// Title of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete landing table?'**
  String get landingsDeleteConfirmTitle;

  /// Content of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed.'**
  String landingsDeleteConfirmContent(String name);

  /// Cancel button in the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get landingsDeleteCancel;

  /// Confirm button in the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get landingsDeleteConfirm;

  /// Error title when landing tables fail to load.
  ///
  /// In en, this message translates to:
  /// **'Landing tables could not be loaded.'**
  String get landingsLoadFailed;

  /// Loading indicator label.
  ///
  /// In en, this message translates to:
  /// **'Loading landing tables'**
  String get landingsLoading;

  /// Empty state when no tables exist.
  ///
  /// In en, this message translates to:
  /// **'No landing tables yet.'**
  String get landingsEmpty;

  /// Label for the name field in the landing editor.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get landingEditorName;

  /// Label for the unit dropdown in the landing editor.
  ///
  /// In en, this message translates to:
  /// **'What the keys mean'**
  String get landingEditorUnitLabel;

  /// Section header for the entries list.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get landingEditorEntries;

  /// Button to add another entry row.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get landingEditorAddEntry;

  /// Save button in the landing editor.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get landingEditorSave;

  /// Cancel button in the landing editor.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get landingEditorCancel;

  /// Label for the entry label field.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get landingEditorEntryLabel;

  /// Label for the entry points field.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get landingEditorEntryPoints;

  /// Tooltip for the remove-entry button.
  ///
  /// In en, this message translates to:
  /// **'Remove entry {n}'**
  String landingEditorRemoveEntry(int n);

  /// Title of the external site confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Opening external site'**
  String get landingOpenExternalTitle;

  /// Cancel button in the external site dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get landingOpenExternalCancel;

  /// Open button in the external site dialog.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get landingOpenExternalOpen;

  /// Snack bar when opening a link fails.
  ///
  /// In en, this message translates to:
  /// **'Could not open \"{label}\".'**
  String landingOpenExternalFailed(String label);

  /// Sign in button on the landing page.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get landingSignIn;

  /// Create account button on the landing page.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get landingCreateAccount;

  /// Loading text while checking sign-in.
  ///
  /// In en, this message translates to:
  /// **'Checking sign-in…'**
  String get landingCheckingSignIn;

  /// Retry button after a failed sign-in check.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get landingRetry;

  /// Continue button on the landing page.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get landingContinue;

  /// Sign out button on the landing page.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get landingSignOut;

  /// Continue offline button on the landing page.
  ///
  /// In en, this message translates to:
  /// **'Continue offline'**
  String get landingContinueOffline;

  /// Help button on the landing page.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get landingHelp;

  /// Link to the public contest site.
  ///
  /// In en, this message translates to:
  /// **'Public contest site'**
  String get landingPublicSite;

  /// Content of the external site dialog.
  ///
  /// In en, this message translates to:
  /// **'You are about to leave Soar Score and open \"{label}\" in a new browser tab. Any unsaved local work is not affected.'**
  String landingOpenExternalContent(String label);

  /// Title when the identity provider is unreachable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in unavailable'**
  String get landingSignInUnavailable;

  /// Detail text when the identity provider is unreachable.
  ///
  /// In en, this message translates to:
  /// **'The identity provider is currently unreachable: {error}.'**
  String landingSignInUnavailableDetail(String error);

  /// Label showing the signed-in user.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String landingSignedInAs(String name);

  /// Tagline under the brand logo.
  ///
  /// In en, this message translates to:
  /// **'Manage and score RC sailplane soaring contests.'**
  String get landingTagline;

  /// Note about offline contests (native only).
  ///
  /// In en, this message translates to:
  /// **'Offline contests stay on this device unless you publish them or sign in to enable synchronization.'**
  String get landingOfflineNote;

  /// Title of the Participants page list pane.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsTitle;

  /// Number of participants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant} other{{count} participants}}'**
  String participantsCount(int count);

  /// Filtered count of participants.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String participantsCountOf(int shown, int total);

  /// Search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, FAI number or national ID'**
  String get participantsSearchHint;

  /// Empty state when search has no results.
  ///
  /// In en, this message translates to:
  /// **'No participants match.'**
  String get participantsNoMatch;

  /// Error title when participants fail to load.
  ///
  /// In en, this message translates to:
  /// **'Participants could not be loaded.'**
  String get participantsLoadFailed;

  /// Loading indicator label.
  ///
  /// In en, this message translates to:
  /// **'Loading participants'**
  String get participantsLoading;

  /// Empty state when no participants exist.
  ///
  /// In en, this message translates to:
  /// **'No participants yet.'**
  String get participantsEmpty;

  /// Title of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete participant?'**
  String get participantsDeleteTitle;

  /// Content of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from your participant list.'**
  String participantsDeleteContent(String name);

  /// Cancel button in the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get participantsDeleteCancel;

  /// Confirm button in the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get participantsDeleteConfirm;

  /// Tooltip for the back arrow in the detail pane.
  ///
  /// In en, this message translates to:
  /// **'Back to participants'**
  String get participantsBackToParticipants;

  /// Edit button in the detail pane.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get participantsEdit;

  /// Tooltip for the delete button.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String participantsDeleteTooltip(String name);

  /// Section title: identification.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get participantsSectionIdentification;

  /// Label for the FAI number field.
  ///
  /// In en, this message translates to:
  /// **'FAI number'**
  String get participantsFaiNumber;

  /// Label for the national organization ID field.
  ///
  /// In en, this message translates to:
  /// **'National organization ID'**
  String get participantsNationalOrgId;

  /// Label for the club field.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get participantsClub;

  /// Section title: location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get participantsSectionLocation;

  /// Label for the city field.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get participantsCity;

  /// Label for the state/province field.
  ///
  /// In en, this message translates to:
  /// **'State/province'**
  String get participantsState;

  /// Label for the country field.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get participantsCountry;

  /// Section title: contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get participantsSectionContact;

  /// Label for the email field in the detail pane.
  ///
  /// In en, this message translates to:
  /// **'Email (private, used for matching only)'**
  String get participantsEmailPrivate;

  /// Notice on the sync page when sync is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Syncing is only used in the Windows app.'**
  String get syncWindowsOnly;

  /// Title of the sync details card.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// Loading text in the sync details card.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get syncChecking;

  /// Notice for a local-only contest.
  ///
  /// In en, this message translates to:
  /// **'This contest is local only. It has no remote backup and does not sync until it is tied to an account.'**
  String get syncLocalOnlyText;

  /// Always-shown warning in the sync details card.
  ///
  /// In en, this message translates to:
  /// **'Changes made after the last successful sync cannot be recovered if this installation is lost.'**
  String get syncUnrecoverableWarning;

  /// Row label: last synced time.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get syncLastSynced;

  /// Row value when never synced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNotSyncedYet;

  /// Row label: pending changes.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be sent'**
  String get syncWaitingToSend;

  /// Row label: rejected changes.
  ///
  /// In en, this message translates to:
  /// **'Refused by the service'**
  String get syncRefusedByService;

  /// Row label / card title for conflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts to decide'**
  String get syncConflictsToDecide;

  /// Button label to trigger a sync.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// Button label while syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncSyncing;

  /// Loading text in the conflicts card.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get syncConflictsLoading;

  /// Empty state in the conflicts card.
  ///
  /// In en, this message translates to:
  /// **'None. Nothing is waiting for your decision.'**
  String get syncConflictsNone;

  /// Button to review a conflict.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get syncReview;

  /// Title of the refused changes card.
  ///
  /// In en, this message translates to:
  /// **'Changes the service refused'**
  String get syncRefusedTitle;

  /// Loading text in the refused changes card.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get syncRefusedLoading;

  /// Empty state in the refused changes card.
  ///
  /// In en, this message translates to:
  /// **'None. The service accepted every change it has answered.'**
  String get syncRefusedNone;

  /// Snack bar after a successful conflict decision.
  ///
  /// In en, this message translates to:
  /// **'Decision saved.'**
  String get syncDecisionSaved;

  /// Snack bar when the post-decision sync failed.
  ///
  /// In en, this message translates to:
  /// **'Decision sent. The sync that follows failed ({problem}), so this screen updates after the next successful sync.'**
  String syncDecisionFailed(String problem);

  /// Button to close the conflict dialog without deciding.
  ///
  /// In en, this message translates to:
  /// **'Decide later'**
  String get syncDecideLater;

  /// Button to cancel editing in the conflict dialog.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get syncBack;

  /// Button to save an edited conflict payload.
  ///
  /// In en, this message translates to:
  /// **'Keep edited value'**
  String get syncKeepEdited;

  /// Button to edit a conflict payload.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get syncEdit;

  /// Button to keep the competing version.
  ///
  /// In en, this message translates to:
  /// **'Use competing change'**
  String get syncUseCompeting;

  /// Button to keep the accepted version.
  ///
  /// In en, this message translates to:
  /// **'Keep accepted value'**
  String get syncKeepAccepted;

  /// Title of the conflict resolve dialog.
  ///
  /// In en, this message translates to:
  /// **'Resolve {entityType} conflict'**
  String syncResolveTitle(String entityType);

  /// Title of the add-participant dialog.
  ///
  /// In en, this message translates to:
  /// **'Add {name}?'**
  String contestParticipantsAddTitle(String name);

  /// Title of the add-participant dialog after the draw.
  ///
  /// In en, this message translates to:
  /// **'Add after the draw?'**
  String get contestParticipantsAddAfterDrawTitle;

  /// Add-participant dialog body after the draw.
  ///
  /// In en, this message translates to:
  /// **'The draw has already been made. {name} will be added to the contest. Place them in a group from the Matrix page. A redraw is also possible.'**
  String contestParticipantsAddBodyLate(String name);

  /// Add-participant dialog body.
  ///
  /// In en, this message translates to:
  /// **'{name} will be added to the contest{asRole}.'**
  String contestParticipantsAddBody(String name, String asRole);

  /// Label of the role dropdown in the add-participant dialog.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get contestParticipantsAddRoleLabel;

  /// Confirm button in the add-participant dialog.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get contestParticipantsAddConfirm;

  /// Title of the redraw-offer dialog.
  ///
  /// In en, this message translates to:
  /// **'Redraw the matrix with {name}?'**
  String contestParticipantsRedrawTitle(String name);

  /// Body of the redraw-offer dialog.
  ///
  /// In en, this message translates to:
  /// **'No scores have been entered, so the matrix can be drawn again to include {name} fairly. Or keep the matrix as it is: {name} is then added to the last group of every round, within the contest’s group sizes and team protection.'**
  String contestParticipantsRedrawBody(String name);

  /// Button to keep the matrix in the redraw-offer dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep the matrix'**
  String get contestParticipantsRedrawKeep;

  /// Button to redraw the matrix in the redraw-offer dialog.
  ///
  /// In en, this message translates to:
  /// **'Redraw'**
  String get contestParticipantsRedrawDo;

  /// Title of the role-change confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Change {name} to {roleName}?'**
  String contestParticipantsChangeRoleTitle(String name, String roleName);

  /// First sentence of the role-change confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{roleName} is a non-flying role, so {name} {verb} no score rows{classCleared}.'**
  String contestParticipantsChangeRoleBody(
    String roleName,
    String name,
    String verb,
    String classCleared,
  );

  /// Note when the pilot has places in the draw.
  ///
  /// In en, this message translates to:
  /// **'Their places in the draw are removed when you save, and the draw will need redoing.'**
  String get contestParticipantsChangeRoleDrawNote;

  /// Final sentence of the role-change confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'You can still undo this before you save.'**
  String get contestParticipantsChangeRoleUndoNote;

  /// Confirm button in the role-change confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get contestParticipantsChangeRoleConfirm;

  /// Title of the remove confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove {count, plural, =1{1 person} other{{count} people}} from this contest?'**
  String contestParticipantsRemoveTitle(int count);

  /// Body of the remove confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This removes them from {contestName} only. Their saved profiles stay, and you can add them again later.'**
  String contestParticipantsRemoveBody(String contestName);

  /// Note about draw places in the remove confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{names} {verb} in the draw. Their places in it are removed too, and the draw will need redoing.'**
  String contestParticipantsRemoveInDraw(String names, String verb);

  /// Confirm button in the remove confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove {count}'**
  String contestParticipantsRemoveButton(int count);

  /// Button to discard unsaved rows in the save bar.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get contestParticipantsSaveDiscard;

  /// Note that role changes are made in the Configuration page.
  ///
  /// In en, this message translates to:
  /// **'Change in Configuration.'**
  String get contestParticipantsChangeInConfiguration;

  /// Banner line for a pilot without a class.
  ///
  /// In en, this message translates to:
  /// **'{name}: enter a class'**
  String contestParticipantsMissingClass(String name);

  /// Save bar title while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving {count, plural, =1{1 participant} other{{count} participants}}…'**
  String contestParticipantsSavingRows(int count);

  /// Save bar note while saving.
  ///
  /// In en, this message translates to:
  /// **'Rows are locked until it finishes.'**
  String get contestParticipantsRowsLocked;

  /// Save bar title when a row is stale.
  ///
  /// In en, this message translates to:
  /// **'Someone changed this participant. Refresh to continue.'**
  String get contestParticipantsStaleTitle;

  /// Link in the save bar to refresh a stale row.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get contestParticipantsRefresh;

  /// Save bar title when rows are invalid.
  ///
  /// In en, this message translates to:
  /// **'Fix {count, plural, =1{1 row} other{{count} rows}} before saving.'**
  String contestParticipantsFixRows(int count);

  /// Link in the save bar to an invalid row.
  ///
  /// In en, this message translates to:
  /// **'Show row'**
  String get contestParticipantsShowRow;

  /// Save bar title with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes to {count, plural, =1{1 participant} other{{count} participants}}'**
  String contestParticipantsUnsavedChanges(int count);

  /// Save bar note under unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Each participant saves on its own.'**
  String get contestParticipantsEachSaves;

  /// Save bar title when nothing is changed.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get contestParticipantsNoChanges;

  /// Save button in the save bar.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get contestParticipantsSaveChanges;

  /// Count line when the contest has no participants.
  ///
  /// In en, this message translates to:
  /// **'No participants'**
  String get contestParticipantsCountNone;

  /// Count line of pilots and non-flying participants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pilot} other{{count} pilots}}{nonFlying}'**
  String contestParticipantsCountPilots(int count, String nonFlying);

  /// Suffix of the count line for non-flying participants.
  ///
  /// In en, this message translates to:
  /// **', {count} non-flying'**
  String contestParticipantsCountNonFlying(int count);

  /// Options line when no participant option is on.
  ///
  /// In en, this message translates to:
  /// **'No participant options are on.'**
  String get contestParticipantsOptionsNone;

  /// Options line naming the participant options that are on.
  ///
  /// In en, this message translates to:
  /// **'{options} {verb} on.'**
  String contestParticipantsOptionsOn(String options, String verb);

  /// Name of the teams participant option.
  ///
  /// In en, this message translates to:
  /// **'teams'**
  String get contestParticipantsOptionTeams;

  /// Name of the classes participant option.
  ///
  /// In en, this message translates to:
  /// **'classes'**
  String get contestParticipantsOptionClasses;

  /// Name of the roles participant option.
  ///
  /// In en, this message translates to:
  /// **'roles'**
  String get contestParticipantsOptionRoles;

  /// Name of the pilot numbers participant option.
  ///
  /// In en, this message translates to:
  /// **'pilot numbers'**
  String get contestParticipantsOptionPilotNumbers;

  /// Name of the pilot models participant option.
  ///
  /// In en, this message translates to:
  /// **'pilot models'**
  String get contestParticipantsOptionPilotModels;

  /// Banner when the contest is read-only.
  ///
  /// In en, this message translates to:
  /// **'This contest is completed. Participants can’t be changed.'**
  String get contestParticipantsReadOnlyText;

  /// Banner title when administration is locked.
  ///
  /// In en, this message translates to:
  /// **'Administration is locked. Unlock to change.'**
  String get contestParticipantsLockedTitle;

  /// Banner text when administration is locked.
  ///
  /// In en, this message translates to:
  /// **'Role, class and team feed the matrix, so they’re off while locked. Adding and removing people are off too.'**
  String get contestParticipantsLockedText;

  /// Button to unlock administration.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get contestParticipantsUnlock;

  /// Banner when fewer than 2 scoring pilots.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 scoring pilots before the draw.'**
  String get contestParticipantsMinPilots;

  /// Banner when exactly 2 scoring pilots.
  ///
  /// In en, this message translates to:
  /// **'With fewer than 3 pilots, use 1 group per round.'**
  String get contestParticipantsFewPilots;

  /// Banner title after a failed add.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add {name}'**
  String contestParticipantsAddFailedTitle(String name);

  /// Banner text when the add needs room in the groups.
  ///
  /// In en, this message translates to:
  /// **'{failure} Nothing was added. Add them again once the groups are changed.'**
  String contestParticipantsAddFailedRoom(String failure);

  /// Banner text after a failed add.
  ///
  /// In en, this message translates to:
  /// **'{failure} Nothing was added. Trying again won’t add them twice.'**
  String contestParticipantsAddFailedRetry(String failure);

  /// Button to open the Matrix page.
  ///
  /// In en, this message translates to:
  /// **'Open Matrix'**
  String get contestParticipantsOpenMatrix;

  /// Button to retry a failed add.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get contestParticipantsTryAgain;

  /// Banner title when a removal was partial.
  ///
  /// In en, this message translates to:
  /// **'{removed} of {total} removed'**
  String contestParticipantsPartialRemoved(int removed, int total);

  /// Banner title when a removal was refused.
  ///
  /// In en, this message translates to:
  /// **'Not removed'**
  String get contestParticipantsNotRemoved;

  /// Line naming the participants removed.
  ///
  /// In en, this message translates to:
  /// **'{names} {verb} removed from this contest.'**
  String contestParticipantsRemovedFrom(String names, String verb);

  /// Line for a participant that was not removed.
  ///
  /// In en, this message translates to:
  /// **'{name} wasn’t: {reason}'**
  String contestParticipantsRefused(String name, String reason);

  /// Note about retiring a pilot with scores.
  ///
  /// In en, this message translates to:
  /// **'To take a pilot with scores out of the results, retire them in Scoring.'**
  String get contestParticipantsRetireNote;

  /// Button to open the Scoring page.
  ///
  /// In en, this message translates to:
  /// **'Open Scoring'**
  String get contestParticipantsOpenScoring;

  /// Button to dismiss a banner.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get contestParticipantsDismiss;

  /// Banner title when people left the draw.
  ///
  /// In en, this message translates to:
  /// **'The draw needs redoing'**
  String get contestParticipantsRedoDrawTitle;

  /// Banner text when people left the draw.
  ///
  /// In en, this message translates to:
  /// **'{names} {wasWere} in the draw and {hasHave} no scores, so their places were removed from it. The groups are not balanced for the pilots who are left until the matrix is drawn again.'**
  String contestParticipantsRedoDrawText(
    String names,
    String wasWere,
    String hasHave,
  );

  /// Button to redo the draw.
  ///
  /// In en, this message translates to:
  /// **'Redo the draw'**
  String get contestParticipantsRedoDraw;

  /// Banner title after a change in a running contest.
  ///
  /// In en, this message translates to:
  /// **'Results are recalculated'**
  String get contestParticipantsRecalculatedTitle;

  /// Banner text after a change in a running contest.
  ///
  /// In en, this message translates to:
  /// **'{names} changed. All results will be recalculated.'**
  String contestParticipantsRecalculatedText(String names);

  /// Banner title when a pilot is placed in every round.
  ///
  /// In en, this message translates to:
  /// **'{name} is in every round'**
  String contestParticipantsPlacedEverywhere(String name);

  /// Banner title when a pilot is not in every round.
  ///
  /// In en, this message translates to:
  /// **'{name} is not in every round'**
  String contestParticipantsNotPlacedEverywhere(String name);

  /// Line naming the rounds a pilot was placed in.
  ///
  /// In en, this message translates to:
  /// **'{name} was added to the last group that could take them in {count} {roundWord}.'**
  String contestParticipantsPlacedInRounds(
    String name,
    int count,
    String roundWord,
  );

  /// Line about rounds that were already scored.
  ///
  /// In en, this message translates to:
  /// **'{rounds} {wasWere} already scored, so they got a zero {where}. Correct the scores in Scoring if needed.'**
  String contestParticipantsZeroedRounds(
    String rounds,
    String wasWere,
    String where,
  );

  /// Line for a skipped round.
  ///
  /// In en, this message translates to:
  /// **'Round {round}: {reason}.'**
  String contestParticipantsRoundReason(int round, String reason);

  /// Note when a pilot is not in every round.
  ///
  /// In en, this message translates to:
  /// **'Place them in those rounds from the Matrix page.'**
  String get contestParticipantsPlaceFromMatrix;

  /// Banner title for unplaced pilots.
  ///
  /// In en, this message translates to:
  /// **'{names} {isnt} placed yet'**
  String contestParticipantsUnplacedTitle(String names, String isnt);

  /// Banner text for unplaced pilots.
  ///
  /// In en, this message translates to:
  /// **'Put them in the last group of every round, or place them from the Matrix page. A redraw is also possible.'**
  String get contestParticipantsUnplacedText;

  /// Button to place unplaced pilots in all rounds.
  ///
  /// In en, this message translates to:
  /// **'Place in all rounds'**
  String get contestParticipantsPlaceAllRounds;

  /// Banner title for pilots without a class.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant has} other{{count} participants have}} no class'**
  String contestParticipantsMissingClassTitle(int count);

  /// Banner text for pilots without a class.
  ///
  /// In en, this message translates to:
  /// **'Results are grouped by class. This does not stop you saving, drawing or scoring.'**
  String get contestParticipantsMissingClassText;

  /// Title of the empty participants state.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get participantsEmptyTitle;

  /// Text under the empty participants state.
  ///
  /// In en, this message translates to:
  /// **'Add people you’ve saved before, or create a new one.'**
  String get participantsEmptyText;

  /// Title of the save-configuration confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Save configuration?'**
  String get configSaveTitle;

  /// Heading for matrix-affecting changes in the save dialog.
  ///
  /// In en, this message translates to:
  /// **'The drawn matrix becomes out of date'**
  String get configSaveMatrixHead;

  /// Text for matrix-affecting changes in the save dialog.
  ///
  /// In en, this message translates to:
  /// **'{names} changed. The drawn matrix{revision} no longer matches; redraw unscored rounds on the Matrix page.'**
  String configSaveMatrixText(String names, String revision);

  /// Matrix revision in the save dialog text.
  ///
  /// In en, this message translates to:
  /// **' (revision {revision})'**
  String configSaveMatrixRevision(int revision);

  /// Text for changes with no effect in the save dialog.
  ///
  /// In en, this message translates to:
  /// **'Also saving, with no effect on the matrix or results: {names}.'**
  String configSaveOtherText(String names);

  /// Confirm button in the save dialog.
  ///
  /// In en, this message translates to:
  /// **'Save configuration'**
  String get configSaveConfirm;

  /// Save bar title while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving configuration…'**
  String get configBarSaving;

  /// Save bar note while saving.
  ///
  /// In en, this message translates to:
  /// **'The page is locked until the save finishes.'**
  String get configBarSavingLocked;

  /// Save bar title after a failed save.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the configuration'**
  String get configBarSaveFailed;

  /// Save bar note after a failed save.
  ///
  /// In en, this message translates to:
  /// **'{error} Every value you entered is kept.'**
  String configBarSaveFailedSub(String error);

  /// Save bar title with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsaved change} other{{count} unsaved changes}}'**
  String configBarUnsaved(int count);

  /// Chip when the change makes the drawn matrix out of date.
  ///
  /// In en, this message translates to:
  /// **'Makes the drawn matrix out of date'**
  String get configBarMatrixChip;

  /// Chip when the change recalculates results.
  ///
  /// In en, this message translates to:
  /// **'Recalculates all results'**
  String get configBarRecalcChip;

  /// Chip when the change has no effect.
  ///
  /// In en, this message translates to:
  /// **'No effect on the matrix or results'**
  String get configBarNoEffectChip;

  /// Save bar note when errors stop a save.
  ///
  /// In en, this message translates to:
  /// **'Fix {count, plural, =1{1 error} other{{count} errors}} to save'**
  String configBarFixErrors(int count);

  /// Semantics label of the configuration save bar.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get configBarUnsavedLabel;

  /// Semantics label of the progress bar while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving configuration'**
  String get configBarSavingProgress;

  /// Save button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get configBarSaveShort;

  /// Save button label after a failed save.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get configBarRetry;

  /// Error summary title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 setting needs} other{{count} settings need}} fixing before you can save'**
  String configBarSettingsNeedFixing(int count);

  /// One error in the error summary.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String configBarErrorItem(String label, String value);

  /// Title of the landing table picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a landing table'**
  String get landingPickerTitle;

  /// Note under the picker title.
  ///
  /// In en, this message translates to:
  /// **'Any table works for any discipline. Check the unit matches how your scorers measure.'**
  String get landingPickerNote;

  /// Button that opens the Landings page to create a table.
  ///
  /// In en, this message translates to:
  /// **'Create a table in Landings'**
  String get landingPickerCreateTable;

  /// Button that picks the highlighted table.
  ///
  /// In en, this message translates to:
  /// **'Use this table'**
  String get landingPickerUse;

  /// Chip for the profile's default table.
  ///
  /// In en, this message translates to:
  /// **'Profile default'**
  String get landingPickerProfileDefault;

  /// Chip for the table the draft uses now.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get landingPickerCurrent;

  /// Heading above the table preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get landingPickerPreview;

  /// Chip: the setting differs from the saved one.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get configChipUnsaved;

  /// Chip: the value differs from the official profile.
  ///
  /// In en, this message translates to:
  /// **'House rule'**
  String get configChipHouseRule;

  /// Chip: the value cannot be saved.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get configChipError;

  /// Chip on the participants section: the list is a summary.
  ///
  /// In en, this message translates to:
  /// **'Summary only'**
  String get configSummaryOnly;

  /// Tooltip when every discipline option matches the profile default.
  ///
  /// In en, this message translates to:
  /// **'Every option matches the {label}'**
  String configDefaultMatches(String label);

  /// Chip naming the number of house rules.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 house rule} other{{count} house rules}}'**
  String configHouseRules(int count);

  /// Detail under Open scoring access.
  ///
  /// In en, this message translates to:
  /// **'Participants can submit scores.'**
  String get configStateScoringOpenDetail;

  /// Detail under Closed scoring access.
  ///
  /// In en, this message translates to:
  /// **'Participants can’t submit scores.'**
  String get configStateScoringClosedDetail;

  /// Detail under a locked administration.
  ///
  /// In en, this message translates to:
  /// **'The configuration, participants and matrix are read-only.'**
  String get configStateAdminLockedDetail;

  /// Detail under an unlocked administration.
  ///
  /// In en, this message translates to:
  /// **'The contest can be administered.'**
  String get configStateAdminUnlockedDetail;

  /// Button to change a contest state in the Workspace.
  ///
  /// In en, this message translates to:
  /// **'Change in Workspace'**
  String get configChangeInWorkspace;

  /// Label of the scoring pilots count.
  ///
  /// In en, this message translates to:
  /// **'Scoring pilots'**
  String get configParticipantsScoringPilots;

  /// Label of the other participants count.
  ///
  /// In en, this message translates to:
  /// **'Other participants'**
  String get configParticipantsOther;

  /// Label of the teams count.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get configParticipantsTeams;

  /// Note when fewer than 2 scoring pilots.
  ///
  /// In en, this message translates to:
  /// **'A matrix needs at least 2 scoring pilots. This contest has {count}.'**
  String configParticipantsMinPilotsNote(int count);

  /// Button to open the Participants page.
  ///
  /// In en, this message translates to:
  /// **'Open Participants'**
  String get configOpenParticipants;

  /// Note under the Open Participants button.
  ///
  /// In en, this message translates to:
  /// **'Participants are edited there.'**
  String get configParticipantsEditedThere;

  /// Heading and semantics label of the matrix readiness panel.
  ///
  /// In en, this message translates to:
  /// **'Matrix readiness'**
  String get configMatrixReadiness;

  /// Button to open the Matrix page from the readiness panel.
  ///
  /// In en, this message translates to:
  /// **'Go to matrix'**
  String get configGoToMatrix;

  /// Error when no landing table is chosen.
  ///
  /// In en, this message translates to:
  /// **'No landing table chosen. Scorers can’t record landing bonuses until one is set.'**
  String get configLandingNoTable;

  /// Button to choose a landing table.
  ///
  /// In en, this message translates to:
  /// **'Choose table'**
  String get configLandingChoose;

  /// Button to change the landing table.
  ///
  /// In en, this message translates to:
  /// **'Change table'**
  String get configLandingChange;

  /// Button to hide the entries table.
  ///
  /// In en, this message translates to:
  /// **'Hide entries'**
  String get configLandingHideEntries;

  /// Button to show the entries table.
  ///
  /// In en, this message translates to:
  /// **'Show entries'**
  String get configLandingShowEntries;

  /// Button to open the Landings page.
  ///
  /// In en, this message translates to:
  /// **'Open Landings'**
  String get configOpenLandings;

  /// Note when the table is not the profile default.
  ///
  /// In en, this message translates to:
  /// **'Not the {defaultLabel} ({name}). That’s fine; any table works for any discipline. The unit is {unit}.'**
  String configLandingNotDefault(String defaultLabel, String name, String unit);

  /// Note of the saved table after a change.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String configLandingSaved(String name);

  /// The saved table when there is none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get configLandingNone;

  /// Warning when the change makes the drawn matrix out of date.
  ///
  /// In en, this message translates to:
  /// **'Saving makes the drawn matrix out of date.'**
  String get configLandingOutdatesMatrix;

  /// Label of the unit fact.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get configLandingUnit;

  /// Label of the entries fact.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get configLandingEntries;

  /// Label of the points range fact.
  ///
  /// In en, this message translates to:
  /// **'Points range'**
  String get configLandingPointsRange;

  /// Button to undo a change.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// Note when team protection is off with seeded draw.
  ///
  /// In en, this message translates to:
  /// **'Not available with Seeded Man on Man. Seeded groups are formed by score, so teammates may have to fly together.'**
  String get configNoteTeamProtectionSeeded;

  /// Action to switch the draw mode.
  ///
  /// In en, this message translates to:
  /// **'Use Man on Man instead'**
  String get configNoteUseManOnMan;

  /// House rule note naming the official value.
  ///
  /// In en, this message translates to:
  /// **'{label}: {official}{seconds}.'**
  String configNoteHouseRule(String label, String official, String seconds);

  /// Action to reset to the official value.
  ///
  /// In en, this message translates to:
  /// **'Reset to {label}'**
  String configNoteResetTo(String label);

  /// Note for a duration entered as minutes:seconds.
  ///
  /// In en, this message translates to:
  /// **'Entered as minutes:seconds. {display} = {seconds} s.'**
  String configNoteDuration(String display, int seconds);

  /// Note about group sizes with team protection.
  ///
  /// In en, this message translates to:
  /// **'Groups per round, set on the Matrix page, must be at least the size of the largest team.'**
  String get configNoteTeamProtectionSize;

  /// Note when the draw already assigns numbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers assigned at the draw don’t change.'**
  String get configNoteNumbersFixed;

  /// Note about drop rounds before the draw.
  ///
  /// In en, this message translates to:
  /// **'Checked against the rounds drawn on the Matrix page.'**
  String get configNoteDropsChecked;

  /// Note for a setting hidden and cleared by this one.
  ///
  /// In en, this message translates to:
  /// **'{label} ({saved}) is hidden and will be cleared when you save.'**
  String configNoteCleared(String label, String saved);

  /// Note of the saved value after a change.
  ///
  /// In en, this message translates to:
  /// **'Saved: {value}'**
  String configNoteSaved(String value);

  /// Note when the change recalculates results.
  ///
  /// In en, this message translates to:
  /// **'Saving recalculates all results.'**
  String get configNoteRecalculates;

  /// Example note for decimal places.
  ///
  /// In en, this message translates to:
  /// **'Example: 987.654 → {result} {mode}'**
  String configNoteExample(String result, String mode);

  /// Example mode: truncated.
  ///
  /// In en, this message translates to:
  /// **'(truncated)'**
  String get configNoteTruncated;

  /// Example mode: rounded.
  ///
  /// In en, this message translates to:
  /// **'(rounded)'**
  String get configNoteRounded;

  /// Drop note when no rounds are dropped.
  ///
  /// In en, this message translates to:
  /// **'No rounds are dropped.'**
  String get configNoteNoDrops;

  /// Drop note for one dropped round.
  ///
  /// In en, this message translates to:
  /// **'Drop the worst round after round {round1}.'**
  String configNoteDropOne(String round1);

  /// Drop note for two dropped rounds.
  ///
  /// In en, this message translates to:
  /// **'Drop the worst round after round {round1}, and a second after round {round2}.'**
  String configNoteDropTwo(String round1, String round2);

  /// Note about a non-droppable motor restart round.
  ///
  /// In en, this message translates to:
  /// **'A round with a motor restart can’t be dropped (Motor restart mode: Allowed, not dropped).'**
  String get configNoteMotorRestart;

  /// Reason the seeded draw mode is blocked.
  ///
  /// In en, this message translates to:
  /// **'Not available while team protection is on. Seeded groups are formed by score, so teammates may have to fly together.'**
  String get configBlockedTeamProtection;

  /// Fix action to turn off team protection.
  ///
  /// In en, this message translates to:
  /// **'Turn off team protection'**
  String get configFixTurnOffTeamProtection;

  /// One round named in a list.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String contestParticipantsRound(String number);

  /// Several rounds named in a list.
  ///
  /// In en, this message translates to:
  /// **'Rounds {numbers}'**
  String contestParticipantsRounds(String numbers);

  /// Save button label while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get contestParticipantsSavingShort;

  /// Semantics label of the progress bar while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving participants'**
  String get contestParticipantsSavingProgress;

  /// Summary of a save that left rows unsaved.
  ///
  /// In en, this message translates to:
  /// **'{saved} saved. {failed} not saved. Their typed values are kept.'**
  String contestParticipantsSavedSummary(int saved, int failed);

  /// Generic confirm button label.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Cancel button of the unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get configKeepEditing;

  /// Confirm button of the unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard and leave'**
  String get configDiscardAndLeave;

  /// Confirm button of the unsaved-changes dialog on app close.
  ///
  /// In en, this message translates to:
  /// **'Close and discard'**
  String get configCloseAndDiscard;

  /// Title of the unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get configLeaveTitle;

  /// Body of the unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'You have {count} unsaved {changes} in {sections}. {action} discards them.'**
  String configLeaveBody(
    int count,
    String changes,
    String sections,
    String action,
  );

  /// Message after discarding configuration changes.
  ///
  /// In en, this message translates to:
  /// **'Changes discarded.'**
  String get configChangesDiscarded;

  /// Action that discards changes on app close.
  ///
  /// In en, this message translates to:
  /// **'Closing the app'**
  String get configActionClosing;

  /// Action that discards changes when leaving the page.
  ///
  /// In en, this message translates to:
  /// **'Leaving'**
  String get configActionLeaving;

  /// Message after saving configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved as revision {revision}.{warning}'**
  String configSavedRevision(int revision, String warning);

  /// Message after saving only the contest details.
  ///
  /// In en, this message translates to:
  /// **'Contest details saved.'**
  String get configDetailsSaved;

  /// Title of the other-device-updated dialog.
  ///
  /// In en, this message translates to:
  /// **'Configuration updated'**
  String get configUpdatedTitle;

  /// Body when the contest has no saved configuration.
  ///
  /// In en, this message translates to:
  /// **'This contest was changed from another device. This page now shows the latest version. Your unsaved changes are kept.'**
  String get configUpdatedText;

  /// Body when another device saved a revision.
  ///
  /// In en, this message translates to:
  /// **'Revision {revision} was saved from another device. This page now shows the latest version. Your unsaved changes are kept; check them before saving again.'**
  String configUpdatedRevision(int revision);

  /// Title of the load-failure state.
  ///
  /// In en, this message translates to:
  /// **'The configuration could not be loaded.'**
  String get configLoadFailed;

  /// Label of the loading state.
  ///
  /// In en, this message translates to:
  /// **'Loading the configuration'**
  String get configLoading;

  /// Title of the administration-locked banner.
  ///
  /// In en, this message translates to:
  /// **'Administration is locked'**
  String get configAdminLockedTitle;

  /// Body of the administration-locked banner.
  ///
  /// In en, this message translates to:
  /// **'The configuration is read-only while administration is locked. Unlock it from the Workspace.'**
  String get configAdminLockedBody;

  /// Action of the administration-locked banner.
  ///
  /// In en, this message translates to:
  /// **'Go to Workspace'**
  String get configGoToWorkspace;

  /// Title of the completed-contest banner.
  ///
  /// In en, this message translates to:
  /// **'Contest completed'**
  String get configCompletedTitle;

  /// Body of the completed-contest banner.
  ///
  /// In en, this message translates to:
  /// **'The configuration is read-only. Only score corrections remain, and those are made on the Scoring page.'**
  String get configCompletedBody;

  /// Title of the not-saved banner.
  ///
  /// In en, this message translates to:
  /// **'Configuration not saved yet'**
  String get configNotSavedTitle;

  /// Body of the not-saved banner.
  ///
  /// In en, this message translates to:
  /// **'This contest has no saved configuration, and its discipline can’t be chosen on this page. Create the contest again with the New contest wizard to set one.'**
  String get configNotSavedBody;

  /// Title of the scoring-started banner.
  ///
  /// In en, this message translates to:
  /// **'Scoring has started'**
  String get configScoringStartedTitle;

  /// Body of the scoring-started banner.
  ///
  /// In en, this message translates to:
  /// **'Structural settings, discipline options and the landing table are fixed. Scoring settings can still change; saving them recalculates all results.'**
  String get configScoringStartedBody;

  /// Label of a setting the contest state has locked.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get configFixedChip;

  /// Accessible name of a locked setting.
  ///
  /// In en, this message translates to:
  /// **'Fixed: {reason}'**
  String configFixedChipSemantics(String reason);

  /// Key column header for a meters table.
  ///
  /// In en, this message translates to:
  /// **'Distance (m)'**
  String get configLandingKeyHeaderMeters;

  /// Key column header for a feet table.
  ///
  /// In en, this message translates to:
  /// **'Distance (ft)'**
  String get configLandingKeyHeaderFeet;

  /// Key column header for a points table.
  ///
  /// In en, this message translates to:
  /// **'Landing key'**
  String get configLandingKeyHeaderPoints;

  /// Points range when a table has no entries.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get configLandingNoEntries;

  /// Points range of a landing table.
  ///
  /// In en, this message translates to:
  /// **'{low}–{high} points'**
  String configLandingPointsRangeValue(int low, int high);

  /// Entry count in a landing table summary.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String configLandingEntriesCount(int count);

  /// Accessible name of a landing entries table.
  ///
  /// In en, this message translates to:
  /// **'{name} entries'**
  String configLandingEntriesLabel(String name);

  /// Heading of the pilot picker.
  ///
  /// In en, this message translates to:
  /// **'Pilots'**
  String get cardsPilotsHeading;

  /// Live count of the pilot picker.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} selected'**
  String cardsPilotCount(int count, int total);

  /// Hint of the pilot picker search.
  ///
  /// In en, this message translates to:
  /// **'Search pilots'**
  String get cardsSearchPilots;

  /// Select button while a search is active.
  ///
  /// In en, this message translates to:
  /// **'Select {count} shown'**
  String cardsSelectShown(int count);

  /// Button that selects every listed pilot.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get cardsSelectAll;

  /// Deselect button while a search is active.
  ///
  /// In en, this message translates to:
  /// **'Clear shown'**
  String get cardsClearShown;

  /// Button that deselects every listed pilot.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get cardsSelectNone;

  /// Tooltip of the add-a-team button.
  ///
  /// In en, this message translates to:
  /// **'Add a team’s pilots to the selection'**
  String get cardsAddTeamHint;

  /// Label of the add-a-team button.
  ///
  /// In en, this message translates to:
  /// **'Add a team'**
  String get cardsAddTeam;

  /// Accessible label of the pilot list.
  ///
  /// In en, this message translates to:
  /// **'Pilot list'**
  String get cardsPilotList;

  /// Picker list when the contest has no pilots.
  ///
  /// In en, this message translates to:
  /// **'No pilots in this contest yet.'**
  String get cardsNoPilotsYet;

  /// Picker list when no pilot matches the search.
  ///
  /// In en, this message translates to:
  /// **'No pilot matches “{query}”.'**
  String cardsNoPilotMatches(String query);

  /// Mark on a retired pilot.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get cardsRetired;

  /// Heading of the pilot cards options group.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get cardsOptions;

  /// Heading of the pilot cards group.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cardsGroup;

  /// Label of the include-retired-pilots option.
  ///
  /// In en, this message translates to:
  /// **'Include retired pilots'**
  String get cardsIncludeRetired;

  /// Help when include retired pilots is on.
  ///
  /// In en, this message translates to:
  /// **'Retired pilots are marked “Retired” on their cards.'**
  String get cardsIncludeRetiredHelp;

  /// Help when include retired pilots is off.
  ///
  /// In en, this message translates to:
  /// **'{count} retired {count, plural, =1{pilot is}other{pilots are}} left out.'**
  String cardsRetiredLeftOut(int count);

  /// Label of the pre-fill option.
  ///
  /// In en, this message translates to:
  /// **'Pre-fill'**
  String get cardsPrefill;

  /// Help when pre-fill is unavailable.
  ///
  /// In en, this message translates to:
  /// **'No scores have been entered yet.'**
  String get cardsPrefillUnavailable;

  /// Help when pre-fill is available.
  ///
  /// In en, this message translates to:
  /// **'Prints the scores already entered, so pilots can check them.'**
  String get cardsPrefillHelp;

  /// Label of the automatic cards-per-page choice.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get cardsAutomatic;

  /// Label of the four-cards-per-page choice.
  ///
  /// In en, this message translates to:
  /// **'Four per page'**
  String get cardsFourPerPage;

  /// Label of the two-cards-per-page choice.
  ///
  /// In en, this message translates to:
  /// **'Two per page'**
  String get cardsTwoPerPage;

  /// Label of a print margin choice.
  ///
  /// In en, this message translates to:
  /// **'{label} margin'**
  String cardsMarginLabel(String label);

  /// Label of the standard print margin.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get cardsMarginStandard;

  /// Help of the standard print margin.
  ///
  /// In en, this message translates to:
  /// **'6.35 mm (¼ in) from the paper’s edge.'**
  String get cardsMarginStandardHelp;

  /// Label of the wide print margin.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get cardsMarginWide;

  /// Help of the wide print margin.
  ///
  /// In en, this message translates to:
  /// **'10 mm from the paper’s edge, for a printer that cuts the cards off.'**
  String get cardsMarginWideHelp;

  /// Summary when no card is produced.
  ///
  /// In en, this message translates to:
  /// **'No cards'**
  String get cardsNoCards;

  /// Summary of the cards and pages produced.
  ///
  /// In en, this message translates to:
  /// **'{cards} {cards, plural, =1{card}other{cards}} · {pages} {pages, plural, =1{page}other{pages}}'**
  String cardsSummary(int cards, int pages);

  /// Choice help when the rounds do not fit.
  ///
  /// In en, this message translates to:
  /// **'Too many rounds'**
  String get cardsTooManyRounds;

  /// Choice help when automatic picks four per page.
  ///
  /// In en, this message translates to:
  /// **'Using four per page'**
  String get cardsUsingFourPerPage;

  /// Choice help when automatic picks two per page.
  ///
  /// In en, this message translates to:
  /// **'Using two per page'**
  String get cardsUsingTwoPerPage;

  /// Choice help for the four-per-page choice.
  ///
  /// In en, this message translates to:
  /// **'Quarter-page cards'**
  String get cardsQuarterPage;

  /// Choice help when four per page does not fit.
  ///
  /// In en, this message translates to:
  /// **'Rows would be under 8 mm'**
  String get cardsRowsUnderEight;

  /// Choice help for the two-per-page choice.
  ///
  /// In en, this message translates to:
  /// **'Half-page cards'**
  String get cardsHalfPage;

  /// Cards message when the range holds no rounds.
  ///
  /// In en, this message translates to:
  /// **'No rounds in range.'**
  String get cardsNoRoundsInRange;

  /// Cards message when the rounds do not fit even a half page.
  ///
  /// In en, this message translates to:
  /// **'This contest has too many rounds for a scoring card. A half-page card holds up to {max} rounds at the minimum 8 mm row height.'**
  String cardsTooManyRoundsMessage(int max);

  /// Cards message when two per page is in force.
  ///
  /// In en, this message translates to:
  /// **'{rounds} rounds on half-page cards. Up to {max} fit.'**
  String cardsRoundsHalfPage(int rounds, int max);

  /// Cards message when four per page fits.
  ///
  /// In en, this message translates to:
  /// **'{rounds} rounds fit four to a page (up to {max} at 8 mm rows).'**
  String cardsRoundsFitFour(int rounds, int max);

  /// Cards message when four per page does not fit.
  ///
  /// In en, this message translates to:
  /// **'{rounds} rounds don’t fit four to a page; using two. Four holds up to {max}.'**
  String cardsRoundsNotFour(int rounds, int max);

  /// Accessible label of a pilot's scoring card.
  ///
  /// In en, this message translates to:
  /// **'Scoring card, {pilot}'**
  String cardsCardSemantics(String pilot);

  /// Caption beside the card's QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan to enter scores'**
  String get cardsScanToEnter;

  /// Accessible label of the card's QR code.
  ///
  /// In en, this message translates to:
  /// **'QR code, scan to enter scores'**
  String get cardsQrLabel;

  /// Accessible label of a printed page of cards.
  ///
  /// In en, this message translates to:
  /// **'Page {page}, {count} {count, plural, =1{card}other{cards}}'**
  String cardsPageLabel(int page, int count);

  /// Help when include retired pilots is on.
  ///
  /// In en, this message translates to:
  /// **'Retired pilots stay in every round, marked (R).'**
  String get sheetIncludeRetiredHelp;

  /// Help when include retired pilots is off.
  ///
  /// In en, this message translates to:
  /// **'{count} retired {count, plural, =1{pilot is}other{pilots are}} left out of the rounds after they retired.'**
  String sheetRetiredLeftOut(int count);

  /// Help when pre-fill is on.
  ///
  /// In en, this message translates to:
  /// **'Prints the scores already entered. * marks values not yet official.'**
  String get sheetPrefillOn;

  /// Help when pre-fill is off.
  ///
  /// In en, this message translates to:
  /// **'Prints the scores already entered, so the sheet can be checked against them.'**
  String get sheetPrefillOff;

  /// Help of the club column option.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Hidden: its width goes to the writing cells.'**
  String get sheetClubHelp;

  /// Label of the validated column option.
  ///
  /// In en, this message translates to:
  /// **'Validated'**
  String get sheetValidated;

  /// Help of the validated column option.
  ///
  /// In en, this message translates to:
  /// **'A blank spot for officials’ initials or notes.'**
  String get sheetValidatedHelp;

  /// Column readout when the columns fit one strip.
  ///
  /// In en, this message translates to:
  /// **'Writing cells {writing} mm of {across} mm across the page'**
  String sheetWritingCells(int writing, int across);

  /// Column readout when the columns continue onto more strips.
  ///
  /// In en, this message translates to:
  /// **'The columns need more than the {across} mm across this page: they continue on {more} more {more, plural, =1{page}other{pages}} for the same rows.'**
  String sheetColumnsContinue(int across, int more);

  /// Mark on a carried-on round or group.
  ///
  /// In en, this message translates to:
  /// **' (Continued)'**
  String get sheetContinued;

  /// Working time on a round row.
  ///
  /// In en, this message translates to:
  /// **'Working Time {time}'**
  String sheetWorkingTime(String time);

  /// Accessible label of a blank sheet table.
  ///
  /// In en, this message translates to:
  /// **'{label}. Score cells are blank for officials to write in.'**
  String sheetTableBlank(String label);

  /// Accessible label of a sheet table with pre-filled scores.
  ///
  /// In en, this message translates to:
  /// **'{label}. Scores already entered are printed in the score cells; the other score cells are blank for officials to write in.'**
  String sheetTablePrefilled(String label);

  /// Key line for a dropped round.
  ///
  /// In en, this message translates to:
  /// **'* = dropped round (shaded)'**
  String get standingsKeyDropped;

  /// Key line for a no-score cell.
  ///
  /// In en, this message translates to:
  /// **'— = no score'**
  String get standingsKeyNoScore;

  /// Key line for a partly scored round.
  ///
  /// In en, this message translates to:
  /// **'R{round} partial: {partial}'**
  String standingsKeyPartial(int round, String partial);

  /// Key line for flight details without height.
  ///
  /// In en, this message translates to:
  /// **'Flight details: time m:ss, landing points; — = not recorded'**
  String get standingsKeyFlightDetails;

  /// Key line for flight details with height.
  ///
  /// In en, this message translates to:
  /// **'Flight details: time m:ss, landing points, launch height; — = not recorded'**
  String get standingsKeyFlightDetailsHeight;

  /// Key line for the percentage column.
  ///
  /// In en, this message translates to:
  /// **'Pct = total as % of the winner'**
  String get standingsKeyPct;

  /// Key line for the raw column.
  ///
  /// In en, this message translates to:
  /// **'Raw = total plus dropped rounds'**
  String get standingsKeyRaw;

  /// Key line for the penalty column.
  ///
  /// In en, this message translates to:
  /// **'Penalty: deducted from the total, not dropped'**
  String get standingsKeyPenalty;

  /// Key line when pilots are tied.
  ///
  /// In en, this message translates to:
  /// **'Tied pilots share a rank'**
  String get standingsKeyTied;

  /// Note that several rounds continue on a later page.
  ///
  /// In en, this message translates to:
  /// **'{text} continue on page {page}'**
  String standingsContinuePage(String text, int page);

  /// Note that one round continues on a later page.
  ///
  /// In en, this message translates to:
  /// **'{text} continues on page {page}'**
  String standingsContinuesPage(String text, int page);

  /// Indicator of the pilots and rounds a page holds.
  ///
  /// In en, this message translates to:
  /// **'Pilots {start} to {end} · {rounds}'**
  String standingsIndicator(int start, int end, String rounds);

  /// Suffix when the page also holds the penalty set.
  ///
  /// In en, this message translates to:
  /// **' + Penalty'**
  String get standingsIndicatorPenalty;

  /// Rounds text when the page holds only the penalty set.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get standingsKeyRoundsPenalty;

  /// Rounds text when the page holds no round set.
  ///
  /// In en, this message translates to:
  /// **'No rounds'**
  String get standingsKeyRoundsNone;

  /// Rounds text for a range of rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds {from} to {to}'**
  String standingsKeyRoundsRange(int from, int to);

  /// Reason naming a round with missing scores.
  ///
  /// In en, this message translates to:
  /// **'round {round} has {count} missing {count, plural, =1{score}other{scores}}'**
  String standingsStatusRoundMissing(int round, int count);

  /// Reason naming further rounds with missing scores.
  ///
  /// In en, this message translates to:
  /// **'{count} more rounds are missing scores'**
  String standingsStatusMoreRounds(int count);

  /// Reason naming pilots with a score in review.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{pilot has}other{pilots have}} a score in review'**
  String standingsStatusReview(int count);

  /// Reason for stale results.
  ///
  /// In en, this message translates to:
  /// **'these results were calculated before the latest change to the scores, the configuration or the matrix.'**
  String get standingsStatusStale;

  /// Reason for scores not yet final.
  ///
  /// In en, this message translates to:
  /// **'some scores are not final yet.'**
  String get standingsStatusNotFinal;

  /// Hint to turn Provisional off.
  ///
  /// In en, this message translates to:
  /// **' Turn off Provisional to print rounds 1 to {round} as Official.'**
  String standingsStatusProvisionalHint(int round);

  /// Action that opens the Scoring page.
  ///
  /// In en, this message translates to:
  /// **'Open Scoring'**
  String get standingsStatusOpenScoring;

  /// Flight-detail label for time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get standingsDetailTime;

  /// Flight-detail label for landing points.
  ///
  /// In en, this message translates to:
  /// **'Landing'**
  String get standingsDetailLanding;

  /// Flight-detail label for launch height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get standingsDetailHeight;

  /// Accessibility label for the contest participants list.
  ///
  /// In en, this message translates to:
  /// **'Contest participants'**
  String get participantsTableLabel;

  /// Accessibility label for the select-all checkbox.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get participantSelectAll;

  /// Accessibility label for a row's checkbox.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String participantSelect(String name);

  /// Marker under a pilot's name when they have scores.
  ///
  /// In en, this message translates to:
  /// **'Has flights'**
  String get participantNameFlights;

  /// Accessibility label for a row's role cell.
  ///
  /// In en, this message translates to:
  /// **'Role for {name}'**
  String participantRoleSemantics(String name);

  /// A non-flying role a pilot with flights cannot take.
  ///
  /// In en, this message translates to:
  /// **'{role} (not available: has flights)'**
  String participantRoleNotAvailable(String role);

  /// Accessibility label for a row's class cell.
  ///
  /// In en, this message translates to:
  /// **'Class for {name}'**
  String participantClassSemantics(String name);

  /// A read-only row with no class.
  ///
  /// In en, this message translates to:
  /// **'No class'**
  String get participantClassNone;

  /// A non-flying row's class, and the hint for a non-scoring row.
  ///
  /// In en, this message translates to:
  /// **'Not scored'**
  String get participantClassNotScored;

  /// Hint in a scoring pilot's class cell.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get participantClassRequired;

  /// Accessibility label for a row's team cell.
  ///
  /// In en, this message translates to:
  /// **'Team for {name}'**
  String participantTeamSemantics(String name);

  /// A read-only row with no team, and the picker's clear choice.
  ///
  /// In en, this message translates to:
  /// **'No team'**
  String get participantTeamNone;

  /// Row status for a non-flying participant.
  ///
  /// In en, this message translates to:
  /// **'Non-flying'**
  String get participantStatusNonFlying;

  /// Row status naming what a row still needs.
  ///
  /// In en, this message translates to:
  /// **'Needs {issues}'**
  String participantNeeds(String issues);

  /// Row status for a ready participant.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get participantReady;

  /// Header and card label for the pilot number column.
  ///
  /// In en, this message translates to:
  /// **'Pilot no.'**
  String get participantColumnPilotNo;

  /// Header and card label for the role column.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get participantColumnRole;

  /// Header and card label for the class column.
  ///
  /// In en, this message translates to:
  /// **'Class *'**
  String get participantColumnClass;

  /// Header and card label for the team column.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get participantColumnTeam;

  /// Header and card label for the models column.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get participantColumnModels;

  /// Header for the status column.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get participantColumnStatus;

  /// Header for the email column.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get participantColumnEmail;

  /// Header for the name column.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get participantColumnName;

  /// A bulk menu with no choices yet.
  ///
  /// In en, this message translates to:
  /// **'Nothing entered yet'**
  String get participantBulkNothing;

  /// Why Remove is off for the selection.
  ///
  /// In en, this message translates to:
  /// **'The selection contains a pilot with flights.'**
  String get participantBulkSelectionHasFlights;

  /// Asking before leaving the participants page with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Leave with unsaved changes?'**
  String get participantLeaveTitle;

  /// Body of the leave-with-unsaved-changes question.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to {count} participant{plural}. {action} discards them.'**
  String participantLeaveBody(int count, String plural, String action);

  /// The leaving action when the app is closing.
  ///
  /// In en, this message translates to:
  /// **'Closing the app'**
  String get participantLeaveClosing;

  /// The leaving action when leaving the page.
  ///
  /// In en, this message translates to:
  /// **'Leaving'**
  String get participantLeaveLeaving;

  /// Keep editing in the leave-with-unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get participantStay;

  /// Discard and leave in the leave-with-unsaved-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard and leave'**
  String get participantDiscardAndLeave;

  /// Fallback contest name when it is not known.
  ///
  /// In en, this message translates to:
  /// **'this contest'**
  String get participantThisContest;

  /// Page state when there is no API client.
  ///
  /// In en, this message translates to:
  /// **'No API client is available.'**
  String get participantNoApi;

  /// Title of the failed-load view.
  ///
  /// In en, this message translates to:
  /// **'The participants could not be loaded.'**
  String get participantLoadFailed;

  /// Loading label for the participants page.
  ///
  /// In en, this message translates to:
  /// **'Loading the participants'**
  String get participantLoading;

  /// How many people are on a team, in the team picker.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 participant} other{{count} participants}}'**
  String teamCount(int count);

  /// Note when a typed team matches an existing one only by case.
  ///
  /// In en, this message translates to:
  /// **' · existing team, case ignored'**
  String get teamCaseIgnored;

  /// Picker choice for a new team.
  ///
  /// In en, this message translates to:
  /// **'Create team “{name}”'**
  String teamCreate(String name);

  /// Subtitle under the create-team choice.
  ///
  /// In en, this message translates to:
  /// **'New team'**
  String get teamNew;

  /// Subtitle under the no-team choice.
  ///
  /// In en, this message translates to:
  /// **'Clear the name. The pilot stays unassigned.'**
  String get teamClearSubtitle;

  /// Hint in an empty team cell.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get teamUnassigned;

  /// Hint in the participant search field.
  ///
  /// In en, this message translates to:
  /// **'Enter a name or email to search or filter'**
  String get searchHint;

  /// Tooltip for the clear-search button.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// Search source line when online with a remote directory.
  ///
  /// In en, this message translates to:
  /// **'Online: searching remote first, then your profiles'**
  String get searchOnline;

  /// Search source line when offline.
  ///
  /// In en, this message translates to:
  /// **'Offline: searching your profiles only'**
  String get searchOffline;

  /// Search source line when there is no remote directory.
  ///
  /// In en, this message translates to:
  /// **'Searching your participant profiles'**
  String get searchProfiles;

  /// Header of the search results when remote is available.
  ///
  /// In en, this message translates to:
  /// **'Add from remote and your profiles'**
  String get searchHeaderRemote;

  /// Header of the search results from saved profiles.
  ///
  /// In en, this message translates to:
  /// **'Add from saved profiles'**
  String get searchHeaderProfiles;

  /// Shown while the director's profiles load.
  ///
  /// In en, this message translates to:
  /// **'Loading people…'**
  String get searchLoading;

  /// A search result with no club.
  ///
  /// In en, this message translates to:
  /// **'No club'**
  String get searchNoClub;

  /// A result's email status, in the subtitle.
  ///
  /// In en, this message translates to:
  /// **'Email: {status}'**
  String searchEmailPrefix(String status);

  /// A search result that is already in the contest.
  ///
  /// In en, this message translates to:
  /// **'Already in this contest'**
  String get searchAlready;

  /// A result found in the remote directory.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get searchRemote;

  /// A result from the director's own profiles.
  ///
  /// In en, this message translates to:
  /// **'Your profiles'**
  String get searchYourProfiles;

  /// Cancel button in the participant editor action bar.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get participantEditorCancel;

  /// Button that saves the profile and keeps the editor open for the next one.
  ///
  /// In en, this message translates to:
  /// **'Save and add another'**
  String get participantEditorSaveAnother;

  /// Status text in the editor action bar while a save runs.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get participantEditorSaving;

  /// Status text in the editor action bar for a dirty edit.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get participantEditorUnsaved;

  /// Status text in the editor action bar while a duplicate decision is open.
  ///
  /// In en, this message translates to:
  /// **'Choose an option above to continue.'**
  String get participantEditorChooseOption;

  /// Status text in the editor action bar while a stale-revision conflict is open.
  ///
  /// In en, this message translates to:
  /// **'Resolve the conflict above to save.'**
  String get participantEditorResolveConflict;

  /// Save button in the participant editor when editing a stored profile.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get participantEditorSaveChanges;

  /// Save button in the participant editor opened from the New Contest wizard.
  ///
  /// In en, this message translates to:
  /// **'Add to contest'**
  String get participantEditorAddToContest;

  /// Header title and save label when creating a new participant.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get participantEditorAddTitle;

  /// Header subtitle of an edit whose profile has no club.
  ///
  /// In en, this message translates to:
  /// **'No club'**
  String get participantEditorNoClub;

  /// Header subtitle when creating a new participant.
  ///
  /// In en, this message translates to:
  /// **'Details are reused in every contest you add them to.'**
  String get participantEditorReuseDetails;

  /// Checkbox that keeps club and location for the next profile.
  ///
  /// In en, this message translates to:
  /// **'Keep club and location for the next participant'**
  String get participantEditorKeepClubLocation;

  /// Explanation under the keep-club-and-location checkbox.
  ///
  /// In en, this message translates to:
  /// **'Used by Save and add another, so a row of pilots from one club needs them once.'**
  String get participantEditorKeepClubLocationSub;

  /// Title of the failed-load view in the participant editor.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load this participant'**
  String get participantEditorLoadFailedTitle;

  /// Failed-load action when the editor was opened from the New Contest wizard.
  ///
  /// In en, this message translates to:
  /// **'Back to contest setup'**
  String get participantEditorBackToWizard;

  /// Title of the save-failed banner in the participant editor.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save'**
  String get participantEditorSaveFailedTitle;

  /// Action on the save-failed banner that retries the save.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get participantEditorSaveFailedTry;

  /// Note under the save-failed banner explaining the entries are safe.
  ///
  /// In en, this message translates to:
  /// **'Nothing was saved and your entries are kept, so it’s safe to try again.'**
  String get participantEditorSaveFailedKept;

  /// Snack bar after Save and add another.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String participantEditorAddedSnack(String name);

  /// Title of the discard dialog when leaving the editor.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get participantEditorDiscardTitle;

  /// Discard-dialog text when the app is closing.
  ///
  /// In en, this message translates to:
  /// **'Closing the app will lose your unsaved changes to this participant.'**
  String get participantEditorDiscardClosing;

  /// Discard-dialog text when leaving the page.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get participantEditorDiscardBody;

  /// Cancel action in the discard dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get participantEditorKeepEditing;

  /// Discard action in the dialog when the app is closing.
  ///
  /// In en, this message translates to:
  /// **'Close and discard'**
  String get participantEditorDiscardAndClose;

  /// Discard action in the discard dialog when leaving the page.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get participantEditorDiscard;

  /// Title of the stale-revision banner.
  ///
  /// In en, this message translates to:
  /// **'This participant was changed elsewhere since you opened it.'**
  String get participantEditorStaleTitle;

  /// Body of the stale-revision banner naming the changed fields.
  ///
  /// In en, this message translates to:
  /// **'{fields} {verb} changed elsewhere. Nothing was saved, and your edits are kept.'**
  String participantEditorStaleBody(String fields, String verb);

  /// Verb for one changed field in the stale banner.
  ///
  /// In en, this message translates to:
  /// **'was'**
  String get participantEditorWas;

  /// Verb for several changed fields in the stale banner.
  ///
  /// In en, this message translates to:
  /// **'were'**
  String get participantEditorWere;

  /// Stale banner action that reloads the stored version.
  ///
  /// In en, this message translates to:
  /// **'Reload their version'**
  String get participantEditorReloadLatest;

  /// Stale banner action that opens the field-by-field review.
  ///
  /// In en, this message translates to:
  /// **'Review differences'**
  String get participantEditorReviewStart;

  /// Banner after values were kept from a previous profile.
  ///
  /// In en, this message translates to:
  /// **'Club and location kept from {name}.'**
  String participantEditorKeptTitle(String name);

  /// Action on the kept-values banner that clears them.
  ///
  /// In en, this message translates to:
  /// **'Clear them'**
  String get participantEditorClearKept;

  /// Semantics label of the editor loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading participant'**
  String get participantEditorLoading;

  /// Text in the editor loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading participant…'**
  String get participantEditorLoadingText;

  /// Label of the country field.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get participantEditorCountry;

  /// Lead line of the duplicate-email decision panel.
  ///
  /// In en, this message translates to:
  /// **'Decision needed. Nothing has been saved.'**
  String get participantEditorDuplicateLead;

  /// Title of the duplicate-email decision panel.
  ///
  /// In en, this message translates to:
  /// **'Someone with this email already exists'**
  String get participantEditorDuplicateTitle;

  /// Instruction under the duplicate-email title.
  ///
  /// In en, this message translates to:
  /// **'Compare the two and choose. Matching ignores upper and lower case.'**
  String get participantEditorDuplicateCompare;

  /// Heading of the existing-profile tile.
  ///
  /// In en, this message translates to:
  /// **'Existing participant'**
  String get participantEditorDuplicateExisting;

  /// Heading of the typed-values tile.
  ///
  /// In en, this message translates to:
  /// **'What you entered'**
  String get participantEditorDuplicateEntered;

  /// Button that uses the existing profile.
  ///
  /// In en, this message translates to:
  /// **'Use existing participant'**
  String get participantEditorUseExisting;

  /// Note under Use existing when opened from the wizard.
  ///
  /// In en, this message translates to:
  /// **'Adds {name} to this contest. Nothing new is created and what you typed here isn’t saved.'**
  String participantEditorDuplicateAdds(String name);

  /// Note under Use existing when opened from the list.
  ///
  /// In en, this message translates to:
  /// **'Opens {name}. Nothing new is created and what you typed here isn’t saved.'**
  String participantEditorDuplicateOpens(String name);

  /// Button that returns to the form to change the email.
  ///
  /// In en, this message translates to:
  /// **'Change the email'**
  String get participantEditorChangeEmail;

  /// Note under Change the email.
  ///
  /// In en, this message translates to:
  /// **'Two participants cannot share an email. Go back and enter a different one for {name}.'**
  String participantEditorDuplicateNote(String name);

  /// Fallback name when the typed name is empty.
  ///
  /// In en, this message translates to:
  /// **'this person'**
  String get participantEditorThisPerson;

  /// Semantics label for a masked email.
  ///
  /// In en, this message translates to:
  /// **'Email hidden, starts with {letter}'**
  String participantEditorEmailPrefix(String letter);

  /// Tile name when it is empty.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get participantEditorNoName;

  /// Tile place when it is empty.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get participantEditorNoLocation;

  /// Title of the field-by-field review panel.
  ///
  /// In en, this message translates to:
  /// **'Review differences'**
  String get participantEditorReviewTitle;

  /// Instruction under the review panel title.
  ///
  /// In en, this message translates to:
  /// **'Choose the value to keep for each field that differs. Fields you changed start on your version; fields only they changed start on theirs.'**
  String get participantEditorReviewBody;

  /// Review action that reloads the stored version.
  ///
  /// In en, this message translates to:
  /// **'Reload their version'**
  String get participantEditorReviewReload;

  /// Review action that saves the chosen values.
  ///
  /// In en, this message translates to:
  /// **'Save with these choices'**
  String get participantEditorReviewApply;

  /// Heading of the own-value choice in the review.
  ///
  /// In en, this message translates to:
  /// **'Your version'**
  String get participantEditorReviewYourVersion;

  /// Heading of the stored-value choice in the review.
  ///
  /// In en, this message translates to:
  /// **'Their version'**
  String get participantEditorReviewTheirVersion;

  /// Shown for an empty value in the review.
  ///
  /// In en, this message translates to:
  /// **'(blank)'**
  String get participantEditorReviewBlank;

  /// Semantics label of the storage chip naming where a participant lives.
  ///
  /// In en, this message translates to:
  /// **'Storage: {storage}'**
  String participantEditorStorage(String storage);
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
