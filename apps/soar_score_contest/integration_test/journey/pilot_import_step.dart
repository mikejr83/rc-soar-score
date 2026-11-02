import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/participant_extras.dart';
import '../support/participant_form.dart';
import '../support/pump_until_gone.dart';
import 'journey.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Imports pilots from a GliderScore file into the participants manager,
/// twice. Native only: the web build holds no local participants.
///
/// The file chooser and the GliderScore reader are replaced because a journey
/// cannot drive the system dialog or has an `.mdb` to read; everything after
/// that (review, saving, the list) is the real thing.
Future<void> importPilotsFromGliderScore(
  WidgetTester tester,
  JourneyContext data,
) async {
  final l10n = AppLocalizationsEn();
  final zoe = data.roster.first;
  final milo = data.roster[1];
  const newPilot = (first: 'Gina', last: 'Glidertest');
  const gsEmail = 'gina.glidertest@e2e.example';

  final original = GliderScoreFiles.current;
  addTearDown(() => GliderScoreFiles.current = original);
  GliderScoreFiles.current = GliderScoreFiles(
    choose: () async => r'C:\E2E\Contest.mdb',
    read: (client, path) async => GliderScoreImportResult(
      id: Id.create(),
      sourceDbFile: 'Contest.mdb',
      tables: [
        GliderScoreTable(
          name: 'Pilots',
          rowCount: 4,
          rowCapExceeded: false,
          rows: [
            {
              'PilotNo': 1,
              'FirstName': newPilot.first,
              'LastName': newPilot.last,
              'Email': gsEmail,
              'Club': 'E2E GS Club',
              'Country': 'USA',
            },
            // The same person as a participant the journey made, found by email.
            {
              'PilotNo': 2,
              'FirstName': zoe.first,
              'LastName': zoe.last,
              'Email': zoe.email,
              'Club': 'E2E GS Club',
            },
            // Only the name matches, so a person decides.
            {'PilotNo': 3, 'FirstName': milo.first, 'LastName': milo.last},
            // GliderScore's own test pilot.
            {'PilotNo': 4, 'FirstName': 'Test', 'LastName': 'ZZPilot'},
          ],
        ),
      ],
    ),
  );

  await goToMainPage(tester);
  await openParticipantsManager(tester);

  // First import: one new, one updated, one left for a decision (skipped).
  await tapVisible(tester, _key('import-pilots'));
  await pumpUntilFound(tester, _key('pilot-import-confirm'));
  expect(find.text(l10n.pilotImportNewHeading(1)), findsOneWidget);
  expect(find.text(l10n.pilotImportUpdateHeading(1)), findsOneWidget);
  expect(find.text(l10n.pilotImportMaybeHeading(1)), findsOneWidget);
  expect(find.textContaining('1 GliderScore test pilot'), findsOneWidget);
  await tapVisible(tester, _key('pilot-import-confirm'));
  await pumpUntilFound(tester, _key('pilot-import-result'));
  expect(find.text(l10n.pilotImportDone(1, 1, 0, 1)), findsOneWidget);
  await tapVisible(tester, _key('pilot-import-done'));
  await pumpUntilGone(tester, _key('pilot-import-dialog'));

  final name = '${newPilot.first} ${newPilot.last}';
  await searchParticipants(tester, name);
  final row = participantRow(name);
  await pumpUntilFound(tester, row);
  await tapVisible(tester, row);
  await pumpUntilFound(tester, find.text(gsEmail));
  expect(find.text('E2E GS Club'), findsWidgets);

  // Second import of the same file: nobody is added twice.
  await tapVisible(tester, _key('import-pilots'));
  await pumpUntilFound(tester, _key('pilot-import-confirm'));
  expect(find.text(l10n.pilotImportNewHeading(1)), findsNothing);
  expect(find.text(l10n.pilotImportUpdateHeading(2)), findsOneWidget);
  await tapVisible(tester, _key('pilot-import-confirm'));
  await pumpUntilFound(tester, _key('pilot-import-result'));
  expect(find.text(l10n.pilotImportDone(0, 0, 2, 1)), findsOneWidget);
  await tapVisible(tester, _key('pilot-import-done'));
  await pumpUntilGone(tester, _key('pilot-import-dialog'));
}
