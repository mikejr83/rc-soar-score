import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../../support/matrix_test_support.dart';

MatrixServer _server() => MatrixServer(matrix: drawnMatrix());

final _toggle = find.byKey(const ValueKey('draw-details-toggle'));
final _details = find.text('Matrix revision');

CollapsibleAreasController _controller(LocalUiStore store) {
  final controller = CollapsibleAreasController(store: store);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  testWidgets('draw details stay shown when the page is reopened', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final first = _controller(store);
    await pumpMatrixPage(tester, _server(), areas: first);
    expect(_details, findsNothing);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(_details, findsOneWidget);

    // A fresh app on the same store, as after closing and reopening.
    await tester.pumpWidget(const SizedBox());
    final second = _controller(store);
    await second.load();
    await pumpMatrixPage(tester, _server(), areas: second);
    expect(_details, findsOneWidget);
  });

  testWidgets('reset hides the draw details back to how they start', (
    tester,
  ) async {
    final controller = _controller(BackendLocalUiStore(MemoryLocalUiBackend()));
    await pumpMatrixPage(tester, _server(), areas: controller);
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(_details, findsOneWidget);

    await controller.resetAll();
    await tester.pumpAndSettle();
    expect(_details, findsNothing);
  });
}
