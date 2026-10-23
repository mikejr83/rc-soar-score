import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_columns.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_data.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_layout.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_options.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_style.dart';

import '../../../support/draw_matrix_support.dart';

const _body = Size(720, 860);

void main() {
  // One line per cell, whatever the text.
  int oneLine(String text, double width, double fontSize) => 1;

  // Eight pixels a character, whatever the type.
  double eight(String text, double fontSize, {bool bold = false}) =>
      text.length * 8;

  DrawMatrixLayout plan(
    DrawMatrixData data, {
    Map<String, String> filters = const {},
    DrawMatrixLineCounter? lines,
    Size body = _body,
    bool classes = false,
  }) {
    return DrawMatrixLayout.plan(
      data: data,
      options: DrawMatrixOptions.parse(
        filters,
        drawnRounds: [for (final round in data.rounds) round.ordinal],
      ),
      body: body,
      teams: false,
      numbers: true,
      classes: classes,
      lineCounter: lines ?? oneLine,
      textMeter: eight,
    );
  }

  Iterable<DrawMatrixItem> items(DrawMatrixLayout layout) => [
    for (final page in layout.pages)
      for (final table in page.tables) ...table,
  ];

  test('a typical contest takes several portrait pages', () {
    final layout = plan(syntheticDraw());
    expect(layout.pages.length, greaterThan(3));
    expect(items(layout).whereType<DrawMatrixPilotRow>(), hasLength(180));
    expect(layout.pages.every((p) => p.tables.length == 1), isTrue);
  });

  test('every table starts with a round header, never ends on one', () {
    final layout = plan(syntheticDraw());
    for (final page in layout.pages) {
      for (final table in page.tables) {
        expect(table.first, isA<DrawMatrixRoundRow>());
        expect(table.last, isNot(isA<DrawMatrixRoundRow>()));
      }
    }
  });

  test('a round header is always followed by its group header', () {
    final all = items(plan(syntheticDraw())).toList();
    for (var i = 0; i < all.length; i++) {
      if (all[i] is DrawMatrixRoundRow) {
        expect(all[i + 1], isA<DrawMatrixGroupRow>());
      }
    }
  });

  test('a group that fits is never split', () {
    final layout = plan(syntheticDraw());
    for (final page in layout.pages) {
      for (final table in page.tables) {
        var i = 0;
        while (i < table.length) {
          final item = table[i];
          if (item is DrawMatrixGroupRow && !item.continued) {
            final rows = table
                .skip(i + 1)
                .takeWhile((x) => x is DrawMatrixPilotRow)
                .length;
            expect(rows, item.size, reason: 'group ${item.label}');
          }
          i++;
        }
      }
    }
  });

  test('a round that carries on repeats its header as continued', () {
    final layout = plan(syntheticDraw());
    final continued = items(layout)
        .whereType<DrawMatrixRoundRow>()
        .where((r) => r.continued);
    expect(continued, isNotEmpty);
    // Only a later table of a round that began earlier repeats it.
    for (final page in layout.pages) {
      for (final table in page.tables) {
        final first = table.first as DrawMatrixRoundRow;
        if (first.continued) {
          expect(table[1], isA<DrawMatrixGroupRow>());
        }
      }
    }
  });

  test('column headings and rows fit the body', () {
    final layout = plan(syntheticDraw());
    for (final page in layout.pages) {
      for (final table in page.tables) {
        var used = layout.style.headHeight;
        for (final item in table) {
          used += switch (item) {
            DrawMatrixRoundRow(:final gapAbove) => layout.style.roundHeight(
              gap: gapAbove,
            ),
            DrawMatrixGroupRow() => layout.style.groupHeight,
            DrawMatrixPilotRow(:final lines) => layout.style.rowHeight(lines),
          };
        }
        expect(used, lessThanOrEqualTo(_body.height));
      }
    }
  });

  test('a group taller than a page carries on as continued', () {
    final layout = plan(
      syntheticDraw(rounds: 1, groupSizes: [90], lanes: false),
    );
    expect(layout.pages.length, greaterThan(1));
    final groups = items(layout).whereType<DrawMatrixGroupRow>().toList();
    expect(groups.first.continued, isFalse);
    expect(groups.skip(1).every((g) => g.continued), isTrue);
    expect(items(layout).whereType<DrawMatrixPilotRow>(), hasLength(90));
  });

  test('a long name that wraps pushes groups on, never over the page', () {
    final plain = plan(syntheticDraw(rounds: 1, groupSizes: [30]));
    final wrapping = plan(
      syntheticDraw(rounds: 1, groupSizes: [30]),
      lines: (text, width, fontSize) => 3,
    );
    expect(wrapping.pages.length, greaterThan(plain.pages.length));
  });

  test('compact mode sets two tables per page and takes fewer pages', () {
    final normal = plan(syntheticDraw());
    final compact = plan(syntheticDraw(), filters: {'cmp': '1'});
    expect(compact.style, DrawMatrixStyle.compact);
    expect(compact.pages.length, lessThan(normal.pages.length));
    expect(compact.pages.first.tables, hasLength(2));
    for (final page in compact.pages) {
      expect(page.tables.length, lessThanOrEqualTo(2));
    }
    expect(compact.tableWidth, (_body.width - 28) ~/ 2);
    expect(items(compact).whereType<DrawMatrixPilotRow>(), hasLength(180));
  });

  test('a range shows only those rounds', () {
    final layout = plan(syntheticDraw(), filters: {'from': '2', 'to': '3'});
    final rounds = items(layout)
        .whereType<DrawMatrixRoundRow>()
        .map((r) => r.ordinal)
        .toSet();
    expect(rounds, {2, 3});
    expect(items(layout).whereType<DrawMatrixPilotRow>(), hasLength(60));
  });

  test('a short contest fits on one page', () {
    final layout = plan(
      syntheticDraw(rounds: 2, groupSizes: [4, 4], lanes: true),
    );
    expect(layout.pages, hasLength(1));
  });

  group('columns', () {
    List<DrawMatrixColumnId> ids(DrawMatrixLayout layout) =>
        layout.columns.map((c) => c.id).toList();

    test('lane first, then pilot and number', () {
      final layout = plan(syntheticDraw());
      expect(ids(layout), [
        DrawMatrixColumnId.lane,
        DrawMatrixColumnId.name,
        DrawMatrixColumnId.number,
      ]);
    });

    test('no lanes, no Lane column; the pilot column takes the room', () {
      final layout = plan(syntheticDraw(lanes: false));
      expect(ids(layout), [DrawMatrixColumnId.name, DrawMatrixColumnId.number]);
      final number = layout.columns.last.width;
      expect(layout.columns.first.width, _body.width - number);
    });

    test('the columns fill the table exactly', () {
      for (final filters in [
        const <String, String>{},
        const {'inf': '1', 'nat': '1'},
        const {'cmp': '1'},
      ]) {
        final layout = plan(syntheticDraw(), filters: filters);
        final total = layout.columns.fold(0.0, (sum, c) => sum + c.width);
        expect(total, layout.tableWidth, reason: '$filters');
      }
    });

    test(
      'every column but the pilot shrinks to fit; the pilot takes the rest',
      () {
        final layout = plan(
          syntheticDraw(className: 'Sportsman'),
          classes: true,
        );
        double width(DrawMatrixColumnId id) =>
            layout.columns.firstWhere((c) => c.id == id).width;
        // 9 characters at 8 px, the cell padding and the slack.
        expect(width(DrawMatrixColumnId.className), 9 * 8 + 12 + 2);
        // "Lane" and "No." headings set bold at the heading size also fit.
        expect(width(DrawMatrixColumnId.lane), 4 * 8 + 12 + 2);
        final others = layout.columns
            .where((c) => c.id != DrawMatrixColumnId.name)
            .fold(0.0, (sum, c) => sum + c.width);
        expect(width(DrawMatrixColumnId.name), layout.tableWidth - others);
      },
    );

    test('a wide class pushes the other columns left, not onto two lines', () {
      final plain = plan(syntheticDraw(className: 'Open'), classes: true);
      final wide = plan(syntheticDraw(className: 'Sportsman'), classes: true);
      double name(DrawMatrixLayout l) =>
          l.columns.firstWhere((c) => c.id == DrawMatrixColumnId.name).width;
      expect(name(wide), lessThan(name(plain)));
      expect(
        wide.columns
            .firstWhere((c) => c.id == DrawMatrixColumnId.className)
            .wraps,
        isFalse,
      );
    });

    test('additional info adds club, FAI ID and National ID after class', () {
      final layout = plan(syntheticDraw(), filters: {'inf': '1', 'nat': '1'});
      expect(ids(layout).skip(3), [
        DrawMatrixColumnId.club,
        DrawMatrixColumnId.fai,
        DrawMatrixColumnId.national,
      ]);
    });

    test('compact mode leaves the additional columns out', () {
      final layout = plan(syntheticDraw(), filters: {'inf': '1', 'cmp': '1'});
      expect(ids(layout), isNot(contains(DrawMatrixColumnId.club)));
    });
  });

  test('the default line counter wraps long text', () {
    final short = DrawMatrixLayout.measuredLines('Lee, Ann', 400, 14.67);
    final long = DrawMatrixLayout.measuredLines(
      'Vanderhoeven-Castellanos, Maximiliano José Of The Long Name',
      80,
      14.67,
    );
    expect(short, 1);
    expect(long, greaterThan(1));
    expect(DrawMatrixLayout.measuredLines('', 80, 14.67), 1);
  });
}
