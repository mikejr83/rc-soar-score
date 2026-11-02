import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/widgets/matrix/pilot_row_tile.dart';

import '../support/configuration_fields.dart';
import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
import '../support/pump_until_gone.dart';
import 'journey.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Phase 4: set the contest up before the run (configuration, roles, landing
/// tables, matrix draw) and check the reports a director prints before it.
/// Printing itself is not part of the journey.
Future<void> runSetupPhase(Journey journey, JourneyContext data) async {
  final tester = journey.tester;

  Future<void> inContest(Future<void> Function() body) async {
    await goToMainPage(tester);
    await openContest(tester, data.contestName);
    await body();
  }

  await journey.step(
    'Configuration: scoring settings are edited and saved',
    () => inContest(() => _editConfiguration(tester)),
  );
  await journey.step(
    'Participants: the contest lists its pilots with Save off',
    () => inContest(() async {
      await tapRail(tester, 'Participants');
      await pumpUntilFound(tester, _key('participants-count'));
      expect(
        tester.widget<Text>(_key('participants-count')).data,
        matches(r'^\d+ pilots?'),
      );
      // The contest has no optional participant options, so no Class column.
      expect(find.text('Class *'), findsNothing);
      for (final person in data.demoPilots) {
        expect(find.text(person), findsOneWidget);
      }
      // Save is always there, off, with its reason.
      expect(
        tester.widget<FilledButton>(_key('save-participants')).onPressed,
        isNull,
      );
      expect(find.text('No changes to save.'), findsOneWidget);
    }),
  );
  await journey.step(
    'Participants: a class is edited, discarded, then saved',
    () async {
      await goToMainPage(tester);
      // The copied contest keeps its pilots' classes (phase 3).
      await openContest(tester, 'E2E Copied Classes');
      await tapRail(tester, 'Participants');
      await pumpUntilFound(tester, _key('participants-count'));
      final classField = find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('class-'),
          description: 'a class cell',
        ),
        matching: find.byType(TextField),
      );
      final save = _key('save-participants');

      // An edit marks the row and turns Save on.
      await enterIn(tester, classField.first, 'Zz Class');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpUntilFound(
        tester,
        find.text('Unsaved changes to 1 participant'),
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      // Discard puts the saved value back.
      await tapVisible(tester, _key('discard-participants'));
      await pumpUntilFound(tester, find.text('No changes to save.'));

      // Save stores the change and says so.
      await enterIn(tester, classField.first, 'Zz Class');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpUntilFound(
        tester,
        find.text('Unsaved changes to 1 participant'),
      );
      await tapVisible(tester, save);
      await pumpUntilFound(tester, find.text('1 participant saved.'));
      await pumpUntilFound(tester, find.text('No changes to save.'));
      expect(
        tester.widget<TextField>(classField.first).controller!.text,
        'Zz Class',
      );
    },
  );
  await journey.step(
    'Configuration: scoring access and the lock point to the Workspace',
    () => inContest(() async {
      await openConfiguration(tester);
      for (final title in ['Scoring access', 'Administration lock']) {
        expect(find.text(title, skipOffstage: false), findsWidgets);
      }
      expect(
        find.byKey(const ValueKey("state-scoringAccess"), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey("state-adminLock"), skipOffstage: false),
        findsOneWidget,
      );
      // A new contest has participant scoring closed and administration
      // unlocked.
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey('state-scoringAccess'),
                skipOffstage: false,
              ),
            )
            .data,
        'Closed',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey('state-adminLock'),
                skipOffstage: false,
              ),
            )
            .data,
        'Unlocked',
      );
      await tapVisible(tester, find.text('Change in Workspace').first);
      await pumpUntilFound(tester, find.text('Setup checklist'));
    }),
  );
  await journey.step('Roles: a role is created, renamed and deleted', () async {
    await goToMainPage(tester);
    await _rolesManager(tester);
  });
  await journey.step(
    'Landings: a table is created, copied, abandoned and deleted',
    () async {
      await goToMainPage(tester);
      await _landingsManager(tester);
    },
  );
  await journey.step(
    'Matrix: the undrawn contest is drawn with the wizard options',
    () => inContest(() => _drawMatrix(tester, data)),
  );
  await journey.step(
    'Matrix: a pilot is moved to another group and the grid says so',
    () => inContest(() => _movePilot(tester)),
  );
  await journey.step(
    'Matrix: a contest that arrives drawn shows its grid and no Draw action',
    () async {
      await goToMainPage(tester);
      await openContest(tester, 'Front Range F5J Open');
      await tapRail(tester, 'Matrix');
      await pumpUntilFound(tester, _key('fairness-score'));
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Group A'), findsWidgets);
      expect(_key('draw-button'), findsNothing);
      expect(find.text('No matrix drawn yet'), findsNothing);
    },
  );
  await journey.step(
    'Participants: a pilot added to a drawn contest is offered a redraw, '
    'or put in every round',
    () async {
      await goToMainPage(tester);
      // A demo contest that arrives drawn, ready and without scores.
      await openContest(tester, 'Front Range F5J Open');
      await tapRail(tester, 'Participants');
      await pumpUntilFound(tester, _key('participants-count'));
      final newcomer = data.roster.last;
      final name = '${newcomer.first} ${newcomer.last}';
      await _addFromSearch(tester, newcomer);

      // No scores yet, so the director may redraw the matrix with them.
      await pumpUntilFound(tester, find.text('Redraw the matrix with $name?'));
      // Keeping the matrix puts them in the last group that can take them
      // in every round.
      await tapVisible(tester, _key('redraw-keep'));
      await pumpUntilFound(tester, _key('banner-placement'));
      expect(find.text(name), findsWidgets);
    },
  );
  await journey.step(
    'Participants: a pilot is refused while every group of a round is full',
    () async {
      await goToMainPage(tester);
      // The demo contest flies 14 pilots in 3 groups, so each group holds 5.
      // The previous step took the last open seat of every round.
      await openContest(tester, 'Front Range F5J Open');
      await tapRail(tester, 'Participants');
      await pumpUntilFound(tester, _key('participants-count'));
      final blocked = data.roster[data.rosterPilots];
      final name = '${blocked.first} ${blocked.last}';
      await _addFromSearch(tester, blocked);

      await pumpUntilFound(tester, _key('banner-add-failed'));
      expect(find.text('Couldn’t add $name'), findsOneWidget);
      expect(find.textContaining('Round 1 has no group'), findsOneWidget);
      expect(find.textContaining('groups per round'), findsOneWidget);
      expect(find.textContaining('Nothing was added'), findsOneWidget);
      // Nothing was saved: the count is still the 14 demo pilots and the one
      // added before, and there is no offer to redraw or place them.
      expect(find.textContaining('15 pilots'), findsWidgets);
      expect(find.text('Redraw the matrix with $name?'), findsNothing);
    },
  );
  await journey.step(
    'Participants: removing an unscored pilot from a drawn contest takes '
    'them out of the draw and says it needs redoing',
    () async {
      await goToMainPage(tester);
      await openContest(tester, 'Front Range F5J Open');
      await tapRail(tester, 'Participants');
      await pumpUntilFound(tester, _key('participants-count'));
      // The previous step put this pilot in every round; they have no scores.
      final newcomer = data.roster.last;
      final name = '${newcomer.first} ${newcomer.last}';
      await pumpUntilFound(tester, find.text(name));
      await tapVisible(
        tester,
        find.byWidgetPredicate(
          (w) => w is Checkbox && w.semanticLabel == 'Select $name',
        ),
      );
      await tapVisible(tester, _key('remove-participants'));
      await pumpUntilFound(tester, _key('confirm-remove-draw'));
      expect(
        find.textContaining('Their places in it are removed too'),
        findsOneWidget,
      );
      await tapVisible(tester, _key('confirm-remove'));

      await pumpUntilFound(tester, _key('banner-redo-draw'));
      expect(find.text('The draw needs redoing'), findsOneWidget);
      expect(find.textContaining('$name was in the draw'), findsOneWidget);
      await pumpUntilGone(tester, find.text(name));

      // The notice leads to the Matrix page's redraw.
      await tapVisible(tester, find.text('Redo the draw'));
      await pumpUntilFound(tester, find.text('Redraw unscored rounds'));
    },
  );
  await journey.step(
    'Reports: readiness before the run',
    () => inContest(() async {
      await _openReports(tester);
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

      // The matrix is drawn but nothing is scored: the documents can be
      // opened and the standings say why they cannot.
      for (final report in ['matrix', 'sheet', 'cards']) {
        expect(_reportEnabled(tester, report), isTrue, reason: report);
      }
      expect(_reportEnabled(tester, 'standings'), isFalse);
      expect(find.text('No scores have been entered yet.'), findsOneWidget);

      // The reason links to the page that fixes it.
      await tapVisible(tester, find.text('Open Scoring'));
      await pumpUntilFound(tester, find.textContaining('Round 1 of'));
    }),
  );
  await journey.step(
    'Reports: the Draw Matrix viewer opens with a way back',
    () => inContest(() async {
      await _openReports(tester);
      await tapVisible(tester, _key('report-open-matrix'));
      await pumpUntilFound(tester, _key('viewer-title'));
      expect(tester.widget<Text>(_key('viewer-title')).data, 'Draw Matrix');
      // The paper sheet, its filter and page panel, and Print.
      expect(find.textContaining('Page 1 of'), findsWidgets);
      expect(find.text('Print'), findsWidgets);
      await tapVisible(tester, _key('viewer-back'));
      await pumpUntilFound(tester, find.text('Reports are built from'));
    }),
  );
  await journey.step(
    'Reports: a Draw Matrix option is remembered across reopenings',
    () => inContest(() async {
      await _openReports(tester);
      await tapVisible(tester, _key('report-open-matrix'));
      await pumpUntilFound(tester, _key('viewer-title'));
      final compact = find.widgetWithText(SwitchListTile, 'Compact mode');
      expect(tester.widget<SwitchListTile>(compact).value, isFalse);

      // Turning it on writes the account's stored options.
      await tapVisible(tester, compact);
      await tester.pump(const Duration(milliseconds: 300));

      // Back to Reports, then reopen: the option comes back on, and the URL
      // carries it.
      await tapVisible(tester, _key('viewer-back'));
      await pumpUntilFound(tester, find.text('Reports are built from'));
      await tapVisible(tester, _key('report-open-matrix'));
      await pumpUntilFound(tester, _key('viewer-title'));
      expect(tester.widget<SwitchListTile>(compact).value, isTrue);
      expect(currentRoute(tester), contains('f.cmp=1'));
    }),
  );
  await journey.step(
    'Reports: the Scoring Sheet shows blank grids and follows the options',
    () => inContest(() async {
      await _openReports(tester);
      await tapVisible(tester, _key('report-open-sheet'));
      await pumpUntilFound(tester, _key('viewer-title'));
      expect(tester.widget<Text>(_key('viewer-title')).data, 'Scoring Sheet');

      // The draw by round and group, ruled for writing, with the readout.
      await pumpUntilFound(tester, _key('sheet-readout'));
      expect(find.textContaining('Round 1'), findsWidgets);
      expect(find.textContaining('Working Time'), findsWidgets);
      expect(find.text('Reflight'), findsWidgets);

      // Nothing is scored yet, so Pre-fill says why it is off; an option
      // changes at once.
      expect(find.text('No scores have been entered yet.'), findsOneWidget);
      await tapVisible(tester, _key('sheet-validated'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.descendant(
                of: _key('sheet-validated'),
                matching: find.byType(CheckboxListTile),
              ),
            )
            .value,
        isFalse,
      );

      await tapVisible(tester, _key('viewer-back'));
      await pumpUntilFound(tester, find.text('Reports are built from'));
    }),
  );
  await journey.step(
    'Reports: Pilot Scoring Cards show a card per pilot and follow the choice',
    () => inContest(() async {
      await _openReports(tester);
      await tapVisible(tester, _key('report-open-cards'));
      await pumpUntilFound(tester, _key('viewer-title'));

      // A card per pilot, landscape only, with the live count in the panel.
      await pumpUntilFound(tester, _key('cards-summary'));
      expect(find.text('Orientation'), findsNothing);
      expect(
        tester.widget<Text>(_key('cards-summary')).data,
        matches(r'^\d+ cards? · \d+ pages?$'),
      );

      // Choosing no pilots leaves nothing to print and says so.
      await tapVisible(tester, _key('cards-select-none'));
      await pumpUntilFound(tester, find.text('No pilots selected'));
      await tapVisible(tester, _key('cards-select-all'));
      await pumpUntilGone(tester, find.text('No pilots selected'));

      // The viewer has no shell, so leave it for the next step.
      await tapVisible(tester, _key('viewer-back'));
      await pumpUntilFound(tester, find.text('Reports are built from'));
    }),
  );
}

