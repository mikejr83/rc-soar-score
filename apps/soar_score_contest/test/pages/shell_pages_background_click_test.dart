import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/page_surface.dart';

void main() {
  // Every page in the shell sits in a nested navigator whose modal barrier
  // plays the system alert for a click no widget catches, so every shell
  // route must put its page on a PageSurface.
  testWidgets('every shell route builds its page on a PageSurface', (
    tester,
  ) async {
    final app = buildAppRouter();
    addTearDown(app.dispose);
    final shell = app.configuration.routes.whereType<ShellRoute>().single;
    final routes = shell.routes.whereType<GoRoute>().toList();
    expect(routes, isNotEmpty);

    for (final route in routes) {
      Widget? built;
      final probe = GoRouter(
        initialLocation: '/a/b/c',
        routes: [
          GoRoute(
            path: '/:contestId/:participantId/:report',
            builder: (context, state) {
              // Only the route's own builder runs; the page is never built.
              built = route.builder!(context, state);
              return const SizedBox();
            },
          ),
        ],
      );
      addTearDown(probe.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: probe));
      expect(built, isA<PageSurface>(), reason: '${route.path} lacks one');
    }
  });
}
