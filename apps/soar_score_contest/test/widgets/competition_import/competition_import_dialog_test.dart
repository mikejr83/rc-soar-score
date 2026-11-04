import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/competition_import/competition_import.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_contest/widgets/competition_import/competition_import_dialog.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/competition_import_fakes.dart';

void main() {
  late FakeCompetitionImportStore store;
  late CompetitionImportController controller;
  CompetitionImportOutcome? outcome;
  final l10n = AppLocalizationsEn();

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> open(
    WidgetTester tester, {
    String? chosen = '/gs/Contest.mdb',
    bool settle = true,
    Future<GliderScoreImportResult> Function(String)? read,
  }) async {
    controller = CompetitionImportController(
      store: store,
      readFile: read ?? (_) async => competitionsSnapshot(),
      files: GliderScoreFiles(choose: () async => chosen),
    );
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('open'),
            onPressed: () async => outcome = await showDialog(
              context: context,
              builder: (_) => CompetitionImportDialog(controller: controller),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(key('open'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  setUp(() {
    store = FakeCompetitionImportStore([]);
    outcome = null;
  });

  testWidgets('a cancelled chooser closes the dialog', (tester) async {
    await open(tester, chosen: null);
    expect(key('competition-import-dialog'), findsNothing);
    expect(outcome, isNull);
  });

  testWidgets('lists competitions with none chosen and reasons for others', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(l10n.competitionImportTitle), findsOneWidget);
    for (final no in [1, 2, 3, 4]) {
      expect(key('competition-import-row-$no'), findsOneWidget);
    }
    expect(find.text(l10n.competitionImportChosenCount(0)), findsOneWidget);
    expect(
      tester.widget<FilledButton>(key('competition-import-continue')).onPressed,
      isNull,
    );
    expect(
      find.textContaining(l10n.competitionImportReasonClassNotSupportedYet),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10n.competitionImportReasonNoParticipants),
      findsOneWidget,
    );
    // A blocked competition cannot be ticked.
    await tester.tap(key('competition-import-row-4'));
    await tester.pump();
    expect(controller.chosen, isEmpty);
  });

  testWidgets('imports the chosen competition and offers to open it', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    expect(find.text(l10n.competitionImportChosenCount(1)), findsOneWidget);

    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    expect(controller.step, CompetitionImportStep.pilots);
    // Only the pilots of competition 1 are reviewed.
    expect(key('pilot-import-row-1'), findsOneWidget);
    expect(key('pilot-import-row-2'), findsOneWidget);
    expect(key('pilot-import-row-3'), findsNothing);

    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    expect(key('competition-import-summary-contests'), findsOneWidget);
    expect(find.text(l10n.competitionImportSummaryContests(1)), findsOneWidget);
    expect(find.text(l10n.competitionImportNotImported), findsOneWidget);

    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();
    expect(store.imported.map((i) => i.$1), [1]);
    expect(
      find.text(l10n.competitionImportResultImported('Spring Open')),
      findsOneWidget,
    );

    await tester.tap(key('competition-import-open-1'));
    await tester.pumpAndSettle();
    expect(outcome, isNotNull);
    expect(outcome!.imported, hasLength(1));
    expect(outcome!.open, outcome!.imported.single);
  });

  testWidgets('shows an already imported competition', (tester) async {
    store.answers[1] = CompetitionAlreadyImported(
      1,
      contestId: Id.create(),
      importedAt: DateTime.utc(2026, 11, 1),
      importOperationId: Id.create(),
    );
    await open(tester);
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();

    expect(key('competition-import-result-1'), findsOneWidget);
    expect(
      find.textContaining('Spring Open: already imported'),
      findsOneWidget,
    );
    // Nothing was written, so the dialog reports no import.
    await tester.tap(key('competition-import-done'));
    await tester.pumpAndSettle();
    expect(outcome, isNull);
  });

  testWidgets('shows why a competition failed and keeps the others', (
    tester,
  ) async {
    store.answers[2] = const CompetitionImportFailed(
      2,
      CompetitionImportFailure.profileUnavailable,
    );
    await open(tester);
    await tester.tap(key('competition-import-select-all'));
    await tester.pump();
    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        l10n.competitionImportResultFailed(
          'Autumn Open',
          l10n.competitionImportFailProfileUnavailable,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(l10n.competitionImportResultImported('Spring Open')),
      findsOneWidget,
    );
    await tester.tap(key('competition-import-done'));
    await tester.pumpAndSettle();
    expect(outcome!.imported, hasLength(1));
    expect(outcome!.open, isNull);
  });

  testWidgets('an unreadable file shows the error', (tester) async {
    await open(tester, read: (_) async => throw StateError('broken'));
    expect(key('competition-import-error'), findsOneWidget);
  });

  testWidgets('cancelling while reading closes the dialog', (tester) async {
    final gate = Completer<GliderScoreImportResult>();
    await open(tester, read: (_) => gate.future, settle: false);
    expect(find.text(l10n.competitionImportReading('Contest.mdb')), findsOne);
    await tester.tap(key('competition-import-cancel-reading'));
    await tester.pumpAndSettle();
    expect(key('competition-import-dialog'), findsNothing);
    gate.complete(competitionsSnapshot());
    await tester.pumpAndSettle();
    expect(outcome, isNull);
  });

  group('the draw of a competition imported before', () {
    Future<void> openWithDraw(WidgetTester tester) =>
        open(tester, read: (_) async => competitionsSnapshotWithDraw());

    testWidgets('shows the counts and notes of the dry run', (tester) async {
      store.drawTargets[1] = stampedTarget(1);
      await openWithDraw(tester);

      expect(key('competition-import-draw-1'), findsOneWidget);
      expect(key('competition-import-draw-2'), findsNothing);
      expect(
        find.textContaining(l10n.competitionImportDrawDetails(2, 1, 2)),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.competitionImportDrawNoteHistory),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.competitionImportDrawNoLanes),
        findsOneWidget,
      );
      // Nothing in the fixture is scored.
      expect(
        find.textContaining(l10n.competitionImportDrawNoScores),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(key('competition-import-continue'))
            .onPressed,
        isNull,
        reason: 'nothing is chosen yet',
      );
    });

    testWidgets('says why a draw cannot be added', (tester) async {
      store.drawTargets[1] = stampedTarget(1, hasMatrix: true);
      await openWithDraw(tester);

      expect(key('competition-import-draw-1'), findsNothing);
      expect(key('competition-import-draw-refused-1'), findsOneWidget);
      expect(find.text(l10n.competitionImportDrawReasonDrawn), findsOneWidget);
    });

    testWidgets('adds the draw without a pilot review', (tester) async {
      final contestId = Id.create();
      store.drawTargets[1] = stampedTarget(1, contestId: contestId);
      await openWithDraw(tester);

      await tester.tap(key('competition-import-draw-1'));
      await tester.pump();
      expect(find.text(l10n.competitionImportChosenCount(1)), findsOneWidget);
      await tester.tap(key('competition-import-continue'));
      await tester.pumpAndSettle();

      expect(controller.step, CompetitionImportStep.confirm);
      expect(key('competition-import-summary-draws'), findsOneWidget);
      expect(find.text(l10n.competitionImportSummaryDraws(1)), findsOneWidget);
      expect(key('competition-import-summary-contests'), findsNothing);
      expect(find.text(l10n.competitionImportDrawNotImported), findsOneWidget);

      await tester.tap(key('competition-import-confirm'));
      await tester.pumpAndSettle();
      expect(store.drawn, [(1, contestId)]);
      expect(
        find.text(l10n.competitionImportResultDrawAdded('Spring Open', 2, 4)),
        findsOneWidget,
      );

      await tester.tap(key('competition-import-open-draw-1'));
      await tester.pumpAndSettle();
      expect(outcome!.imported, [contestId]);
      expect(outcome!.open, contestId);
    });

    testWidgets('reports a draw that was refused when it was written', (
      tester,
    ) async {
      store.drawTargets[1] = stampedTarget(1);
      store.drawAnswers[1] = const DrawImportFailed(
        1,
        DrawImportReason.alreadyDrawn,
      );
      await openWithDraw(tester);
      await tester.tap(key('competition-import-draw-1'));
      await tester.pump();
      await tester.tap(key('competition-import-continue'));
      await tester.pumpAndSettle();
      await tester.tap(key('competition-import-confirm'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          l10n.competitionImportResultDrawFailed(
            'Spring Open',
            l10n.competitionImportDrawReasonDrawn,
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(key('competition-import-done'));
      await tester.pumpAndSettle();
      expect(outcome, isNull);
    });
  });
}
