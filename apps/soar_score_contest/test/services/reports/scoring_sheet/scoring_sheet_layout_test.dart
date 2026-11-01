import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_data.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_layout.dart';

import '../../../support/scoring_sheet_support.dart';

ScoringSheetLayout _plan(
  ScoringSheetData data, {
  Map<String, String> filters = const {},
  Size? body,
}) => ScoringSheetLayout.plan(
  data: data,
  options: sheetOptions(filters),
  body: body ?? letterLandscapeBody,
);

/// The rows of a page as short labels: "R1", "R1+" (continued), "GA", "GA+",
/// and "p3" for the pilot numbered 3.
List<String> _labels(ScoringSheetPage page) => [
  for (final item in page.items)
    switch (item) {
      ScoringSheetRoundRow() => 'R${item.ordinal}${item.continued ? '+' : ''}',
      ScoringSheetGroupRow() => 'G${item.label}${item.continued ? '+' : ''}',
      ScoringSheetPilotRow() => 'p${item.pilot.pilot.number! - 100}',
    },
];

List<String> _headings(ScoringSheetPage page) => [
  for (final label in _labels(page))
    if (!label.startsWith('p')) label,
];

void main() {
  test('two groups of seven fill a Letter landscape page', () {
    final layout = _plan(syntheticSheet(rounds: 1, groupSizes: [7, 7, 7, 7]));
    expect(layout.fitsAcross, isTrue);
    expect(layout.pages, hasLength(2));
    expect(_headings(layout.pages[0]), ['R1', 'GA', 'GB']);
    // A page that starts mid-round says so; a group is never split.
    expect(_headings(layout.pages[1]), ['R1+', 'GC', 'GD']);
  });

  test('a round heading moves to the next page with its first group', () {
    final layout = _plan(syntheticSheet(groupSizes: [7, 6, 6, 6]));
    // Round 1 takes the first page and a half; round 2's heading cannot sit
    // alone at the foot, so it starts the next page with its group.
    for (final page in layout.pages) {
      final labels = _labels(page);
      for (var i = 0; i < labels.length; i++) {
        if (labels[i].startsWith('R')) {
          expect(labels[i + 1], startsWith('G'), reason: labels.join(' '));
        }
      }
    }
    final round2 = layout.pages.firstWhere((p) => _labels(p).contains('R2'));
    expect(_labels(round2).first, anyOf('R2', 'R1+'));
  });

  test('a group is never split across pages when it fits on one', () {
    final layout = _plan(syntheticSheet(rounds: 3, groupSizes: [7, 7, 7]));
    for (final page in layout.pages) {
      final continued = _labels(page).where((l) => l.endsWith('GA+'));
      expect(continued, isEmpty);
      expect(
        _labels(page).any((l) => l.startsWith('G') && l.endsWith('+')),
        isFalse,
      );
    }
  });

  test('a group larger than a page carries on as continued', () {
    final layout = _plan(syntheticSheet(rounds: 1, groupSizes: [30]));
    expect(layout.pages.length, greaterThan(1));
    expect(_headings(layout.pages[1]), ['R1+', 'GA+']);
  });

  test('pilots run by lane, or by name without lanes', () {
    final laned = _plan(syntheticSheet(rounds: 1, groupSizes: [3]));
    expect(_labels(laned.pages.single), ['R1', 'GA', 'p1', 'p2', 'p3']);
    final named = _plan(
      syntheticSheet(rounds: 1, groupSizes: [3], lanes: false),
    );
    expect(named.columns.map((c) => c.id.name), isNot(contains('lane')));
  });

  test('the round range limits the rounds', () {
    final layout = _plan(
      syntheticSheet(rounds: 2, groupSizes: [3]),
      filters: {'from': '2', 'to': '2'},
    );
    final all = layout.pages.expand(_labels);
    expect(all, contains('R2'));
    expect(all, isNot(contains('R1')));
  });

  group('retired pilots', () {
    test('are left out of the rounds after they retired', () {
      final layout = _plan(syntheticSheet(groupSizes: [3], retiredAt: {2: 2}));
      final rounds = [for (final page in layout.pages) ..._labels(page)];
      expect(rounds.where((l) => l == 'p2'), hasLength(1));
      final group = layout.pages
          .expand((p) => p.items)
          .whereType<ScoringSheetGroupRow>()
          .toList();
      expect(group.map((g) => g.size), [3, 2]);
      expect(layout.legend, isNull);
    });

    test('stay in every round, marked, with a legend, when asked for', () {
      final layout = _plan(
        syntheticSheet(groupSizes: [3], retiredAt: {2: 2}),
        filters: {'ret': '1'},
      );
      final rows = layout.pages
          .expand((p) => p.items)
          .whereType<ScoringSheetPilotRow>();
      expect(rows.where((r) => r.pilot.pilot.number == 102), hasLength(2));
      expect(
        rows.where((r) => r.marked).map((r) => r.pilot.pilot.number),
        everyElement(102),
      );
      expect(layout.legend, '(R) = retired');
    });
  });

  group('columns that do not fit across the page', () {
    test('the same rows repeat for each strip, band by band', () {
      final layout = _plan(
        syntheticSheet(rounds: 1, groupSizes: [7, 7, 7, 7]),
        filters: {'club': '1'},
        body: const Size(600, 906),
      );
      expect(layout.fitsAcross, isFalse);
      final strips = layout.strips.length;
      expect(layout.pages, hasLength(layout.bands * strips));
      for (var band = 0; band < layout.bands; band++) {
        final pages = layout.pages.skip(band * strips).take(strips).toList();
        expect(pages.map((p) => p.band).toSet(), {band + 1});
        expect(pages.map((p) => p.stripIndex), [
          for (var i = 0; i < strips; i++) i,
        ]);
        // Round and group headings repeat on every page of the band.
        for (final page in pages) {
          expect(_headings(page), _headings(pages.first));
        }
      }
    });
  });
}
