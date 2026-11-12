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

  /// Body of the confirmation before QR codes are created. Issuing never emails.
  ///
  /// In en, this message translates to:
  /// **'QR codes will be created for these pilots, and each of these cards will carry one. Nobody is emailed: print the cards to hand them out.'**
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
  /// **'The cards now carry them. Nothing was emailed.'**
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
  /// **'{have} of {total, plural, =1{1 pilot has} other{{total} pilots have}} a QR code. Sending creates the rest. Nobody is emailed.'**
  String invitationsCoverage(int have, int total);

  /// Workspace invitations card text when every pilot has an invitation.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{The pilot has} other{All {total} pilots have}} a QR code. Print the pilot cards to hand them out.'**
  String invitationsCoverageAll(int total);

  /// Button on the workspace invitations card that opens the pilot cards report.
  ///
  /// In en, this message translates to:
  /// **'Open pilot cards'**
  String get invitationsOpenCards;

  /// Workspace button that sends invitations to the pilots who have none.
  ///
  /// In en, this message translates to:
  /// **'Send invitations ({count})'**
  String invitationsSendMissing(int count);

  /// Snack bar after invitations were created.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invitation created} other{{count} invitations created}}. Nobody was emailed.'**
  String invitationsSentSnack(int count);

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

  /// Participants invitations menu item that creates invitations for the selected pilots.
  ///
  /// In en, this message translates to:
  /// **'Send invitations'**
  String get invitationsMenuSend;

  /// Participants invitations menu item with the number of selected pilots that have none.
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

  /// Reason sending is off: every selected pilot has an invitation.
  ///
  /// In en, this message translates to:
  /// **'The selected pilots already have an invitation.'**
  String get invitationsAllHaveLinks;

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

  /// Reason Send invitation is off in a participant row menu: the pilot already has one.
  ///
  /// In en, this message translates to:
  /// **'This pilot already has an invitation.'**
  String get participantInvitationExists;

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

  /// Chip on a score row whose values a pilot or helper submitted and the director has not saved yet.
  ///
  /// In en, this message translates to:
  /// **'Pilot entry'**
  String get scorePilotEntryChip;

  /// Tooltip of the Pilot entry chip.
  ///
  /// In en, this message translates to:
  /// **'A pilot or helper submitted values. The submission is kept in history.'**
  String get scorePilotEntryTooltip;
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
