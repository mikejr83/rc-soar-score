import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_columns.dart';

import '../../../support/scoring_sheet_support.dart';

List<ScoringSheetColumn> _columns(
  String? discipline, {
  bool lanes = true,
  bool restart = true,
  Map<String, String> filters = const {},
}) => ScoringSheetColumns.forContest(
  discipline: discipline,
  lanes: lanes,
  restart: restart,
  options: sheetOptions(filters),
);

List<ScoringSheetColumnId> _ids(
  String? discipline, {
  bool lanes = true,
  bool restart = true,
  Map<String, String> filters = const {},
}) => [
  for (final c in _columns(
    discipline,
    lanes: lanes,
    restart: restart,
    filters: filters,
  ))
    c.id,
];

/// Narrower than the F5J columns need at their minimums.
const _narrow = 600.0;

void main() {
  group('columns', () {
    test('F5J has time, landing, height, over 75 and motor restart', () {
      final ids = _ids('F5J');
      expect(ids.first, ScoringSheetColumnId.lane);
      expect(ids.skipWhile((id) => id != ScoringSheetColumnId.time), [
        ScoringSheetColumnId.time,
        ScoringSheetColumnId.landing,
        ScoringSheetColumnId.height,
        ScoringSheetColumnId.over75,
        ScoringSheetColumnId.restart,
        ScoringSheetColumnId.penalty,
        ScoringSheetColumnId.reflight,
        ScoringSheetColumnId.validated,
      ]);
    });

    test('F3J has no height and no motor restart', () {
      final ids = _ids('F3J');
      expect(ids, isNot(contains(ScoringSheetColumnId.height)));
      expect(ids, isNot(contains(ScoringSheetColumnId.restart)));
      expect(ids, contains(ScoringSheetColumnId.over75));
    });

    test(
      'a restart column needs the discipline and the contest to allow it',
      () {
        expect(
          _ids('F5J', restart: false),
          isNot(contains(ScoringSheetColumnId.restart)),
        );
        expect(_ids('ALES'), contains(ScoringSheetColumnId.restart));
        expect(_ids('ALES'), isNot(contains(ScoringSheetColumnId.height)));
      },
    );

    test('without lanes there is no Lane column and the pilot comes first', () {
      expect(_ids('F5J', lanes: false).first, ScoringSheetColumnId.name);
    });

    test('Club and Validated follow their switches', () {
      expect(_ids('F5J'), isNot(contains(ScoringSheetColumnId.club)));
      expect(
        _ids('F5J', filters: {'club': '1'}),
        contains(ScoringSheetColumnId.club),
      );
      expect(
        _ids('F5J', filters: {'val': '0'}),
        isNot(contains(ScoringSheetColumnId.validated)),
      );
    });

    test('ticks are boxes; Reflight and Validated are text spots', () {
      final columns = _columns('F5J');
      ScoringSheetColumnKind kindOf(ScoringSheetColumnId id) =>
          columns.firstWhere((c) => c.id == id).kind;
      expect(kindOf(ScoringSheetColumnId.over75), ScoringSheetColumnKind.tick);
      expect(kindOf(ScoringSheetColumnId.restart), ScoringSheetColumnKind.tick);
      expect(
        kindOf(ScoringSheetColumnId.reflight),
        ScoringSheetColumnKind.write,
      );
      expect(
        kindOf(ScoringSheetColumnId.validated),
        ScoringSheetColumnKind.write,
      );
    });
  });

  group('fitting a page', () {
    final f5j = _columns('F5J', filters: {'club': '1'});
    final f3jMinimum = _columns(
      'F3J',
      lanes: false,
      restart: false,
      filters: {'val': '0'},
    );

    test('a sheet that fits fills the page width in one strip', () {
      final strips = ScoringSheetColumns.plan(f5j, letterLandscapeBody.width);
      expect(strips, hasLength(1));
      expect(strips.single.width, letterLandscapeBody.width);
      expect(strips.single.columns, hasLength(f5j.length));
    });

    test('no column goes under its minimum width', () {
      for (final width in [
        letterLandscapeBody.width,
        letterPortraitBody.width,
      ]) {
        for (final strip in ScoringSheetColumns.plan(f5j, width)) {
          for (final sized in strip.columns) {
            expect(
              sized.width,
              greaterThanOrEqualTo(
                sized.column.minMm * ScoringSheetColumns.pxPerMm - 1,
              ),
              reason: '${sized.column.id} at $width',
            );
          }
        }
      }
    });

    test('the columns fit when the page is as wide as their minimums', () {
      final minimum = ScoringSheetColumns.minimumMm(f5j);
      expect(ScoringSheetColumns.fits(f5j, letterLandscapeBody.width), isTrue);
      expect(
        ScoringSheetColumns.fits(
          f5j,
          (minimum + 1) * ScoringSheetColumns.pxPerMm,
        ),
        isTrue,
      );
      expect(
        ScoringSheetColumns.fits(
          f5j,
          (minimum - 1) * ScoringSheetColumns.pxPerMm,
        ),
        isFalse,
      );
    });

    test('a short F3J sheet fits portrait', () {
      expect(
        ScoringSheetColumns.fits(f3jMinimum, letterPortraitBody.width),
        isTrue,
      );
    });

    test('columns that do not fit continue in strips of whole columns', () {
      final strips = ScoringSheetColumns.plan(f5j, _narrow);
      expect(strips.length, greaterThan(1));
      expect(
        [for (final s in strips) ...s.columns.map((c) => c.column.id)],
        [for (final c in f5j) c.id],
        reason: 'every column once, in order, none repeated',
      );
      for (final strip in strips) {
        expect(strip.width, _narrow);
      }
      expect(
        strips.first.columns.map((c) => c.column.id),
        contains(ScoringSheetColumnId.name),
      );
      expect(
        strips.skip(1).expand((s) => s.columns).map((c) => c.column.id),
        isNot(contains(ScoringSheetColumnId.name)),
      );
    });
  });
}
