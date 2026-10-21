import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/collapsible_areas_provider.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/shell_test_router.dart';

final _toggle = find.byKey(const ValueKey('rail-toggle'));

NavigationRail _rail(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail));

Future<void> _pump(
  WidgetTester tester,
  {
  Size size = const Size(1280, 800),
  CollapsibleAreasController? areas,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = buildShellTestRouter();
  addTearDown(router.dispose);
  Widget app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    routerConfig: router,
  );
  if (areas != null) {
    app = CollapsibleAreasInherited(controller: areas, child: app);
  }
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

CollapsibleAreasController _controller(LocalUiStore store) {
  final controller = CollapsibleAreasController(store: store);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  testWidgets('an expanded rail stays expanded when the app reopens', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final first = _controller(store);
    await _pump(tester, areas: first);
    expect(_rail(tester).extended, isFalse);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(_rail(tester).extended, isTrue);

    // A fresh app on the same store, as after closing and reopening.
    await tester.pumpWidget(const SizedBox());
    final second = _controller(store);
    await second.load();
    await _pump(tester, areas: second);
    expect(_rail(tester).extended, isTrue);
  });

  testWidgets('reset collapses the rail back to how it starts', (
    tester,
  ) async {
    final controller = _controller(BackendLocalUiStore(MemoryLocalUiBackend()));
    await _pump(tester, areas: controller);
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(_rail(tester).extended, isTrue);

    await controller.resetAll();
    await tester.pumpAndSettle();
    expect(_rail(tester).extended, isFalse);
  });
}
