import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/participant_editor/editor_skeleton.dart';

void main() {
  testWidgets('the loading skeleton does not overflow a short window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EditorSkeleton())),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Loading participant…'), findsOneWidget);
  });
}