Future<void> _openReports(WidgetTester tester) async {
  await tapRail(tester, 'Reports');
  await pumpUntilFound(tester, find.text('Reports are built from'));
}

/// The current route as a string; the viewer keeps its options in the query.
String currentRoute(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return GoRouter.of(context).routeInformationProvider.value.uri.toString();
}

bool _reportEnabled(WidgetTester tester, String report) =>
    tester
        .widget<ButtonStyleButton>(find.byKey(ValueKey('report-open-$report')))
        .onPressed !=
    null;

/// Changes one setting of each kind, always to the other value than the one
/// shown, so the step does not depend on defaults.
Future<void> _editConfiguration(WidgetTester tester) async {
  await openConfiguration(tester);
  expect(find.text('Discard changes'), findsNothing);

  final rounding = segmentedValue(tester, 'rounding_mode');
  final newRounding = rounding == 'Round' ? 'Truncate' : 'Round';
  await tapSegment(tester, 'rounding_mode', newRounding);

  final decimals = segmentedValue(tester, 'decimal_places') as int;
  final newDecimals = (decimals + 1) % 4;
  await tapSegment(tester, 'decimal_places', '$newDecimals');

  final tiebreaker = toggleValue(tester, 'tiebreaker_enabled');
  await flipToggle(tester, 'tiebreaker_enabled');

  // The save bar counts the changes. A contest with no drawn matrix and no
  // scores has nothing to lose, so Save needs no confirmation.
  expect(find.text('3 unsaved changes'), findsOneWidget);
  await tapVisible(
    tester,
    find.widgetWithText(FilledButton, 'Save configuration'),
  );
  await pumpUntilFound(
    tester,
    find.textContaining('Configuration saved as revision'),
  );
  expect(find.text('Save configuration?'), findsNothing);
  expect(find.text('Discard changes'), findsNothing);

  // Leave the page and come back: the saved values are loaded again.
  await tapRail(tester, 'Workspace');
  await pumpUntilGone(tester, find.text('Scoring pilots'));
  await openConfiguration(tester);
  expect(segmentedValue(tester, 'rounding_mode'), newRounding);
  expect(segmentedValue(tester, 'decimal_places'), newDecimals);
  expect(toggleValue(tester, 'tiebreaker_enabled'), !tiebreaker);
  expect(find.text('Discard changes'), findsNothing);

  // Saving the configuration never draws the matrix.
  expect(find.text('Drawn and in sync'), findsNothing);
  await tapRail(tester, 'Matrix');
  await pumpUntilFound(tester, _key('draw-button'));
  expect(_key('fairness-score'), findsNothing);
}

