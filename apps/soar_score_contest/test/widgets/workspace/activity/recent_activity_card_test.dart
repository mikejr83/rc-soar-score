import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_entry.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_facts.dart';
import 'package:soar_score_contest/widgets/workspace/activity/recent_activity_card.dart';

import '../../../support/matrix_test_support.dart';

Future<void> _pump(
  WidgetTester tester,
  ActivityFacts? activity, {
  VoidCallback? onRetry,
  double width = 640,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecentActivityCard(
            contest: matrixContest(),
            activity: activity,
            onRetry: onRetry,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('lists the events newest first with actor and time', (
    tester,
  ) async {
    await _pump(
      tester,
      ActivityFacts(
        entries: [
          ActivityEntry(
            kind: ActivityKind.complete,
            byYou: true,
            at: DateTime.utc(2026, 10, 18, 16, 40),
          ),
          ActivityEntry(
            kind: ActivityKind.openScoring,
            byYou: false,
            at: DateTime.utc(2026, 10, 17, 8, 40),
          ),
        ],
      ),
    );

    expect(find.text('Recent activity'), findsOneWidget);
    expect(
      find.text('You completed the contest. Participant scoring closed.'),
      findsOneWidget,
    );
    expect(find.text('Participant scoring was opened'), findsOneWidget);
    expect(find.textContaining('2026-10-18 '), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('You completed the contest. Participant scoring closed.')).dy,
      lessThan(
        tester
            .getTopLeft(find.text('Participant scoring was opened'))
            .dy,
      ),
    );
  });

  testWidgets('View all is off and says why', (tester) async {
    await _pump(
      tester,
      ActivityFacts(
        entries: [
          ActivityEntry(
            kind: ActivityKind.lock,
            byYou: true,
            at: DateTime.utc(2026, 10, 18, 16, 40),
          ),
        ],
      ),
    );

    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('activity-view-all')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('The full activity log is not available yet.'), findsOne);
  });

  testWidgets('shows the empty state', (tester) async {
    await _pump(tester, ActivityFacts.none);

    expect(find.text('Nothing has happened yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-view-all')), findsNothing);
  });

  testWidgets('shows the loading state', (tester) async {
    await _pump(tester, null);

    expect(find.text('Loading recent activity…'), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    var retried = 0;
    await _pump(tester, ActivityFacts.unavailable, onRetry: () => retried++);

    expect(find.text('Recent activity could not be loaded.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('activity-retry')));
    expect(retried, 1);
  });

  testWidgets('fits a narrow window', (tester) async {
    await _pump(
      tester,
      ActivityFacts(
        entries: [
          ActivityEntry(
            kind: ActivityKind.complete,
            byYou: true,
            at: DateTime.utc(2026, 10, 18, 16, 40),
          ),
        ],
      ),
      width: 320,
    );

    expect(tester.takeException(), isNull);
  });
}
