import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// A ready demo contest: a drawn matrix, nothing scored yet.
const _contest = 'Front Range F5J Open';

bool _enabled(WidgetTester tester, String report) =>
    tester
        .widget<ButtonStyleButton>(find.byKey(ValueKey('report-open-$report')))
        .onPressed !=
    null;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the Reports page lists the reports and their readiness', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);

    await tapRail(tester, 'Reports');
    await pumpUntilFound(tester, find.text('Reports are built from'));

    // The strip says what the reports are built from.
    expect(find.text('Lifecycle'), findsOneWidget);
    expect(find.text('Scoring progress'), findsOneWidget);
    expect(find.text('Standings produced now would be'), findsOneWidget);

    // All four reports are listed under their groups.
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Documents to print'), findsOneWidget);
    for (final title in [
      'Overall Standings',
      'Draw Matrix',
      'Scoring Sheet',
      'Pilot Scoring Cards',
    ]) {
      expect(find.text(title), findsOneWidget);
    }

    // The matrix is drawn but nothing is scored: the documents can be opened
    // and the standings say why they cannot.
    for (final report in ['matrix', 'sheet', 'cards']) {
      expect(_enabled(tester, report), isTrue, reason: report);
    }
    expect(_enabled(tester, 'standings'), isFalse);
    expect(find.text('No scores have been entered yet.'), findsOneWidget);

    // The reason links to the page that fixes it.
    await tapVisible(tester, find.text('Open Scoring'));
    await pumpUntilFound(tester, find.textContaining('Round 1 of'));
  });

  // Native opens the viewer in place; the web opens a new tab, which a journey
  // cannot drive, so this part is native-only.
  testWidgets('Open shows the report viewer with a way back (native)', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);
    await tapRail(tester, 'Reports');
    await pumpUntilFound(tester, find.text('Reports are built from'));

    await tapVisible(tester, find.byKey(const ValueKey('report-open-matrix')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('viewer-title')));
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('viewer-title'))).data,
      'Draw Matrix',
    );
    // The paper sheet, its filter and page panel, and Print.
    expect(find.textContaining('Page 1 of'), findsWidgets);
    expect(find.text('Print'), findsWidgets);

    await tapVisible(tester, find.byKey(const ValueKey('viewer-back')));
    await pumpUntilFound(tester, find.text('Reports are built from'));
  }, skip: kIsWeb);

  // The Overall Standings report reads the stored results of a contest that is
  // being scored. Native opens it in place; the web opens a new tab, which a
  // journey cannot drive, so this journey is native-only.
  testWidgets(
    'Overall Standings shows the standings and follows its options (native)',
    (tester) async {
      await openMainPage(tester);
      await openContest(tester, 'Mountain States Team F5J');
      await tapRail(tester, 'Reports');
      await pumpUntilFound(tester, find.text('Reports are built from'));

      await tapVisible(
        tester,
        find.byKey(const ValueKey('report-open-standings')),
      );
      await pumpUntilFound(tester, find.text('Rank'));

      // The heading, the columns and the pilots in their stored order.
      expect(find.textContaining('Overall Results - '), findsWidgets);
      expect(find.text('Total'), findsWidgets);
      expect(find.text('R1'), findsWidgets);
      expect(find.text('Raw'), findsNothing);

      // An option adds its column at once.
      await tapVisible(
        tester,
        find.widgetWithText(CheckboxListTile, 'Raw score'),
      );
      await pumpUntilFound(tester, find.text('Raw'));

      await tapVisible(tester, find.byKey(const ValueKey('viewer-back')));
      await pumpUntilFound(tester, find.text('Reports are built from'));
    },
    skip: kIsWeb,
  );
}
