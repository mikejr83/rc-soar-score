import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/entry_context.dart';
import 'package:soar_score_self_score/models/score_submission.dart';
import 'package:soar_score_self_score/pages/score_entry_page.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/key_value_store.dart';
import 'package:soar_score_self_score/session/score_draft_store.dart';

/// Answers each send with the next queued answer and records what was sent.
class _ScriptedRepository extends SampleSelfScoreRepository {
  _ScriptedRepository(this.answers);

  final List<Object> answers;
  final sent = <ScoreSubmission>[];

  @override
  Future<EntryContext> entryContext(
    String contestId,
    String pilotId,
    int round,
  ) async {
    final base = await super.entryContext(contestId, pilotId, round);
    return EntryContext(
      pilotName: base.pilotName,
      pilotNumber: base.pilotNumber,
      round: base.round,
      roundCount: base.roundCount,
      group: base.group,
      lane: base.lane,
      landingTable: base.landingTable,
      matrixRevision: 3,
    );
  }

  @override
  Future<SubmitResult> submitScore(ScoreSubmission submission) async {
    sent.add(submission);
    final answer = answers.removeAt(0);
    if (answer is SubmitResult) return answer;
    throw answer;
  }
}

Future<void> _pump(
  WidgetTester tester,
  SelfScoreRepository repository, {
  ScoreDraftStore? drafts,
}) async {
  tester.view.physicalSize = const Size(400, 550);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScoreDraftScope(
      store: drafts ?? ScoreDraftStore(MemoryKeyValueStore()),
      child: SelfScoreScope(
        repository: repository,
        child: const MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          home: ScoreEntryPage(
            contestId: SampleData.contestId,
            pilotId: '12',
            roundId: '4',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _inView(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  return rect.top >= 0 && rect.bottom <= height;
}

void main() {
  testWidgets('a refusal scrolls its banner into view (#922)', (tester) async {
    final repository = _ScriptedRepository([
      const ScoreRejected(
        code: 'validation_failed',
        message: 'Check the highlighted fields.',
        fields: ['time_flown'],
      ),
    ]);
    await _pump(tester, repository);
    await tester.enterText(find.byType(TextField).at(0), '630.4');
    await tester.enterText(find.byType(TextField).at(1), '45');
    await tester.tap(find.text('Choose landing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Submit score'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit score'));
    await tester.pumpAndSettle();

    final banner = find.textContaining('Check your entries');
    expect(banner, findsOneWidget);
    expect(_inView(tester, banner), isTrue);
    expect(find.text('The server did not accept this value.'), findsOneWidget);
  });

  testWidgets('an accepted score scrolls to See group results (#923)', (
    tester,
  ) async {
    final repository = _ScriptedRepository([
      const ScoreAccepted(flightScore: '962.5', nextRound: 5),
    ]);
    await _pump(tester, repository);
    await tester.enterText(find.byType(TextField).at(0), '630.4');
    await tester.enterText(find.byType(TextField).at(1), '45');
    await tester.tap(find.text('Choose landing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Submit score'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit score'));
    await tester.pumpAndSettle();

    final button = find.text('See group results');
    expect(_inView(tester, button), isTrue);
    // Settled at the bottom, not merely somewhere on screen.
    expect(tester.getRect(button).bottom, greaterThan(550 - 80));
  });

  testWidgets('a queued score scrolls its card into view', (tester) async {
    final repository = _ScriptedRepository([
      const SelfScoreOfflineException('offline'),
    ]);
    await _pump(tester, repository);
    await tester.enterText(find.byType(TextField).at(0), '630.4');
    await tester.enterText(find.byType(TextField).at(1), '45');
    await tester.tap(find.text('Choose landing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Submit score'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit score'));
    await tester.pumpAndSettle();

    expect(_inView(tester, find.text('Not sent yet')), isTrue);
  });

  testWidgets('editing a refused field clears its message', (tester) async {
    final repository = _ScriptedRepository([
      const ScoreRejected(
        code: 'validation_failed',
        message: 'Check the highlighted fields.',
        fields: ['time_flown'],
      ),
    ]);
    await _pump(tester, repository);
    await tester.enterText(find.byType(TextField).at(0), '630.4');
    await tester.enterText(find.byType(TextField).at(1), '45');
    await tester.tap(find.text('Choose landing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Submit score'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit score'));
    await tester.pumpAndSettle();
    expect(find.text('The server did not accept this value.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '640');
    await tester.pumpAndSettle();
    expect(find.text('The server did not accept this value.'), findsNothing);
  });
}
