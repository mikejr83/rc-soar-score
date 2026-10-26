import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/matrix_test_support.dart';

final _rounds = find.byKey(const ValueKey('draw-rounds'));
final _groups = find.byKey(const ValueKey('draw-groups'));
final _draw = find.byKey(const ValueKey('draw-button'));
final _cancel = find.byKey(const ValueKey('cancel-draw'));
final _text = find.byKey(const ValueKey('draw-progress-text'));
final _bar = find.byKey(const ValueKey('draw-progress-bar'));

/// Starts a draw that the server holds until told to finish.
Future<MatrixServer> _startHeldDraw(WidgetTester tester) async {
  final server = MatrixServer(configuration: matrixConfiguration())
    ..holdDraw = Completer<void>();
  await pumpMatrixPage(tester, server);
  await tester.enterText(_rounds, '3');
  await tester.enterText(_groups, '2');
  await tester.pump();
  await tester.ensureVisible(_draw);
  await tester.tap(_draw);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('confirm-draw')));
  await tester.pump();
  return server;
}

/// Lets the page's progress poll run once.
Future<void> _poll(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump();
}

void main() {
  testWidgets('a running draw shows its progress and a Cancel button', (
    tester,
  ) async {
    final server = await _startHeldDraw(tester);

    expect(find.text('Drawing matrix…'), findsOneWidget);
    expect(_text, findsOneWidget);
    expect(find.text('Starting the draw…'), findsOneWidget);
    expect(_cancel, findsOneWidget);

    await _poll(tester);

    expect(server.statusRequests, greaterThan(0));
    expect(find.text('Drawing the matrix: 40% (seed 2 of 3)'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(_bar).value, 0.4);

    server.drawPercent = 75;
    await _poll(tester);
    expect(find.text('Drawing the matrix: 75% (seed 2 of 3)'), findsOneWidget);

    server.holdDraw!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Round 1'), findsOneWidget);
    expect(_bar, findsNothing);
  });

  testWidgets('Cancel stops the draw and keeps the form as it was', (
    tester,
  ) async {
    final server = await _startHeldDraw(tester);
    await _poll(tester);

    await tester.ensureVisible(_cancel);
    await tester.tap(_cancel);
    await tester.pumpAndSettle();

    expect(server.cancelRequests, 1);
    expect(find.text('Draw cancelled. Nothing was changed.'), findsOneWidget);
    expect(find.text('Draw the first matrix'), findsOneWidget);
    expect(_bar, findsNothing);
    expect(tester.widget<TextField>(_rounds).controller?.text, '3');
    expect(tester.widget<TextField>(_groups).controller?.text, '2');
    expect(find.text('The server rejected the draw'), findsNothing);
    expect(tester.widget<FilledButton>(_draw).onPressed, isNotNull);
    expect(server.matrix, isNull);

    // A cancelled draw can be started again, as a new request.
    server.holdDraw = null;
    await tester.tap(_draw);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-draw')));
    await tester.pumpAndSettle();
    expect(server.draws, hasLength(2));
    expect(server.draws.last['id'], isNot(server.draws.first['id']));
    expect(find.text('Round 1'), findsOneWidget);
  });
}
