import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/pages/contest/participants_page.dart';
import 'package:soar_score_contest/pages/contest/reports_page.dart';
import 'package:soar_score_contest/pages/contest/sync_page.dart';
import 'package:soar_score_contest/pages/contest/scoring_page.dart';

import 'app_mode_provider.dart';
import 'auth/auth_session.dart';
import 'auth/auth_session_inherited.dart';
import 'pages/contest/configuration_page.dart';
import 'pages/contest/workspace_page.dart';
import 'pages/home_page.dart';
import 'pages/landing_editor_page.dart';
import 'pages/landings_page.dart';
import 'pages/landing_page.dart';
import 'pages/contest/matrix_page.dart';
import 'pages/new_contest_wizard_page.dart';
import 'pages/participant_editor_page.dart';
import 'pages/participants_page.dart';
import 'pages/roles_page.dart';
import 'services/workspace/workspace_control_target.dart';
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

/// The workspace of the contest with [contestId], opened on [target]'s
/// control (`…/workspace#administration`).
String contestWorkspacePathFor(
  String contestId,
  WorkspaceControlTarget target,
) => '${contestWorkspacePath(contestId)}#${target.fragment}';

/// The configuration page of the contest with [contestId].
String contestConfigurationPath(String contestId) =>
    '$contestsPath/$contestId/configuration';

/// The participants page of the contest with [contestId].
String contestParticipantsPath(String contestId) =>
    '$contestsPath/$contestId/participants';

/// The scoring page of the contest with [contestId], opened at [round] (and
/// [group] within it) when given. The Scoring page reads both from the query.
String contestScoringPath(String contestId, {int? round, int? group}) {
  final base = '$contestsPath/$contestId/scoring';
  final query = [
    if (round != null) 'round=$round',
    if (round != null && group != null) 'group=$group',
  ];
  return query.isEmpty ? base : '$base?${query.join('&')}';
}

/// The reports page of the contest with [contestId].
String contestReportsPath(String contestId) =>
    '$contestsPath/$contestId/reports';

/// The sync details page of the contest with [contestId].
String contestSyncPath(String contestId) => '$contestsPath/$contestId/sync';

/// The matrix page of the contest with [contestId].
String contestMatrixPath(String contestId) => '$contestsPath/$contestId/matrix';

GoRouter buildAppRouter({
  String initialLocation = landingPath,
  AppModeNotifier? appMode,
  AuthSession? auth,
}) {
  // One editor is open at a time, so one guard serves both editor routes.
  final editorGuard = UnsavedChangesGuard();
  final wizardGuard = UnsavedChangesGuard();
  final configurationGuard = UnsavedChangesGuard();
  final scoringGuard = UnsavedChangesGuard();
  return GoRouter(
    initialLocation: initialLocation,
    // Re-runs the guard when offline mode or the signed-in state changes.
    refreshListenable: Listenable.merge([if (!kIsWeb) ?appMode, ?auth]),
    redirect: (context, state) =>
        navigationGuard(context, state, appMode: appMode, auth: auth),
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
              guard: configurationGuard,
            ),
            onExit: (context, state) => configurationGuard.confirmLeave(),
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
              initialFocus: WorkspaceControlTarget.fromFragment(
                state.uri.fragment,
              ),
            ),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/scoring',
            name: 'contestScoring',
            builder: (context, state) => ContestScoringPage(
              contestId: state.pathParameters['contestId']!,
              round: int.tryParse(state.uri.queryParameters['round'] ?? ''),
              group: int.tryParse(state.uri.queryParameters['group'] ?? ''),
              guard: scoringGuard,
            ),
            onExit: (context, state) => scoringGuard.confirmLeave(),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/reports',
            name: 'contestReports',
            builder: (context, state) => ContestReportsPage(
              contestId: state.pathParameters['contestId']!,
            ),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/sync',
            name: 'contestSync',
            builder: (context, state) =>
                ContestSyncPage(contestId: state.pathParameters['contestId']!),
          ),
          GoRoute(
            path: '$contestsPath/:contestId/participants',
            name: 'contestParticipants',
            builder: (context, state) => ContestParticipantsPage(
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
/// - The landing page ([landingPath]) is accessible anonymously. A signed-in
///   user ([auth]) is sent on to the main page ([homePath]) instead.
/// - When in offline mode (native desktop only), the navigation guard is inactive
///   for routes, permitting access beyond the landing page.
/// - A signed-in user ([auth]) has access beyond the landing page.
/// - When not in offline mode (and unauthenticated), attempting to access routes
///   beyond the landing page redirects back to [landingPath].
String? navigationGuard(
  BuildContext context,
  GoRouterState state, {
  AppModeNotifier? appMode,
  AuthSession? auth,
}) {
  final path = state.uri.path;

  // Unknown paths fall back to the landing page so browser back never lands on a dead URL.
  if (path != landingPath && !path.startsWith('$landingPath/')) {
    return landingPath;
  }

  final signedIn =
      auth?.isSignedIn ?? authSessionOf(context)?.isSignedIn ?? false;

  // The landing page allows anonymous access; signing in moves on to the
  // main page.
  if (path == landingPath) {
    return signedIn ? homePath : null;
  }

  // Check if offline mode is active (desktop only; tree-shaken on web).
  if (!kIsWeb) {
    final isOffline =
        appMode?.isOfflineMode ?? appModeOf(context)?.isOfflineMode ?? false;
    if (isOffline) {
      return null;
    }
  }

  // A signed-in user may go anywhere.
  if (signedIn) {
    return null;
  }

  // When not in offline mode (and not yet authenticated), routes beyond
  // the landing page are guarded and redirected to the landing page.
  return landingPath;
}
