import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/bootstrap_failure_page.dart';

void main() {
  testWidgets('shows startup reason and offers retry and quit', (tester) async {
    var retryCount = 0;
    var quit = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BootstrapFailurePage(
          error: StateError('Database is unavailable'),
          onRetry: () async {
            retryCount++;
            throw StateError('Database is still unavailable');
          },
          onQuit: () => quit = true,
          showQuit: true,
        ),
      ),
    );

    expect(find.text('Application startup failed'), findsOneWidget);
    expect(find.textContaining('Database is unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retryCount, 1);
    expect(
      find.textContaining('Database is still unavailable'),
      findsOneWidget,
    );

    await tester.tap(find.text('Quit'));
    expect(quit, isTrue);
  });

  testWidgets('can hide quit action for web startup errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BootstrapFailurePage(
          error: StateError('Invalid server URL'),
          onRetry: () async {},
          onQuit: () {},
          showQuit: false,
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Quit'), findsNothing);
  });
}
