import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';

import 'app_mode_provider.dart';
import 'pages/contest_configuration_page.dart';
import 'pages/contest_workspace_page.dart';
import 'pages/home_page.dart';
import 'pages/landing_editor_page.dart';
import 'pages/landings_page.dart';
import 'pages/landing_page.dart';
import 'pages/matrix_page.dart';
import 'pages/new_contest_wizard_page.dart';
import 'pages/participant_editor_page.dart';
import 'pages/participants_page.dart';
import 'pages/roles_page.dart';
import 'widgets/contest_shell.dart';
import 'widgets/unsaved_changes_guard.dart';

/// The contest-administration root path (the landing page).
const String landingPath = '/contest-administration';

/// The main page (contest selection). The user arrives here after signing in
/// or choosing offline mode, and the application shell wraps it and every
/// route below it.
const String homePath = '$landingPath/home';

/// The root of the per-contest routes. Every route below it belongs to one
/// selected contest, and the shell shows contest-scoped navigation there.
const String contestsPath = '$landingPath/contests';

/// The New Contest wizard. It sits below [contestsPath] but creates a
/// contest rather than belonging to one, so it stays in the system scope.
const String newContestPath = '$contestsPath/new';

/// The director's participant list (system scope).
const String participantsPath = '$landingPath/participants';

/// The roles page (system scope).
const String rolesPath = '$landingPath/roles';

/// The roles page with its name dialog open, for the `New role` action.
const String newRolePath = '$rolesPath?new=1';

/// The landings page (system scope).
const String landingsPath = '$landingPath/landings';

/// The landing table form; a copy starts from the table passed as `extra`.
const String newLandingPath = '$landingsPath/new';

/// The participant editor in create mode.
const String newParticipantPath = '$participantsPath/new';

/// The participant editor for the profile with [participantId].
String participantPath(String participantId) =>
    '$participantsPath/$participantId';

/// The contest workspace for the contest with [contestId].
String contestWorkspacePath(String contestId) =>
    '$contestsPath/$contestId/workspace';

/// The configuration page of the contest with [contestId].
String contestConfigurationPath(String contestId) =>
    '$contestsPath/$contestId/configuration';

/// The matrix page of the contest with [contestId].
String contestMatrixPath(String contestId) => '$contestsPath/$contestId/matrix';

GoRouter buildAppRouter({
  String initialLocation = landingPath,
  AppModeNotifier? appMode,
}) {
  // One editor is open at a time, so one guard serves both editor routes.
  final editorGuard = UnsavedChangesGuard();
  final wizardGuard = UnsavedChangesGuard();
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
          GoRoute(
            path: participantsPath,
            name: 'participants',
            builder: (context, state) => const ParticipantsPage(),
          ),
          GoRoute(
            path: rolesPath,
            name: 'roles',
            builder: (context, state) => RolesPage(
              createRequested: state.uri.queryParameters['new'] == '1',
            ),
          ),
          GoRoute(
            path: landingsPath,
            name: 'landings',
            builder: (context, state) => const LandingsPage(),
          ),
          GoRoute(
            path: newLandingPath,
            name: 'newLanding',
            builder: (context, state) => LandingEditorPage(
              source: state.extra is LandingTableView
                  ? state.extra as LandingTableView
                  : null,
              guard: editorGuard,
            ),
            onExit: (context, state) => editorGuard.confirmLeave(),
          ),
          GoRoute(
            path: newParticipantPath,
            name: 'newParticipant',
            builder: (context, state) =>
                ParticipantEditorPage(guard: editorGuard),
            onExit: (context, state) => editorGuard.confirmLeave(),
          ),
          GoRoute(
            path: '$participantsPath/:participantId',
            name: 'editParticipant',
            builder: (context, state) => ParticipantEditorPage(
              participantId: state.pathParameters['participantId'],
              guard: editorGuard,
            ),
            onExit: (context, state) => editorGuard.confirmLeave(),
          ),
          GoRoute(
            path: newContestPath,
            name: 'newContest',
            builder: (context, state) =>
                NewContestWizardPage(guard: wizardGuard),
            onExit: (context, state) => wizardGuard.confirmLeave(),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/configuration',
            name: 'contestConfiguration',
            builder: (context, state) => ContestConfigurationPage(
              contestId: state.pathParameters['contestId']!,
            ),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/matrix',
            name: 'contestMatrix',
            builder: (context, state) =>
                MatrixPage(contestId: state.pathParameters['contestId']!),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/workspace',
            name: 'contestWorkspace',
            builder: (context, state) => ContestWorkspacePage(
              contestId: state.pathParameters['contestId']!,
            ),
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
