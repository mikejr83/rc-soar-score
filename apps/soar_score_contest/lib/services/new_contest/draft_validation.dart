import 'package:intl/intl.dart';

import 'contest_draft.dart';
import 'draw_settings.dart';
import 'participant_option.dart';
import 'participant_rules.dart';
import 'scoring_settings.dart';

/// A required or checked field in step 1.
enum DetailsField {
  name('Contest name'),
  venue('Venue / host'),
  startDate('Start date'),
  endDate('End date');

  const DetailsField(this.label);

  final String label;
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
  static Map<DetailsField, String> details(ContestDraft draft) {
    final errors = <DetailsField, String>{};
    if (draft.name.trim().isEmpty) {
      errors[DetailsField.name] = 'Enter a contest name.';
    }
    if (draft.venue.trim().isEmpty) {
      errors[DetailsField.venue] = 'Enter the venue or host club.';
    }
    final start = parseDate(draft.startDate);
    if (draft.startDate.trim().isEmpty) {
      errors[DetailsField.startDate] = 'Enter a start date.';
    } else if (start == null) {
      errors[DetailsField.startDate] = 'Use a date like Nov 14, 2026.';
    }
    final end = parseDate(draft.endDate);
    if (draft.endDate.trim().isEmpty) {
      errors[DetailsField.endDate] = 'Enter an end date.';
    } else if (end == null) {
      errors[DetailsField.endDate] = 'Use a date like Nov 15, 2026.';
    } else if (start != null && end.isBefore(start)) {
      errors[DetailsField.endDate] =
          'End date can’t be before the start date (${draft.startDate.trim()}).';
    }
    return errors;
  }

  /// The step 2 error, if any.
  static String? discipline(ContestDraft draft) =>
      draft.discipline == null ? 'Choose a discipline.' : null;

  /// The step 3 error for the pilots counted for the team score, if any.
  static String? teamPilotCount(ContestDraft draft) {
    if (!draft.has(ParticipantOption.teams)) {
      return null;
    }
    final value = int.tryParse(draft.teamPilotCount.trim());
    return value == null || value < 1 ? 'Enter a whole number above 0.' : null;
  }

  /// The dropped-round errors of step 5: the first and second "after round"
  /// inputs, when invalid.
  static ({String? first, String? second}) drops(ContestDraft draft) {
    final settings = draft.scoringSettings;
    if (settings.dropPolicy == DropPolicy.disabled) {
      return (first: null, second: null);
    }
    const whole = 'Enter a whole number above 0.';
    final first = int.tryParse(settings.firstDrop.trim());
    final firstError = first == null || first < 1 ? whole : null;
    if (settings.dropPolicy == DropPolicy.one) {
      return (first: firstError, second: null);
    }
    final second = int.tryParse(settings.secondDrop.trim());
    final secondError = second == null || second < 1
        ? whole
        : firstError == null && second <= first!
        ? 'Must be after round $first.'
        : null;
    return (first: firstError, second: secondError);
  }

  /// Whether step 5 can be left.
  static bool scoring(ContestDraft draft) {
    final errors = drops(draft);
    return errors.first == null && errors.second == null;
  }

  /// The step 6 errors, by field, when invalid.
  static ({String? groups, String? rounds, String? seededRounds}) draw(
    ContestDraft draft,
  ) {
    final settings = draft.drawSettings;
    final plan = GroupPlan.of(draft);
    String? whole(String text, String message) {
      final value = int.tryParse(text.trim());
      return value == null || value < 1 ? message : null;
    }

    final groups = settings.groups != null
        ? whole(settings.groups!, 'Enter a whole number above 0.')
        : null;
    return (
      groups:
          groups ??
          (!plan.bigEnough
              ? 'Use ${plan.maxGroups} or fewer so every group has at least 2 '
                    'scoring pilots.'
              : !plan.protectionMet
              ? 'Team protection needs at least ${plan.minGroups} groups.'
              : null),
      rounds: whole(draft.roundsText, 'Enter a whole number above 0.'),
      seededRounds: settings.seeded
          ? whole(settings.seededRounds, 'Enter 1 or more.')
          : null,
    );
  }

  /// Whether step 6 can be left.
  static bool drawOptions(ContestDraft draft) {
    final errors = draw(draft);
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
