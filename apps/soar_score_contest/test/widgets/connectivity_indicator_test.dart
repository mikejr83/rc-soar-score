import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';
import 'package:soar_score_contest/widgets/connectivity_indicator.dart';

/// `AppConnectivity` stand-in for widget tests: every public property is
/// configurable, and [notifyListeners] replays a change to any
/// `ListenableBuilder` watching it. Retry calls are recorded, never executed
/// (the chip only invokes them — it does not decide connectivity).
class _FakeMonitor extends ChangeNotifier implements AppConnectivity {
  _FakeMonitor({
    this.internetStatus = ConnectivityStatus.unknown,
    this.apiStatus = ConnectivityStatus.unknown,
  });

  @override
  ConnectivityStatus internetStatus;

  @override
  ConnectivityStatus apiStatus;

  @override
  bool supportsConnectivity = true;

  @override
  DateTime? internetLastObservedAt;

  @override
  DateTime? apiLastSuccessfulAt;

  @override
  String? apiLastError;

  @override
  String apiTarget = 'example.com:8080';

  int internetRetryCalls = 0;
  int apiRetryCalls = 0;

  @override
  Future<void> retryInternet() async {
    internetRetryCalls++;
  }

  @override
  void retryApi() {
    apiRetryCalls++;
  }
}

Widget _host({required ConnectivityIndicator indicator}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Host'), actions: [indicator]),
    ),
  );
}

const _internetStates = <(ConnectivityStatus, IconData, String)>[
  (ConnectivityStatus.unknown, Icons.help_outline, 'Unknown'),
  (ConnectivityStatus.checking, Icons.sync, 'Checking'),
  (ConnectivityStatus.available, Icons.wifi, 'Online'),
  (ConnectivityStatus.unavailable, Icons.wifi_off, 'Offline'),
];

void main() {
  group('ConnectivityIndicator chip', () {
    for (final (status, icon, label) in _internetStates) {
      testWidgets(
        'internet chip: ${status.name} shows icon + text label',
        (tester) async {
          final monitor = _FakeMonitor(internetStatus: status);
          await tester.pumpWidget(
            _host(indicator: ConnectivityIndicator.internet(monitor)),
          );

          final labelFinder = find.text(label);
          expect(labelFinder, findsOneWidget);
          expect(find.byIcon(icon), findsOneWidget);
          // Icon and text are always paired (never color-only) and the text
          // is the machine-readable status for assistive tech.
          final chip = tester
              .widgetList<Semantics>(
                find.byWidgetPredicate(
                  (w) =>
                      w is Semantics &&
                      w.properties.button == true &&
                      w.properties.label != null,
                ),
              )
              .single;
          expect(chip.properties.label, 'Internet connectivity');
          expect(chip.properties.value, label);
          expect(tester.getSize(find.text(label)).height, greaterThan(12));
        },
      );
    }

    testWidgets('api chip: available and unavailable', (tester) async {
      final online = _FakeMonitor(apiStatus: ConnectivityStatus.available);
      await tester.pumpWidget(_host(indicator: ConnectivityIndicator.api(online)));
      expect(find.text('Online'), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
      expect(
        tester
            .widgetList<Semantics>(
              find.byWidgetPredicate(
                (w) =>
                    w is Semantics &&
                    w.properties.button == true &&
                    w.properties.label != null,
              ),
            )
            .single
            .properties.label,
        'Remote API connectivity',
      );

      online.apiStatus = ConnectivityStatus.unavailable;
      online.notifyListeners();
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });

  group('ConnectivityIndicator detail dialog', () {
    testWidgets(
      'internet dialog shows status and last observed, Retry now re-checks',
      (tester) async {
        final observedAt = DateTime(2026, 9, 28, 12, 30);
        final monitor = _FakeMonitor(
          internetStatus: ConnectivityStatus.available,
        )..internetLastObservedAt = observedAt.toLocal();
        await tester.pumpWidget(
          _host(indicator: ConnectivityIndicator.internet(monitor)),
        );

        await tester.tap(find.text('Online'));
        await tester.pumpAndSettle();

        expect(find.text('Internet connectivity'), findsOneWidget);
        expect(find.text('Status: Online'), findsOneWidget);
        expect(
          find.text(
            'Last observed: '
            '${DateFormat.yMd().add_jm().format(observedAt)}',
          ),
          findsOneWidget,
        );

        // Retry now calls the monitor and leaves the dialog open showing the
        // (possibly new) state.
        monitor.internetStatus = ConnectivityStatus.unavailable;
        monitor.notifyListeners();
        await tester.tap(find.text('Retry now'));
        await tester.pump();
        expect(monitor.internetRetryCalls, 1);
        expect(find.text('Status: Offline'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'api dialog shows last success, target, error, and Retry now re-probes',
      (tester) async {
        final lastSuccess = DateTime(2026, 9, 28, 9, 0);
        final monitor = _FakeMonitor(apiStatus: ConnectivityStatus.unavailable)
          ..apiLastSuccessfulAt = lastSuccess.toLocal()
          ..apiLastError = 'Network error';
        await tester.pumpWidget(
          _host(indicator: ConnectivityIndicator.api(monitor)),
        );

        await tester.tap(find.text('Offline'));
        await tester.pumpAndSettle();

        expect(find.text('Remote API connectivity'), findsOneWidget);
        expect(find.text('Status: Offline'), findsOneWidget);
        expect(
          find.text(
            'Last successful connection: '
            '${DateFormat.yMd().add_jm().format(lastSuccess)}',
          ),
          findsOneWidget,
        );
        expect(find.text('Target: example.com:8080'), findsOneWidget);
        expect(find.text('Error: Network error'), findsOneWidget);

        monitor.apiStatus = ConnectivityStatus.available;
        monitor.apiLastError = null;
        monitor.notifyListeners();
        await tester.tap(find.text('Retry now'));
        await tester.pump();
        expect(monitor.apiRetryCalls, 1);
        expect(find.text('Status: Online'), findsOneWidget);
        // The error line disappears once the probe succeeds.
        expect(find.text('Error: Network error'), findsNothing);
      },
    );

    testWidgets('api dialog shows Never before the first success', (
      tester,
    ) async {
      final monitor = _FakeMonitor(apiStatus: ConnectivityStatus.unknown);
      await tester.pumpWidget(
        _host(indicator: ConnectivityIndicator.api(monitor)),
      );

      await tester.tap(find.text('Unknown'));
      await tester.pumpAndSettle();

      expect(find.text('Last successful connection: Never'), findsOneWidget);
      expect(find.text('Error: Network error'), findsNothing);
    });
  });
}
