import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/fake_app_connectivity.dart';
import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

String _current(WidgetTester tester) => tester
    .widget<Text>(_key('control-results-current'))
    .textSpan!
    .toPlainText();

String _status(WidgetTester tester) =>
    tester.widget<Text>(_key('status-results-value')).data!;

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(_key(key)).onPressed != null;

WorkspaceServer _server({LifecycleState state = LifecycleState.running}) =>
    WorkspaceServer(state: state, configuration: matrixConfiguration());

void main() {
  group('the overall results card', () {
    testWidgets('replaces the placeholder and shows visible results', (
      tester,
    ) async {
      await pumpWorkspace(tester, _server());
      expect(find.textContaining('goes here'), findsNothing);
      expect(_current(tester), 'Now: Visible');
      expect(_enabled(tester, 'control-hideResults'), isTrue);
      expect(_key('control-results-reason'), findsNothing);
    });

    testWidgets('hides, shows and undoes without a reload', (tester) async {
      final server = _server();
      await pumpWorkspace(tester, server);

      await tester.tap(_key('control-hideResults'));
      await tester.pumpAndSettle();
      expect(server.actions, ['hideResults']);
      expect(find.textContaining('Results hidden.'), findsOneWidget);
      // Hidden at 15:00 UTC; the card and the status summary agree.
      expect(
        _current(tester),
        'Now: Hidden through round 2, ends at '
        '2026-10-18 09:00 MDT',
      );
      expect(_status(tester), 'Hidden through round 2');
      expect(find.text('Show results'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(server.actions, ['hideResults', 'showResults']);
      expect(_current(tester), 'Now: Visible');
      expect(_status(tester), 'Off');

      await tester.tap(_key('control-hideResults'));
      await tester.pumpAndSettle();
      await tester.tap(_key('control-showResults'));
      await tester.pumpAndSettle();
      expect(server.actions.last, 'showResults');
      expect(find.text('Results are visible again.'), findsOneWidget);
      expect(_status(tester), 'Off');
    });

    testWidgets('hidden results explain the expiry and count down', (
      tester,
    ) async {
      final server = _server()..startHidden();
      await pumpWorkspace(tester, server);
      expect(_current(tester), contains('Hidden through round 2'));
      expect(
        find.textContaining('24 hours after it was turned on'),
        findsOneWidget,
      );
      // Hidden 15:00, now 16:00: 23 hours left.
      expect(find.textContaining('23 hours left'), findsOneWidget);
      expect(_key('control-showResults'), findsOneWidget);
    });

    testWidgets('the last hour counts in minutes', (tester) async {
      final server = _server()..startHidden();
      await pumpWorkspace(
        tester,
        server,
        clock: () => DateTime.utc(2026, 10, 18, 14, 20),
      );
      expect(find.textContaining('40 minutes left'), findsOneWidget);
    });

    testWidgets('the countdown rounds up and never understates', (
      tester,
    ) async {
      final server = _server()..startHidden();
      // 23 h 59 m left reads 24 hours; 59 m 30 s left reads 60 minutes -> 1
      // hour; one second left reads 1 minute.
      await pumpWorkspace(
        tester,
        server,
        clock: () => DateTime.utc(2026, 10, 17, 15, 1),
      );
      expect(find.textContaining('24 hours left'), findsOneWidget);
    });

    testWidgets('one second left reads 1 minute', (tester) async {
      final server = _server()..startHidden();
      await pumpWorkspace(
        tester,
        server,
        clock: () => DateTime.utc(2026, 10, 18, 14, 59, 59),
      );
      expect(find.textContaining('1 minute left'), findsOneWidget);
    });

    testWidgets('the card flips to Visible by itself when the time runs out', (
      tester,
    ) async {
      final server = _server()..startHidden();
      var now = DateTime.utc(2026, 10, 18, 14, 58);
      await pumpWorkspace(tester, server, clock: () => now);
      expect(_current(tester), contains('Hidden through round 2'));
      expect(find.textContaining('2 minutes left'), findsOneWidget);

      now = DateTime.utc(2026, 10, 18, 14, 59);
      await tester.pump(const Duration(minutes: 1));
      expect(find.textContaining('1 minute left'), findsOneWidget);

      now = DateTime.utc(2026, 10, 18, 15);
      await tester.pump(const Duration(minutes: 1));
      expect(_current(tester), 'Now: Visible');
      expect(_key('control-hideResults'), findsOneWidget);
    });

    testWidgets('hiding that has run out reads as visible', (tester) async {
      final server = _server()..startHidden();
      await pumpWorkspace(
        tester,
        server,
        clock: () => DateTime.utc(2026, 10, 18, 15),
      );
      expect(_current(tester), 'Now: Visible');
      expect(_status(tester), 'Off');
      expect(_enabled(tester, 'control-hideResults'), isTrue);
    });

    testWidgets('offline disables the button with a reason', (tester) async {
      final monitor = FakeAppConnectivity()
        ..internetStatus = ConnectivityStatus.unavailable;
      await pumpWorkspace(tester, _server(), monitor: monitor);
      expect(_enabled(tester, 'control-hideResults'), isFalse);
      expect(
        tester.widget<Text>(_key('control-results-reason')).data,
        'Needs a connection.',
      );
    });

    testWidgets('is busy while it runs and ignores a second tap', (
      tester,
    ) async {
      final server = _server()..actionGate = Completer<void>();
      await pumpWorkspace(tester, server);
      await tester.tap(_key('control-hideResults'));
      await tester.pump();
      expect(_enabled(tester, 'control-hideResults'), isFalse);
      expect(find.text('Hiding…'), findsOneWidget);
      server.actionGate!.complete();
      await tester.pumpAndSettle();
      expect(server.actions, ['hideResults']);
    });

    testWidgets('a conflict leaves the card as it was and says why', (
      tester,
    ) async {
      final server = _server()..rejectNext = 409;
      await pumpWorkspace(tester, server);
      await tester.tap(_key('control-hideResults'));
      await tester.pumpAndSettle();
      expect(server.actions, ['hideResults']);
      expect(_current(tester), 'Now: Visible');
      expect(_status(tester), 'Off');
      expect(find.textContaining('results hiding'), findsWidgets);
    });

    testWidgets('a contest that is not running has no results card', (
      tester,
    ) async {
      await pumpWorkspace(tester, _server(state: LifecycleState.ready));
      expect(_key('workspace-control-results'), findsNothing);
    });
  });
}
