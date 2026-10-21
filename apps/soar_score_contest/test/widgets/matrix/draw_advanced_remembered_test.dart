import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../../support/matrix_test_support.dart';

MatrixServer _server() => MatrixServer(configuration: matrixConfiguration());

final _toggle = find.byType(ExpansionTile);

// The seed field only exists while the tile is expanded.
final _open = find.byKey(const ValueKey('draw-seed'));

CollapsibleAreasController _controller(LocalUiStore store) {
  final controller = CollapsibleAreasController(store: store);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  testWidgets('the Advanced section stays open when the page is reopened', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final first = _controller(store);
    await pumpMatrixPage(tester, _server(), areas: first);
    expect(_open, findsNothing);

    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(_open, findsOneWidget);

    // A fresh app on the same store, as after closing and reopening.
    await tester.pumpWidget(const SizedBox());
    final second = _controller(store);
    await second.load();
    await pumpMatrixPage(tester, _server(), areas: second);
    expect(_open, findsOneWidget);
  });

  testWidgets('reset closes the Advanced section back to how it starts', (
    tester,
  ) async {
    final controller = _controller(BackendLocalUiStore(MemoryLocalUiBackend()));
    await pumpMatrixPage(tester, _server(), areas: controller);
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(_open, findsOneWidget);

    await controller.resetAll();
    await tester.pumpAndSettle();
    expect(_open, findsNothing);
  });
}
