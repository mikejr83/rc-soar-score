import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/matrix_test_support.dart';

MatrixServer _server(Map<String, Object?> core) => MatrixServer(
  configuration: matrixConfiguration(core),
  matrix: drawnMatrix(),
);

Finder _drop(int number) =>
    find.bySemanticsLabel('Drop $number starts after this round');

Finder _inHeader(Finder icon, int round) => find.descendant(
  of: find.ancestor(of: find.text('Round $round'), matching: find.byType(Row)),
  matching: icon,
);

void main() {
  testWidgets('no drops, no icon', (tester) async {
    await pumpMatrixPage(tester, _server({}));
    expect(find.byIcon(Icons.arrow_circle_down_outlined), findsNothing);
  });

  testWidgets('one drop marks only its round', (tester) async {
    await pumpMatrixPage(
      tester,
      _server({
        'drop_after_rounds': [2],
      }),
    );
    expect(_drop(1), findsOneWidget);
    expect(find.byIcon(Icons.arrow_circle_down_outlined), findsOneWidget);
    expect(
      _inHeader(find.byIcon(Icons.arrow_circle_down_outlined), 2),
      findsWidgets,
    );
    expect(
      find.byTooltip(
        'Drop 1: the lowest round score is dropped once this round is '
        'complete',
      ),
      findsOneWidget,
    );
  });

  testWidgets('two drops mark each round', (tester) async {
    await pumpMatrixPage(
      tester,
      _server({
        'drop_after_rounds': [1, 2],
      }),
    );
    expect(_drop(1), findsOneWidget);
    expect(_drop(2), findsOneWidget);
  });

  testWidgets('a drop round past the last drawn round shows nothing', (
    tester,
  ) async {
    await pumpMatrixPage(
      tester,
      _server({
        'drop_after_rounds': [6, 10],
      }),
    );
    expect(find.byIcon(Icons.arrow_circle_down_outlined), findsNothing);
  });
}
