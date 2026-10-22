import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/participant_editor_page.dart';

import '../support/participant_test_support.dart';

void main() {
  testWidgets('a failed email lookup says so and can be retried', (
    tester,
  ) async {
    useTallWindow(tester);
    var failing = true;
    final client = clientFor((_) async {
      return failing
          ? errorResponse(500, 'oops', 'The server is busy.')
          : json({'participants': []});
    });

    await tester.pumpWidget(editorApp(client, const ParticipantEditorPage()));
    await tester.pumpAndSettle();
    await enterField(tester, 'email', 'sam@example.com');
    await leaveField(tester, 'email');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('email-check-failed')), findsOneWidget);

    failing = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('email-check-failed')), findsNothing);
    expect(
      find.text('No existing participant uses this email.'),
      findsOneWidget,
    );
  });

  testWidgets('large text above the phone width uses the stacked bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 1200);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(
      editorApp(
        clientFor((_) async => json({'participants': []})),
        const ParticipantEditorPage(),
      ),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'first-name', 'Sam');

    expect(tester.takeException(), isNull);
    final save = tester.getRect(find.byKey(const ValueKey('save-participant')));
    final another = tester.getRect(
      find.byKey(const ValueKey('save-add-another')),
    );
    // Side by side inside the window, not pushed off the edge.
    expect(save.right, lessThanOrEqualTo(700));
    expect(another.left, greaterThanOrEqualTo(0));
  });
}
