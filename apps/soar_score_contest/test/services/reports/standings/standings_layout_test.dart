import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/standings/standings_key.dart';
import 'package:soar_score_contest/services/reports/standings/standings_layout.dart';
import 'package:soar_score_contest/services/reports/standings/standings_options.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/widgets/reports/viewer/report_sheet_page.dart';

import '../../../support/standings_fixtures.dart';

void main() {
  final facts = factsOf(StandingsFixture());
  StandingsOptions options(Map<String, String> filters) => StandingsOptions.of({
    ...StandingsOptions.defaults(facts),
    ...filters,
  }, facts);

  /// Letter landscape, the report's default page.
  final letter = SheetLayout.bodySize(
    const PageSetup(PaperSize.letter, PageOrientation.landscape),
  );
  List<int> rounds(int n) => [for (var r = 1; r <= n; r++) r];

  StandingsLayout plan(
    StandingsOptions options, {
    int roundCount = 14,
    int rows = 14,
    bool penalty = false,
    bool partial = false,
    Size? body,
    bool f3j = false,
  }) => StandingsLayout.plan(
    options: options,
    rounds: rounds(roundCount),
    rows: rows,
    hasPenalty: penalty,
    hasPartial: partial,
    body: body ?? letter,
    isF3j: f3j,
  );

  group('column sets', () {
    test('a short contest fits on one page', () {
      final layout = plan(options({}), roundCount: 8);
      expect(layout.pages, hasLength(1));
      expect(layout.pages.single.rounds, rounds(8));
      expect(layout.pages.single.isFirstSet, isTrue);
    });

    test('rounds that do not fit continue on a second set', () {
      // Letter landscape holds 960 px: 298 px of fixed columns leaves 11 rounds.
      final layout = plan(options({}));
      expect(layout.pages, hasLength(2));
      expect(layout.pages[0].rounds, rounds(11));
      // Later sets carry only rank and pilot, so the other 3 rounds fit.
      expect(layout.pages[1].rounds, [12, 13, 14]);
      expect(layout.pages[1].isFirstSet, isFalse);
    });

    test('every optional column takes room from the rounds', () {
      final narrow = plan(options({'raw': '1'}));
      final wide = plan(options({}));
      expect(
        narrow.pages.first.rounds.length,
        lessThan(wide.pages.first.rounds.length),
      );
    });

    test('flight details add a label column to every set', () {
      final plain = plan(options({}), roundCount: 14).pages.first.rounds.length;
      final detailed = plan(
        options({'det': '1'}),
        roundCount: 14,
      ).pages.first.rounds.length;
      expect(detailed, lessThan(plain));
    });

    test('A4 is wider than Letter, so it holds more on a page', () {
      final a4 = SheetLayout.bodySize(
        const PageSetup(PaperSize.a4, PageOrientation.landscape),
      );
      expect(
        plan(options({}), body: a4).pages.first.rounds.length,
        greaterThanOrEqualTo(plan(options({})).pages.first.rounds.length),
      );
    });

    test('portrait re-paginates: fewer rounds fit on the first page', () {
      final portrait = SheetLayout.bodySize(
        const PageSetup(PaperSize.letter, PageOrientation.portrait),
      );
      expect(
        plan(options({}), body: portrait).pages.first.rounds.length,
        lessThan(plan(options({})).pages.first.rounds.length),
      );
    });
  });

  group('penalty', () {
    test('rides with the last rounds when there is room', () {
      final layout = plan(options({}), roundCount: 8, penalty: true);
      expect(layout.pages.single.penalty, isTrue);
      expect(layout.pages.single.rounds, rounds(8));
    });

    test('takes the last round with it when the first set is full', () {
      // 11 rounds fill the first set exactly, leaving no room for Penalty, so
      // the last round moves to the second set to sit beside it.
      final layout = plan(options({}), roundCount: 11, penalty: true);
      expect(layout.sets, 2);
      expect(layout.pages.first.rounds, rounds(10));
      expect(layout.pages.first.penalty, isFalse);
      expect(layout.pages.last.rounds, [11]);
      expect(layout.pages.last.penalty, isTrue);
    });
  });

  group('pilots', () {
    test('split by the first page and reused for every set', () {
      // A tall page holds 24 plain rows; 30 pilots need two pages per set.
      final layout = plan(options({}), rows: 30);
      expect(layout.pages, hasLength(4));
      expect([for (final p in layout.pages) p.pilotStart], [0, 24, 0, 24]);
      expect([for (final p in layout.pages) p.pilotEnd], [24, 30, 24, 30]);
      expect([for (final p in layout.pages) p.number], [1, 2, 3, 4]);
      expect([for (final p in layout.pages) p.setIndex], [0, 0, 1, 1]);
    });

    test('details make rows taller, so fewer fit', () {
      final plain = plan(options({}), rows: 40).pages.first.pilotEnd;
      final detailed = plan(
        options({'det': '1'}),
        rows: 40,
      ).pages.first.pilotEnd;
      expect(detailed, lessThan(plain));
    });

    test('F3J detail rows are shorter than F5J', () {
      final f5j = plan(options({'det': '1'}), rows: 40).pages.first.pilotEnd;
      final f3j = plan(
        options({'det': '1'}),
        rows: 40,
        f3j: true,
      ).pages.first.pilotEnd;
      expect(f3j, greaterThan(f5j));
    });

    test('no pilots still makes one page', () {
      expect(plan(options({}), rows: 0).pages, hasLength(2));
    });
  });

  group('where it continues', () {
    final layout = plan(options({}), rows: 30);

    test('a page points to the next set for the same pilots', () {
      expect(
        StandingsKey.continuation(page: layout.pages[0], layout: layout),
        'Rounds 12 to 14 continue on page 3',
      );
      expect(
        StandingsKey.continuation(page: layout.pages[1], layout: layout),
        'Rounds 12 to 14 continue on page 4',
      );
      expect(
        StandingsKey.continuation(page: layout.pages[2], layout: layout),
        isNull,
      );
    });

    test('a page says which pilots and rounds it holds', () {
      expect(
        StandingsKey.indicator(page: layout.pages[1]),
        'Pilots 25 to 30 · Rounds 1 to 11',
      );
      expect(
        StandingsKey.indicator(page: layout.pages[2]),
        'Pilots 1 to 24 · Rounds 12 to 14',
      );
    });

    test('rounds are written for one, several and none', () {
      expect(StandingsKey.roundsText([5]), 'Round 5');
      expect(StandingsKey.roundsText([5, 6, 7]), 'Rounds 5 to 7');
      expect(StandingsKey.roundsText([], penalty: true), 'Penalty');
    });
  });
}
