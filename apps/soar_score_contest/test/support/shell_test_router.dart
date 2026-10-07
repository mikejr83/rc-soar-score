import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';

/// A valid UUIDv7 contest id for contest-scoped routes.
const String testContestId = '01890a5d-ac96-774b-bcce-b302099a8057';

class LandingStub extends StatelessWidget {
  const LandingStub({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Landing stub'));
}

/// Builds a router with the landing route outside the shell, and inside it
/// the main page, a nested route below it (a stand-in for a future page),
/// and a contest workspace route, so [ContestShell] can be exercised in
/// both the system and the contest scope.
GoRouter buildShellTestRouter({String initialLocation = homePath}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: landingPath,
        name: 'landing',
        builder: (context, state) => const LandingStub(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ContestShell(state: state, child: child),
        routes: [
          GoRoute(
            path: homePath,
            name: 'home',
            builder: (context, state) => const Text('Home content'),
            routes: [
              GoRoute(
                path: 'workspace',
                name: 'workspace',
                builder: (context, state) => const Text('Workspace content'),
              ),
            ],
          ),
          GoRoute(
            path: participantsPath,
            builder: (context, state) => const Text('Participants content'),
          ),
          GoRoute(
            path: rolesPath,
            builder: (context, state) => const Text('Roles content'),
          ),
          GoRoute(
            path: landingsPath,
            builder: (context, state) => const Text('Landings content'),
          ),
          GoRoute(
            path: '$participantsPath/:participantId',
            builder: (context, state) => const Text('Participant editor'),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/workspace',
            name: 'contestWorkspace',
            builder: (context, state) =>
                const Text('Contest workspace content'),
          ),
        ],
      ),
    ],
  );
}

/// Pumps [router] in a bare `MaterialApp`, below [client] when given, and
/// settles.
Future<void> pumpShellRouter(
  WidgetTester tester,
  GoRouter router, {
  ApiClient? client,
}) async {
  Widget app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    routerConfig: router,
  );
  if (client != null) {
    app = ApiClientInherited(client: client, child: app);
  }
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// The labels of the rail's destinations, in order.
List<String> railLabels(WidgetTester tester) => tester
    .widget<NavigationRail>(find.byType(NavigationRail))
    .destinations
    .map((destination) => (destination.label as Text).data!)
    .toList();
