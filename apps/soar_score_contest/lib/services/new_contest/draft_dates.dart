import 'contest_draft.dart';
import 'draft_validation.dart';

/// Keeps the end date in step with the start date while the director fills in
/// step 1.
abstract final class DraftDates {
  /// [draft] with its start date set to [text].
  ///
  /// A contest is assumed to last one day, so the end date follows the start
  /// date while it is empty, equal to the previous start date, or would fall
  /// before the new start date. An end date the director chose on a later day
  /// is kept.
  static ContestDraft withStartDate(ContestDraft draft, String text) {
    final start = DraftValidation.parseDate(text);
    if (start == null) {
      return draft.copyWith(startDate: text);
    }
    final end = DraftValidation.parseDate(draft.endDate);
    final previousStart = DraftValidation.parseDate(draft.startDate);
    final follows =
        draft.endDate.trim().isEmpty ||
        (end != null && (end == previousStart || end.isBefore(start)));
    return draft.copyWith(
      startDate: text,
      endDate: follows ? DraftValidation.dateFormat.format(start) : null,
    );
  }
}
