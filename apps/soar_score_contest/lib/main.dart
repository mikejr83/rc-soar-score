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
import 'services/alpha_notice/alpha_notice_mode.dart';
import 'services/bundled_licences.dart';
import 'services/connectivity/app_connectivity.dart';
import 'services/connectivity/reachability_forwarder.dart';
import 'services/storage/storage_monitor.dart';
import 'services/collapsible_areas/collapsible_areas_controller.dart';
import 'services/window/close_warning.dart';
import 'services/text_size/text_size_controller.dart';
import 'services/theme/theme_controller.dart';

final _logger = Logger('Main');

Future<void> main() async {
  configureLogging(level: Level.FINER, format: LogFormat.text);

  WidgetsFlutterBinding.ensureInitialized();
  installCloseWarning();
  registerBundledLicences();

  try {
    _logger.info('Starting Soar Score Contest App');
    await _runContestApp(await bootstrap.start());
  } catch (error, stackTrace) {
    _logger.severe('Soar Score startup failed: $error\n$stackTrace');
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
  await _runContestApp(await bootstrap.start());
}

Future<void> _runContestApp(AppBootstrap appBootstrap) async {
  // The connectivity monitor observes the same client the app talks through,
  // so no API request ever bypasses `soar_score_api`, and no platform channel
  // is needed on web (its connectivity probe resolves there). Tests that pump
  // the app without a bootstrap simply get no monitor (D5).
  final connectivity = AppConnectivity(client: appBootstrap.remoteApiClient);
  forwardReachability(connectivity, appBootstrap);
  final storage = appBootstrap.hasLocalStorage
      ? StorageMonitor(probe: appBootstrap.checkStorage)
      : null;

  // Load the saved theme first so the first frame already has it.
  final theme = ThemeController(
    store: appBootstrap.localUiStore,
    account: appBootstrap.uiAccount,
  );
  await theme.load();
  final textSize = TextSizeController(
    store: appBootstrap.localUiStore,
    account: appBootstrap.uiAccount,
  );
  await textSize.load();
  final areas = CollapsibleAreasController(
    store: appBootstrap.localUiStore,
    account: appBootstrap.uiAccount,
  );
  await areas.load();

  // `SoarScoreContestApp` releases the bootstrap (closing the embedded
  // server and its port) and disposes the monitor on dispose.
  runApp(
    SoarScoreContestApp(
      bootstrap: appBootstrap,
      connectivity: connectivity,
      storage: storage,
      themeController: theme,
      textSizeController: textSize,
      collapsibleAreas: areas,
      alphaNotice: showAlphaNotice,
    ),
  );
}
