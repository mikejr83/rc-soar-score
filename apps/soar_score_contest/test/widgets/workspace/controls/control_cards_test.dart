import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/controls/contest_transition.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(_key(key)).onPressed != null;

WorkspaceServer _server({
  LifecycleState state = LifecycleState.running,
  AdminLock lock = AdminLock.unlocked,
  ScoringAccess access = ScoringAccess.closed,
}) => WorkspaceServer(
  state: state,
  lock: lock,
  access: access,
  configuration: matrixConfiguration(),
);

void main() {
  group('the status summary', () {
    testWidgets('shows the labelled values as text', (tester) async {
      await pumpWorkspace(
        tester,
        _server(lock: AdminLock.locked, access: ScoringAccess.open),
      );
      expect(_key('status-summary'), findsOneWidget);
      expect(find.text('Participant scoring'), findsWidgets);
      expect(_text(tester, 'status-lifecycle-value'), 'Running');
      expect(_text(tester, 'status-scoring-value'), 'Open');
      expect(_text(tester, 'status-administration-value'), 'Locked');
      expect(_text(tester, 'status-publication-value'), 'Unpublished');
      expect(_text(tester, 'status-results-value'), 'Off');
      expect(_text(tester, 'status-archive-value'), 'Not archived');
      expect(_key('status-deletion'), findsNothing);
    });

    testWidgets('follows a change without a reload', (tester) async {
      await pumpWorkspace(tester, _server());
      await tester.tap(_key('control-lock'));
      await tester.pumpAndSettle();
      await tester.tap(_key('lock-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(_text(tester, 'status-administration-value'), 'Locked');
    });
  });

  group('enabled and disabled controls for each lifecycle', () {
    for (final state in LifecycleState.values) {
      testWidgets('${state.name}: complete, scoring and lock', (tester) async {
        await pumpWorkspace(tester, _server(state: state));
        final running = state == LifecycleState.running;
        final completed = state == LifecycleState.completed;

        expect(_enabled(tester, 'control-complete'), running);
        expect(
          _key('control-lifecycle-reason'),
          running ? findsNothing : findsOneWidget,
        );

        expect(_enabled(tester, 'control-openScoring'), !completed);
        expect(
          _key('control-scoring-reason'),
          completed ? findsOneWidget : findsNothing,
        );

        // The lock does not depend on the lifecycle.
        expect(_enabled(tester, 'control-lock'), isTrue);
        expect(_key('control-administration-reason'), findsNothing);
      });
    }

    testWidgets('a disabled complete control explains itself', (tester) async {
      await pumpWorkspace(tester, _server(state: LifecycleState.ready));
      expect(
        tester.widget<Text>(_key('control-lifecycle-reason')).data,
        contains('Only a running contest can be completed'),
      );
    });

    testWidgets('archive is disabled with a reason', (tester) async {
      await pumpWorkspace(tester, _server());
      expect(_enabled(tester, 'control-archive'), isFalse);
      expect(_key('control-archive-reason'), findsOneWidget);
    });
  });

  group('participant scoring', () {
    testWidgets('opens, closes and undoes in place', (tester) async {
      final server = _server();
      await pumpWorkspace(tester, server);
      expect(find.text('Open scoring'), findsOneWidget);

      await tester.tap(_key('control-openScoring'));
      await tester.pumpAndSettle();
      expect(server.actions, ['openScoring']);
      expect(find.text(scoringOpenedMessage), findsOneWidget);
      expect(_text(tester, 'status-scoring-value'), 'Open');
      expect(find.text('Close scoring'), findsOneWidget);

      await tester.tap(_key('control-closeScoring'));
      await tester.pumpAndSettle();
      expect(server.actions, ['openScoring', 'closeScoring']);
      expect(find.text(scoringClosedMessage), findsOneWidget);
      expect(_text(tester, 'status-scoring-value'), 'Closed');

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(server.actions.last, 'openScoring');
      expect(_text(tester, 'status-scoring-value'), 'Open');
    });

    testWidgets('is busy while it runs and ignores a second tap', (
      tester,
    ) async {
      final server = _server()..actionGate = Completer<void>();
      await pumpWorkspace(tester, server);
      await tester.tap(_key('control-openScoring'));
      await tester.pump();
      expect(_enabled(tester, 'control-openScoring'), isFalse);
      expect(find.text('Opening…'), findsWidgets);
      server.actionGate!.complete();
      await tester.pumpAndSettle();
      expect(server.actions, ['openScoring']);
    });
  });

  group('administration lock', () {
    testWidgets('lock asks first, naming what it blocks', (tester) async {
      final server = _server();
      await pumpWorkspace(tester, server);

      await tester.tap(_key('control-lock'));
      await tester.pumpAndSettle();
      expect(_key('lock-dialog'), findsOneWidget);
      expect(find.text('Administration: Unlocked → Locked'), findsOneWidget);
      for (final blocked in [
        'Contest configuration',
        'Participants and their roles',
        'The matrix and its assignments',
        'Scores',
      ]) {
        expect(find.text('• $blocked'), findsOneWidget);
      }
      expect(server.actions, isEmpty);

      await tester.tap(_key('lock-dialog-cancel'));
      await tester.pumpAndSettle();
      expect(server.actions, isEmpty);
      expect(server.contest.adminLock, AdminLock.unlocked);

      await tester.tap(_key('control-lock'));
      await tester.pumpAndSettle();
      await tester.tap(_key('lock-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(server.actions, ['lock']);
      expect(find.text(lockedMessage), findsOneWidget);
      expect(find.text('Unlock administration'), findsWidgets);
    });

    testWidgets('unlock needs no confirmation and can be undone', (
      tester,
    ) async {
      final server = _server(lock: AdminLock.locked);
      await pumpWorkspace(tester, server);
      await tester.tap(_key('control-unlock'));
      await tester.pumpAndSettle();
      expect(_key('lock-dialog'), findsNothing);
      expect(server.actions, ['unlock']);
      expect(find.text(unlockedMessage), findsOneWidget);
      expect(_text(tester, 'status-administration-value'), 'Unlocked');

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(server.actions, ['unlock', 'lock']);
    });
  });

  group('a 409 conflict', () {
    testWidgets('leaves the page unchanged and offers Refresh', (tester) async {
      final server = _server()..rejectNext = 409;
      await pumpWorkspace(tester, server);
      final reads = server.contestReads;

      await tester.tap(_key('control-openScoring'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Your change to participant scoring wasn't applied. This page is "
          'out of date.',
        ),
        findsOneWidget,
      );
      expect(find.text(scoringOpenedMessage), findsNothing);
      expect(_text(tester, 'status-scoring-value'), 'Closed');
      expect(_enabled(tester, 'control-openScoring'), isTrue);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(server.contestReads, greaterThan(reads));
      expect(find.textContaining("wasn't applied"), findsNothing);
    });

    testWidgets('a stale revision on lock is rejected the same way', (
      tester,
    ) async {
      final server = _server();
      await pumpWorkspace(tester, server);
      server.contest = Contest.fromJson({
        ...server.contest.toJson(),
        'revision': 5,
      });
      await tester.tap(_key('control-lock'));
      await tester.pumpAndSettle();
      await tester.tap(_key('lock-dialog-confirm'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("Your change to administration wasn't applied"),
        findsOneWidget,
      );
      expect(server.contest.adminLock, AdminLock.unlocked);
    });
  });
}
