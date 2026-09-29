import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'pages/contest_selection_stub_page.dart';
import 'pages/landing_page.dart';

/// The contest-administration root path (the landing page).
const String landingPath = '/contest-administration';

GoRouter buildAppRouter({String initialLocation = landingPath}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: navigationGuard,
    routes: [
      GoRoute(
        path: landingPath,
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '$landingPath/home',
        name: 'home',
        builder: (context, state) => const ContestSelectionStubPage(),
      ),
    ],
  );
}

/// Navigation-guard seam (ticket 020). Anonymous access is currently
/// allowed everywhere; ticket 010 replaces this with identity-aware
/// guards. Unknown paths fall back to the landing page so browser
/// back never lands on a dead URL.
String? navigationGuard(BuildContext context, GoRouterState state) {
  final path = state.uri.path;
  if (path == landingPath || path.startsWith('$landingPath/')) {
    return null;
  }
  return landingPath;
}
