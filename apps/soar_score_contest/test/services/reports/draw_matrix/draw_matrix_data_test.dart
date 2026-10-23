import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_data.dart';

import '../../../support/draw_matrix_support.dart';

void main() {
  test('arranges the rounds by group, pilots in lane order', () {
    final data = DrawMatrixData.of(drawnPage(lanes: true));
    expect(data.hasLanes, isTrue);
    expect(data.rounds.map((r) => r.ordinal), [1, 2]);
    final round1 = data.rounds.first;
    expect(round1.groups.map((g) => g.label), ['A', 'B']);
    expect(round1.groups.first.pilots.map((p) => p.name), [
      'Ray, Bo',
      'Lee, Ann',
    ]);
    expect(round1.groups.first.pilots.map((p) => p.lane), [1, 2]);
    expect(round1.groups.last.pilots.map((p) => p.name), [
      'Fox, Cy',
      'Park, Di',
    ]);
  });

  test('without lanes there is no lane and no Lane column', () {
    final data = DrawMatrixData.of(drawnPage());
    expect(data.hasLanes, isFalse);
    expect(data.rounds.first.groups.first.pilots.first.lane, isNull);
  });

  test('group letters carry on past Z', () {
    expect(DrawMatrixData.groupLabel(0), 'A');
    expect(DrawMatrixData.groupLabel(25), 'Z');
    expect(DrawMatrixData.groupLabel(26), 'AA');
    expect(DrawMatrixData.groupLabel(27), 'AB');
  });
}
