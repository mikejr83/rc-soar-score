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

GliderScoreImportResult _snapshot() {
  Map<String, Object?> comp(int no, String name, String cls) => {
    'CompNo': no,
    'CompName': name,
    'GSCompClass': cls,
    'CompDate': '06/14/26 00:00:00',
  };
  final tables = <String, List<Map<String, Object?>>>{
    'Comps': [
      comp(1, _spring, 'F5J'),
      comp(2, 'E2E GS Old F3J', 'F3J'),
      comp(3, 'E2E GS Empty Cup', 'F5J'),
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
    // The drawn flights of the Spring Open: two rounds, one group of two.
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

/// Imports a GliderScore competition as a contest, imports the same file
/// again (refused), then adds the draw of the imported competition, twice.
/// Native only: the web build holds no local data.
///
/// The file chooser and the GliderScore reader are replaced, as for the pilot
/// import; the file itself is a stand-in that only gives the import something
/// to fingerprint. Everything after (review, saving, the contest) is real.
Future<void> importCompetitionsFromGliderScore(
  WidgetTester tester,
  JourneyContext data,
) async {
  final l10n = AppLocalizationsEn();
  final path = await writeGliderScoreFixtureFile('E2E competitions 1');

  final original = GliderScoreFiles.current;
  addTearDown(() => GliderScoreFiles.current = original);
  GliderScoreFiles.current = GliderScoreFiles(
    choose: () async => path,
    read: (client, _) async => _snapshot(),
  );

  Future<void> toResults() async {
    await tapVisible(tester, _key('competition-import-continue'));
    await pumpUntilFound(tester, _key('pilot-import-row-1'));
    await tapVisible(tester, _key('competition-import-continue'));
    await pumpUntilFound(tester, _key('competition-import-confirm'));
    await tapVisible(tester, _key('competition-import-confirm'));
    await pumpUntilFound(tester, _key('competition-import-result'));
  }

  await goToMainPage(tester);

  // First run: the list, one competition chosen, a blocked and a skipped one.
  await tapVisible(tester, _key('import-competitions'));
  await pumpUntilFound(tester, _key('competition-import-row-1'));
  expect(find.text(l10n.competitionImportChosenCount(0)), findsOneWidget);
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
  // No contest yet, so there is no draw to add.
  expect(_key('competition-import-draw-1'), findsNothing);
  expect(_key('competition-import-draw-refused-1'), findsNothing);
  await toResults();
  expect(
    find.text(l10n.competitionImportResultImported(_spring)),
    findsOneWidget,
  );
  await tapVisible(tester, _key('competition-import-open-1'));
  await pumpUntilGone(tester, _key('competition-import-dialog'));
  await pumpUntilFound(tester, find.text('Workspace'));
  // Open lands on Configuration; the note is on the Workspace page.
  await tapRail(tester, 'Workspace');
  // The workspace says where the contest came from and what it lacks.
  await pumpUntilFound(tester, _key('workspace-banner-imported'));
  expect(find.textContaining(l10n.importedContestNoteNoDraw), findsOneWidget);
  await goToMainPage(tester);
  // The list builds only the rows in view, so scroll to the new contest.
  final row = find.descendant(
    of: find.byType(ListTile),
    matching: find.text(_spring),
  );
  await scrollListTo(tester, row);
  await pumpUntilFound(tester, row);

  // Second run of the same file: refused, nothing is added twice.
  await tapVisible(tester, _key('import-competitions'));
  await pumpUntilFound(tester, _key('competition-import-row-1'));
  await tapVisible(tester, _key('competition-import-row-1'));
  await toResults();
  expect(find.textContaining('$_spring: already imported on'), findsOneWidget);
  expect(
    find.text(l10n.competitionImportResultImported(_spring)),
    findsNothing,
  );
  await tapVisible(tester, _key('competition-import-done'));
  await pumpUntilGone(tester, _key('competition-import-dialog'));
  await scrollListTo(tester, row);
  expect(row, findsOneWidget);

  // Third run: the competition imported before offers its draw, with the
  // counts of the dry run. Adding it needs no pilot review.
  await tapVisible(tester, _key('import-competitions'));
  await pumpUntilFound(tester, _key('competition-import-draw-1'));
  expect(
    find.textContaining(l10n.competitionImportDrawDetails(2, 1, 2)),
    findsOneWidget,
  );
  expect(find.text(l10n.competitionImportChosenCount(0)), findsOneWidget);
  await tapVisible(tester, _key('competition-import-draw-1'));
  expect(find.text(l10n.competitionImportChosenCount(1)), findsOneWidget);
  await tapVisible(tester, _key('competition-import-continue'));
  await pumpUntilFound(tester, _key('competition-import-confirm'));
  expect(find.text(l10n.competitionImportSummaryDraws(1)), findsOneWidget);
  await tapVisible(tester, _key('competition-import-confirm'));
  await pumpUntilFound(tester, _key('competition-import-result'));
  expect(
    find.text(l10n.competitionImportResultDrawAdded(_spring, 2, 4)),
    findsOneWidget,
  );
  await tapVisible(tester, _key('competition-import-open-draw-1'));
  await pumpUntilGone(tester, _key('competition-import-dialog'));
  await pumpUntilFound(tester, find.text('Workspace'));
  // The note now says the draw is GliderScore's.
  await tapRail(tester, 'Workspace');
  await pumpUntilFound(
    tester,
    find.textContaining(l10n.importedContestNoteDraw),
  );
  expect(find.textContaining(l10n.importedContestNoteNoDraw), findsNothing);
  await goToMainPage(tester);

  // Fourth run: the contest has its draw now, so the offer is refused.
  await tapVisible(tester, _key('import-competitions'));
  await pumpUntilFound(tester, _key('competition-import-draw-refused-1'));
  expect(find.text(l10n.competitionImportDrawReasonDrawn), findsOneWidget);
  expect(_key('competition-import-draw-1'), findsNothing);
  await tapVisible(tester, find.text(l10n.cancelButton));
  await pumpUntilGone(tester, _key('competition-import-dialog'));
}
