import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client_provider.dart';
import 'platform/app_bootstrap.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SoarScoreContestApp extends StatefulWidget {
  const SoarScoreContestApp({super.key, this.bootstrap});

  /// The platform bootstrap that started this app, if any. When present its
  /// `ApiClient` is exposed to the tree and its resources are released when
  /// the app is disposed (which, on Windows, is when the window closes —
  /// ticket 018's clean-shutdown requirement).
  final AppBootstrap? bootstrap;

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
    return app;
  }
}
