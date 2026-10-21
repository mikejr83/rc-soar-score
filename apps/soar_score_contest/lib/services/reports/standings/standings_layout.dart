import 'dart:math' as math;
import 'dart:ui';

import 'standings_options.dart';

/// One printed page of the standings: a set of columns for a run of pilots.
class StandingsPageSpec {
  const StandingsPageSpec({
    required this.number,
    required this.setIndex,
    required this.rounds,
    required this.penalty,
    required this.pilotStart,
    required this.pilotEnd,
  });

  /// 1-based page number.
  final int number;

  /// Which set of columns the page carries (0 is the first, with the total and
  /// the optional columns).
  final int setIndex;

  /// The round columns of the page.
  final List<int> rounds;

  /// The Penalty column is on this page.
  final bool penalty;

  /// The pilots of the page, as a half-open range of row indexes.
  final int pilotStart;
  final int pilotEnd;

  /// Only the first set of columns carries the total and the optional columns;
  /// later sets carry rank, pilot and the rounds that did not fit.
  bool get isFirstSet => setIndex == 0;
}

/// How the standings split over pages: rows first, then columns.
///
/// Every round column and the Penalty column are the same fixed width, so the
/// grid is a regular matrix and the split is predictable. The pilots on each
/// page are fixed by the first set of columns and reused for every other set,
/// so "Pilots 11 to 14" is the same pilots on every second page.
class StandingsLayout {
  StandingsLayout._(this.pages, this.sets);

  /// Column widths in logical pixels (96 to the inch; a round column is about
  /// 15 mm). They are the same on screen and on paper.
  static const double rankWidth = 34;
  static const double nameWidth = 150;
  static const double totalWidth = 62;
  static const double percentageWidth = 52;
  static const double rawWidth = 64;
  static const double teamWidth = 104;
  static const double numberWidth = 38;
  static const double classWidth = 70;
  static const double labelWidth = 46;
  static const double roundWidth = 58;

  /// Row heights: plain, and with flight detail lines (F5J three, F3J two).
  static const double plainRow = 20;
  static const double detailRowF5j = 52;
  static const double detailRowF3j = 41;

  /// Room kept for the column heads (24, or 44 with a second line), and for the
  /// key and page note under the table.
  static const double headRow = 24;
  static const double headRowTall = 44;
  static const double footerReserve = 96;

  /// The width of the optional columns [options] turns on.
  static double optionalWidth(StandingsOptions options) =>
      (options.percentage ? percentageWidth : 0) +
      (options.raw ? rawWidth : 0) +
      (options.team ? teamWidth : 0) +
      (options.number ? numberWidth : 0) +
      (options.pilotClass ? classWidth : 0);

  /// Plans the pages for [rows] pilots over [rounds].
  ///
  /// [body] is the room a page body has. [hasPartial] marks a partly scored
  /// round, whose column head takes a second line, as does Penalty.
  factory StandingsLayout.plan({
    required StandingsOptions options,
    required List<int> rounds,
    required int rows,
    required bool hasPenalty,
    required bool hasPartial,
    required Size body,
    required bool isF3j,
  }) {
    final label = options.details ? labelWidth : 0.0;
    final firstFixed =
        rankWidth + nameWidth + totalWidth + optionalWidth(options) + label;
    final laterFixed = rankWidth + nameWidth + label;

    final sets = <({List<int> rounds, bool penalty})>[];
    var k = 0;
    while (k < rounds.length) {
      final fixed = sets.isEmpty ? firstFixed : laterFixed;
      var take = math.min(
        ((body.width - fixed) / roundWidth).floor(),
        rounds.length - k,
      );
      var penalty = false;
      if (k + take >= rounds.length && hasPenalty) {
        if (fixed + (take + 1) * roundWidth <= body.width) {
          penalty = true;
        } else {
          take--;
        }
      }
      // A page always carries at least one round column.
      take = math.max(1, take);
      sets.add((rounds: rounds.sublist(k, k + take), penalty: penalty));
      k += take;
    }
    if (sets.isEmpty) {
      sets.add((rounds: const [], penalty: hasPenalty));
    } else if (hasPenalty && !sets.last.penalty) {
      sets.add((rounds: const [], penalty: true));
    }

    final rowHeight = options.details
        ? (isF3j ? detailRowF3j : detailRowF5j)
        : plainRow;
    final head = hasPartial || hasPenalty ? headRowTall : headRow;
    final perPage = math.max(
      1,
      ((body.height - head - footerReserve) / (rowHeight + 1)).floor(),
    );
    final chunks = <(int, int)>[
      for (var start = 0; start < rows; start += perPage)
        (start, math.min(rows, start + perPage)),
      if (rows == 0) (0, 0),
    ];

    final pages = <StandingsPageSpec>[];
    for (var s = 0; s < sets.length; s++) {
      for (var c = 0; c < chunks.length; c++) {
        pages.add(
          StandingsPageSpec(
            number: s * chunks.length + c + 1,
            setIndex: s,
            rounds: sets[s].rounds,
            penalty: sets[s].penalty,
            pilotStart: chunks[c].$1,
            pilotEnd: chunks[c].$2,
          ),
        );
      }
    }
    return StandingsLayout._(pages, sets.length);
  }

  final List<StandingsPageSpec> pages;

  /// How many sets of columns there are.
  final int sets;

  /// The page of the next column set after [page], or `null` on the last set.
  StandingsPageSpec? continuationOf(StandingsPageSpec page) {
    final next = pages
        .where(
          (other) =>
              other.setIndex == page.setIndex + 1 &&
              other.pilotStart == page.pilotStart,
        )
        .firstOrNull;
    return next;
  }
}
