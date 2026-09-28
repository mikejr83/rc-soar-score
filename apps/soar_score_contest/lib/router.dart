import 'package:go_router/go_router.dart';

import 'pages/landing_page.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/contest-administration',
    routes: [
      GoRoute(
        path: '/contest-administration',
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
    ],
  );
}
