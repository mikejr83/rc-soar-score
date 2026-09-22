import 'package:go_router/go_router.dart';

import 'pages/contests_page.dart';
import 'pages/home_page.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/contests',
        name: 'contests',
        builder: (context, state) => const ContestsPage(),
      ),
    ],
  );
}
