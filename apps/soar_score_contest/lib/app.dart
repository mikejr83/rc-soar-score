import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client_provider.dart';
import 'connectivity_provider.dart';
import 'platform/app_bootstrap.dart';
import 'router.dart';
import 'services/connectivity/app_connectivity.dart';
import 'theme/app_theme.dart';

class SoarScoreContestApp extends StatefulWidget {
  const SoarScoreContestApp({super.key, this.bootstrap, this.connectivity});

  /// The platform bootstrap that started this app, if any. When present its
  /// `ApiClient` is exposed to the tree and its resources are released when
  /// the app is disposed (which, on Windows, is when the window closes —
  /// ticket 018's clean-shutdown requirement).
  final AppBootstrap? bootstrap;

  /// The app-scoped connectivity monitor driving the landing page's
  /// internet and remote API indicators. `null` (tests without a bootstrap)
  /// renders the tree exactly as the app did before the indicators existed.
  final AppConnectivity? connectivity;

  static const String title = 'RC Soar Score Contest Management';

  @override
  State<SoarScoreContestApp> createState() => _SoarScoreContestAppState();
}

class _SoarScoreContestAppState extends State<SoarScoreContestApp> {
  @override
  void dispose() {
    // Closing the bootstrap also shuts down the embedded server on Windows;
    // the web variant only releases its HTTP client.
    final bootstrap = widget.bootstrap;
    if (bootstrap != null) {
      unawaited(bootstrap.close());
    }
    // The monitor owns a periodic poll timer and a connectivity stream
    // subscription; both are cancelled by dispose.
    widget.connectivity?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp.router(
      title: SoarScoreContestApp.title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: buildAppRouter(),
    );
    final bootstrap = widget.bootstrap;
    if (bootstrap != null) {
      app = ApiClientInherited(client: bootstrap.apiClient, child: app);
    }
    final connectivity = widget.connectivity;
    if (connectivity != null) {
      app = AppConnectivityInherited(monitor: connectivity, child: app);
    }
    return app;
  }
}
