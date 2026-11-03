import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/pages/landing_page.dart';
import 'package:soar_score_contest/platform/app_bootstrap.dart';
import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';
import 'package:soar_score_contest/widgets/connectivity_indicator.dart';

/// `AppConnectivity` stand-in for widget tests: static state, no platform
/// probes, and recording retry entry points.
class _FakeMonitor extends ChangeNotifier implements AppConnectivity {
  @override
  void reportReachable() {}

  @override
  void reportUnreachable() {}

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  bool supportsConnectivity = true;

  @override
  ConnectivityStatus internetStatus = ConnectivityStatus.available;

  @override
  ConnectivityStatus apiStatus = ConnectivityStatus.available;

  @override
  DateTime? get internetLastObservedAt => null;

  @override
  DateTime? get apiLastSuccessfulAt => null;

  @override
  String? get apiLastError => null;

  @override
  String get apiTarget => 'example.com:8080';

  @override
  Future<void> retryInternet() async {}

  @override
  void retryApi() {}
}

/// `AppBootstrap` stand-in for widget tests: the real native bootstrap starts
/// an HTTP server and a SQLite database, which widget tests do not need.
class _TestBootstrap extends AppBootstrap {
  _TestBootstrap(this._client);

  final ApiClient _client;
  bool _closed = false;

  @override
  ApiClient get apiClient => _client;

  @override
  ApiClient get remoteApiClient => _client;

  @override
  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      _client.close();
    }
  }
}

void main() {
  testWidgets('gates authentication buttons on live connectivity and keeps '
      'the stub dialogs available when connected', (tester) async {
    final client = ApiClient(baseUrl: Uri.parse('http://localhost:8080'));
    final bootstrap = _TestBootstrap(client);
    final monitor = _FakeMonitor()
      ..internetStatus = ConnectivityStatus.unknown
      ..apiStatus = ConnectivityStatus.unknown;
    addTearDown(bootstrap.close);

    await tester.pumpWidget(
      SoarScoreContestApp(bootstrap: bootstrap, connectivity: monitor),
    );
    await tester.pumpAndSettle();

    final signIn = tester.widget<FilledButton>(find.byType(FilledButton));
    final createAccount = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(signIn.onPressed, isNull);
    expect(createAccount.onPressed, isNull);

    monitor.internetStatus = ConnectivityStatus.available;
    monitor.apiStatus = ConnectivityStatus.unavailable;
    monitor.notifyListeners();
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    monitor.internetStatus = ConnectivityStatus.unavailable;
    monitor.apiStatus = ConnectivityStatus.available;
    monitor.notifyListeners();
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    monitor.internetStatus = ConnectivityStatus.available;
    monitor.apiStatus = ConnectivityStatus.available;
    monitor.notifyListeners();
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in is not available yet'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account is not available yet'), findsOneWidget);
  });

  testWidgets('shows both connectivity chips in the AppBar when a monitor '
      'is present', (tester) async {
    final client = ApiClient(baseUrl: Uri.parse('http://localhost:8080'));
    final bootstrap = _TestBootstrap(client);
    final monitor = _FakeMonitor();
    addTearDown(bootstrap.close);

    await tester.pumpWidget(
      SoarScoreContestApp(bootstrap: bootstrap, connectivity: monitor),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    final chips = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(ConnectivityIndicator),
    );
    expect(chips, findsNWidgets(2));
    expect(find.text('Online'), findsNWidgets(2));
    // Internet first, API second (UI spec order).
    final chipsList = tester.widgetList<ConnectivityIndicator>(chips).toList();
    expect(chipsList.first.kind, ConnectivityIndicatorKind.internet);
    expect(chipsList.last.kind, ConnectivityIndicatorKind.api);
  });

  testWidgets('hides the internet chip when the host cannot report '
      'connectivity (D8) but keeps the API chip', (tester) async {
    final client = ApiClient(baseUrl: Uri.parse('http://localhost:8080'));
    final bootstrap = _TestBootstrap(client);
    final monitor = _FakeMonitor()..supportsConnectivity = false;
    addTearDown(bootstrap.close);

    await tester.pumpWidget(
      SoarScoreContestApp(bootstrap: bootstrap, connectivity: monitor),
    );
    await tester.pumpAndSettle();

    final chips = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(ConnectivityIndicator),
    );
    expect(chips, findsOneWidget);
    expect(
      tester.widgetList<ConnectivityIndicator>(chips).single.kind,
      ConnectivityIndicatorKind.api,
    );
  });

  testWidgets('shows no chips without a connectivity monitor, bootstrap or '
      'no monitor', (tester) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();
    expect(find.byType(ConnectivityIndicator), findsNothing);

    final client = ApiClient(baseUrl: Uri.parse('http://localhost:8080'));
    final bootstrap = _TestBootstrap(client);
    addTearDown(bootstrap.close);
    await tester.pumpWidget(SoarScoreContestApp(bootstrap: bootstrap));
    await tester.pumpAndSettle();
    expect(find.byType(ConnectivityIndicator), findsNothing);
  });
}
