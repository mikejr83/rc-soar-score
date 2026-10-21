import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/collapsible_areas_provider.dart';
import 'package:soar_score_contest/pages/contest/configuration_page.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_contest/widgets/configuration/landing_entries_table.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../../support/configuration_fixtures.dart';

final _toggle = find.byKey(const ValueKey('landing-entries-toggle'));

Future<void> _pump(
  WidgetTester tester,
  ConfigServer server, {
  CollapsibleAreasController? areas,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget page = const MaterialApp(
    home: Scaffold(
      body: ContestConfigurationPage(contestId: configContestId),
    ),
  );
  if (areas != null) {
    page = CollapsibleAreasInherited(controller: areas, child: page);
  }
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: page,
    ),
  );
  await tester.pumpAndSettle();
}

CollapsibleAreasController _controller(LocalUiStore store) {
  final controller = CollapsibleAreasController(store: store);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  testWidgets('the landing entries stay shown when the page is reopened', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final first = _controller(store);
    await _pump(tester, ConfigServer(revision: configRevision(1)), areas: first);

    await tester.ensureVisible(_toggle);
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(find.byType(LandingEntriesTable), findsOneWidget);

    // A fresh app on the same store, as after closing and reopening.
    await tester.pumpWidget(const SizedBox());
    final second = _controller(store);
    await second.load();
    await _pump(tester, ConfigServer(revision: configRevision(1)), areas: second);
    expect(find.byType(LandingEntriesTable), findsOneWidget);
  });

  testWidgets('reset hides the landing entries back to how they start', (
    tester,
  ) async {
    final controller = _controller(BackendLocalUiStore(MemoryLocalUiBackend()));
    await _pump(
      tester,
      ConfigServer(revision: configRevision(1)),
      areas: controller,
    );
    expect(find.byType(LandingEntriesTable), findsNothing);
    await tester.ensureVisible(_toggle);
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(find.byType(LandingEntriesTable), findsOneWidget);

    await controller.resetAll();
    await tester.pumpAndSettle();
    expect(find.byType(LandingEntriesTable), findsNothing);
  });
}
