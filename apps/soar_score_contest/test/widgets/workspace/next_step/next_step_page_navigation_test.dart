import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';

const _primary = ValueKey('next-step-primary');

void main() {
  testWidgets(
    'a contest without a configuration opens the Configuration page',
    (tester) async {
      await pumpWorkspace(
        tester,
        WorkspaceServer(state: LifecycleState.created),
      );
      expect(cardTitle(tester), 'Finish the configuration');
      await tester.tap(find.byKey(_primary));
      await tester.pumpAndSettle();
      expect(find.text('Configuration stub'), findsOneWidget);
    },
  );

  testWidgets('a ready-to-draw contest opens the Matrix page', (tester) async {
    await pumpWorkspace(
      tester,
      WorkspaceServer(
        state: LifecycleState.configuring,
        configuration: matrixConfiguration(),
      ),
    );
    expect(cardTitle(tester), 'Draw the matrix');
    await tester.tap(find.byKey(_primary));
    await tester.pumpAndSettle();
    expect(find.text('Matrix stub'), findsOneWidget);
  });

  testWidgets('a running contest shows the scoring dialog, not a no-op', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      WorkspaceServer(
        configuration: matrixConfiguration(),
        matrix: drawnMatrix(),
      ),
    );
    await tester.tap(find.byKey(_primary));
    await tester.pumpAndSettle();
    expect(find.text('Scoring is not available yet'), findsOneWidget);
  });
}
