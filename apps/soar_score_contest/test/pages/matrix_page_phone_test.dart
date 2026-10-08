import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';

const _phone = Size(400, 800);

MatrixServer _drawn() => MatrixServer(
  configuration: matrixConfiguration(const {
    'lane_mode': 'Random',
    'teams_enabled': true,
    'team_pilot_count': 2,
    'participant_numbers_enabled': true,
  }),
  matrix: drawnMatrix(lanes: true),
);

void main() {
  testWidgets('the draw form fits a phone', (tester) async {
    await pumpMatrixPage(
      tester,
      MatrixServer(configuration: matrixConfiguration()),
      size: _phone,
    );
    expect(find.text('Draw the first matrix'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('draw-rounds')), '3');
    await tester.enterText(find.byKey(const ValueKey('draw-groups')), '2');
    await tester.pump();
    expect(find.text('2 groups: 2, 2 pilots'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('draw-button')));
    await tester.tap(find.byKey(const ValueKey('draw-button')));
    await tester.pumpAndSettle();
    expect(find.text('Draw the matrix?'), findsOneWidget);
  });

  testWidgets('the disabled form and its reason fit a phone', (tester) async {
    await pumpMatrixPage(
      tester,
      MatrixServer(
        contest: matrixContest(lock: AdminLock.locked),
        configuration: matrixConfiguration(),
      ),
      size: _phone,
    );
    expect(find.textContaining('The contest is locked'), findsOneWidget);
    expect(find.text('Unlock in Configuration'), findsOneWidget);
  });

  testWidgets('the grid scrolls sideways on a phone', (tester) async {
    await pumpMatrixPage(tester, _drawn(), size: _phone);
    expect(find.text('Round 1'), findsOneWidget);
    final scroller = find.byKey(const ValueKey('grid-scroll'));
    expect(tester.getSize(scroller).width, lessThanOrEqualTo(400));
    // Round 2 starts off screen on the right until the grid is scrolled.
    expect(tester.getTopLeft(find.text('Round 2')).dx, greaterThan(300));
    await tester.drag(scroller, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Round 2')).dx, lessThan(300));
  });

  testWidgets('the summary starts as one line on a phone', (tester) async {
    await pumpMatrixPage(tester, _drawn(), size: _phone);
    expect(find.text('Show summary'), findsOneWidget);
    expect(find.text('Hide summary'), findsNothing);
    expect(find.textContaining('2 unmet pairs'), findsOneWidget);
  });

  testWidgets('a highlighted pilot and the panel fit a phone', (tester) async {
    await pumpMatrixPage(tester, _drawn(), size: _phone);
    await tester.tap(find.bySemanticsLabel(RegExp('Pilot 1, .*round 1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pilot-panel')), findsOneWidget);
    expect(find.text('Opponents (2 of 3)'), findsOneWidget);
  });

  testWidgets('large text still fits a phone', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpMatrixPage(tester, _drawn(), size: _phone);
    expect(find.text('Round 1'), findsOneWidget);
  });
}
