import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/matrix_page.dart';
import 'package:soar_score_contest/server/embedded_server.dart';

import '../support/embedded_matrix_support.dart';

/// The matrix page itself against the real embedded API and SQLite: the
/// director fills in the form, confirms, and the drawn grid appears. Network
/// calls are real, so the test lets real time pass between frames.
void main() {
  testWidgets('draw from the form, then reopen the page on the same matrix', (
    tester,
  ) async {
    // The test binding blocks real HTTP; this test talks to a loopback server.
    HttpOverrides.global = null;
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final tempDir = Directory.systemTemp.createTempSync('soar_score_page');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    await tester.runAsync(() async {
      final server = await startEmbeddedServer(
        '${tempDir.path}${Platform.pathSeparator}soar_score.db',
      );
      final client = ApiClient(baseUrl: server.baseUrl);
      addTearDown(() async {
        client.close();
        await server.close();
      });
      final contestId = await seedMatrixContest(client);

      Future<void> settle() async {
        for (var i = 0; i < 40; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      }

      Future<void> open() async {
        await tester.pumpWidget(
          ApiClientInherited(
            client: client,
            child: MaterialApp(
              home: Scaffold(
                body: MatrixPage(key: UniqueKey(), contestId: contestId.value),
              ),
            ),
          ),
        );
        await settle();
      }

      await open();
      expect(find.text('No matrix drawn yet'), findsOneWidget);
      expect(find.text('7 scoring pilots'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('draw-rounds')), '4');
      await tester.enterText(find.byKey(const ValueKey('draw-groups')), '3');
      await tester.pump();
      expect(find.text('3 groups: 3, 2, 2 pilots'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('draw-button')));
      await tester.tap(find.byKey(const ValueKey('draw-button')));
      await tester.pumpAndSettle();
      expect(find.text('Draw the matrix?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-draw')));
      await settle();

      expect(find.text('Draw the first matrix'), findsNothing);
      for (var round = 1; round <= 4; round++) {
        expect(find.text('Round $round'), findsOneWidget);
      }
      expect(find.text('7 pilots, each once'), findsWidgets);
      expect(find.text('Group C'), findsOneWidget);
      expect(find.text('FAIRNESS SCORE'), findsOneWidget);
      expect(find.byKey(const ValueKey('fairness-score')), findsOneWidget);

      // Reopening the page shows the same matrix, not the form.
      final seed = tester.widgetList<Text>(find.byType(Text)).length;
      await open();
      expect(find.text('Draw the first matrix'), findsNothing);
      expect(find.text('Round 4'), findsOneWidget);
      expect(tester.widgetList<Text>(find.byType(Text)).length, seed);
    });
  });
}
