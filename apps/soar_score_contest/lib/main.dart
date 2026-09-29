import 'package:flutter/material.dart';

import 'app.dart';
// Platform selection happens at compile time, not at runtime: the web build
// never compiles the native bootstrap (or its FFI-backed data layer and
// `dart:io`), and the only native build today — Windows — never compiles the
// web bootstrap. Both branches expose the same `start()` entry point.
// Ticket 018.
import 'platform/bootstrap.dart' as bootstrap;
import 'services/connectivity/app_connectivity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The bootstrap must complete before the first frame that needs API
  // access: on Windows it starts the embedded API server and constructs the
  // `ApiClient` for it; on web it constructs the client for the deployed
  // server.
  final appBootstrap = await bootstrap.start();

  // The connectivity monitor observes the same client the app talks through,
  // so no API request ever bypasses `soar_score_api`, and no platform channel
  // is needed on web (its connectivity probe resolves there). Tests that pump
  // the app without a bootstrap simply get no monitor (D5).
  final connectivity = AppConnectivity(client: appBootstrap.remoteApiClient);

  // `SoarScoreContestApp` releases the bootstrap (closing the embedded
  // server and its port) and disposes the monitor on dispose.
  runApp(
    SoarScoreContestApp(
      bootstrap: appBootstrap,
      connectivity: connectivity,
    ),
  );
}