/// Draws the matrix of the undrawn contest. The wizard's rounds and groups
/// are in the form already; the dialog and the grid follow them.
Future<void> _drawMatrix(WidgetTester tester, JourneyContext data) async {
  await tapRail(tester, 'Matrix');
  await pumpUntilFound(tester, find.text('No matrix drawn yet'));
  expect(_key('fairness-score'), findsNothing);

  String text(String key) =>
      tester.widget<TextField>(fieldWithKey(key)).controller!.text;
  expect(text('draw-rounds'), '${data.rounds}');
  expect(text('draw-groups'), '${data.groupsPerRound}');
  await pumpUntilFound(
    tester,
    find.textContaining('${data.groupsPerRound} groups:'),
  );

  await tapVisible(tester, _key('draw-button'));
  await pumpUntilFound(tester, find.text('Draw the matrix?'));
  // Scoped to the dialog: the matrix page behind it shows the same counts.
  Finder inDialog(String text) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.textContaining(text),
  );
  expect(inDialog('${data.pilotNames.length} scoring pilots'), findsOneWidget);
  expect(inDialog('${data.rounds} rounds'), findsOneWidget);
  expect(inDialog('${data.groupsPerRound} groups per round'), findsOneWidget);

  await tester.tap(_key('confirm-draw'));
  await pumpUntilFound(tester, _key('fairness-score'));

  // The drawn matrix: every round, the fairness score, no draw form.
  for (var round = 1; round <= data.rounds; round++) {
    expect(find.text('Round $round'), findsOneWidget);
  }
  expect(find.text('Round ${data.rounds + 1}'), findsNothing);
  expect(find.text('Group A'), findsWidgets);
  expect(find.text('Group B'), findsWidgets);
  expect(find.text('No matrix drawn yet'), findsNothing);
  expect(_key('draw-button'), findsNothing);
}

