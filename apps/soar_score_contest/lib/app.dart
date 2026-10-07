import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api_client_provider.dart';
import 'app_mode_provider.dart';
import 'connectivity_provider.dart';
import 'contest_draft_provider.dart';
import 'platform/app_bootstrap.dart';
import 'router.dart';
import 'services/connectivity/app_connectivity.dart';
import 'services/new_contest/contest_draft_store.dart';
import 'theme/app_theme.dart';

class SoarScoreContestApp extends StatefulWidget {
  const SoarScoreContestApp({
    super.key,
    this.bootstrap,
    this.connectivity,
    this.appMode,
    this.routerInitialLocation = landingPath,
  });

  /// The platform bootstrap that started this app, if any. When present its
  /// `ApiClient` is exposed to the tree and its resources are released when
  /// the app is disposed (which, on Windows, is when the window closes —
  /// ticket 018's clean-shutdown requirement).
  final AppBootstrap? bootstrap;

  /// The app-scoped connectivity monitor driving the landing page's
  /// internet and remote API indicators. `null` (tests without a bootstrap)
  /// renders the tree exactly as the app did before the indicators existed.
  final AppConnectivity? connectivity;

  /// The app-scoped application mode notifier tracking offline mode (native
  /// desktop only). Unused and tree-shaken out on web.
  final AppModeNotifier? appMode;

  /// The location the router starts at. Defaults to the landing page; tests
  /// override it to exercise the navigation guard's redirect.
  final String routerInitialLocation;

  static const String title = 'RC Soar Score Contest Management';

  @override
  State<SoarScoreContestApp> createState() => _SoarScoreContestAppState();
}

class _SoarScoreContestAppState extends State<SoarScoreContestApp> {
  late final AppModeNotifier? _appMode;
  late final bool _ownsAppMode;
  late final GoRouter _router;

  /// The user's single New Contest draft, kept until the app is closed.
  final ContestDraftStore _draftStore = ContestDraftStore();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _ownsAppMode = widget.appMode == null;
      _appMode = widget.appMode ?? AppModeNotifier();
    } else {
      _ownsAppMode = false;
      _appMode = null;
    }
    _router = buildAppRouter(
      initialLocation: widget.routerInitialLocation,
      appMode: _appMode,
    );
  }

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
    if (_ownsAppMode) {
      _appMode?.dispose();
    }
    _router.dispose();
    _draftStore.dispose();
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
      routerConfig: _router,
    );
    app = ContestDraftInherited(store: _draftStore, child: app);
    final bootstrap = widget.bootstrap;
    if (bootstrap != null) {
      app = ApiClientInherited(client: bootstrap.apiClient, child: app);
    }
    final connectivity = widget.connectivity;
    if (connectivity != null) {
      app = AppConnectivityInherited(monitor: connectivity, child: app);
    }
    final appMode = _appMode;
    if (!kIsWeb && appMode != null) {
      app = AppModeInherited(notifier: appMode, child: app);
    }
    return app;
  }
}
