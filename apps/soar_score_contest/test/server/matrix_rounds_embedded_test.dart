import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/matrix_page.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' show Id;

import '../support/embedded_matrix_support.dart';

/// Adding rounds and redrawing against the real embedded API and SQLite
/// (#264): the new rounds show in the grid, a redraw gives a different
/// matrix, and a retired pilot is left out of the rounds it draws.
void main() {
  testWidgets('add rounds, then redraw without a retired pilot', (
    tester,
  ) async {
    HttpOverrides.global = null;
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final tempDir = Directory.systemTemp.createTempSync('soar_score_rounds');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    await tester.runAsync(() async {
      final server = await startEmbeddedServer(
        '${tempDir.path}${Platform.pathSeparator}soar_score.db',
      );
      final client = ApiClient(
        baseUrl: server.baseUrl,
        tokenProvider: () async => server.secret,
      );
      addTearDown(() async {
        client.close();
        await server.close();
      });
      final contestId = await seedMatrixContest(client);
      await client.drawMatrix(
        contestId,
        DrawMatrixRequest(id: Id.create(), rounds: 4, groupsPerRound: 3),
      );

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
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: MatrixPage(key: UniqueKey(), contestId: contestId.value),
              ),
            ),
          ),
        );
        await settle();
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();
        await settle();
      }

      /// The slots of the current rounds, to tell one matrix from another.
      Future<List<String>> layout() async {
        final matrix = await client.matrix(contestId);
        final rounds = {
          for (final round in matrix.rounds)
            if (round.isCurrent) round.id: round.ordinal,
        };
        return [
          for (final a in matrix.assignments)
            if (!a.isSuperseded && rounds.containsKey(a.scheduledRoundId))
              '${rounds[a.scheduledRoundId]}/${a.group}/'
                  '${a.contestParticipationId.value}',
        ]..sort();
      }

      await open();
      expect(find.text('Round 4'), findsOneWidget);
      expect(find.text('Round 5'), findsNothing);

      // Add two rounds.
      await tap(find.byKey(const ValueKey('add-rounds')));
      await tester.enterText(find.byKey(const ValueKey('draw-rounds')), '2');
      await tester.pump();
      await tap(find.byKey(const ValueKey('draw-button')));
      await tap(find.byKey(const ValueKey('confirm-rounds')));
      expect(find.text('Round 6'), findsOneWidget);
      expect(find.text('Round 7'), findsNothing);
      expect(find.text('7 pilots, each once'), findsWidgets);
      final added = await layout();

      // Retire a pilot, then redraw everything: nothing has scores.
      final participations = await client.participations(contestId);
      final retiree = participations.firstWhere((p) => p.isPilot);
      await client.updateParticipation(
        contestId,
        retiree.id,
        UpdateParticipationRequest(
          baseRevision: retiree.revision,
          retiredAtRound: 1,
        ),
      );
      await open();
      await tap(find.byKey(const ValueKey('redraw-rounds')));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('draw-rounds')))
            .controller!
            .text,
        '6',
      );
      await tap(find.byKey(const ValueKey('draw-button')));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('6 scoring pilots'),
        ),
        findsOneWidget,
      );
      await tap(find.byKey(const ValueKey('confirm-rounds')));

      expect(find.text('Round 6'), findsOneWidget);
      expect(find.text('6 pilots, each once'), findsWidgets);
      final redrawn = await layout();
      expect(redrawn, isNot(added));
      expect(
        redrawn.where((slot) => slot.endsWith(retiree.id.value)),
        isEmpty,
        reason: 'a retired pilot is not drawn',
      );
      final matrix = await client.matrix(contestId);
      expect(matrix.revision!.revisionNumber, 3);
    });
  });
}
