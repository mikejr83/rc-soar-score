import 'package:flutter/material.dart';

import 'app.dart';
// Platform selection happens at compile time, not at runtime: the web build
// never compiles the native bootstrap (or its FFI-backed data layer and
// `dart:io`), and the only native build today — Windows — never compiles the
// web bootstrap. Both branches expose the same `start()` entry point.
// Ticket 018.
import 'platform/bootstrap.dart' as bootstrap;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The bootstrap must complete before the first frame that needs API
  // access: on Windows it starts the embedded API server and constructs the
  // `ApiClient` for it; on web it constructs the client for the deployed
  // server.
  final appBootstrap = await bootstrap.start();

  // `SoarScoreContestApp` releases the bootstrap (closing the embedded
  // server and its port) on dispose; even in the worst case where the engine
  // tears the process down without disposing, the in-process server cannot
  // outlive the process and the OS reclaims its port.
  runApp(SoarScoreContestApp(bootstrap: appBootstrap));
}
