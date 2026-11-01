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

  /// Disabled button on the Recent activity card that will open the full activity log.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get activityViewAll;

  /// Note under the Recent activity list explaining the disabled View all button.
  ///
  /// In en, this message translates to:
  /// **'The full activity log is not available yet.'**
  String get activityViewAllUnavailable;

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
