import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/workspace/next_step/next_step_card.dart';
import 'package:soar_score_contest/widgets/workspace/next_step/next_step_section.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_frame.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_live_region.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_scope.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';
import '../../../support/workspace_facts_support.dart';

const _primary = ValueKey('next-step-primary');
const _secondary = ValueKey('next-step-secondary');

WorkspaceServer _locked() => WorkspaceServer(
  state: LifecycleState.configuring,
  lock: AdminLock.locked,
  configuration: matrixConfiguration(),
);

WorkspaceServer _ready() {
  final matrix = drawnMatrix();
  return WorkspaceServer(
    state: LifecycleState.configuring,
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scoresFor(matrix, const {}),
  );
}

/// A running contest with every flight scored, the last at [last].
WorkspaceServer _allScored({DateTime? last}) {
  final matrix = drawnMatrix();
  return WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: _scores(matrix, last),
  );
}

ContestScores _scores(CurrentMatrix matrix, DateTime? last) =>
    scoresFor(matrix, {
      for (var r = 1; r <= 2; r++)
        for (var p = 1; p <= 4; p++) (r, p): at(r * 20 + p * 5),
      (2, 4): ?last,
    });

void main() {
  group('unlocking', () {
    testWidgets('unlocks in place, refreshes to the next step and undoes', (
      tester,
    ) async {
      final server = _locked();
      await pumpWorkspace(tester, server);
      expect(cardTitle(tester), 'Draw the matrix');
      expect(find.text('Unlock administration'), findsOneWidget);

      await tester.tap(find.byKey(_primary));
      await tester.pumpAndSettle();

      expect(server.actions, ['unlock']);
      expect(server.contest.adminLock, AdminLock.unlocked);
      expect(find.text(unlockedMessage), findsOneWidget);
      expect(find.text('Unlock administration'), findsNothing);
      expect(find.text('Go to Matrix'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(server.actions, ['unlock', 'lock']);
      expect(server.contest.adminLock, AdminLock.locked);
      expect(find.text('Unlock administration'), findsOneWidget);
    });

    testWidgets('announces the new title politely', (tester) async {
      await pumpWorkspace(tester, _locked());
      await tester.tap(find.byKey(_primary));
      await tester.pumpAndSettle();
      final region = tester.widget<WorkspaceLiveRegion>(
        find.byType(WorkspaceLiveRegion),
      );
      expect(region.message, cardTitle(tester));
    });

    testWidgets('shows the busy label and ignores a second tap', (
      tester,
    ) async {
      final server = _locked()..actionGate = Completer<void>();
      await pumpWorkspace(tester, server);

      await tester.tap(find.byKey(_primary));
      await tester.pump();
      expect(find.text('Unlocking…'), findsOneWidget);
      await tester.tap(find.byKey(_primary), warnIfMissed: false);
      await tester.pump();

      server.actionGate!.complete();
      await tester.pumpAndSettle();
      expect(server.actions, ['unlock']);
      expect(find.text('Unlocking…'), findsNothing);
    });
  });

  group('opening scoring', () {
    testWidgets('opens in place, with Undo that closes it again', (
      tester,
    ) async {
      final server = _ready();
      await pumpWorkspace(tester, server);
      final before = cardTitle(tester);
      expect(find.text('Open online scoring'), findsOneWidget);

      await tester.tap(find.byKey(_primary));
      await tester.pumpAndSettle();

      expect(server.actions, ['openScoring']);
      expect(server.contest.scoringAccess, ScoringAccess.open);
      expect(find.text(scoringOpenedMessage), findsOneWidget);
      expect(cardTitle(tester), isNot(before));
      expect(find.text('Open online scoring'), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(server.actions, ['openScoring', 'closeScoring']);
      expect(cardTitle(tester), before);
    });

    testWidgets('is busy until the new step shows, then tappable again', (
      tester,
    ) async {
      final server = _ready()..actionGate = Completer<void>();
      await pumpWorkspace(tester, server);
      await tester.tap(find.byKey(_primary));
      await tester.pump();
      expect(find.text('Opening…'), findsOneWidget);
      server.actionGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Opening…'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('a rejected action', () {
    testWidgets('leaves the card unchanged and offers Refresh', (tester) async {
      final server = _locked()
        ..rejectNext = 409
        ..rejectMessage = 'The contest is not locked.';
      await pumpWorkspace(tester, server);
      final before = cardTitle(tester);
      final reads = server.contestReads;

      await tester.tap(find.byKey(_primary));
      await tester.pumpAndSettle();

      expect(find.text('The contest is not locked.'), findsOneWidget);
      expect(cardTitle(tester), before);
      expect(find.text('Unlock administration'), findsOneWidget);
      expect(find.text(unlockedMessage), findsNothing);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(server.contestReads, greaterThan(reads));
    });

    testWidgets('a stale revision is answered with the server message', (
      tester,
    ) async {
      final server = _locked();
      await pumpWorkspace(tester, server);
      // Someone else changed the contest after the page loaded it.
      server.contest = Contest.fromJson({
        ...server.contest.toJson(),
        'revision': 5,
      });

      await tester.tap(find.byKey(_primary));
      await tester.pumpAndSettle();

      expect(
        find.text('The contest was changed by someone else.'),
        findsOneWidget,
      );
      expect(server.contest.adminLock, AdminLock.locked);
    });
  });

  group('dismissing the completion suggestion', () {
    testWidgets('shows Continue scoring and says so', (tester) async {
      await pumpWorkspace(tester, _allScored());
      expect(find.text('SUGGESTED NEXT STEP'), findsOneWidget);

      await tester.tap(find.byKey(_secondary));
      await tester.pumpAndSettle();

      expect(find.text('SUGGESTED NEXT STEP'), findsNothing);
      expect(cardTitle(tester), 'Continue scoring');
      expect(find.text(suggestionDismissedMessage), findsOneWidget);
    });

    testWidgets('comes back when a newer score arrives', (tester) async {
      final server = _allScored();
      await pumpWorkspace(tester, server);
      await tester.tap(find.byKey(_secondary));
      await tester.pumpAndSettle();
      expect(cardTitle(tester), 'Continue scoring');

      server.scores = _scores(drawnMatrix(), at(90));
      WorkspaceScope.of(tester.element(find.byType(WorkspaceFrame)))
          .reloadFacts();
      await tester.pumpAndSettle();

      expect(find.text('SUGGESTED NEXT STEP'), findsOneWidget);
    });

    testWidgets('comes back after another 48 hours', (tester) async {
      var now = DateTime.utc(2026, 10, 17, 16);
      final server = _allScored();
      await pumpWorkspace(tester, server, clock: () => now);
      await tester.tap(find.byKey(_secondary));
      await tester.pumpAndSettle();

      now = now.add(const Duration(hours: 49));
      WorkspaceScope.of(tester.element(find.byType(WorkspaceFrame)))
          .reloadFacts();
      await tester.pumpAndSettle();

      expect(find.text('SUGGESTED NEXT STEP'), findsOneWidget);
    });
  });

  group('facts that failed to load', () {
    testWidgets('the card shows with a quiet line, and Retry loads again', (
      tester,
    ) async {
      final server = _ready()..scoresStatus = 500;
      await pumpWorkspace(tester, server);
      expect(find.text(nextStepUnavailableText), findsOneWidget);
      expect(find.byKey(_primary), findsOneWidget);

      server.scoresStatus = 200;
      await tester.tap(find.byKey(const ValueKey('next-step-retry')));
      await tester.pumpAndSettle();
      expect(find.text(nextStepUnavailableText), findsNothing);
    });
  });
}
