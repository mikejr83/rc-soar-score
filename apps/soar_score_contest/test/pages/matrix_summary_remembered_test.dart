import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/matrix_test_support.dart';

MatrixServer _server() => MatrixServer(
  configuration: matrixConfiguration({'teams_enabled': true}),
  matrix: drawnMatrix(),
);

final _toggle = find.byKey(const ValueKey('summary-toggle'));
const _phone = Size(400, 800);

CollapsibleAreasController _controller(LocalUiStore store) {
  final controller = CollapsibleAreasController(store: store);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  testWidgets('hiding the summary is kept when the page is opened again', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final first = _controller(store);
    await pumpMatrixPage(tester, _server(), areas: first);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(find.text('Show summary'), findsOneWidget);

    // A fresh app on the same store, as after closing and reopening.
    await tester.pumpWidget(const SizedBox());
    final second = _controller(store);
    await second.load();
    await pumpMatrixPage(tester, _server(), areas: second);

    expect(find.text('Show summary'), findsOneWidget);
    expect(find.text('Pilot pairs by number of meetings'), findsNothing);
  });

  testWidgets('showing the summary again is kept too', (tester) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final controller = _controller(store);
    await pumpMatrixPage(tester, _server(), areas: controller);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    await tester.tap(_toggle);
    await tester.pumpAndSettle();

    expect(find.text('Hide summary'), findsOneWidget);
    final fresh = _controller(store);
    await fresh.load();
    await tester.pumpWidget(const SizedBox());
    await pumpMatrixPage(tester, _server(), areas: fresh);
    expect(find.text('Hide summary'), findsOneWidget);
  });

  testWidgets('a remembered choice beats the phone default', (tester) async {
    final controller = _controller(BackendLocalUiStore(MemoryLocalUiBackend()));
    await pumpMatrixPage(tester, _server(), size: _phone, areas: controller);
    expect(find.text('Show summary'), findsOneWidget);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();

    expect(find.text('Hide summary'), findsOneWidget);
  });

  testWidgets('reset brings the summary back to how it starts', (tester) async {
    final controller = _controller(BackendLocalUiStore(MemoryLocalUiBackend()));
    await pumpMatrixPage(tester, _server(), areas: controller);
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(find.text('Show summary'), findsOneWidget);

    await controller.resetAll();
    await tester.pumpAndSettle();

    expect(find.text('Hide summary'), findsOneWidget);
  });
}
