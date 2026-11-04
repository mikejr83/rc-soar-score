// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appearanceHeading => 'Appearance';

  @override
  String get appearanceDescription =>
      'Choose a light or dark look, or follow your device. This is saved on this device for your account and is not shared with other devices.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSaveFailed =>
      'The theme could not be saved. It applies until you close the app.';

  @override
  String get textSizeHeading => 'Text size';

  @override
  String get textSizeDescription =>
      'Make text larger on this device. This is saved for your account and is not shared with other devices. Your device\'s own text size setting still applies on top.';

  @override
  String get textSizeDefault => 'Default';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get textSizePreview => 'Sample: Round 3, Group B, Pilot 12';

  @override
  String get textSizeSaveFailed =>
      'The text size could not be saved. It applies until you close the app.';

  @override
  String get panelsHeading => 'Panels';

  @override
  String get panelsDescription =>
      'Panels you hide or minimize, such as the matrix summary, stay that way on this device for your account, in every contest.';

  @override
  String get panelsResetButton => 'Reset panels to defaults';

  @override
  String get panelsResetDone => 'Panels are back to their defaults.';

  @override
  String get panelsResetSaveFailed =>
      'The reset could not be saved. It applies until you close the app.';

  @override
  String get reportOptionsHeading => 'Report options';

  @override
  String get reportOptionsDescription =>
      'Report options are remembered each time you change them. You can reset them all to the default.';

  @override
  String get reportOptionsResetButton => 'Reset report options';

  @override
  String get reportOptionsResetDone =>
      'Report options are back to their defaults.';

  @override
  String get reportOptionsResetSaveFailed => 'The reset could not be saved.';

  @override
  String get timeZoneHeading => 'Time zone';

  @override
  String get timeZoneDescription =>
      'Times shown to you in the app, such as when something was last saved or synced, use this time zone. Times pilots see always use the contest\'s own time zone. This follows your account.';

  @override
  String get timeZoneDeviceButton => 'Use this device\'s time zone';

  @override
  String get timeZoneFollowsDevice => 'Following this device.';

  @override
  String get timeZoneSaveFailed =>
      'The time zone could not be saved. It applies until you close the app.';

  @override
  String get localeHeading => 'Language and formats';

  @override
  String get localeDescription =>
      'Sets the language and how dates and numbers are written for you. This follows your account.';

  @override
  String get localeLabel => 'Language and format';

  @override
  String get localeDevice => 'Use this device\'s language';

  @override
  String get localeEnUs => 'English (United States)';

  @override
  String get localeSaveFailed =>
      'The language could not be saved. It applies until you close the app.';

  @override
  String get preferencesNeedSignIn =>
      'Sign in to keep this on your account. It applies until you close the app.';

  @override
  String get fileOperationRetryHint => 'Choose another place and try again.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get exportContestButton => 'Export…';

  @override
  String exportDialogTitle(String name) {
    return 'Export $name';
  }

  @override
  String get exportDialogDescription =>
      'Saves the whole contest to a .rcsoar file, for support or as a backup. Nothing is sent anywhere.';

  @override
  String get exportRedactionTitle => 'Remove email addresses';

  @override
  String get exportRedactionSubtitle =>
      'Turn this off for a full backup. Names, clubs and scores are kept either way.';

  @override
  String get exportNotice =>
      'The file is not encrypted. Anyone who has it can read the contest. Send it only to people you trust.';

  @override
  String get exportSaveButton => 'Save file…';

  @override
  String exportSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get exportFailed => 'The contest could not be exported.';

  @override
  String exportFailedWithReason(String reason) {
    return 'The contest could not be exported. $reason';
  }

  @override
  String exportFileSaveFailed(String reason) {
    return 'The contest could not be saved to a file. $reason';
  }

  @override
  String get importButton => 'Import contest…';

  @override
  String importOpenFailed(String reason) {
    return 'The file could not be opened. $reason';
  }

  @override
  String importFileRefused(String name, String reason) {
    return '$name cannot be imported. $reason';
  }

  @override
  String importFailed(String reason) {
    return 'The contest was not imported. $reason';
  }

  @override
  String importDialogTitle(String name) {
    return 'Import $name';
  }

  @override
  String get importConfirmButton => 'Import';

  @override
  String importPreviewRedactedFromSource(
    String exportedAt,
    String source,
    num participants,
    num rounds,
    num scores,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      participants,
      locale: localeName,
      other: '$participants participants',
      one: '1 participant',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    String _temp2 = intl.Intl.pluralLogic(
      scores,
      locale: localeName,
      other: '$scores scores',
      one: '1 score',
    );
    return 'Exported $exportedAt from $source. $_temp0, $_temp1, $_temp2. Email addresses were removed.';
  }

  @override
  String importPreviewRedacted(
    String exportedAt,
    num participants,
    num rounds,
    num scores,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      participants,
      locale: localeName,
      other: '$participants participants',
      one: '1 participant',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    String _temp2 = intl.Intl.pluralLogic(
      scores,
      locale: localeName,
      other: '$scores scores',
      one: '1 score',
    );
    return 'Exported $exportedAt. $_temp0, $_temp1, $_temp2. Email addresses were removed.';
  }

  @override
  String importPreviewIncludedFromSource(
    String exportedAt,
    String source,
    num participants,
    num rounds,
    num scores,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      participants,
      locale: localeName,
      other: '$participants participants',
      one: '1 participant',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    String _temp2 = intl.Intl.pluralLogic(
      scores,
      locale: localeName,
      other: '$scores scores',
      one: '1 score',
    );
    return 'Exported $exportedAt from $source. $_temp0, $_temp1, $_temp2. Email addresses are included.';
  }

  @override
  String importPreviewIncluded(
    String exportedAt,
    num participants,
    num rounds,
    num scores,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      participants,
      locale: localeName,
      other: '$participants participants',
      one: '1 participant',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    String _temp2 = intl.Intl.pluralLogic(
      scores,
      locale: localeName,
      other: '$scores scores',
      one: '1 score',
    );
    return 'Exported $exportedAt. $_temp0, $_temp1, $_temp2. Email addresses are included.';
  }

  @override
  String get importModeInspectionTitle => 'Open as a local copy for inspection';

  @override
  String get importModeInspectionNotice =>
      'Kept on this computer only. Nothing you do with it is sent to the service, whoever is signed in.';

  @override
  String get importModeEditableTitle => 'Import as an editable copy';

  @override
  String get importModeEditableNotice =>
      'Owned by the account in use, like a contest made here. The original installation may still run the contest until it is moved here, and sync can be refused until then.';

  @override
  String get importDoneInspection =>
      'Imported as a local copy. It is not synced.';

  @override
  String get importDoneEditable => 'Imported as an editable copy.';

  @override
  String get inspectionChipLabel => 'Imported copy, not synced';

  @override
  String get inspectionNotice =>
      'This contest was imported for inspection. It stays on this computer: nothing in it is sent to the service, whoever is signed in.';

  @override
  String get shellRoundLabel => 'Round';

  @override
  String shellRoundValue(int round, int total) {
    return '$round of $total';
  }

  @override
  String shellRoundGroupValue(int round, int total, String group) {
    return '$round of $total, group $group';
  }

  @override
  String get shellRoundNotStarted => 'Not started';

  @override
  String get shellRoundFinished => 'Finished';

  @override
  String shellRoundSemantics(String label, String value) {
    return '$label: $value. Go to scoring';
  }

  @override
  String get alphaNoticeTitle => 'Alpha release';

  @override
  String get alphaNoticeIntro =>
      'RC Soar Score is an early release. Please read this before you continue.';

  @override
  String get alphaNoticeStorage =>
      'Contest directors should not expect this application to store contest data for the long term. The next release may require the database to be reset.';

  @override
  String get alphaNoticeScoring =>
      'The scoring system should be correct, but manual checks should be performed.';

  @override
  String get alphaNoticeMissing =>
      'Major functionality such as pilot self-scoring and contest results sharing has not been completed.';

  @override
  String get alphaNoticePrimary =>
      'The software is still in an early release and should not be your primary method for tracking a contest and scoring.';

  @override
  String get alphaNoticeAcknowledge =>
      'I understand this, and I will not hold the application developers responsible.';

  @override
  String get alphaNoticeContinue => 'Continue';

  @override
  String get storageIndicatorName => 'Local storage';

  @override
  String get storageStatusAvailable => 'Available';

  @override
  String get storageStatusChecking => 'Checking';

  @override
  String get storageStatusUnavailable => 'Unavailable';

  @override
  String storageIndicatorTooltip(String name, String status) {
    return '$name: $status';
  }

  @override
  String storageDetailStatus(String status) {
    return 'Status: $status';
  }

  @override
  String storageDetailLastObserved(String time) {
    return 'Last observed: $time';
  }

  @override
  String get storageNeverObserved => 'Never';

  @override
  String get storageDetailNote =>
      'Where this device keeps contests and scores. When it is unavailable, changes cannot be saved.';

  @override
  String storageDetailError(String error) {
    return 'Error: $error';
  }

  @override
  String get storageRetry => 'Retry now';

  @override
  String get storageDetailClose => 'OK';

  @override
  String get unsyncedWarningTitle => 'Changes have not synced';

  @override
  String unsyncedWarningBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes have',
      one: '1 change has',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'they',
      one: 'it',
    );
    return '$_temp0 not been sent to the service. If you continue, $_temp1 cannot be recovered.';
  }

  @override
  String get unsyncedWarningContinue => 'Continue anyway';

  @override
  String get unsyncedWarningCancel => 'Cancel';

  @override
  String drawProgress(int percent, int seed, int seedCount) {
    return 'Drawing the matrix: $percent% (seed $seed of $seedCount)';
  }

  @override
  String get drawProgressStarting => 'Starting the draw…';

  @override
  String get drawRunningNote =>
      'You can cancel the draw. Nothing changes until it finishes.';

  @override
  String get drawCancelButton => 'Cancel draw';

  @override
  String get drawCancelling => 'Cancelling…';

  @override
  String get drawCancelled => 'Draw cancelled. Nothing was changed.';

  @override
  String get drawCancelFailed =>
      'Cancel could not reach the server. The draw is still running. Try Cancel again.';

  @override
  String get matrixAddRoundsButton => 'Add rounds';

  @override
  String get matrixRedrawButton => 'Redraw unscored rounds';

  @override
  String get matrixActionLocked =>
      'Administration is locked. Unlock the contest to add or redraw rounds.';

  @override
  String get matrixActionNotEditable =>
      'Rounds can be added or redrawn from the first draw until the contest is complete.';

  @override
  String get matrixRedrawAllScored =>
      'Every round has scores, so there is nothing to redraw.';

  @override
  String matrixRedrawRoundLocked(int round) {
    return 'Round $round is locked. Unlock it before redrawing.';
  }

  @override
  String matrixRedrawGroupLocked(int round) {
    return 'A group of round $round is locked. Unlock it before redrawing.';
  }

  @override
  String get matrixAddTitle => 'Add rounds';

  @override
  String matrixAddIntro(int last) {
    return 'The new rounds continue after round $last. Pilots who already met are kept apart as in the first draw, and the fairness summary counts every round. Retired pilots are not drawn.';
  }

  @override
  String get matrixRedrawTitle => 'Redraw unscored rounds';

  @override
  String matrixRedrawIntro(String span) {
    return 'Replaces the unscored $span. Earlier rounds stay as they are and count toward who has met whom. Retired pilots are not drawn. Each redraw uses a new random seed unless you set one under Advanced.';
  }

  @override
  String get matrixRoundsToAdd => 'Rounds to add';

  @override
  String get matrixRoundsToDraw => 'Rounds to draw';

  @override
  String matrixAddRoundsNote(String span) {
    return 'Draws $span.';
  }

  @override
  String matrixRedrawRoundsNote(String span) {
    return 'Draws $span in place of the unscored rounds.';
  }

  @override
  String matrixRedrawRoundsRemoved(String span, String removed) {
    return 'Draws $span. $removed will be removed.';
  }

  @override
  String matrixGroupsFromRound(int round) {
    return 'From round $round of the current matrix.';
  }

  @override
  String get matrixReasonLabel => 'Reason (optional)';

  @override
  String get matrixReasonHint => 'Kept in the matrix history';

  @override
  String get matrixBackToMatrix => 'Back to matrix';

  @override
  String get matrixAddAction => 'Add rounds';

  @override
  String get matrixAddActionBusy => 'Adding rounds…';

  @override
  String get matrixRedrawAction => 'Redraw rounds';

  @override
  String get matrixRedrawActionBusy => 'Redrawing rounds…';

  @override
  String get matrixAddConfirmTitle => 'Add rounds?';

  @override
  String get matrixRedrawConfirmTitle => 'Redraw unscored rounds?';

  @override
  String matrixConfirmAdds(String span) {
    return 'Adds $span';
  }

  @override
  String matrixConfirmReplaces(String span) {
    return 'Redraws $span';
  }

  @override
  String matrixConfirmRevision(int revision) {
    return 'Current matrix revision $revision';
  }

  @override
  String get matrixConfirmAddNote =>
      'Rounds can be added again later. The new rounds can be redrawn until they have scores.';

  @override
  String get matrixConfirmRedrawNote =>
      'The replaced rounds can’t be restored. Rounds with scores are not touched.';

  @override
  String get matrixRoundsAdded => 'Rounds added.';

  @override
  String get matrixRoundsRedrawn => 'Rounds redrawn.';

  @override
  String get matrixRoundsNetworkFailure =>
      'The matrix wasn’t changed and the page hasn’t changed. Your values are kept.';

  @override
  String get matrixRoundsRejected => 'The server did not change the matrix';

  @override
  String get matrixRoundsConflict =>
      'The matrix changed on the server. Reload to see the current state. Your values stay until you reload.';

  @override
  String matrixSeededStatusDone(int rounds) {
    return 'Seeded Man on Man: $rounds preliminary rounds, all scored. A seeded round also needs official scores and current standings; the server checks this when you draw.';
  }

  @override
  String matrixSeededStatusWaiting(int rounds, int missing) {
    return 'Seeded Man on Man: $rounds preliminary rounds, $missing flights still need a score. A seeded round can be drawn once they are official.';
  }

  @override
  String get matrixSeededOneRound => 'Seeded rounds are drawn one at a time.';

  @override
  String matrixDriftBanner(String differences) {
    return '$differences The matrix is unchanged. Redraw the unscored rounds to apply these changes; rounds with scores keep their draw.';
  }

  @override
  String matrixDriftBannerBlocked(String differences, String reason) {
    return '$differences The matrix is unchanged. $reason';
  }

  @override
  String matrixRoundSpan(int count, int first, int last) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rounds $first to $last',
      one: 'round $first',
    );
    return '$_temp0';
  }

  @override
  String matrixConfirmPilots(int count) {
    return '$count scoring pilots';
  }

  @override
  String matrixConfirmGroups(int groups, String sizes) {
    return '$groups groups per round ($sizes pilots)';
  }

  @override
  String matrixConfirmConfiguration(String revision) {
    return 'Configuration revision $revision';
  }

  @override
  String get matrixConfirmCancel => 'Cancel';

  @override
  String get participantEmailHas => 'Has email';

  @override
  String get participantEmailHasExplanation => 'Email on the profile';

  @override
  String get participantEmailNone => 'None';

  @override
  String get participantEmailNoneExplanation => 'No email on the profile';

  @override
  String get participantEmailPrivate => 'Private';

  @override
  String get participantEmailPrivateExplanation =>
      'This person hasn’t allowed their email to be shown.';

  @override
  String get activityHeading => 'Recent activity';

  @override
  String get activityViewAll => 'View all';

  @override
  String get activityViewAllUnavailable =>
      'The full activity log is not available yet.';

  @override
  String get activityEmpty => 'Nothing has happened yet';

  @override
  String get activityLoading => 'Loading recent activity…';

  @override
  String get activityFailed => 'Recent activity could not be loaded.';

  @override
  String get activityRetry => 'Retry';

  @override
  String activityComplete(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You completed the contest. Participant scoring closed.',
      'other': 'The contest was completed. Participant scoring closed.',
    });
    return '$_temp0';
  }

  @override
  String activityOpenScoring(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You opened participant scoring',
      'other': 'Participant scoring was opened',
    });
    return '$_temp0';
  }

  @override
  String activityCloseScoring(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You closed participant scoring',
      'other': 'Participant scoring was closed',
    });
    return '$_temp0';
  }

  @override
  String activityLock(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You locked administration',
      'other': 'Administration was locked',
    });
    return '$_temp0';
  }

  @override
  String activityUnlock(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You unlocked administration',
      'other': 'Administration was unlocked',
    });
    return '$_temp0';
  }

  @override
  String activityPublication(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You updated the published results',
      'other': 'The published results were updated',
    });
    return '$_temp0';
  }

  @override
  String activityConfigurationSaved(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You saved the contest configuration',
      'other': 'The contest configuration was saved',
    });
    return '$_temp0';
  }

  @override
  String activityMatrixDrawn(String actor) {
    String _temp0 = intl.Intl.selectLogic(actor, {
      'you': 'You drew the matrix',
      'other': 'The matrix was drawn',
    });
    return '$_temp0';
  }

  @override
  String activityScoreCorrected(String actor, String pilot, int round) {
    String _temp0 = intl.Intl.selectLogic(pilot, {
      'none': 'a pilot',
      'other': 'pilot $pilot',
    });
    String _temp1 = intl.Intl.selectLogic(pilot, {
      'none': 'a pilot',
      'other': 'pilot $pilot',
    });
    String _temp2 = intl.Intl.selectLogic(actor, {
      'you': 'You corrected a score for $_temp0 in round $round',
      'other': 'A score was corrected for $_temp1 in round $round',
    });
    return '$_temp2';
  }

  @override
  String activityPilotRetired(String actor, String pilot, int round) {
    String _temp0 = intl.Intl.selectLogic(pilot, {
      'none': 'a pilot',
      'other': 'pilot $pilot',
    });
    String _temp1 = intl.Intl.selectLogic(pilot, {
      'none': 'A pilot',
      'other': 'Pilot $pilot',
    });
    String _temp2 = intl.Intl.selectLogic(actor, {
      'you': 'You retired $_temp0 from round $round',
      'other': '$_temp1 was retired from round $round',
    });
    return '$_temp2';
  }

  @override
  String activityPilotReinstated(String actor, String pilot) {
    String _temp0 = intl.Intl.selectLogic(pilot, {
      'none': 'a pilot',
      'other': 'pilot $pilot',
    });
    String _temp1 = intl.Intl.selectLogic(pilot, {
      'none': 'A pilot',
      'other': 'Pilot $pilot',
    });
    String _temp2 = intl.Intl.selectLogic(actor, {
      'you': 'You reinstated $_temp0',
      'other': '$_temp1 was reinstated',
    });
    return '$_temp2';
  }

  @override
  String get shellNavContests => 'Contests';

  @override
  String get shellNavParticipants => 'Participants';

  @override
  String get shellNavRoles => 'Roles';

  @override
  String get shellNavLandings => 'Landings';

  @override
  String get shellNavWorkspace => 'Workspace';

  @override
  String get shellNavConfiguration => 'Configuration';

  @override
  String get shellNavMatrix => 'Matrix';

  @override
  String get shellNavScoring => 'Scoring';

  @override
  String get shellNavReports => 'Reports';

  @override
  String get shellNavSync => 'Sync';

  @override
  String get shellNavSettings => 'Settings';

  @override
  String get shellAddParticipant => 'Add participant';

  @override
  String get shellNewLanding => 'New landing';

  @override
  String get shellNewRole => 'New role';

  @override
  String get createContestLabel => 'Create contest';

  @override
  String get continueConfigurationLabel => 'Continue configuration';

  @override
  String get shellCollapseNav => 'Collapse navigation';

  @override
  String get shellExpandNav => 'Expand navigation';

  @override
  String get shellCrumbNew => 'New';

  @override
  String get shellCrumbEdit => 'Edit';

  @override
  String get shellCrumbNewContest => 'New contest';

  @override
  String get shellContestFallback => 'Contest';

  @override
  String get shellAccountSettingsAndSignIn => 'Settings and sign in';

  @override
  String get shellSignIn => 'Sign in';

  @override
  String get shellSignOut => 'Sign out';

  @override
  String get shellSignedIn => 'Signed in';

  @override
  String shellAccountTooltip(String name) {
    return 'Account: $name';
  }

  @override
  String get shellAccountMenu => 'Account menu';

  @override
  String get shellNotBuiltDetail =>
      'This page has not been built yet. Please check back soon.';

  @override
  String get shellStatusPanelLabel => 'Contest status';

  @override
  String get shellStatusLifecycle => 'Status';

  @override
  String get shellStatusScoring => 'Participant scoring';

  @override
  String get shellStatusAdministration => 'Administration';

  @override
  String get shellScoringOpen => 'Open';

  @override
  String get shellScoringClosed => 'Closed';

  @override
  String get shellAdminLocked => 'Locked';

  @override
  String get shellAdminUnlocked => 'Unlocked';

  @override
  String shellStatusSemantics(String label, String value, String target) {
    String _temp0 = intl.Intl.selectLogic(target, {
      'lifecycle': 'Go to the status control',
      'scoring': 'Go to the participant scoring control',
      'administration': 'Go to the administration control',
      'other': 'Go to the control',
    });
    return '$label: $value. $_temp0';
  }

  @override
  String get lifecycleCreated => 'Created';

  @override
  String get lifecycleConfiguring => 'Configuring';

  @override
  String get lifecycleReady => 'Ready';

  @override
  String get lifecycleRunning => 'Running';

  @override
  String get lifecycleCompleted => 'Completed';

  @override
  String windowTitleContest(String app, String contest) {
    return '$app: $contest';
  }

  @override
  String get contestListHeading => 'Contests';

  @override
  String contestListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contests',
      one: '1 contest',
    );
    return '$_temp0';
  }

  @override
  String contestDateRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String get contestsLoadFailed => 'Contests could not be loaded.';

  @override
  String get contestsLoading => 'Loading contests';

  @override
  String get contestsEmpty => 'No contests yet.';

  @override
  String get modelsCellNone => 'No models entered';

  @override
  String get modelsCellNoneTooltip =>
      'A pilot without a model is fine. Add models any time.';

  @override
  String modelsEditTooltip(String name) {
    return 'Edit models for $name';
  }

  @override
  String modelsDialogTitle(String name) {
    return 'Models for $name';
  }

  @override
  String get modelsDialogEmpty =>
      'No models yet. The contest can go ahead without them.';

  @override
  String get modelsPickLabel => 'Pick one of their models';

  @override
  String get modelsPickHint => 'Or type a new one below';

  @override
  String get modelsFieldName => 'Model name *';

  @override
  String get modelsFieldManufacturer => 'Manufacturer';

  @override
  String get modelsFieldModelId => 'Model ID';

  @override
  String get modelsFieldModelIdHelper =>
      'The marking the pilot put on the model';

  @override
  String get modelsFieldContestId => 'Contest identifier';

  @override
  String get modelsFieldContestIdHelper =>
      'Applied by you for this contest, such as a serial number';

  @override
  String get modelsAddButton => 'Add a model';

  @override
  String get modelsSaveAdd => 'Add model';

  @override
  String get modelsSaveEdit => 'Save model';

  @override
  String get modelsFormCancel => 'Cancel';

  @override
  String get modelsDone => 'Done';

  @override
  String modelsEditEntry(String model) {
    return 'Edit $model';
  }

  @override
  String modelsRemoveEntry(String model) {
    return 'Remove $model';
  }

  @override
  String get modelsNameRequired => 'Enter a model name.';

  @override
  String get modelsDuplicate =>
      'This pilot already has a model with the same name, manufacturer and ID.';

  @override
  String get modelsStale =>
      'This pilot\'s models were changed elsewhere. Close this window to refresh them, then try again.';

  @override
  String modelsSaveFailed(String error) {
    return 'The model could not be saved. $error';
  }

  @override
  String modelsDetailModelId(String value) {
    return 'ID $value';
  }

  @override
  String modelsDetailContestId(String value) {
    return 'Contest $value';
  }

  @override
  String modelsCellCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models',
      one: '1 model',
    );
    return '$_temp0';
  }

  @override
  String get modelsProfileUnavailable =>
      'Their saved models could not be loaded. You can still type a model.';

  @override
  String get modelsProfileRetry => 'Retry';

  @override
  String get matrixPilotActions => 'Pilot actions';

  @override
  String get matrixMoveMenu => 'Move';

  @override
  String get matrixMoveLocked =>
      'Administration is locked. Unlock the contest to move a pilot.';

  @override
  String get matrixMoveNotEditable =>
      'Pilots can be moved once the matrix is drawn and until the contest is complete.';

  @override
  String matrixMoveTitle(String name) {
    return 'Move $name';
  }

  @override
  String matrixMoveFrom(int round, String group) {
    return 'Now flying round $round, group $group.';
  }

  @override
  String matrixMoveFromLane(int round, String group, int lane) {
    return 'Now flying round $round, group $group, lane $lane.';
  }

  @override
  String get matrixMoveScoredWarning =>
      'This flight has a score. Moving the pilot discards it: the score stays in the history as a reset and no longer counts. This is not the standard way to correct a flight, so check that you want this before you continue.';

  @override
  String get matrixMoveSourceGroupLocked =>
      'The pilot\'s group is locked. Unlock the group before moving the pilot.';

  @override
  String get matrixMoveSourceScoreLocked =>
      'The pilot\'s score is locked. Unlock the score before moving the pilot.';

  @override
  String get matrixMoveRound => 'Round';

  @override
  String matrixMoveRoundOption(int round) {
    return 'Round $round';
  }

  @override
  String get matrixMoveGroupHeading => 'Move to group';

  @override
  String matrixMoveGroupLabel(String group) {
    return 'Group $group';
  }

  @override
  String get matrixMoveRecommended => 'Recommended';

  @override
  String get matrixMoveNotIdeal => 'Not ideal';

  @override
  String get matrixMoveReasonHasScores =>
      'Pilots in this group already have scores.';

  @override
  String get matrixMoveReasonRoundCompleted =>
      'This round appears to be completed.';

  @override
  String get matrixMoveReasonTeammate => 'A teammate flies in this group.';

  @override
  String get matrixMoveBlockCurrent => 'The pilot flies in this group now.';

  @override
  String matrixMoveBlockAlready(int round) {
    return 'The pilot already flies in this group in round $round.';
  }

  @override
  String get matrixMoveBlockGroupLocked =>
      'This group is locked. Unlock the group first.';

  @override
  String get matrixMoveBlockRoundLocked =>
      'This round is locked. Unlock the round first.';

  @override
  String get matrixMoveBlockTeam =>
      'Team protection is on and a teammate flies in this group.';

  @override
  String get matrixMoveLane => 'Lane';

  @override
  String matrixMoveLaneFree(int lane) {
    return 'Lane $lane';
  }

  @override
  String matrixMoveLaneTaken(int lane, String name) {
    return 'Lane $lane, taken by $name';
  }

  @override
  String get matrixMoveReasonLabel => 'Reason';

  @override
  String get matrixMoveReasonHelp =>
      'Required. Kept with the move in the history.';

  @override
  String get matrixMoveReasonRequired => 'Enter a reason.';

  @override
  String get matrixMoveGroupRequired => 'Choose a group to move the pilot to.';

  @override
  String get matrixMoveLaneRequired => 'Choose a lane.';

  @override
  String get matrixMoveCancel => 'Cancel';

  @override
  String get matrixMoveConfirm => 'Move pilot';

  @override
  String get matrixMoveConfirmDiscard => 'Discard score and move';

  @override
  String get matrixMoveWorking => 'Moving…';

  @override
  String get matrixMoveNetwork =>
      'Soar Score can\'t reach the server. Nothing was moved. Try again.';

  @override
  String get matrixMoveChanged =>
      'The matrix or the contest changed since this page loaded. Nothing was moved. Reload to see the current matrix.';

  @override
  String get matrixMoveReload => 'Reload';

  @override
  String matrixMoveScoresFailed(String error) {
    return 'The scores could not be checked, so the pilot was not moved. $error';
  }

  @override
  String matrixPilotMoved(String name) {
    return '$name moved.';
  }

  @override
  String get matrixMovedLabel => 'Moved';

  @override
  String get matrixMovedHeading => 'Moves';

  @override
  String matrixMovedLine(int round, String reason) {
    return 'Round $round: $reason';
  }

  @override
  String get matrixMoveSourceRetired =>
      'This pilot has retired and cannot be moved.';

  @override
  String get matrixMoveChecking => 'Checking scores…';

  @override
  String get aboutHeading => 'About';

  @override
  String get aboutOpenSourceLicences => 'Open source licences';

  @override
  String get aboutOpenSourceLicencesHint =>
      'Opens the list on the RC Soar Score website';

  @override
  String get aboutLicencesOnThisDevice => 'Licences on this device';

  @override
  String get aboutLicencesOnThisDeviceHint =>
      'Works without a network connection';

  @override
  String get aboutSourceCode => 'Source code (AGPL-3.0)';

  @override
  String get aboutPrivacyPolicy => 'Privacy Policy';

  @override
  String get aboutTermsOfService => 'Terms of Service';

  @override
  String get aboutLinkFailed =>
      'Could not open the link. Check your network connection and try again.';

  @override
  String get pilotImportButton => 'Import pilots from GliderScore…';

  @override
  String get pilotImportTitle => 'Import pilots from GliderScore';

  @override
  String get pilotImportChoosing =>
      'Choose a GliderScore database (.mdb) to read the pilots from.';

  @override
  String get pilotImportChooseButton => 'Choose file…';

  @override
  String pilotImportReading(String file) {
    return 'Reading $file…';
  }

  @override
  String get pilotImportReviewIntro =>
      'Choose which pilots to add to your participants. Pilots already in your list get any new details; their names are never changed.';

  @override
  String pilotImportNewHeading(int count) {
    return 'New ($count)';
  }

  @override
  String pilotImportUpdateHeading(int count) {
    return 'Already in your list ($count)';
  }

  @override
  String pilotImportMaybeHeading(int count) {
    return 'Maybe the same person ($count)';
  }

  @override
  String pilotImportWillUpdate(String fields) {
    return 'Will update: $fields';
  }

  @override
  String get pilotImportNothingNew => 'Nothing new to add';

  @override
  String get pilotImportConflict =>
      'Their email and registration numbers match different people in your list.';

  @override
  String get pilotImportDuplicateInFile =>
      'Looks like another pilot earlier in this file.';

  @override
  String get pilotImportChoiceSkip => 'Skip';

  @override
  String get pilotImportChoiceAdd => 'Add as new';

  @override
  String pilotImportChoiceUpdate(String name) {
    return 'Update $name';
  }

  @override
  String get pilotImportFieldEmail => 'email';

  @override
  String get pilotImportFieldFai => 'FAI number';

  @override
  String get pilotImportFieldNationalId => 'national ID';

  @override
  String get pilotImportFieldClub => 'club';

  @override
  String get pilotImportFieldCity => 'city';

  @override
  String get pilotImportFieldState => 'state';

  @override
  String get pilotImportFieldCountry => 'country';

  @override
  String pilotImportTestPilots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count GliderScore test pilots (last name starting ZZ) were left out.',
      one: '1 GliderScore test pilot (last name starting ZZ) was left out.',
    );
    return '$_temp0';
  }

  @override
  String pilotImportSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows could not be used (no name or pilot number).',
      one: '1 row could not be used (no name or pilot number).',
    );
    return '$_temp0';
  }

  @override
  String pilotImportDroppedDetails(String columns) {
    return 'Not imported, because participants have no place for them: $columns.';
  }

  @override
  String pilotImportCountryNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pilots have no recognised country.',
      one: '1 pilot has no recognised country.',
    );
    return '$_temp0';
  }

  @override
  String get pilotImportTruncated =>
      'The file has more pilots than could be read. Some are missing.';

  @override
  String get pilotImportNoPilots => 'No pilots were found in this file.';

  @override
  String pilotImportPlan(int added, int updated, int unchanged, int skipped) {
    return '$added to add, $updated to update, $unchanged unchanged, $skipped left out';
  }

  @override
  String get pilotImportConfirm => 'Import';

  @override
  String get pilotImportSaving => 'Saving pilots…';

  @override
  String pilotImportDone(int added, int updated, int unchanged, int skipped) {
    return 'Added $added, updated $updated, unchanged $unchanged, left out $skipped.';
  }

  @override
  String get pilotImportDoneButton => 'Done';

  @override
  String pilotImportFailed(String reason) {
    return 'The import did not work. $reason';
  }

  @override
  String get pilotImportUnavailable =>
      'Importing from GliderScore is not available on this computer.';

  @override
  String get pilotImportChangedDuringReview =>
      'Your participants changed while you were reviewing. Review again before importing.';

  @override
  String get pilotImportChooseAgain => 'Choose a file again';

  @override
  String get pilotImportReviewAgain => 'Review again';

  @override
  String get shellNavPublication => 'Publication';

  @override
  String get publicationCardTitle => 'Publication';

  @override
  String get publicationStateUnpublished => 'Unpublished';

  @override
  String publicationStatePublished(String visibility) {
    return 'Published, $visibility';
  }

  @override
  String get publicationStateUnknown => 'Unknown';

  @override
  String get publicationStateUnavailable => 'Not available';

  @override
  String get publicationVisibilityUnlisted => 'Unlisted';

  @override
  String get publicationVisibilityPublic => 'Public';

  @override
  String get publicationVisibilityDelisted => 'Delisted';

  @override
  String get publicationScopeUnpublished =>
      'Publishing puts a copy of the results on the public site. It starts Unlisted: only people with the link can see it.';

  @override
  String publicationScopePublished(String time) {
    return 'Last published $time.';
  }

  @override
  String get publicationPolicyAutomatic =>
      'Public updates: automatic after each score.';

  @override
  String get publicationPolicyRoundCompletion =>
      'Public updates: after each completed round.';

  @override
  String get publicationPolicyManual =>
      'Public updates: only when you publish.';

  @override
  String get publicationPolicyUnknown => 'Public updates: not set yet.';

  @override
  String get publicationChangePolicy => 'Change in Configuration';

  @override
  String get publicationActionPublish => 'Publish results';

  @override
  String get publicationActionUpdate => 'Publish update';

  @override
  String get publicationActionMakePublic => 'Make public';

  @override
  String get publicationActionMakeUnlisted => 'Make unlisted';

  @override
  String get publicationActionOpenPage => 'Open Publication page';

  @override
  String get publicationActionRetry => 'Retry';

  @override
  String get publicationNeedsConnection => 'Needs a connection.';

  @override
  String get publicationUnavailableReason =>
      'This server does not publish contests.';

  @override
  String get publicationUnknownReason =>
      'The publication could not be read, so its state is not shown.';

  @override
  String get publicationNotCompletedHint =>
      'You can publish at any time. Most directors publish once the contest is completed.';

  @override
  String get publishDialogTitle => 'Publish results?';

  @override
  String get publishDialogBody =>
      'This copies the contest as it is now to the public site.';

  @override
  String publishDialogRevision(String revision) {
    return 'Contest revision: $revision';
  }

  @override
  String publishDialogVisibility(String visibility) {
    return 'Visibility: $visibility';
  }

  @override
  String get publishDialogConfirm => 'Publish';

  @override
  String get publicDialogTitle => 'Make results public?';

  @override
  String get publicDialogBody =>
      'The results will be listed on the public site, where anyone can find them.';

  @override
  String get publicDialogConfirm => 'Make public';

  @override
  String get publicationDialogCancel => 'Cancel';

  @override
  String get publicationPublishedDone => 'Results published.';

  @override
  String publicationVisibilityDone(String visibility) {
    return 'Visibility is now $visibility.';
  }

  @override
  String get publicationFailStaleContest =>
      'The contest changed since you opened this page. Review it and publish again.';

  @override
  String get publicationFailStaleResults =>
      'The results are out of date. Recalculate them and publish again.';

  @override
  String get publicationFailNotReady =>
      'The contest is not ready to publish yet.';

  @override
  String get publicationFailDelisted =>
      'This publication was delisted and can no longer change.';

  @override
  String get publicationFailUnavailable =>
      'This server does not publish contests.';

  @override
  String get publicationFailNotDirector =>
      'Only the contest\'s director can publish it.';

  @override
  String get publicationFailNetwork =>
      'The server could not be reached. Check your connection and try again.';

  @override
  String get publicationFailOther => 'Publishing failed. Try again.';

  @override
  String publicationStatePublishedDelistPending(String visibility) {
    return 'Published, $visibility. Delisting requested.';
  }

  @override
  String get publicationActionRequestDelisting => 'Request delisting';

  @override
  String get publicationActionWithdrawDelisting => 'Withdraw delisting request';

  @override
  String get delistDialogTitle => 'Request delisting?';

  @override
  String get delistDialogBody =>
      'Delisting removes the publication from public view. A system administrator approves or denies the request, and you can withdraw it while it is pending. Nothing in the contest becomes read-only while a request is pending.';

  @override
  String get delistDialogReasonLabel => 'Reason (optional)';

  @override
  String get delistDialogConfirm => 'Request delisting';

  @override
  String get publicationDelistRequestedDone => 'Delisting requested.';

  @override
  String get publicationDelistWithdrawnDone => 'Delisting request withdrawn.';

  @override
  String get publicationFailNotPublic =>
      'Delisting can only be requested for a Public publication.';

  @override
  String get publicationFailNothingPending =>
      'There is no pending delisting request any more.';

  @override
  String publicationPageDelistPending(String time) {
    return 'Delisting requested $time. A system administrator will decide.';
  }

  @override
  String get publicationPageHistoryTitle => 'Publication history';

  @override
  String publicationPageHistoryEntry(
    String number,
    String revision,
    String time,
  ) {
    return 'Copy $number, from contest revision $revision, $time';
  }

  @override
  String get publicationPageHistoryByYou => 'Published by you';

  @override
  String get publicationPageHistoryAutomatic => 'Updated automatically';

  @override
  String get publicationPageHistoryFailed =>
      'The publication history could not be read.';

  @override
  String get publicationPageLatestCopy => 'Latest published copy';

  @override
  String publicationPageCopyNumber(String number) {
    return 'Copy $number';
  }

  @override
  String publicationPageFromRevision(String revision) {
    return 'Made from contest revision $revision';
  }

  @override
  String publicationPagePublishedAt(String time) {
    return 'Published $time';
  }

  @override
  String get publicationPageNoCopy => 'Nothing has been published yet.';

  @override
  String get publicationPageLoadFailed => 'The contest could not be loaded.';

  @override
  String get publicationPolicyUnreadable =>
      'Public updates: the policy could not be read.';

  @override
  String get resultsCardVisible => 'Visible';

  @override
  String resultsCardHidden(int round, String time) {
    return 'Hidden through round $round, ends at $time';
  }

  @override
  String get resultsCardScopeVisible =>
      'Hiding removes overall scores and placing from the public site and participant views. Round scores stay visible.';

  @override
  String get resultsCardScopeHidden =>
      'Overall scores and placing are hidden from the public site and participant views. Hiding ends by itself 24 hours after it was turned on, or when the contest completes. Showing results ends it now.';

  @override
  String resultsCardRemaining(String time) {
    return '$time left before results show again.';
  }

  @override
  String resultsCardRemainingHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String resultsCardRemainingMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get resultsCardHide => 'Hide results';

  @override
  String get resultsCardShow => 'Show results';

  @override
  String get resultsCardHideBusy => 'Hiding…';

  @override
  String get resultsCardShowBusy => 'Showing…';

  @override
  String get resultsCardHiddenMessage =>
      'Results hidden. They show again after 24 hours, or when you show them or the contest completes.';

  @override
  String get resultsCardShownMessage => 'Results are visible again.';

  @override
  String get resultsCardNeedsConnection => 'Needs a connection.';

  @override
  String get resultsCardNotRunning =>
      'Results can be hidden only while the contest is running.';

  @override
  String get resultsCardNoApi => 'No API client is available.';

  @override
  String get resultsCardWhat => 'results hiding';

  @override
  String get scoreSaveNeedsZeroConfirm =>
      'Confirm the zero above to enable Save row.';

  @override
  String get scoreSaveAllZeroTitle => 'Confirm zero scores';

  @override
  String scoreSaveAllZeroBody(int count, String pilots) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'These $count rows will be saved as zeros: $pilots.',
      one: 'This row will be saved as a zero: $pilots.',
    );
    return '$_temp0';
  }

  @override
  String get scoreSaveAllZeroConfirm => 'Confirm and save';

  @override
  String get scoreSaveAllZeroCancel => 'Go back';

  @override
  String scoreSavingRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saving $count rows…',
      one: 'Saving 1 row…',
    );
    return '$_temp0';
  }

  @override
  String get competitionImportButton => 'Import from GliderScore…';

  @override
  String get competitionImportTitle => 'Import GliderScore competitions';

  @override
  String get competitionImportChoosing => 'Choose a GliderScore file…';

  @override
  String competitionImportReading(String file) {
    return 'Reading $file…';
  }

  @override
  String get competitionImportCancelReading => 'Cancel';

  @override
  String get competitionImportIntro =>
      'Choose the competitions to import. Each becomes a contest with its settings and participants. The draw and the scores are not imported with it, but a competition you imported before can have its draw added.';

  @override
  String get competitionImportNothingImportable =>
      'This file has no competition that can be imported.';

  @override
  String get competitionImportSelectAll => 'Select all';

  @override
  String get competitionImportSelectNone => 'Select none';

  @override
  String competitionImportRowDetails(String date, String className, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
    );
    return '$date · $className · $_temp0';
  }

  @override
  String get competitionImportWarningTeamNames =>
      'Teams are named Team 1, Team 2 and so on, because GliderScore has no team names. You can rename them afterwards.';

  @override
  String get competitionImportWarningRetired =>
      'Retired pilots stay active, because a retirement belongs to a round and there is no draw yet.';

  @override
  String competitionImportWarningOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more notes: settings were adjusted',
      one: '1 more note: a setting was adjusted',
    );
    return '$_temp0';
  }

  @override
  String get competitionImportReasonClassNotSupportedYet =>
      'This class is not imported yet.';

  @override
  String get competitionImportReasonClassOutOfScope =>
      'Soar Score does not support this class.';

  @override
  String get competitionImportReasonClassUnknown => 'This class is not known.';

  @override
  String get competitionImportReasonConfigMissing =>
      'The settings of this competition are missing from the file.';

  @override
  String get competitionImportReasonDateMissing =>
      'This competition has no date.';

  @override
  String get competitionImportReasonConfigInvalid =>
      'The settings of this competition are not valid.';

  @override
  String get competitionImportReasonNoParticipants =>
      'Nobody in this competition can be imported.';

  @override
  String get competitionImportReasonOther =>
      'This competition cannot be imported.';

  @override
  String get competitionImportContinue => 'Continue';

  @override
  String get competitionImportBack => 'Back';

  @override
  String competitionImportChosenCount(int count) {
    return '$count chosen';
  }

  @override
  String get competitionImportConfirmIntro =>
      'Check what will be written, then import.';

  @override
  String competitionImportSummaryContests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contests will be created.',
      one: '1 contest will be created.',
    );
    return '$_temp0';
  }

  @override
  String competitionImportSummaryPilots(int added, int updated) {
    return '$added participants will be added and $updated updated.';
  }

  @override
  String get competitionImportNotImported =>
      'Not imported: the draw, rounds, flights and scores.';

  @override
  String get competitionImportConfirm => 'Import';

  @override
  String get competitionImportSaving => 'Importing…';

  @override
  String competitionImportResultImported(String name) {
    return '$name: imported.';
  }

  @override
  String competitionImportResultSkippedPilots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count participants were left out because no pilot was chosen for them.',
      one: '1 participant was left out because no pilot was chosen for them.',
    );
    return '$_temp0';
  }

  @override
  String competitionImportResultAlready(String name, String date) {
    return '$name: already imported on $date. Nothing was changed.';
  }

  @override
  String competitionImportResultFailed(String name, String reason) {
    return '$name: not imported. $reason';
  }

  @override
  String get competitionImportOpen => 'Open';

  @override
  String get competitionImportDoneButton => 'Done';

  @override
  String get competitionImportFailNoAccount =>
      'There is no account to own the contest.';

  @override
  String get competitionImportFailNotImportable =>
      'This competition cannot be imported.';

  @override
  String get competitionImportFailProfileUnavailable =>
      'No scoring rules are available for this class.';

  @override
  String get competitionImportFailConfigInvalid =>
      'Its settings are not valid for the scoring rules.';

  @override
  String get competitionImportFailProfileMissing =>
      'A participant you chose is no longer in your list.';

  @override
  String get competitionImportFailOther =>
      'Something went wrong and nothing of this competition was kept.';

  @override
  String competitionImportFailed(String error) {
    return 'The import failed: $error';
  }

  @override
  String get competitionImportDrawTitle => 'Add the draw';

  @override
  String get competitionImportDrawIntro =>
      'Imported before. Adding the draw gives the contest its rounds, groups and every pilot\'s place, and makes it Ready. Every flight waits for a score.';

  @override
  String competitionImportDrawDetails(int rounds, int groups, int pilots) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups groups per round',
      one: '1 group per round',
    );
    String _temp2 = intl.Intl.pluralLogic(
      pilots,
      locale: localeName,
      other: '$pilots pilots',
      one: '1 pilot',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get competitionImportDrawNoteHistory =>
      'The draw is kept as GliderScore drew it. It cannot be reproduced from a seed, but rounds without scores can be redrawn like any other.';

  @override
  String competitionImportDrawWarningGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'In $count rounds the groups per round setting differs from the groups drawn. The groups as drawn are used.',
      one: 'In 1 round the groups per round setting differs from the groups drawn. The groups as drawn are used.',
    );
    return '$_temp0';
  }

  @override
  String competitionImportDrawWarningSizes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'In $count rounds the group sizes are not an even split. They are imported as drawn.',
      one: 'In 1 round the group sizes are not an even split. They are imported as drawn.',
    );
    return '$_temp0';
  }

  @override
  String competitionImportDrawWarningLanes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count places are beyond the lane count of the competition and get the next lanes.',
      one: '1 place is beyond the lane count of the competition and gets the next lane.',
    );
    return '$_temp0';
  }

  @override
  String competitionImportDrawWarningOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more notes about the order of pilots in groups.',
      one: '1 more note about the order of pilots in a group.',
    );
    return '$_temp0';
  }

  @override
  String get competitionImportDrawReasonFingerprint =>
      'This contest was imported from a different version of the file, so its pilots may no longer line up. Delete the contest and import the competition again to add its draw.';

  @override
  String get competitionImportDrawReasonDrawn =>
      'The contest already has a draw.';

  @override
  String get competitionImportDrawReasonScores =>
      'The contest already has scores.';

  @override
  String get competitionImportDrawReasonNoDraw =>
      'This competition has no drawn flights.';

  @override
  String get competitionImportDrawReasonPilot =>
      'A pilot in the draw is not a participant of the contest.';

  @override
  String get competitionImportDrawReasonMoved =>
      'A flight was moved to another round in GliderScore. Moved flights cannot be imported.';

  @override
  String get competitionImportDrawReasonRounds =>
      'The rounds or flights of this competition are not in a form that can be imported.';

  @override
  String get competitionImportDrawReasonOther =>
      'The draw of this competition cannot be added.';

  @override
  String get competitionImportDrawFailLocked =>
      'The contest is locked. Unlock it, then try again.';

  @override
  String competitionImportSummaryDraws(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The draws of $count contests will be added.',
      one: 'The draw of 1 contest will be added.',
    );
    return '$_temp0';
  }

  @override
  String get competitionImportDrawNotImported =>
      'Not imported with the draw: flights and scores.';

  @override
  String competitionImportResultDrawAdded(String name, int rounds, int places) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    String _temp1 = intl.Intl.pluralLogic(
      places,
      locale: localeName,
      other: '$places places',
      one: '1 place',
    );
    return '$name: the draw was added. $_temp0 and $_temp1. The contest is Ready.';
  }

  @override
  String competitionImportResultDrawFailed(String name, String reason) {
    return '$name: the draw was not added. $reason';
  }

  @override
  String competitionImportDrawLanes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Lanes: $count lanes. Each pilot\'s lane follows their place in the group.',
      one:
          'Lanes: 1 lane. Each pilot\'s lane follows their place in the group.',
    );
    return '$_temp0';
  }

  @override
  String get competitionImportDrawNoLanes =>
      'No lanes: the competition has none, so the order in each group is kept but no lane is set.';

  @override
  String competitionImportDrawUnflown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The last $count rounds have no scores yet. They may not have been flown.',
      one: 'The last round has no scores yet. It may not have been flown.',
    );
    return '$_temp0';
  }

  @override
  String get competitionImportDrawNoScores => 'No round has scores yet.';
}
