import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/bootstrap_failure_page.dart';

void main() {
  Widget page({
    required Future<void> Function() onRetry,
    VoidCallback? onQuit,
  }) => MaterialApp(
    home: BootstrapFailurePage(
      error: 'first failure',
      onRetry: onRetry,
      onQuit: onQuit ?? () {},
      showQuit: true,
    ),
  );

  testWidgets('a retry that fails again keeps the error, Retry and Quit', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      page(
        onRetry: () async {
          attempts++;
          throw StateError('failure $attempts');
        },
      ),
    );
    for (var i = 1; i <= 2; i++) {
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('failure $i'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Quit'), findsOneWidget);
    }
    expect(attempts, 2);
  });

  testWidgets('a retry that succeeds is called once', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(page(onRetry: () async => attempts++));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 1);
  });

  testWidgets('taps during a retry in progress start no second attempt', (
    tester,
  ) async {
    var attempts = 0;
    final done = Completer<void>();
    await tester.pumpWidget(
      page(
        onRetry: () {
          attempts++;
          return done.future;
        },
      ),
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Retrying...'), findsOneWidget);
    await tester.tap(find.text('Retrying...'), warnIfMissed: false);
    await tester.pump();
    expect(attempts, 1);
    done.complete();
    await tester.pumpAndSettle();
    expect(attempts, 1);
  });
}
