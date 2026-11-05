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
      // The app maps on a background isolate; the tests map in place.
      mapFile: (result) async => mapGliderScoreFile(result),
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

  Future<void> toConfirm(WidgetTester tester) async {
    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('imports the chosen competition and offers to open it', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    expect(find.text(l10n.competitionImportChosenCount(1)), findsOneWidget);
    // The Completed box starts on, because every flown round is scored.
    expect(
      tester
          .widget<CheckboxListTile>(key('competition-import-completed-1'))
          .value,
      isTrue,
    );

    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    expect(controller.step, CompetitionImportStep.pilots);
    // Only the pilots of competition 1 are reviewed.
    expect(key('pilot-import-row-1'), findsOneWidget);
    expect(key('pilot-import-row-2'), findsOneWidget);
    expect(key('pilot-import-row-3'), findsNothing);

    await tester.tap(key('competition-import-continue'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.competitionImportSummaryContests(1)), findsOneWidget);
    expect(find.text(l10n.competitionImportSummaryFlights(4)), findsOneWidget);
    expect(
      find.text(l10n.competitionImportSummaryCompleted(1)),
      findsOneWidget,
    );
    expect(find.text(l10n.competitionImportSummaryCheck), findsOneWidget);
    // A short list is named.
    expect(key('competition-import-sum-1'), findsOneWidget);

    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();
    expect(store.restored.map((i) => i.compNo), [1]);
    expect(
      find.text(l10n.competitionImportResultRestored('Spring Open', 4)),
      findsOneWidget,
    );

    await tester.tap(key('competition-import-open-1'));
    await tester.pumpAndSettle();
    expect(outcome, isNotNull);
    expect(outcome!.imported, hasLength(1));
    expect(outcome!.open, outcome!.imported.single);
  });

  testWidgets('a long list of contests is counted, not named', (tester) async {
    await open(tester);
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    await toConfirm(tester);
    expect(key('competition-import-sum-1'), findsOneWidget);
    // Ten or more chosen competitions would overflow the dialog.
    final many = _TenChosen(controller);
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CompetitionImportDialog(controller: many)),
      ),
    );
    await tester.pump();
    expect(find.textContaining('• '), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the director can leave the contest open for scoring', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    await tester.ensureVisible(key('competition-import-completed-1'));
    await tester.pumpAndSettle();
    await tester.tap(key('competition-import-completed-1'));
    await tester.pump();
    expect(controller.completed(1), isFalse);
    await toConfirm(tester);
    expect(find.text(l10n.competitionImportSummaryCompleted(1)), findsNothing);
    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();
    expect(store.restored.single.completed, isFalse);
  });

  testWidgets('replacing a contest changed since asks for confirmation', (
    tester,
  ) async {
    store.targets[1] = earlierImport(
      changes: const ContestChanges(scoresEntered: 2),
    );
    await open(tester);
    expect(
      find.textContaining(l10n.competitionImportTargetReplaces('Spring Open')),
      findsOneWidget,
    );
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    await toConfirm(tester);

    expect(find.text(l10n.competitionImportSummaryReplaced(1)), findsOneWidget);
    expect(
      tester.widget<FilledButton>(key('competition-import-confirm')).onPressed,
      isNull,
    );
    await tester.tap(key('competition-import-confirm-replace'));
    await tester.pump();
    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();

    expect(store.restored.single.confirmedReplace, isTrue);
    expect(
      find.text(l10n.competitionImportResultReplaced('Spring Open', 4)),
      findsOneWidget,
    );
  });

  testWidgets('a contest that cannot be replaced says why', (tester) async {
    store.targets[1] = earlierImport(synced: true);
    await open(tester);

    expect(find.textContaining(l10n.competitionImportTargetSynced), findsOne);
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    expect(controller.chosen, isEmpty);
  });

  testWidgets('a number match asks whether it is the same competition', (
    tester,
  ) async {
    store.targets[1] = earlierImport(kind: RestoreTargetKind.numberMatch);
    await open(tester);

    expect(key('competition-import-same-1'), findsOneWidget);
    await tester.ensureVisible(key('competition-import-same-1'));
    await tester.pumpAndSettle();
    await tester.tap(key('competition-import-same-1'));
    await tester.pump();
    expect(controller.isSameAs(1), isTrue);
  });

  testWidgets('shows a competition that is already up to date', (tester) async {
    store.answers[1] = CompetitionUnchanged(
      1,
      contestId: Id.create(),
      importedAt: DateTime.utc(2026, 11, 1),
    );
    await open(tester);
    await tester.tap(key('competition-import-row-1'));
    await tester.pump();
    await toConfirm(tester);
    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.competitionImportResultUnchanged('Spring Open')),
      findsOneWidget,
    );
    // Nothing was written, so the dialog reports no import.
    await tester.tap(key('competition-import-done'));
    await tester.pumpAndSettle();
    expect(outcome, isNull);
  });

  testWidgets('names the first flights when the check against GliderScore '
      'fails, and keeps the others', (tester) async {
    store.answers[2] = const CompetitionRestoreFailed(
      2,
      RestoreFailure.comparisonFailed,
      mismatchCount: 3,
      mismatches: [
        RestoreMismatch(
          roundNo: 1,
          groupNo: 2,
          sourcePilotNo: 7,
          reflightNo: 0,
        ),
        RestoreMismatch(
          roundNo: 4,
          groupNo: 1,
          sourcePilotNo: 9,
          reflightNo: 0,
        ),
      ],
    );
    await open(tester);
    await tester.tap(key('competition-import-select-all'));
    await tester.pump();
    await toConfirm(tester);
    await tester.tap(key('competition-import-confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        l10n.competitionImportResultRefused(
          'Autumn Open',
          l10n.competitionImportFailComparison(
            3,
            '${l10n.competitionImportMismatchFlight(1, 2, 7)}; '
            '${l10n.competitionImportMismatchFlight(4, 1, 9)}',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(l10n.competitionImportResultRestored('Spring Open', 4)),
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

  testWidgets('shows the reading state, animated, and cancelling closes it', (
    tester,
  ) async {
    final gate = Completer<GliderScoreImportResult>();
    await open(tester, read: (_) => gate.future, settle: false);
    expect(find.text(l10n.competitionImportReading('Contest.mdb')), findsOne);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(key('competition-import-cancel-reading'));
    await tester.pumpAndSettle();
    expect(key('competition-import-dialog'), findsNothing);
    gate.complete(competitionsSnapshot());
    await tester.pumpAndSettle();
    expect(outcome, isNull);
  });
}

/// A controller whose chosen list is long, to see the summary of a big run.
class _TenChosen extends CompetitionImportController {
  _TenChosen(CompetitionImportController from)
    : _plans = [for (var i = 0; i < 10; i++) from.chosenPlans.single],
      super(
        store: from.store,
        readFile: from.readFile,
        mapFile: (result) async => mapGliderScoreFile(result),
      );

  final List<RestorePlan> _plans;

  @override
  CompetitionImportStep get step => CompetitionImportStep.confirm;

  @override
  List<RestorePlan> get chosenPlans => _plans;
}
