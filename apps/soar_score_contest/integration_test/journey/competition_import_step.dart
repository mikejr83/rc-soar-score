import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/pump_until_gone.dart';
import 'gs_fixture_file_native.dart'
    if (dart.library.js_interop) 'gs_fixture_file_web.dart';
import 'journey.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

const _spring = 'E2E GS Spring Open';

GliderScoreImportResult _snapshot({int scoredRounds = 2}) {
  Map<String, Object?> comp(int no, String name, String cls, String date) => {
    'CompNo': no,
    'CompName': name,
    'GSCompClass': cls,
    'CompDate': date,
  };
  final tables = <String, List<Map<String, Object?>>>{
    'Comps': [
      comp(1, _spring, 'F5J', '06/14/26 00:00:00'),
      comp(2, 'E2E GS Old F3J', 'F3J', '05/01/25 00:00:00'),
      comp(3, 'E2E GS Empty Cup', 'F5J', '08/09/26 00:00:00'),
    ],
    'CompPilots': [
      {'CompNo': 1, 'PilotNo': 1},
      {'CompNo': 1, 'PilotNo': 2},
      {'CompNo': 2, 'PilotNo': 1},
    ],
    'Pilots': [
      {
        'PilotNo': 1,
        'FirstName': 'Hal',
        'LastName': 'Hangtime',
        'Email': 'hal.hangtime@e2e.example',
      },
      {
        'PilotNo': 2,
        'FirstName': 'Ida',
        'LastName': 'Ironwing',
        'Email': 'ida.ironwing@e2e.example',
      },
    ],
    'Dur': [
      for (final no in [1, 3]) {'CompNo': no, 'durTargetTime': 600},
    ],
    // The Spring Open: two rounds, one group of two. The scores are what the
    // F5J calculator gives for these flights, so the check against
    // GliderScore's own score passes: 9:00 and 100 m high with a 50 point
    // landing is 540, 8:50 and 60 m with a 30 point landing is 510.
    'Scores': [
      for (var round = 1; round <= 2; round++)
        for (final pilot in [1, 2])
          {
            'CompNo': 1,
            'TaskNo': 1,
            'RoundNo': round,
            'GroupNo': 1,
            'ReFlightNo': 0,
            'PilotNo': pilot,
            'SeqNo': pilot,
            'OriginalRoundNo': round,
            if (round <= scoredRounds) ...{
              'Updated': 'True',
              'Time1Mins': pilot == 1 ? 900 : 830,
              'FlightScoreDeduction': pilot == 1 ? 100 : 60,
              'Landing': pilot == 1 ? 50 : 30,
              'RawScore': pilot == 1 ? 540 : 510,
            } else
              'Updated': 'False',
          },
    ],
  };
  return GliderScoreImportResult(
    id: Id.create(),
    sourceDbFile: 'E2E Contests.mdb',
    tables: [
      for (final e in tables.entries)
        GliderScoreTable(
          name: e.key,
          rows: e.value,
          rowCount: e.value.length,
          rowCapExceeded: false,
        ),
    ],
  );
}

