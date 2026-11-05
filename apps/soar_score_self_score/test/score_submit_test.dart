import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/entry_context.dart';
import 'package:soar_score_self_score/models/score_submission.dart';
import 'package:soar_score_self_score/pages/score_entry_page.dart';
import 'package:soar_score_self_score/services/score_components.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/key_value_store.dart';
import 'package:soar_score_self_score/session/score_draft_store.dart';

/// Answers each send with the next queued answer and records what was sent.
class _ScriptedRepository extends SampleSelfScoreRepository {
  _ScriptedRepository(this.answers, {this.alreadySubmitted = false});

  final List<Object> answers;
  final bool alreadySubmitted;
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
      alreadySubmitted: alreadySubmitted,
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
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScoreDraftScope(
      store: drafts ?? ScoreDraftStore(MemoryKeyValueStore()),
      child: SelfScoreScope(
        repository: repository,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), '630.4');
  await tester.enterText(find.byType(TextField).at(1), '45');
  await tester.tap(find.text('Choose landing'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Good'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Submit score'));
  await tester.pump();
}

void main() {
  testWidgets('an accepted score is read-only and shows the server value', (
    tester,
  ) async {
    final repository = _ScriptedRepository([
      const ScoreAccepted(flightScore: '962.5', nextRound: 5),
    ]);
    await _pump(tester, repository);
    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Official score: 962.5'), findsOneWidget);
    expect(find.text('Submit score'), findsNothing);
    expect(find.text('See group results'), findsOneWidget);
    final sent = repository.sent.single;
    expect(sent.round, 4);
    expect(sent.matrixRevision, 3);
    expect(sent.clientMutationId, startsWith('entry-12-4-'));
    expect(sent.components, {
      'time_flown': 390.4,
      'launch_height': 45,
      'landing': 'good',
    });
  });

  testWidgets('nothing is official before the server answers', (tester) async {
    final repository = _ScriptedRepository([
      const SelfScoreOfflineException('offline'),
    ]);
    await _pump(tester, repository);
    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Not sent yet'), findsOneWidget);
    expect(find.text('Submitted'), findsNothing);
    expect(find.textContaining('Official score'), findsNothing);
    expect(find.text('See group results'), findsNothing);
  });

  testWidgets('a retry after a timeout reuses the request id', (tester) async {
    final repository = _ScriptedRepository([
      const SelfScoreOfflineException('offline'),
      const ScoreAccepted(flightScore: '962.5'),
    ]);
    await _pump(tester, repository);
    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Try again now'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsOneWidget);
    expect(repository.sent, hasLength(2));
    expect(
      repository.sent[1].clientMutationId,
      repository.sent[0].clientMutationId,
    );
  });

  testWidgets('a queued score sends itself again after a while', (
    tester,
  ) async {
    final repository = _ScriptedRepository([
      const SelfScoreOfflineException('offline'),
      const ScoreAccepted(flightScore: '962.5'),
    ]);
    await _pump(tester, repository);
    await _fillAndSubmit(tester);
    await tester.pump();
    expect(find.text('Not sent yet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsOneWidget);
    expect(repository.sent, hasLength(2));
  });

  testWidgets('a refusal explains itself and leaves the form editable', (
    tester,
  ) async {
    final repository = _ScriptedRepository([
      const ScoreRejected(
        code: 'validation_failed',
        message: 'Check the highlighted fields.',
        fields: ['time_flown'],
      ),
      const ScoreAccepted(flightScore: '1'),
    ]);
    await _pump(tester, repository);
    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Check your entries. The score was not sent.'),
      findsOneWidget,
    );
    expect(find.text('Submitted'), findsNothing);
    expect(find.text('Submit score'), findsOneWidget);

    // A corrected try is a new attempt with its own id.
    await tester.tap(find.text('Submit score'));
    await tester.pumpAndSettle();
    expect(find.text('Submitted'), findsOneWidget);
    expect(
      repository.sent[1].clientMutationId,
      isNot(repository.sent[0].clientMutationId),
    );
  });

  testWidgets('a flight that already has a score keeps the stored one', (
    tester,
  ) async {
    final repository = _ScriptedRepository([
      const ScoreAlreadySubmitted(flightScore: '962.5'),
    ]);
    await _pump(tester, repository);
    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsOneWidget);
    expect(
      find.text(
        'This flight already has a score: 962.5. The stored score stands.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a scored flight opens read-only', (tester) async {
    await _pump(tester, _ScriptedRepository([], alreadySubmitted: true));

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Submit score'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).enabled,
      false,
    );
  });

  testWidgets('a reload restores the draft', (tester) async {
    final drafts = ScoreDraftStore(MemoryKeyValueStore());
    final repository = _ScriptedRepository([]);
    await _pump(tester, repository, drafts: drafts);
    await tester.enterText(find.byType(TextField).at(0), '630.4');
    await tester.enterText(find.byType(TextField).at(1), '45');
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await _pump(tester, repository, drafts: drafts);

    expect(find.text('Reads as 6:30.4.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
      '45',
    );
  });

  testWidgets('a send that never got an answer is sent again on reload', (
    tester,
  ) async {
    final drafts = ScoreDraftStore(MemoryKeyValueStore());
    final first = _ScriptedRepository([
      const SelfScoreOfflineException('offline'),
    ]);
    await _pump(tester, first, drafts: drafts);
    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();
    final id = first.sent.single.clientMutationId;

    await tester.pumpWidget(const SizedBox());
    final second = _ScriptedRepository([const ScoreAccepted(flightScore: '9')]);
    await _pump(tester, second, drafts: drafts);
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsOneWidget);
    expect(second.sent.single.clientMutationId, id);
    expect(second.sent.single.components['landing'], 'good');
    // Accepted: nothing is left in the draft.
    expect(drafts.read(SampleData.contestId, '12', 4), isNull);
  });

  group('buildF5jComponents', () {
    Map<String, Object?> build({
      double? seconds = 540,
      int? height = 45,
      String? landing = 'good',
      bool late = false,
      bool restart = false,
      bool oob = false,
      bool noAlt = false,
      int? penalty = 0,
    }) => buildF5jComponents(
      seconds: seconds,
      height: height,
      landingId: landing,
      lateLanding: late,
      motorRestart: restart,
      outOfBounds: oob,
      noAltitude: noAlt,
      penalty: penalty,
    );

    test('a normal flight', () {
      expect(build(), {
        'time_flown': 540,
        'launch_height': 45,
        'landing': 'good',
      });
    });

    test('late landing drops the landing and flags it', () {
      expect(build(late: true), {
        'time_flown': 540,
        'launch_height': 45,
        'late_landing': true,
      });
    });

    test('zeroing flags replace the flight values', () {
      expect(build(restart: true), {'motor_restart': true});
      expect(build(oob: true), {'out_of_bounds': true});
      expect(build(noAlt: true, oob: true), {'no_altitude_recorded': true});
    });

    test('a penalty is sent only above zero', () {
      expect(build(penalty: 0).containsKey('flight_penalty'), isFalse);
      expect(build(penalty: 25)['flight_penalty'], 25);
    });
  });
}