/// Moves the first pilot of the grid to the first group that can take them
/// in their own round, with a reason, and checks the Moved label and the
/// reason in the pilot panel. Which group that is depends on the draw.
Future<void> _movePilot(WidgetTester tester) async {
  await tapRail(tester, 'Matrix');
  await pumpUntilFound(tester, _key('fairness-score'));
  expect(_key('moved-label'), findsNothing);

  // The test window is small: hide the fairness summary so the grid has room
  // for its tiles. It is shown again at the end.
  await tapVisible(tester, _key('summary-toggle'));
  await pumpUntilFound(tester, find.byType(PilotRowTile));

  // Highlight a pilot; the pilot actions menu is on their tiles.
  final tile = find.byType(PilotRowTile).first;
  await tapVisible(tester, tile);
  await pumpUntilFound(tester, _key('pilot-panel'));
  await pumpUntilFound(tester, _key('pilot-actions'));
  await tapVisible(tester, _key('pilot-actions').first);
  await pumpUntilFound(tester, _key('pilot-action-move'));
  await tester.tap(_key('pilot-action-move'));
  await pumpUntilFound(tester, _key('move-reason'));

  // Nothing is scored yet, so there is no discard warning.
  expect(_key('move-score-warning'), findsNothing);
  // Their own group cannot be chosen; the first group that can is.
  final groups = find.byWidgetPredicate(
    (w) =>
        w is ListTile &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('move-group-') &&
        w.enabled,
    description: 'a group that can take the pilot',
  );
  await tapVisible(tester, groups.first);
  await enterIn(tester, _key('move-reason'), 'E2E move');
  await tapVisible(tester, _key('move-confirm'));
  await pumpUntilGone(tester, _key('move-confirm'));

  // The grid shows the Moved label and the pilot panel the reason.
  await pumpUntilFound(tester, _key('moved-label'));
  await pumpUntilFound(tester, find.textContaining(': E2E move'));
  await tapVisible(tester, _key('summary-toggle'));
}