/// Restores a GliderScore competition as a contest with its draw and scores,
/// restores the same file again (nothing changes), then a later copy of it in
/// which the last round is not scored yet, which replaces the contest in
/// place. Native only: the web build holds no local data.
///
/// The file chooser and the GliderScore reader are replaced, as for the pilot
/// import; the file itself is a stand-in that only gives the import something
/// to fingerprint. Everything after (review, saving, the contest) is real,
/// including the check of every score against GliderScore's.
Future<void> importCompetitionsFromGliderScore(
  WidgetTester tester,
  JourneyContext data,
) async {
  final l10n = AppLocalizationsEn();
  final path = await writeGliderScoreFixtureFile('E2E competitions 1');

  var scoredRounds = 2;
  final original = GliderScoreFiles.current;
  addTearDown(() => GliderScoreFiles.current = original);
  GliderScoreFiles.current = GliderScoreFiles(
    choose: () async => path,
    read: (client, _) async => _snapshot(scoredRounds: scoredRounds),
  );

  Future<void> toResults() async {
    await tapVisible(tester, _key('competition-import-continue'));
    await pumpUntilFound(tester, _key('pilot-import-row-1'));
    await tapVisible(tester, _key('competition-import-continue'));
    await pumpUntilFound(tester, _key('competition-import-confirm'));
    await tapVisible(tester, _key('competition-import-confirm'));
    await pumpUntilFound(tester, _key('competition-import-result'));
  }

  String status(String id) =>
      tester.widget<Text>(_key('status-$id-value')).data!;

  await goToMainPage(tester);

  // First run: the list, one competition chosen, a blocked and a skipped one.
  await tapVisible(tester, _key('import-competitions'));
  await pumpUntilFound(tester, _key('competition-import-row-1'));
  expect(find.text(l10n.competitionImportChosenCount(0)), findsOneWidget);
  // Newest start first: Empty Cup (Aug 2026), Spring Open (Jun 2026), Old F3J.
  double top(int no) =>
      tester.getTopLeft(_key('competition-import-row-$no')).dy;
  expect(top(3), lessThan(top(1)));
  expect(top(1), lessThan(top(2)));
  expect(
    find.textContaining(l10n.competitionImportReasonClassNotSupportedYet),
    findsOneWidget,
  );
  expect(
    find.textContaining(l10n.competitionImportReasonNoParticipants),
    findsOneWidget,
  );
  // A blocked competition cannot be chosen.
  await tapVisible(tester, _key('competition-import-row-3'));
  expect(find.text(l10n.competitionImportChosenCount(0)), findsOneWidget);
  await tapVisible(tester, _key('competition-import-row-1'));
  expect(find.text(l10n.competitionImportChosenCount(1)), findsOneWidget);
  // Every flown round is scored, so the contest ends Completed unless the
  // director says otherwise.
  expect(
    tester
        .widget<CheckboxListTile>(_key('competition-import-completed-1'))
        .value,
    isTrue,
  );
  await tapVisible(tester, _key('competition-import-continue'));
  await pumpUntilFound(tester, _key('pilot-import-row-1'));
  await tapVisible(tester, _key('competition-import-continue'));
  await pumpUntilFound(tester, _key('competition-import-confirm'));
  // The summary names the scores and the check against GliderScore.
  expect(find.text(l10n.competitionImportSummaryFlights(4)), findsOneWidget);
  expect(find.text(l10n.competitionImportSummaryCompleted(1)), findsOneWidget);
  expect(find.text(l10n.competitionImportSummaryCheck), findsOneWidget);
  await tapVisible(tester, _key('competition-import-confirm'));
  await pumpUntilFound(tester, _key('competition-import-result'));
  expect(
    find.text(l10n.competitionImportResultRestored(_spring, 4)),
    findsOneWidget,
  );
  await tapVisible(tester, _key('competition-import-open-1'));
  await pumpUntilGone(tester, _key('competition-import-dialog'));
  await pumpUntilFound(tester, find.text('Workspace'));
  // Open lands on Configuration; the status is on the Workspace page.
  await tapRail(tester, 'Workspace');
  await pumpUntilFound(tester, _key('workspace-banner-imported'));
  expect(find.textContaining(l10n.importedContestNoteBody), findsOneWidget);
  // The scores came with it and the contest is closed.
  await pumpUntilFound(tester, _key('status-lifecycle-value'));
  expect(status('lifecycle'), 'Completed');
  expect(status('scoring'), 'Closed');
  await goToMainPage(tester);
  // The list builds only the rows in view, so scroll to the new contest.
  final row = find.descendant(
    of: find.byType(ListTile),
    matching: find.text(_spring),
  );
  await scrollListTo(tester, row);
  await pumpUntilFound(tester, row);
  // The detail pane marks the contest as imported.
  await tapVisible(tester, row);
  await pumpUntilFound(tester, _key('imported-label'));
  expect(find.text(l10n.importedChipLabel), findsOneWidget);
  // A narrow window shows the detail alone; go back to the list.
  if (_key('contest-detail-back').evaluate().isNotEmpty) {
    await tapVisible(tester, _key('contest-detail-back'));
    await pumpUntilFound(tester, row);
  }

  // Second run of the same file: the contest is up to date, nothing is
  // written again.
  await tapVisible(tester, _key('import-competitions'));
  await pumpUntilFound(tester, _key('competition-import-row-1'));
  expect(
    find.textContaining(l10n.competitionImportTargetUnchanged),
    findsOneWidget,
  );
  await tapVisible(tester, _key('competition-import-row-1'));
  await toResults();
  expect(
    find.text(l10n.competitionImportResultUnchanged(_spring)),
    findsOneWidget,
  );
  await tapVisible(tester, _key('competition-import-done'));
  await pumpUntilGone(tester, _key('competition-import-dialog'));
  await scrollListTo(tester, row);
  expect(row, findsOneWidget);

  // Third run: a later copy of the file in which the last round is not
  // scored yet. The contest it made is replaced in place, and left open.
  scoredRounds = 1;
  await tapVisible(tester, _key('import-competitions'));
  await pumpUntilFound(tester, _key('competition-import-row-1'));
  expect(
    find.textContaining(l10n.competitionImportTargetReplaces(_spring)),
    findsOneWidget,
  );
  await tapVisible(tester, _key('competition-import-row-1'));
  // The unscored round is a trailing unflown one, not a partly flown one, so
  // every flown round is scored and Completed starts on. Untick it so the
  // contest stays open.
  expect(
    tester
        .widget<CheckboxListTile>(_key('competition-import-completed-1'))
        .value,
    isTrue,
  );
  await tapVisible(tester, _key('competition-import-completed-1'));
  expect(
    tester
        .widget<CheckboxListTile>(_key('competition-import-completed-1'))
        .value,
    isFalse,
  );
  await toResults();
  expect(
    find.text(l10n.competitionImportResultReplaced(_spring, 2)),
    findsOneWidget,
  );
  await tapVisible(tester, _key('competition-import-open-1'));
  await pumpUntilGone(tester, _key('competition-import-dialog'));
  await pumpUntilFound(tester, find.text('Workspace'));
  await tapRail(tester, 'Workspace');
  await pumpUntilFound(tester, _key('status-lifecycle-value'));
  expect(status('lifecycle'), 'Running');
  await goToMainPage(tester);
}
