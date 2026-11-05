import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_contest/widgets/pilot_import/pilot_import_dialog.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/pilot_import_fakes.dart';

void main() {
  final rows = <Map<String, Object?>>[
    {
      'PilotNo': 1,
      'FirstName': 'Nina',
      'LastName': 'Newcomer',
      'Country': 'USA',
      'Street': '1 Road',
    },
    {
      'PilotNo': 2,
      'FirstName': 'Erin',
      'LastName': 'Existing',
      'Email': 'e@x.test',
      'Club': 'New Club',
    },
    {'PilotNo': 3, 'FirstName': 'Sam', 'LastName': 'Samename'},
    {'PilotNo': 4, 'FirstName': 'Test', 'LastName': 'ZZUser'},
    {'PilotNo': 5, 'FirstName': 'Zed', 'LastName': 'ZZOther'},
  ];
  late FakePilotImportStore store;
  bool? result;

  setUp(() {
    store = FakePilotImportStore([
      profile(first: 'Erin', last: 'Existing', email: 'e@x.test'),
      profile(first: 'Sam', last: 'Samename'),
    ]);
    result = null;
  });

  Future<void> open(
    WidgetTester tester, {
    String? chosen = '/gs/Contest.mdb',
    Future<GliderScoreImportResult> Function(String)? read,
    Future<String?> Function()? choose,
  }) async {
    final controller = PilotImportController(
      store: store,
      readFile: read ?? (_) async => pilotsSnapshot(rows),
      files: GliderScoreFiles(choose: choose ?? () async => chosen),
    );
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('open'),
            onPressed: () async => result = await showDialog<bool>(
              context: context,
              builder: (_) => PilotImportDialog(controller: controller),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('a cancelled chooser closes the dialog without a change', (
    tester,
  ) async {
    await open(tester, chosen: null);
    expect(find.byKey(const ValueKey('pilot-import-dialog')), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('shows new pilots, matches and maybes, with the notes', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Import pilots from GliderScore'), findsOneWidget);
    expect(find.text('New (1)'), findsOneWidget);
    expect(find.text('Already in your list (1)'), findsOneWidget);
    expect(find.text('Maybe the same person (1)'), findsOneWidget);
    expect(find.textContaining('Will update: club'), findsOneWidget);
    expect(find.textContaining('2 GliderScore test pilots'), findsOneWidget);
    expect(find.textContaining('street'), findsNothing);
    expect(find.textContaining('Street'), findsOneWidget);
    expect(
      find.text('1 to add, 1 to update, 0 unchanged, 1 left out'),
      findsOneWidget,
    );
  });

  testWidgets('unchecking a pilot and choosing for a maybe updates the plan', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('pilot-import-row-1')));
    await tester.pump();
    expect(
      find.text('0 to add, 1 to update, 0 unchanged, 1 left out'),
      findsNothing,
    );
    expect(
      find.text('0 to add, 1 to update, 0 unchanged, 2 left out'),
      findsOneWidget,
    );

    // Every choice box is the same width, whatever it says.
    final boxes = find.byWidgetPredicate((w) => w is DropdownButton<String>);
    expect(boxes, findsWidgets);
    for (final box in boxes.evaluate()) {
      expect(tester.getSize(find.byWidget(box.widget)).width, 120);
    }
    await tester.tap(find.byKey(const ValueKey('pilot-import-choice-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add as new').last);
    await tester.pumpAndSettle();
    expect(
      find.text('1 to add, 1 to update, 0 unchanged, 1 left out'),
      findsOneWidget,
    );
  });

  testWidgets('importing saves, shows the result and reports a change', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('pilot-import-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.text('Added 1, updated 1, unchanged 0, left out 1.'),
      findsOneWidget,
    );
    expect(store.applied, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('pilot-import-done')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('a file with no usable pilots says so', (tester) async {
    await open(
      tester,
      read: (_) async => pilotsSnapshot([
        {'PilotNo': 1, 'FirstName': 'Only', 'LastName': 'ZZTest'},
      ]),
    );
    expect(find.byKey(const ValueKey('pilot-import-empty')), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('pilot-import-confirm')),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('a read failure is shown and can be closed', (tester) async {
    await open(tester, read: (_) async => throw StateError('broken file'));
    expect(find.textContaining('The import did not work.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('a participant changed during review offers to review again', (
    tester,
  ) async {
    await open(tester);
    store.applyError = StaleRevisionError(
      entityType: 'ParticipantProfile',
      entityId: Id.create(),
      expectedRevision: 0,
      storedRevision: 1,
    );
    await tester.tap(find.byKey(const ValueKey('pilot-import-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your participants changed while you were reviewing. '
        'Review again before importing.',
      ),
      findsOneWidget,
    );
    store.applyError = null;
    await tester.tap(find.byKey(const ValueKey('pilot-import-review-again')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pilot-import-confirm')), findsOneWidget);
  });

  testWidgets('a review of only unchanged matches can still be confirmed', (
    tester,
  ) async {
    store = FakePilotImportStore([
      profile(first: 'Erin', last: 'Existing', email: 'e@x.test'),
    ]);
    await open(
      tester,
      read: (_) async => pilotsSnapshot([
        {
          'PilotNo': 2,
          'FirstName': 'Erin',
          'LastName': 'Existing',
          'Email': 'e@x.test',
        },
      ]),
    );
    expect(
      find.text('0 to add, 0 to update, 1 unchanged, 0 left out'),
      findsOneWidget,
    );
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('pilot-import-confirm')),
    );
    expect(confirm.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('pilot-import-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.text('Added 0, updated 0, unchanged 1, left out 0.'),
      findsOneWidget,
    );
  });

  testWidgets('a review where every row is skipped cannot be confirmed', (
    tester,
  ) async {
    await open(tester);
    for (final n in [1, 2]) {
      await tester.tap(find.byKey(ValueKey('pilot-import-row-$n')));
      await tester.pump();
    }
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('pilot-import-confirm')),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('a throwing file chooser shows the error and can retry', (
    tester,
  ) async {
    var calls = 0;
    await open(
      tester,
      choose: () async {
        calls++;
        if (calls == 1) throw StateError('no picker');
        return '/gs/Contest.mdb';
      },
    );
    expect(find.byKey(const ValueKey('pilot-import-error')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pilot-import-choose-again')));
    await tester.pumpAndSettle();
    expect(find.text('New (1)'), findsOneWidget);
  });

  testWidgets('a changed participant list offers a new review', (tester) async {
    await open(tester);
    store.applyError = PilotImportReviewChangedError(const []);
    await tester.tap(find.byKey(const ValueKey('pilot-import-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pilot-import-review-again')),
      findsOneWidget,
    );
  });
}
