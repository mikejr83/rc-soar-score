import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/widgets/connectivity_indicator.dart';
import 'package:soar_score_contest/widgets/contest_status_bar.dart';

import '../support/fake_app_connectivity.dart';

/// Hosts the status bar at the bottom of a page, the way the shell does,
/// optionally below a connectivity provider.
Widget _host({FakeAppConnectivity? monitor}) {
  Widget app = const MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(child: SizedBox.shrink()),
          ContestStatusBar(),
        ],
      ),
    ),
  );
  if (monitor != null) {
    app = AppConnectivityInherited(monitor: monitor, child: app);
  }
  return app;
}

List<ConnectivityIndicatorKind> _indicatorKinds(WidgetTester tester) => tester
    .widgetList<ConnectivityIndicator>(find.byType(ConnectivityIndicator))
    .map((indicator) => indicator.kind)
    .toList();

void main() {
  testWidgets('spans the full width even inside a centering column', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    final screen = tester.getSize(find.byType(Scaffold));
    expect(tester.getSize(find.byType(ContestStatusBar)).width, screen.width);
    expect(find.text(ContestStatusBar.status), findsOneWidget);
  });

  testWidgets('shows no indicators without a connectivity monitor', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.byType(ConnectivityIndicator), findsNothing);
  });

  testWidgets('shows the internet then the API indicator on the trailing '
      'side', (tester) async {
    final monitor = FakeAppConnectivity();
    addTearDown(monitor.dispose);
    await tester.pumpWidget(_host(monitor: monitor));

    expect(_indicatorKinds(tester), [
      ConnectivityIndicatorKind.internet,
      ConnectivityIndicatorKind.api,
    ]);

    final status = tester.getRect(find.text(ContestStatusBar.status));
    final api = tester.getRect(find.byType(ConnectivityIndicator).last);
    final bar = tester.getRect(find.byType(ContestStatusBar));
    expect(api.left, greaterThan(status.right));
    expect(bar.right - api.right, lessThan(32));
  });

  testWidgets('hides the internet indicator when the host cannot report '
      'connectivity', (tester) async {
    final monitor = FakeAppConnectivity()..supportsConnectivity = false;
    addTearDown(monitor.dispose);
    await tester.pumpWidget(_host(monitor: monitor));

    expect(_indicatorKinds(tester), [ConnectivityIndicatorKind.api]);
  });
}