/// The list row of the role called [name]; the detail pane repeats the name.
Finder _roleRow(String name) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(name));

/// Types [name] into the role name dialog and confirms it.
Future<void> _confirmRoleName(WidgetTester tester, String name) async {
  final field = _key('role-name-field');
  await pumpUntilFound(tester, field);
  await enterIn(tester, field, name);
  await tapVisible(tester, _key('role-name-confirm'));
  await pumpUntilFound(tester, find.byType(ListTile));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _rolesManager(WidgetTester tester) async {
  await tapRail(tester, 'Roles');
  await pumpUntilFound(tester, _roleRow('Pilot'));

  // System roles are protected: no Rename or Delete.
  await tapVisible(tester, _roleRow('Pilot'));
  await pumpUntilFound(tester, find.text('System role'));
  expect(_key('rename-role'), findsNothing);
  expect(_key('delete-role'), findsNothing);

  // Create.
  await tapVisible(tester, _key('new-role'));
  await _confirmRoleName(tester, 'E2E Scorer');
  await pumpUntilFound(tester, _roleRow('E2E Scorer'));
  expect(_key('rename-role'), findsOneWidget);

  // Rename.
  await tapVisible(tester, _key('rename-role'));
  await _confirmRoleName(tester, 'E2E Timekeeper');
  await pumpUntilFound(tester, _roleRow('E2E Timekeeper'));
  expect(_roleRow('E2E Scorer'), findsNothing);

  // Delete, after the confirmation.
  await tapVisible(tester, _roleRow('E2E Timekeeper'));
  await tapVisible(tester, _key('delete-role'));
  await pumpUntilFound(tester, find.text('Delete role?'));
  await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete'));
  await pumpUntilGone(tester, _roleRow('E2E Timekeeper'));
  expect(_roleRow('Pilot'), findsOneWidget);
}

/// The landings manager's list row of the table called [name].
Finder _landingRow(String name) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(name));

