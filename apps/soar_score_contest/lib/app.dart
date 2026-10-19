import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import 'api_client_provider.dart';
import 'app_sync_provider.dart';
import 'app_mode_provider.dart';
import 'auth/auth_session_inherited.dart';
import 'connectivity_provider.dart';
import 'contest_draft_provider.dart';
import 'local_ui_store_provider.dart';
import 'platform/app_bootstrap.dart';
import 'router.dart';
import 'services/collapsible_areas/collapsible_areas_controller.dart';
import 'services/theme/theme_controller.dart';
import 'collapsible_areas_provider.dart';
import 'theme_controller_provider.dart';
import 'ui_account_provider.dart';
import 'services/connectivity/app_connectivity.dart';
import 'services/new_contest/contest_draft_store.dart';
import 'services/new_contest/local_ui_draft_persistence.dart';

class SoarScoreContestApp extends StatefulWidget {
  const SoarScoreContestApp({
    super.key,
    this.bootstrap,
    this.connectivity,
    this.appMode,
    this.routerInitialLocation = landingPath,
    this.themeController,
    this.collapsibleAreas,
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

  /// The theme controller, already loaded so the first frame has the right
  /// theme. When `null` the app makes one from the bootstrap's store and loads
  /// it after the first frame.
  final ThemeController? themeController;

  /// The remembered hidden and minimized areas, already loaded so panels do
  /// not flip after the first frame. When `null` the app makes one from the
  /// bootstrap's store and loads it after the first frame.
  final CollapsibleAreasController? collapsibleAreas;

  static const String title = 'RC Soar Score Contest Management';

  @override
  State<SoarScoreContestApp> createState() => _SoarScoreContestAppState();
}

class _SoarScoreContestAppState extends State<SoarScoreContestApp> {
  late final AppModeNotifier? _appMode;
  late final bool _ownsAppMode;
  late final GoRouter _router;
  late final ThemeController _theme;
  late final bool _ownsTheme;
  late final CollapsibleAreasController _areas;
  late final bool _ownsAreas;

  /// The user's single New Contest draft, kept across restarts where the
  /// bootstrap has local UI storage.
  late final ContestDraftStore _draftStore;

  @override
  void initState() {
    super.initState();
    final bootstrap = widget.bootstrap;
    final uiStore = bootstrap?.localUiStore;
    _draftStore = ContestDraftStore(
      persistence: bootstrap == null || uiStore == null
          ? null
          : LocalUiDraftPersistence(
              uiStore,
              account: () => bootstrap.uiAccount.id,
            ),
    );
    if (!kIsWeb) {
      _ownsAppMode = widget.appMode == null;
      _appMode = widget.appMode ?? AppModeNotifier();
    } else {
      _ownsAppMode = false;
      _appMode = null;
    }
    final givenTheme = widget.themeController;
    _ownsTheme = givenTheme == null;
    _theme =
        givenTheme ??
        ThemeController(
          store: widget.bootstrap?.localUiStore,
          account: widget.bootstrap?.uiAccount,
        );
    if (_ownsTheme) unawaited(_theme.load());
    final givenAreas = widget.collapsibleAreas;
    _ownsAreas = givenAreas == null;
    _areas =
        givenAreas ??
        CollapsibleAreasController(
          store: widget.bootstrap?.localUiStore,
          account: widget.bootstrap?.uiAccount,
        );
    if (_ownsAreas) unawaited(_areas.load());
    _router = buildAppRouter(
      initialLocation: widget.routerInitialLocation,
      appMode: _appMode,
      auth: widget.bootstrap?.authSession,
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
    if (_ownsTheme) _theme.dispose();
    if (_ownsAreas) _areas.dispose();
    _draftStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget app = ListenableBuilder(
      listenable: _theme,
      builder: (context, _) => MaterialApp.router(
        title: SoarScoreContestApp.title,
        debugShowCheckedModeBanner: false,
        theme: ContestAppTheme.lightTheme,
        darkTheme: ContestAppTheme.darkTheme,
        themeMode: _theme.mode,
        routerConfig: _router,
      ),
    );
    app = ThemeControllerInherited(controller: _theme, child: app);
    app = CollapsibleAreasInherited(controller: _areas, child: app);
    app = ContestDraftInherited(store: _draftStore, child: app);
    final bootstrap = widget.bootstrap;
    if (bootstrap != null) {
      app = UiAccountInherited(account: bootstrap.uiAccount, child: app);
      final uiStore = bootstrap.localUiStore;
      if (uiStore != null) {
        app = LocalUiStoreInherited(store: uiStore, child: app);
      }
      app = AppSyncInherited(sync: bootstrap.appSync, child: app);
      app = ApiClientInherited(client: bootstrap.apiClient, child: app);
      final auth = bootstrap.authSession;
      if (auth != null) {
        app = AuthSessionInherited(session: auth, child: app);
      }
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
