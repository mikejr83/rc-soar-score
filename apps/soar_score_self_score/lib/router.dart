import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/score_entry_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/scores',
      builder: (context, state) => const ScoreEntryPage(),
    ),
  ],
);
