import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/round_progress_view.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';

MatrixServer _server({
  (int, int)? scored,
  RoundStatus round2Status = RoundStatus.open,
}) => MatrixServer(
  configuration: matrixConfiguration(),
  matrix: drawnMatrix(scored: scored, round2Status: round2Status),
);

void main() {
  group('RoundProgressView', () {
    test('follows the counts', () {
      RoundProgressState state(int scored, int total) => RoundProgressView.of(
        RoundStatus.open,
        scored: scored,
        total: total,
      ).state;

      expect(state(0, 4), RoundProgressState.notFlown);
      expect(state(1, 4), RoundProgressState.inProgress);
      expect(state(4, 4), RoundProgressState.scored);
      // A late add raises the total, so a scored round is in progress again.
      expect(state(4, 5), RoundProgressState.inProgress);
    });

    test('a locked round is not scored by the lock alone', () {
      final view = RoundProgressView.of(
        RoundStatus.locked,
        scored: 0,
        total: 4,
      );

      expect(view.state, RoundProgressState.notFlown);
    });

    test('a cancelled round stays cancelled', () {
      final view = RoundProgressView.of(
        RoundStatus.cancelled,
        scored: 4,
        total: 4,
      );

      expect(view.label, 'Cancelled');
    });
  });

  testWidgets('shows scored, in progress and the counts', (tester) async {
    await pumpMatrixPage(tester, _server(scored: (4, 3)));

    expect(find.text('Scored, 4 of 4'), findsOneWidget);
    expect(find.text('In progress, 3 of 4 scored'), findsOneWidget);
    expect(find.text('Not flown'), findsNothing);
  });

  testWidgets('shows not flown when nothing is scored', (tester) async {
    await pumpMatrixPage(tester, _server(scored: (0, 0)));

    expect(find.text('Not flown'), findsNWidgets(2));
  });

  testWidgets('a locked round shows the lock, not Scored', (tester) async {
    await pumpMatrixPage(
      tester,
      _server(scored: (0, 0), round2Status: RoundStatus.locked),
    );

    expect(find.text('Scored, 4 of 4'), findsNothing);
    expect(find.text('Not flown'), findsNWidgets(2));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
