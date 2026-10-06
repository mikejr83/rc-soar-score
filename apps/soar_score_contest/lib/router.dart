import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_mode_provider.dart';
import 'pages/home_page.dart';
import 'pages/landing_page.dart';
import 'widgets/contest_shell.dart';

/// The contest-administration root path (the landing page).
const String landingPath = '/contest-administration';

/// The main page (contest selection). The user arrives here after signing in
/// or choosing offline mode, and the application shell wraps it and every
/// route below it.
const String homePath = '$landingPath/home';

GoRouter buildAppRouter({
  String initialLocation = landingPath,
  AppModeNotifier? appMode,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: !kIsWeb ? appMode : null,
    redirect: (context, state) =>
        navigationGuard(context, state, appMode: appMode),
    routes: [
      // The landing page is a plain page outside the shell; the shell starts
      // once the user is using the application.
      GoRoute(
        path: landingPath,
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ContestShell(state: state, child: child),
        routes: [
          GoRoute(
            path: homePath,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
    ],
  );
}

/// Navigation-guard seam (ticket 020).
///
/// Guard behavior:
/// - Unknown paths outside the contest administration hierarchy fall back to [landingPath].
/// - The landing page ([landingPath]) is always accessible anonymously.
/// - When in offline mode (native desktop only), the navigation guard is inactive
///   for routes, permitting access beyond the landing page.
/// - When not in offline mode (and unauthenticated), attempting to access routes
///   beyond the landing page redirects back to [landingPath].
String? navigationGuard(
  BuildContext context,
  GoRouterState state, {
  AppModeNotifier? appMode,
}) {
  final path = state.uri.path;

  // Unknown paths fall back to the landing page so browser back never lands on a dead URL.
  if (path != landingPath && !path.startsWith('$landingPath/')) {
    return landingPath;
  }

  // The landing page allows anonymous access.
  if (path == landingPath) {
    return null;
  }

  // Check if offline mode is active (desktop only; tree-shaken on web).
  if (!kIsWeb) {
    final isOffline =
        appMode?.isOfflineMode ?? appModeOf(context)?.isOfflineMode ?? false;
    if (isOffline) {
      return null;
    }
  }

  // When not in offline mode (and not yet authenticated), routes beyond
  // the landing page are guarded and redirected to the landing page.
  return landingPath;
}
