import 'package:go_router/go_router.dart';

import 'pages/contests_page.dart';
import 'pages/group_results_page.dart';
import 'pages/home_page.dart';
import 'pages/invitation_page.dart';
import 'pages/pilot_overview_page.dart';
import 'pages/results_page.dart';
import 'pages/score_entry_page.dart';
import 'pages/team_page.dart';
import 'session/guest_session_scope.dart';

/// Routes follow `plan/ui/participant-scoring/participant-scoring.md`.
const homePath = '/';
const contestsPath = '/contests';

/// The address an invitation link carries. Matches `/invitations/{credential}`
/// in the participant-scoring spec.
String invitationPath(String credential) =>
    '/invitations/${Uri.encodeComponent(credential)}';

String contestPath(String contestId) => '/contests/$contestId';
String teamPath(String contestId) => '/contests/$contestId/team';
String resultsPath(String contestId, {int? asOfRound}) =>
    '/contests/$contestId/results${asOfRound == null ? '' : '?round=$asOfRound'}';
String pilotPath(String contestId, String pilotId) =>
    '/contests/$contestId/pilots/$pilotId';
String scoreEntryPath(String contestId, String pilotId, String roundId) =>
    '/contests/$contestId/pilots/$pilotId/rounds/$roundId';

/// Group results for a round. Not in the spec's route table; the spec shows
/// them under score entry, and this gives them an address.
String groupResultsPath(String contestId, String pilotId, String roundId) =>
    '${scoreEntryPath(contestId, pilotId, roundId)}/group';

final router = GoRouter(
  routes: [
    GoRoute(path: homePath, builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/invitations/:credential',
      builder: (context, state) =>
          InvitationPage(credential: state.pathParameters['credential']!),
    ),
    GoRoute(
      path: contestsPath,
      builder: (context, state) => const ContestsPage(),
      routes: [
        // The contest entry route sends a pilot to their pilot overview. A
        // guest session names the pilot; everyone else goes to the team
        // overview until accounts and helpers exist.
        GoRoute(
          path: ':contestId',
          redirect: (context, state) {
            if (state.uri.pathSegments.length > 2) return null;
            final contestId = state.pathParameters['contestId']!;
            final session = context.guestSessions.read();
            if (session != null &&
                session.role == 'pilot' &&
                session.contestId == contestId) {
              return pilotPath(contestId, session.pilotId);
            }
            return teamPath(contestId);
          },
          routes: [
            GoRoute(
              path: 'team',
              builder: (context, state) =>
                  TeamPage(contestId: state.pathParameters['contestId']!),
            ),
            GoRoute(
              path: 'results',
              builder: (context, state) => ResultsPage(
                contestId: state.pathParameters['contestId']!,
                asOfRound: int.tryParse(
                  state.uri.queryParameters['round'] ?? '',
                ),
              ),
            ),
            GoRoute(
              path: 'pilots/:pilotId',
              // A guest sees only their own pilot. The server checks the token
              // on every read; this keeps a hand-edited address from showing
              // another pilot's page shell.
              redirect: (context, state) {
                final session = context.guestSessions.read();
                final contestId = state.pathParameters['contestId']!;
                final pilotId = state.pathParameters['pilotId']!;
                // Only pilot sessions exist in the first field release. Any
                // other role has no pilot page and goes through contest entry.
                if (session != null && session.role != 'pilot') {
                  return contestPath(contestId);
                }
                if (session != null &&
                    session.contestId == contestId &&
                    session.pilotId != pilotId) {
                  return pilotPath(contestId, session.pilotId);
                }
                if (session != null && session.contestId != contestId) {
                  return contestPath(session.contestId);
                }
                return null;
              },
              builder: (context, state) => PilotOverviewPage(
                contestId: state.pathParameters['contestId']!,
                pilotId: state.pathParameters['pilotId']!,
              ),
              routes: [
                GoRoute(
                  path: 'rounds/:roundId',
                  builder: (context, state) => ScoreEntryPage(
                    contestId: state.pathParameters['contestId']!,
                    pilotId: state.pathParameters['pilotId']!,
                    roundId: state.pathParameters['roundId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'group',
                      builder: (context, state) => GroupResultsPage(
                        contestId: state.pathParameters['contestId']!,
                        pilotId: state.pathParameters['pilotId']!,
                        roundId: state.pathParameters['roundId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
