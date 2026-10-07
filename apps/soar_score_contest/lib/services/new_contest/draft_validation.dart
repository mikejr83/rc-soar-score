import 'package:intl/intl.dart';

import 'contest_draft.dart';
import 'participant_option.dart';

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
}
