import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'contest_draft.dart';
import 'draw_settings.dart';
import '../participants/participant_option.dart';
import 'participant_rules.dart';
import 'scoring_settings.dart';

/// A required or checked field in step 1.
enum DetailsField {
  name,
  venue,
  startDate,
  endDate;

  /// The user-visible label for this field.
  String label(AppLocalizations l10n) => switch (this) {
    name => l10n.wizardDetailsFieldContestName,
    venue => l10n.wizardDetailsFieldVenue,
    startDate => l10n.wizardDetailsFieldStartDate,
    endDate => l10n.wizardDetailsFieldEndDate,
  };
}

/// Validation of the wizard steps built so far.
abstract final class DraftValidation {
  /// The date format the date fields accept and show (`Nov 14, 2026`).
  static final DateFormat dateFormat = DateFormat.yMMMd('en_US');

  /// [text] as a date, or `null` when it is not one.
  static DateTime? parseDate(String text) {
    try {
      return dateFormat.parseStrict(text.trim());
    } on FormatException {
      return null;
    }
  }

  /// The step 1 errors, in field order.
  static Map<DetailsField, String> details(
    ContestDraft draft,
    AppLocalizations l10n,
  ) {
    final errors = <DetailsField, String>{};
    if (draft.name.trim().isEmpty) {
      errors[DetailsField.name] = l10n.wizardValidationEnterName;
    }
    if (draft.venue.trim().isEmpty) {
      errors[DetailsField.venue] = l10n.wizardValidationEnterVenue;
    }
    final start = parseDate(draft.startDate);
    if (draft.startDate.trim().isEmpty) {
      errors[DetailsField.startDate] = l10n.wizardValidationEnterStartDate;
    } else if (start == null) {
      errors[DetailsField.startDate] = l10n.wizardValidationStartDateFormat;
    }
    final end = parseDate(draft.endDate);
    if (draft.endDate.trim().isEmpty) {
      errors[DetailsField.endDate] = l10n.wizardValidationEnterEndDate;
    } else if (end == null) {
      errors[DetailsField.endDate] = l10n.wizardValidationEndDateFormat;
    } else if (start != null && end.isBefore(start)) {
      errors[DetailsField.endDate] = l10n
          .wizardValidationEndDateBeforeStart(draft.startDate.trim());
    }
    return errors;
  }

  /// The step 2 error, if any.
  static String? discipline(ContestDraft draft, AppLocalizations l10n) =>
      draft.discipline == null ? l10n.wizardValidationChooseDiscipline : null;

  /// The step 3 error for the pilots counted for the team score, if any.
  static String? teamPilotCount(
    ContestDraft draft,
    AppLocalizations l10n,
  ) {
    if (!draft.has(ParticipantOption.teams)) {
      return null;
    }
    final value = int.tryParse(draft.teamPilotCount.trim());
    return value == null || value < 1 ? l10n.wizardValidationWholeNumber : null;
  }

  /// The dropped-round errors of step 5: the first and second "after round"
  /// inputs, when invalid.
  static ({String? first, String? second}) drops(
    ContestDraft draft,
    AppLocalizations l10n,
  ) {
    final settings = draft.scoringSettings;
    if (settings.dropPolicy == DropPolicy.disabled) {
      return (first: null, second: null);
    }
    final whole = l10n.wizardValidationWholeNumber;
    final first = int.tryParse(settings.firstDrop.trim());
    final firstError = first == null || first < 1 ? whole : null;
    if (settings.dropPolicy == DropPolicy.one) {
      return (first: firstError, second: null);
    }
    final second = int.tryParse(settings.secondDrop.trim());
    final secondError = second == null || second < 1
        ? whole
        : firstError == null && second <= first!
        ? l10n.wizardValidationMustBeAfterRound(first)
        : null;
    return (first: firstError, second: secondError);
  }

  /// Whether step 5 can be left.
  static bool scoring(ContestDraft draft, AppLocalizations l10n) {
    final errors = drops(draft, l10n);
    return errors.first == null && errors.second == null;
  }

  /// The step 6 errors, by field, when invalid.
  static ({String? groups, String? rounds, String? seededRounds}) draw(
    ContestDraft draft,
    AppLocalizations l10n,
  ) {
    final settings = draft.drawSettings;
    final plan = GroupPlan.of(draft);
    String? whole(String text, String message) {
      final value = int.tryParse(text.trim());
      return value == null || value < 1 ? message : null;
    }
    final wholeMsg = l10n.wizardValidationWholeNumber;

    final groups = settings.groups != null
        ? whole(settings.groups!, wholeMsg)
        : null;
    return (
      groups:
          groups ??
          (!plan.bigEnough
              ? l10n.wizardValidationGroupsMax(plan.maxGroups)
              : !plan.protectionMet
              ? l10n.wizardValidationGroupsMin(plan.minGroups)
              : null),
      rounds: whole(draft.roundsText, wholeMsg),
      seededRounds: settings.seeded
          ? whole(settings.seededRounds, l10n.wizardValidationSeededRounds)
          : null,
    );
  }

  /// Whether step 6 can be left.
  static bool drawOptions(ContestDraft draft, AppLocalizations l10n) {
    final errors = draw(draft, l10n);
    return errors.groups == null &&
        errors.rounds == null &&
        errors.seededRounds == null;
  }

  /// The fewest scoring pilots a contest can have.
  static const int minScoringPilots = 2;

  /// Whether step 4 can be left: enough scoring pilots and every row
  /// complete.
  static bool participants(ContestDraft draft) =>
      draft.scoringCount >= minScoringPilots &&
      draft.participantsNeedingFixes.isEmpty;
}
