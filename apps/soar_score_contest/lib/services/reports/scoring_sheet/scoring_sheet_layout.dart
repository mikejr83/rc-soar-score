import 'package:flutter/painting.dart';

import 'scoring_sheet_columns.dart';
import 'scoring_sheet_data.dart';
import 'scoring_sheet_options.dart';

/// The sizes of the sheet, in logical pixels (96 to the inch). Rows are 9 mm:
/// enough to write in with a pen.
abstract final class ScoringSheetStyle {
  static const double rowHeight = 34;
  static const double columnHeadHeight = 48;
  static const double roundHeight = 34;
  static const double roundGap = 10;
  static const double groupHeight = 28;
  static const double legendHeight = 18;

  /// The room kept under the table for the legend.
  static const double legendGap = 6;

  /// The tick box, 5 mm square.
  static const double tickBox = 19;

  /// Extra blank space down each side of the page, header and footer
  /// included, 5 mm on top of the frame's own margin: printers cut a wide
  /// table's outer rules and the header off otherwise.
  static const double sideMargin = 18.9;
}

/// One row of a table on a printed page.
sealed class ScoringSheetItem {
  const ScoringSheetItem();
}

/// Where a round starts, or carries on.
final class ScoringSheetRoundRow extends ScoringSheetItem {
  const ScoringSheetRoundRow({
    required this.ordinal,
    this.continued = false,
    this.gapAbove = false,
  });

  final int ordinal;
  final bool continued;

  /// Space above it, because something sits above it on the page.
  final bool gapAbove;
}

/// Where a group starts, or carries on, with its size.
final class ScoringSheetGroupRow extends ScoringSheetItem {
  const ScoringSheetGroupRow({
    required this.label,
    required this.size,
    this.continued = false,
  });

  final String label;
  final int size;
  final bool continued;
}

/// One pilot in a group.
final class ScoringSheetPilotRow extends ScoringSheetItem {
  const ScoringSheetPilotRow(this.pilot, {this.marked = false});

  final ScoringSheetPilot pilot;

  /// The name carries the retired marker.
  final bool marked;
}

/// One printed page: a band of rows, in one strip of columns.
class ScoringSheetPage {
  const ScoringSheetPage({
    required this.items,
    required this.strip,
    required this.band,
    required this.stripIndex,
  });

  final List<ScoringSheetItem> items;
  final ScoringSheetStrip strip;

  /// The band of rows this page shows, from 1.
  final int band;

  /// Which strip of columns, from 0.
  final int stripIndex;
}

/// How the Scoring Sheet splits over pages.
///
/// Rows run in order of round and group. A group is never split when it fits
/// on a page; a round heading is only placed together with its first group; a
/// round that carries on repeats its heading as "(Continued)"; a group larger
/// than a page carries on as "(Continued)". When the columns do not fit across
/// the page the same rows are repeated for each strip of columns, so pages
/// taped side by side line up.
class ScoringSheetLayout {
  ScoringSheetLayout._({
    required this.pages,
    required this.columns,
    required this.strips,
    required this.legend,
    required this.workingTime,
    required this.bands,
  });

