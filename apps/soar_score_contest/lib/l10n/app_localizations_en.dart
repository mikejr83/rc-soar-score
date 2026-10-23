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
}
