import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest_configuration_page.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/configuration_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  ConfigServer server, {
  Size size = const Size(1280, 900),
  Future<http.Response> Function(http.Request)? handler,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(handler ?? server.handle),
      ),
      child: const MaterialApp(
        home: Scaffold(
          body: ContestConfigurationPage(contestId: configContestId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _saveButton = find.widgetWithText(FilledButton, 'Save configuration');
final _confirmSave = find.byKey(const ValueKey('confirm-save'));

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Taps the segment labelled [label] in the setting [setting].
Future<void> _segment(WidgetTester tester, String setting, String label) async {
  final row = find.byKey(ValueKey('field-$setting'));
  final segment = find.descendant(of: row, matching: find.text(label));
  await _scrollTo(tester, segment);
  await tester.tap(segment);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows every section with the saved revision', (tester) async {
    await _pump(tester, ConfigServer(revision: configRevision(1)));

    expect(find.text('Configuration revision 1'), findsOneWidget);
    for (final title in [
      'Contest details',
      'Discipline and rules',
      'Landing table',
      'Scoring',
      'Participant options',
      'Participants',
      'Draw options',
      'Public updates and reviews',
    ]) {
      expect(find.text(title, skipOffstage: false), findsWidgets);
    }
    expect(find.text('Official rules', skipOffstage: false), findsOneWidget);
    expect(find.text('Ready to draw'), findsNothing);
    expect(find.text('Can’t be drawn yet'), findsOneWidget);
  });

  testWidgets('the save bar appears only while the draft differs', (
    tester,
  ) async {
    await _pump(tester, ConfigServer(revision: configRevision(1)));
    expect(find.text('Discard changes'), findsNothing);

    await _segment(tester, 'decimal_places', '2');
    expect(find.text('1 unsaved change'), findsOneWidget);
    expect(find.text('No effect on the matrix or results'), findsOneWidget);

    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes'), findsNothing);
  });

  testWidgets('saving posts the next revision and clears the bar', (
    tester,
  ) async {
    final server = ConfigServer(revision: configRevision(1));
    await _pump(tester, server);

    await _segment(tester, 'decimal_places', '2');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(server.saved!['base_revision_number'], 1);
    expect((server.saved!['config'] as Map)['core']['decimal_places'], 2);
    expect(find.text('Configuration revision 2'), findsOneWidget);
    expect(find.text('Discard changes'), findsNothing);
    expect(server.updatedContest, isNull);
  });

  testWidgets('changed contest details are saved to the contest', (
    tester,
  ) async {
    final server = ConfigServer(revision: configRevision(1));
    await _pump(tester, server);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('field-city')),
        matching: find.byType(TextField),
      ),
      'Boulder',
    );
    await tester.pumpAndSettle();
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(server.updatedContest!['city'], 'Boulder');
    expect(server.saved, isNull);
  });

  testWidgets('an invalid value blocks Save and is listed in the bar', (
    tester,
  ) async {
    await _pump(tester, ConfigServer(revision: configRevision(1)));

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('field-name')),
        matching: find.byType(TextField),
      ),
      '',
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter a contest name.'), findsOneWidget);
    expect(
      find.text('1 setting needs fixing before you can save'),
      findsOneWidget,
    );
    expect(find.text('Fix 1 error to save'), findsOneWidget);
    expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);
  });

  testWidgets('a working time over the limit says what to enter', (
    tester,
  ) async {
    await _pump(tester, ConfigServer(revision: configRevision(1)));

    final field = find.descendant(
      of: find.byKey(const ValueKey('field-d_working_time')),
      matching: find.byType(TextField),
    );
    await _scrollTo(tester, field);
    await tester.enterText(field, '10:75');
    await tester.pumpAndSettle();

    expect(find.textContaining('Seconds go up to 59'), findsWidgets);
  });

  testWidgets('a house rule shows the official value and resets to it', (
    tester,
  ) async {
    await _pump(
      tester,
      ConfigServer(
        revision: configRevision(1, discipline: {'working_time': 480}),
      ),
    );

    expect(find.text('1 house rule', skipOffstage: false), findsOneWidget);
    final reset = find.text('Reset to official');
    await _scrollTo(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('Reset to official'), findsNothing);
    expect(find.text('Official rules', skipOffstage: false), findsOneWidget);
  });

  testWidgets('team protection blocks Seeded with a one-tap fix', (
    tester,
  ) async {
    await _pump(
      tester,
      ConfigServer(
        revision: configRevision(
          1,
          core: {
            'teams_enabled': true,
            'team_pilot_count': 3,
            'team_protection': true,
          },
        ),
      ),
    );

    final fix = find.text('Turn off team protection');
    await _scrollTo(tester, fix);
    await tester.tap(fix);
    await tester.pumpAndSettle();

    expect(find.text('Turn off team protection'), findsNothing);
    expect(find.text('2 unsaved', skipOffstage: false), findsWidgets);
  });

  testWidgets('a change that outdates the drawn matrix asks first', (
    tester,
  ) async {
    final server = ConfigServer(
      revision: configRevision(1),
      participations: [configParticipation(1), configParticipation(2)],
      matrix: configDrawnMatrix(),
    );
    await _pump(tester, server);
    expect(find.text('Drawn and in sync'), findsOneWidget);

    await _segment(tester, 'lane_mode', 'Random');
    expect(find.text('Makes the drawn matrix out of date'), findsOneWidget);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(find.text('The drawn matrix becomes out of date'), findsOneWidget);
    expect(server.saved, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(server.saved, isNull);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    await tester.tap(_confirmSave);
    await tester.pumpAndSettle();
    expect((server.saved!['config'] as Map)['core']['lane_mode'], 'Random');
  });

  testWidgets('a lane change with no matrix saves without a dialog', (
    tester,
  ) async {
    final server = ConfigServer(revision: configRevision(1));
    await _pump(tester, server);

    await _segment(tester, 'lane_mode', 'Random');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Save configuration?'), findsNothing);
    expect(server.saved, isNotNull);
  });

  testWidgets('fixed settings once scoring has started', (tester) async {
    final server = ConfigServer(
      contest: configContest(state: LifecycleState.running),
      revision: configRevision(1),
      participations: [configParticipation(1), configParticipation(2)],
      matrix: configDrawnMatrix(),
    );
    await _pump(tester, server);

    expect(find.text('Scoring has started'), findsOneWidget);
    expect(
      find.text('Fixed once scoring has started.', skipOffstage: false),
      findsWidgets,
    );

    await _segment(tester, 'decimal_places', '2');
    expect(find.text('Recalculates all results'), findsOneWidget);
  });

  testWidgets('a locked contest is read-only', (tester) async {
    await _pump(
      tester,
      ConfigServer(
        contest: configContest(lock: AdminLock.locked),
        revision: configRevision(1),
        participations: [configParticipation(1), configParticipation(2)],
      ),
    );

    expect(find.text('Administration is locked'), findsOneWidget);
    final classes = find.descendant(
      of: find.byKey(const ValueKey('field-classes_enabled')),
      matching: find.byType(Switch),
    );
    await _scrollTo(tester, classes);
    expect(tester.widget<Switch>(classes).onChanged, isNull);
    expect(find.text('Discard changes'), findsNothing);
  });

  testWidgets('a completed contest is read-only', (tester) async {
    await _pump(
      tester,
      ConfigServer(
        contest: configContest(state: LifecycleState.completed),
        revision: configRevision(1),
      ),
    );
    // The page banner and the readiness panel both say it now.
    expect(find.text('Contest completed'), findsWidgets);
  });

  testWidgets(
    'a completed contest with a drawn matrix: finished, participants locked',
    (tester) async {
      await _pump(
        tester,
        ConfigServer(
          contest: configContest(state: LifecycleState.completed),
          revision: configRevision(1),
          participations: [configParticipation(1), configParticipation(2)],
          matrix: configDrawnMatrix(),
        ),
      );
      expect(
        find.text('Contest completed', skipOffstage: false),
        findsWidgets,
      );
      expect(find.text('Drawn and in sync'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('nav-participants')),
          matching: find.byIcon(Icons.lock),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'an admin-locked contest does not add a read-only mark to participants',
    (tester) async {
      await _pump(
        tester,
        ConfigServer(
          contest: configContest(lock: AdminLock.locked),
          revision: configRevision(1),
          participations: [configParticipation(1), configParticipation(2)],
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('nav-participants')),
          matching: find.text('Read-only'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('another device saved first: latest is shown, edits kept', (
    tester,
  ) async {
    final server = ConfigServer(
      revision: configRevision(1),
      conflictOnSave: true,
    );
    await _pump(tester, server);

    await _segment(tester, 'decimal_places', '2');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Configuration updated'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('1 unsaved change'), findsOneWidget);
  });

  testWidgets('a failed save keeps the values and offers Retry', (
    tester,
  ) async {
    final server = ConfigServer(revision: configRevision(1));
    var fail = true;
    await _pump(
      tester,
      server,
      handler: (request) async => fail && request.method == 'POST'
          ? http.Response('boom', 500)
          : server.handle(request),
    );

    await _segment(tester, 'decimal_places', '2');
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t save the configuration'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(server.saved, isNotNull);
  });

  testWidgets('the landing picker previews a table and uses it', (
    tester,
  ) async {
    await _pump(tester, ConfigServer(revision: configRevision(1)));

    await _scrollTo(tester, find.text('Change table'));
    await tester.tap(find.text('Change table'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a landing table'), findsOneWidget);

    await tester.tap(find.text('Club tape'));
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    await tester.tap(find.text('Use this table'));
    await tester.pumpAndSettle();

    expect(find.text('Club tape'), findsOneWidget);
    expect(find.text('Saved: F5J standard'), findsOneWidget);
  });

  testWidgets('narrow pages use the chip row and show readiness inline', (
    tester,
  ) async {
    await _pump(
      tester,
      ConfigServer(revision: configRevision(1)),
      size: const Size(700, 900),
    );
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.text('On this page'), findsNothing);
    expect(find.text('Matrix readiness', skipOffstage: false), findsOneWidget);
  });

  testWidgets('a load failure offers Retry', (tester) async {
    var fail = true;
    final server = ConfigServer(revision: configRevision(1));
    await _pump(
      tester,
      server,
      handler: (request) async =>
          fail ? http.Response('boom', 500) : server.handle(request),
    );
    expect(find.text('The configuration could not be loaded.'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Contest details'), findsWidgets);
  });
}