  factory ScoringSheetLayout.plan({
    required ScoringSheetData data,
    required ScoringSheetOptions options,
    required Size body,
  }) {
    final columns = ScoringSheetColumns.forContest(
      discipline: data.discipline,
      lanes: data.hasLanes,
      restart: data.motorRestart,
      options: options,
    );
    final strips = ScoringSheetColumns.plan(columns, body.width);

    // What the rounds hold once the options are applied.
    final rounds = <(int, List<(String, List<ScoringSheetPilot>)>)>[];
    for (final round in data.rounds) {
      if (!options.rounds.contains(round.ordinal)) {
        continue;
      }
      final groups = <(String, List<ScoringSheetPilot>)>[];
      for (final group in round.groups) {
        final pilots = [
          for (final p in group.pilots)
            if (options.includeRetired || !p.retiredBy(round.ordinal))
              options.prefill ? p : p.withoutScore(),
        ];
        if (pilots.isNotEmpty) {
          groups.add((group.label, pilots));
        }
      }
      if (groups.isNotEmpty) {
        rounds.add((round.ordinal, groups));
      }
    }

    final legend = _legend(options, rounds);
    final capacity =
        body.height -
        ScoringSheetStyle.columnHeadHeight -
        2 -
        (legend == null
            ? 0
            : ScoringSheetStyle.legendHeight + ScoringSheetStyle.legendGap);

    final bands = <List<ScoringSheetItem>>[];
    var band = <ScoringSheetItem>[];
    var used = 0.0;
    void newBand() {
      band = [];
      bands.add(band);
      used = 0;
    }

    void push(ScoringSheetItem item, double height) {
      band.add(item);
      used += height;
    }

    ScoringSheetPilotRow row(ScoringSheetPilot p) => ScoringSheetPilotRow(
      p,
      marked: options.includeRetired && p.pilot.isRetired,
    );

    newBand();
    for (final (ordinal, groups) in rounds) {
      for (var g = 0; g < groups.length; g++) {
        final (label, pilots) = groups[g];
        final groupHeight =
            ScoringSheetStyle.groupHeight +
            pilots.length * ScoringSheetStyle.rowHeight;
        final top = band.isEmpty;
        final roundHeight = g == 0
            ? ScoringSheetStyle.roundHeight +
                  (top ? 0 : ScoringSheetStyle.roundGap)
            : 0.0;
        if (!top && used + roundHeight + groupHeight > capacity) {
          newBand();
          if (g > 0) {
            push(
              ScoringSheetRoundRow(ordinal: ordinal, continued: true),
              ScoringSheetStyle.roundHeight,
            );
          }
        }
        if (g == 0) {
          final gap = band.isNotEmpty;
          push(
            ScoringSheetRoundRow(ordinal: ordinal, gapAbove: gap),
            ScoringSheetStyle.roundHeight +
                (gap ? ScoringSheetStyle.roundGap : 0),
          );
        }
        push(
          ScoringSheetGroupRow(label: label, size: pilots.length),
          ScoringSheetStyle.groupHeight,
        );
        for (final pilot in pilots) {
          if (used + ScoringSheetStyle.rowHeight > capacity) {
            newBand();
            push(
              ScoringSheetRoundRow(ordinal: ordinal, continued: true),
              ScoringSheetStyle.roundHeight,
            );
            push(
              ScoringSheetGroupRow(
                label: label,
                size: pilots.length,
                continued: true,
              ),
              ScoringSheetStyle.groupHeight,
            );
          }
          push(row(pilot), ScoringSheetStyle.rowHeight);
        }
      }
    }

    final nonEmpty = [
      for (final b in bands)
        if (b.isNotEmpty) b,
    ];
    return ScoringSheetLayout._(
      pages: [
        for (var b = 0; b < nonEmpty.length; b++)
          for (var s = 0; s < strips.length; s++)
            ScoringSheetPage(
              items: nonEmpty[b],
              strip: strips[s],
              band: b + 1,
              stripIndex: s,
            ),
      ],
      columns: columns,
      strips: strips,
      legend: legend,
      workingTime: data.workingTime,
      bands: nonEmpty.length,
    );
  }

  /// The one line under the table, for what the marks on the sheet mean; `null`
  /// when no mark needs one.
  static String? _legend(
    ScoringSheetOptions options,
    List<(int, List<(String, List<ScoringSheetPilot>)>)> rounds,
  ) {
    var retired = false;
    int? scoredThrough;
    var unofficial = false;
    for (final (ordinal, groups) in rounds) {
      for (final (_, pilots) in groups) {
        for (final p in pilots) {
          retired = retired || p.pilot.isRetired;
          final score = p.score;
          if (options.prefill && score != null) {
            scoredThrough = ordinal;
            unofficial = unofficial || !score.official;
          }
        }
      }
    }
    final parts = [
      if (options.includeRetired && retired) '(R) = retired',
      if (scoredThrough != null)
        'Includes scores through round $scoredThrough'
            '${unofficial ? ' · * not official' : ''}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  final List<ScoringSheetPage> pages;
  final List<ScoringSheetColumn> columns;

  /// The strips of columns; one when every column fits across the page.
  final List<ScoringSheetStrip> strips;

  /// What the marks on the sheet mean, printed under the table.
  final String? legend;

  /// "10:00", for every group heading.
  final String workingTime;

  /// The bands of rows; each is repeated for every strip.
  final int bands;

  bool get fitsAcross => strips.length == 1;

  /// The writing cells' width across the page, in millimetres.
  double get writingMm => ScoringSheetColumns.writingMm(strips);
}
