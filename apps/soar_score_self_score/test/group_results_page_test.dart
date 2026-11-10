import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/pages/group_results_page.dart';
import 'package:soar_score_self_score/widgets/group_result_tile.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SelfScoreScope(
      repository: const SampleSelfScoreRepository(),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: GroupResultsPage(
          contestId: SampleData.contestId,
          pilotId: '12',
          roundId: '4',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every component gets its own column', (tester) async {
    await _pump(tester, const Size(800, 2400));
    for (final label in [
      'Pilot and flight',
      'Time',
      'Height',
      'Landing',
      'Raw',
      'Score',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // Raw and score come from different server fields and can differ.
    expect(find.text('876'), findsOneWidget);
    expect(find.text('863'), findsOneWidget);
    // The landing column is the points awarded, not the label.
    expect(find.text('100'), findsOneWidget);
    expect(find.text('50'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the fixed table scrolls sideways on a phone', (tester) async {
    await _pump(tester, const Size(390, 844));
    // The page padding is 16 on each side.
    expect(GroupResultColumns.all, greaterThan(390 - 32));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    // No overflow: the table scrolls instead of spilling off the screen.
    expect(tester.takeException(), isNull);
    // The pilot name still sits with the table.
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('(you)'), findsOneWidget);
  });

  testWidgets('a row with no score shows no value and says so', (tester) async {
    await _pump(tester, const Size(800, 2400));
    expect(find.text('Kate Brooks'), findsOneWidget);
    expect(find.text('No score yet'), findsOneWidget);
    expect(find.text('Not in the standings for this round.'), findsOneWidget);
    // Every value cell of the unscored row is a dash.
    expect(find.text('–'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
