import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draft_dates.dart';

void main() {
  group('withStartDate', () {
    test('fills an empty end date with the start date', () {
      final next = DraftDates.withStartDate(
        const ContestDraft(),
        'Nov 14, 2026',
      );
      expect(next.startDate, 'Nov 14, 2026');
      expect(next.endDate, 'Nov 14, 2026');
    });

    test('moves an end date that matched the old start date', () {
      const draft = ContestDraft(
        startDate: 'Nov 14, 2026',
        endDate: 'Nov 14, 2026',
      );
      expect(
        DraftDates.withStartDate(draft, 'Nov 20, 2026').endDate,
        'Nov 20, 2026',
      );
    });

    test('keeps a later end date the director chose', () {
      const draft = ContestDraft(
        startDate: 'Nov 14, 2026',
        endDate: 'Nov 16, 2026',
      );
      expect(
        DraftDates.withStartDate(draft, 'Nov 15, 2026').endDate,
        'Nov 16, 2026',
      );
    });

    test('pulls an end date forward when the start passes it', () {
      const draft = ContestDraft(
        startDate: 'Nov 14, 2026',
        endDate: 'Nov 16, 2026',
      );
      expect(
        DraftDates.withStartDate(draft, 'Nov 20, 2026').endDate,
        'Nov 20, 2026',
      );
    });

    test('leaves the end date alone while the start is not a date', () {
      const draft = ContestDraft(
        startDate: 'Nov 14, 2026',
        endDate: 'Nov 14, 2026',
      );
      final next = DraftDates.withStartDate(draft, 'Nov 1');
      expect(next.startDate, 'Nov 1');
      expect(next.endDate, 'Nov 14, 2026');
    });
  });
}
