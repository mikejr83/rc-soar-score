import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'app.dart';
import 'pages/bootstrap_failure_page.dart';
import 'platform/app_bootstrap.dart';
// Platform selection happens at compile time, not at runtime: the web build
// never compiles the native bootstrap (or its FFI-backed data layer and
// `dart:io`), and the only native build today — Windows — never compiles the
// web bootstrap. Both branches expose the same `start()` entry point.
// Ticket 018.
import 'platform/bootstrap.dart' as bootstrap;
import 'services/connectivity/app_connectivity.dart';

final _logger = Logger('Main');

Future<void> main() async {
  configureLogging(level: Level.FINER, format: LogFormat.text);

  WidgetsFlutterBinding.ensureInitialized();

  try {
    _logger.info('Starting Soar Score Contest App');
    _runContestApp(await bootstrap.start());
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Soar Score startup failed: $error',
      stackTrace: stackTrace,
    );
    runApp(
      MaterialApp(
        title: SoarScoreContestApp.title,
        theme: ThemeData(useMaterial3: true),
        home: BootstrapFailurePage(
          error: error,
          onRetry: _retryStartup,
          onQuit: bootstrap.quitApplication,
        ),
      ),
    );
  }
}

Future<void> _retryStartup() async {
  _runContestApp(await bootstrap.start());
}

void _runContestApp(AppBootstrap appBootstrap) {
  // The connectivity monitor observes the same client the app talks through,
  // so no API request ever bypasses `soar_score_api`, and no platform channel
  // is needed on web (its connectivity probe resolves there). Tests that pump
  // the app without a bootstrap simply get no monitor (D5).
  final connectivity = AppConnectivity(client: appBootstrap.remoteApiClient);

  // `SoarScoreContestApp` releases the bootstrap (closing the embedded
  // server and its port) and disposes the monitor on dispose.
  runApp(
    SoarScoreContestApp(bootstrap: appBootstrap, connectivity: connectivity),
  );
}
