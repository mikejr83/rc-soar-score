import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/pages/contest/matrix_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/text_size/preferred_text_scaler.dart';
import 'package:soar_score_contest/services/text_size/text_size.dart';
import 'package:soar_score_contest/services/text_size/text_size_controller.dart';
import 'package:soar_score_core/soar_score_core.dart' show Id;
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/embedded_matrix_support.dart';
import '../support/fake_bootstrap.dart';

/// `FakeBootstrap` that talks to a real embedded server, so the contest pages
/// have a contest, pilots and a drawn matrix to lay out.
class _EmbeddedBootstrap extends FakeBootstrap {
  _EmbeddedBootstrap(super.store, this.client);

  final ApiClient client;

  @override
  ApiClient get apiClient => client;

  @override
  ApiClient get remoteApiClient => client;

  @override
  Future<void> close() async {}
}

/// Every key page of the contest app at each text size and width: nothing
/// overflows or throws. Network calls are real, so the test lets real time
/// pass between frames.
void main() {
  testWidgets('key pages lay out at every text size', (tester) async {
    // The test binding blocks real HTTP; this test talks to a loopback server.
    HttpOverrides.global = null;
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    final tempDir = Directory.systemTemp.createTempSync('soar_score_text');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final failures = <String>[];
    final reported = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final what = details.exceptionAsString().split('\n').first;
      final widget = details
          .toString()
          .split('\n')
          .where((l) => l.contains('file:///') && !l.contains('/test/'))
          .take(2)
          .join(' ');
      reported.add('$what $widget'.trim());
      original!(details);
    };

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
        DrawMatrixRequest(
          id: Id.create(),
          rounds: 4,
          groupsPerRound: 3,
          randomSeed: 42,
        ),
      );
      final id = contestId.value;
      final routes = {
        'contests': homePath,
        'workspace': contestWorkspacePath(id),
        'configuration': contestConfigurationPath(id),
        'contest participants': contestParticipantsPath(id),
        'matrix': contestMatrixPath(id),
        'scoring': contestScoringPath(id, round: 1, group: 1),
        'reports': contestReportsPath(id),
        'sync': contestSyncPath(id),
        'settings': settingsPath,
        'participants': participantsPath,
        'roles': rolesPath,
        'landings': landingsPath,
        'new contest': newContestPath,
      };

      // Phone width is the matrix layout alone: the rest needs a tablet.
      for (final (width, height) in [
        (1280.0, 900.0),
        (800.0, 900.0),
        (800.0, 600.0),
        (400.0, 900.0),
      ]) {
        for (final size in TextSize.values) {
          for (final MapEntry(key: name, value: path) in routes.entries) {
            if (width < 600 && name != 'matrix') continue;
            final phone = width < 600;
            tester.view.physicalSize = Size(width, height);
            final store = BackendLocalUiStore(MemoryLocalUiBackend());
            final controller = TextSizeController();
            await controller.setSize(size);
            await tester.pumpWidget(
              phone
                  ? ApiClientInherited(
                      client: client,
                      child: MaterialApp(
                        home: Scaffold(
                          body: MatrixPage(key: UniqueKey(), contestId: id),
                        ),
                        builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: PreferredTextScaler.of(
                              TextScaler.noScaling,
                              size,
                            ),
                          ),
                          child: child!,
                        ),
                      ),
                    )
                  : SoarScoreContestApp(
                      key: UniqueKey(),
                      bootstrap: _EmbeddedBootstrap(store, client),
                      routerInitialLocation: path,
                      textSizeController: controller,
                    ),
            );
            for (var i = 0; i < 20; i++) {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              await tester.pump();
            }
            // Flutter reports only the first exception to `takeException`,
            // so read each one from the error handler and name its widget.
            tester.takeException();
            for (final line in reported.toSet()) {
              failures.add(
                '$name at ${width.round()}x${height.round()} dp, '
                '${size.name}: $line',
              );
            }
            reported.clear();
            controller.dispose();
          }
        }
      }
    });

    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
