import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/reports/standings/standings_table_view.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
import '../support/pump_until_gone.dart';
import 'export_step.dart';
import 'journey.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Phase 6: complete the contest and check the results a director publishes.
Future<void> runFinishPhase(Journey journey, JourneyContext data) async {
  final tester = journey.tester;

  Future<void> inContest(Future<void> Function() body) async {
    await goToMainPage(tester);
    await openContest(tester, data.contestName);
    await body();
  }

  await journey.step(
    'Complete: nothing is left open, so the contest completes and closes',
    () => inContest(() async {
      await pumpUntilFound(tester, _key('status-summary'));
      await tapVisible(tester, _key('control-complete'));
      await pumpUntilFound(tester, _key('complete-dialog'));
      // Every flight is scored or retired, and every round was flown.
      expect(_key('complete-dialog-missing'), findsNothing);
      expect(_key('complete-dialog-unflown'), findsNothing);
      await tester.tap(_key('complete-dialog-confirm'));
      await pumpUntilGone(tester, _key('complete-dialog'));
      await pumpUntilFound(tester, find.text('Completed'));

      String status(String id) =>
          tester.widget<Text>(_key('status-$id-value')).data!;
      expect(status('lifecycle'), 'Completed');
      expect(status('scoring'), 'Closed');
      // The next-step card dates the completion from the audit trail.
      await pumpUntilFound(
        tester,
        find.textContaining('The contest was completed'),
      );
      expect(
        tester.widget<FilledButton>(_key('control-complete')).onPressed,
        isNull,
      );
      expect(_key('control-lifecycle-reason'), findsOneWidget);
    }),
  );

  await journey.step(
    'Overall Standings: every pilot ranked, no Provisional, options apply',
    () => inContest(() async {
      await tapRail(tester, 'Reports');
      await pumpUntilFound(tester, find.text('Reports are built from'));
      await tapVisible(tester, _key('report-open-standings'));
      await pumpUntilFound(tester, find.text('Rank'));

      // The heading, the columns and a column for each round.
      expect(find.textContaining('Overall Results - '), findsWidgets);
      expect(find.text('Total'), findsWidgets);
      for (var round = 1; round <= data.rounds; round++) {
        expect(find.text('R$round'), findsWidgets);
      }
      expect(find.text('Raw'), findsNothing);

      // Every score is final: no Provisional switch, but Flight details.
      expect(
        find.widgetWithText(CheckboxListTile, 'Flight details'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CheckboxListTile, 'Provisional'),
        findsNothing,
      );

      // The ranking follows the flights the journey entered: the pilot who
      // flew longest and lowest wins (possibly tied with another group's
      // winner), the pilot who flew least and retired last, and nobody
      // ranks above a pilot with a higher total.
      final rows = tester
          .widgetList<StandingsTableView>(find.byType(StandingsTableView))
          .first
          .table
          .rows;
      final names = rows.map((r) => r.pilot.givenSurname).toList();
      expect(names, unorderedEquals(data.pilotNames));
      final best = rows.firstWhere(
        (r) => r.pilot.givenSurname == data.pilotNames.first,
      );
      final worst = rows.firstWhere(
        (r) => r.pilot.givenSurname == data.pilotNames.last,
      );
      expect(best.place, 1);
      expect(worst.place, data.pilotNames.length);
      expect(rows.where((r) => r.place == worst.place), hasLength(1));
      for (var i = 1; i < rows.length; i++) {
        expect(rows[i].place, greaterThanOrEqualTo(rows[i - 1].place));
        expect(rows[i].total, lessThanOrEqualTo(rows[i - 1].total));
      }
      // The retired pilot has no score in the round they left.
      expect(worst.cells[data.rounds]?.score ?? 0, 0);

      // An option adds its column at once.
      await tapVisible(
        tester,
        find.widgetWithText(CheckboxListTile, 'Raw score'),
      );
      await pumpUntilFound(tester, find.text('Raw'));

      await tapVisible(tester, _key('viewer-back'));
      await pumpUntilFound(tester, find.text('Reports are built from'));
    }),
  );

  await journey.step(
    'Export: the contest is saved to a file (native)',
    () => exportContestToFile(tester, data),
    nativeOnly: true,
  );
}