Future<void> _landingsManager(WidgetTester tester) async {
  await tapRail(tester, 'Landings');
  await pumpUntilFound(tester, find.text('Landings'));

  // A system table is read-only: copy is offered, delete is locked.
  final system = _landingRow('F5J Standard Landing Table');
  await pumpUntilFound(tester, system);
  await tapVisible(tester, system);
  await pumpUntilFound(tester, _key('landing-locked-notice'));
  expect(_key('delete-landing'), findsNothing);
  expect(_key('delete-landing-locked'), findsOneWidget);
  expect(_key('copy-landing'), findsOneWidget);

  // Create a new table with two entries.
  await tapVisible(tester, _key('new-landing'));
  await pumpUntilFound(tester, _key('landing-name'));
  expect(find.text('New landing table'), findsOneWidget);

  // Saving the empty form is refused with inline messages.
  await tapVisible(tester, _key('save-landing'));
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Name is required.'), findsOneWidget);
  expect(find.text('Label is required.'), findsOneWidget);
  expect(find.text('Points is required.'), findsOneWidget);

  await enterIn(tester, _key('landing-name'), 'E2E Club Table');
  await tapVisible(tester, _key('landing-unit'));
  await pumpUntilFound(tester, find.text('Meters'));
  await tapVisible(tester, find.text('Meters').last);
  await enterIn(tester, _key('entry-label-0'), 'Inside 1 m');
  await enterIn(tester, _key('entry-points-0'), '30');
  await tapVisible(tester, _key('add-landing-entry'));
  await pumpUntilFound(tester, _key('entry-label-1'));
  await enterIn(tester, _key('entry-label-1'), 'Inside 5 m');
  await enterIn(tester, _key('entry-points-1'), '15');
  await tapVisible(tester, _key('save-landing'));

  // Back on the list, the new table is "Yours" with its two entries.
  final created = _landingRow('E2E Club Table');
  await pumpUntilFound(tester, created);
  expect(find.text('Yours · Meters · 2 entries'), findsOneWidget);
  await tapVisible(tester, created);
  await pumpUntilFound(tester, find.text('Inside 5 m'));
  expect(find.text('Inside 1 m'), findsOneWidget);
  expect(_key('landing-locked-notice'), findsNothing);
  expect(_key('delete-landing'), findsOneWidget);

  // Copy it: the form starts filled, a third entry is added.
  await tapVisible(tester, _key('copy-landing'));
  await pumpUntilFound(tester, _key('entry-label-1'));
  expect(find.text('New landing table from a copy'), findsOneWidget);
  expect(
    tester.widget<TextFormField>(_key('landing-name')).controller!.text,
    'Copy of E2E Club Table',
  );
  await enterIn(tester, _key('landing-name'), 'E2E Club Table v2');
  await tapVisible(tester, _key('add-landing-entry'));
  await pumpUntilFound(tester, _key('entry-label-2'));
  await enterIn(tester, _key('entry-label-2'), 'Touch and go');
  await enterIn(tester, _key('entry-points-2'), '5');
  await tapVisible(tester, _key('save-landing'));

  final copy = _landingRow('E2E Club Table v2');
  await pumpUntilFound(tester, copy);
  expect(_landingRow('E2E Club Table'), findsOneWidget);
  await tapVisible(tester, copy);
  await pumpUntilFound(tester, find.text('Touch and go'));
  expect(find.text('Inside 1 m'), findsOneWidget);

  // Leaving a form with changes asks first; keep editing, then discard.
  await tapVisible(tester, _key('copy-landing'));
  await pumpUntilFound(tester, _key('landing-name'));
  await enterIn(tester, _key('landing-name'), 'E2E Abandoned');
  await tapVisible(tester, _key('cancel-landing'));
  await pumpUntilFound(tester, find.text('Discard changes?'));
  await tapVisible(tester, find.text('Keep editing'));
  await tester.pump(const Duration(milliseconds: 300));
  expect(_key('landing-name'), findsOneWidget);
  await tapVisible(tester, _key('cancel-landing'));
  await pumpUntilFound(tester, find.text('Discard changes?'));
  await tapVisible(tester, find.widgetWithText(FilledButton, 'Discard'));
  await pumpUntilFound(tester, _landingRow('E2E Club Table v2'));
  expect(_landingRow('E2E Abandoned'), findsNothing);

  // Delete both of our tables, each after the confirm dialog.
  for (final name in ['E2E Club Table v2', 'E2E Club Table']) {
    await tapVisible(tester, _landingRow(name));
    await pumpUntilFound(tester, _key('delete-landing'));
    await tapVisible(tester, _key('delete-landing'));
    await pumpUntilFound(tester, find.text('Delete landing table?'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete'));
    // The row goes once the list reloads.
    await pumpUntilGone(tester, _landingRow(name));
  }
  expect(_landingRow('F5J Standard Landing Table'), findsOneWidget);
}

/// Picks [person] from the participants page's search menu and confirms the
/// add dialog.
Future<void> _addFromSearch(WidgetTester tester, Person person) async {
  final name = '${person.first} ${person.last}';
  // Give the web input time to attach after the tap, or the first
  // characters are lost.
  final search = find.descendant(
    of: _key('participant-search'),
    matching: find.byType(TextField),
  );
  await tester.tap(search);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.enterText(search, person.last);
  await tester.pump(const Duration(milliseconds: 300));
  final result = find.widgetWithText(ListTile, name);
  await pumpUntilFound(tester, result);
  // Tap the menu row itself: scrolling to it first closes the menu.
  await tester.tap(result);
  await tester.pump(const Duration(milliseconds: 300));
  await pumpUntilFound(tester, _key('add-participant-confirm'));
  await tapVisible(tester, _key('add-participant-confirm'));
}
