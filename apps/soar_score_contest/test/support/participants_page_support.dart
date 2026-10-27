import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/participants_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/unsaved_changes_guard.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_test_support.dart';

Id _id(String kind, int n) =>
    Id.parse('019c0000-0000-7000-8000-$kind${n.toString().padLeft(8, '0')}');

final DateTime _created = DateTime.utc(2026, 9);
final Id _actor = Id.parse('019c0000-0000-7000-8000-0000000000b1');

/// The participation id of person [n] (1 to 6) on the Participants page.
Id personParticipationId(int n) => _id('0011', n);

/// The profile id of person [n] (1 to 8); 7 and 8 are not in the contest.
Id personProfileId(int n) => _id('0015', n);

const _people = [
  ('Ann', 'Lee', 'Open', 'Flying Gators'),
  ('Bo', 'Ray', 'Sportsman', 'Harbor Hawks'),
  ('Cy', 'Fox', 'Open', 'Flying Gators'),
  ('Di', 'Park', '', ''),
  ('Gary', 'Novak', '', ''),
  ('Eve', 'Moss', 'Open', ''),
];

/// A fake server for the contest Participants page: the contest's reads and
/// the writes the page makes, with the state they change.
///
/// People 1 to 4 are pilots, 5 is a timer and 6 an official (non-flying, no
/// class). Person 1 has a score when [withScores] is set. Profiles 7 and 8
/// are saved but not in the contest.
class ParticipantsServer {
  ParticipantsServer({
    LifecycleState state = LifecycleState.configuring,
    AdminLock lock = AdminLock.unlocked,
    this.drawn = false,
    this.options = const {
      'teams_enabled': true,
      'team_pilot_count': 2,
      'classes_enabled': true,
      'roles_enabled': true,
      'participant_numbers_enabled': true,
    },
    this.withScores = false,
    int pilots = 4,
  }) : contest = matrixContest(state: state, lock: lock) {
    for (var n = 1; n <= _people.length; n++) {
      if (n <= 4 && n > pilots) continue;
      _participations.add(_participation(n));
      final team = _people[n - 1].$4;
      if (team.isNotEmpty) {
        final teamId = _teamIdOf(team);
        _memberships.add(
          TeamMembership(
            id: _id('0017', n),
            teamId: teamId,
            contestParticipationId: personParticipationId(n),
            contestId: contestId,
          ),
        );
      }
    }
  }

  Contest contest;
  final bool drawn;
  final Map<String, Object?> options;
  final bool withScores;

  final List<ContestParticipation> _participations = [];
  final List<TeamMembership> _memberships = [];
  final List<Team> _teams = [
    Team(id: _id('0016', 1), contestId: contestId, name: 'Flying Gators'),
    Team(id: _id('0016', 2), contestId: contestId, name: 'Harbor Hawks'),
  ];

  /// The bodies of the participation updates, with the participation id.
  final List<({Id id, Map<String, dynamic> body})> updates = [];
  final List<Map<String, dynamic>> additions = [];
  final List<Id> removals = [];
  final List<Map<String, dynamic>> membershipAdds = [];
  final List<Id> membershipRemovals = [];
  final List<Map<String, dynamic>> teamCreations = [];

  /// Answers the update of these participations with a status and code.
  final Map<Id, (int, String)> updateFailures = {};

  /// Fails every read with this status when set.
  int? readFailure;

  /// Fails every addition with this status when set.
  int? addFailure;

  /// Answers every removal of these participations with a 409.
  final Set<Id> removalRefused = {};

  /// Makes every request fail like a lost connection.
  bool offline = false;

  /// A notice sent with every successful participation update.
  String? warning;

  Id _teamIdOf(String name) =>
      _teams.firstWhere((team) => team.name == name).id;

  ContestParticipation _participation(int n) {
    final (_, _, classification, _) = _people[n - 1];
    final pilot = n <= 4;
    return ContestParticipation(
      id: personParticipationId(n),
      contestId: contestId,
      participantProfileId: personProfileId(n),
      roleId: n == 5
          ? SystemRoles.helperId
          : n == 6
          ? SystemRoles.teamManagerId
          : SystemRoles.pilotId,
      roleName: n == 5
          ? 'Helper'
          : n == 6
          ? 'Team manager'
          : 'Pilot',
      roleType: pilot ? RoleType.pilot : RoleType.nonFlier,
      classification: pilot && classification.isNotEmpty
          ? classification
          : null,
      participantNumber: drawn && pilot ? n : null,
      scoringUuid: ScoringUuid.create(),
    );
  }

  List<ParticipantProfile> get _profiles => [
    for (var n = 1; n <= 8; n++)
      ParticipantProfile(
        id: personProfileId(n),
        ownerAccountId: _actor,
        firstName: n <= 6 ? _people[n - 1].$1 : (n == 7 ? 'Pia' : 'Quinn'),
        lastName: n <= 6 ? _people[n - 1].$2 : (n == 7 ? 'Ward' : 'Zane'),
        email: n.isOdd ? 'p$n@example.com' : null,
        createdAt: _created,
        updatedAt: _created,
      ),
  ];

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _error(int status, String code, String message) => _json({
    'error': {'code': code, 'message': message},
  }, status);

  Future<http.Response> handle(http.Request request) async {
    if (offline) throw http.ClientException('offline', request.url);
    final path = request.url.path;
    final method = request.method;
    if (method == 'GET' && readFailure != null) {
      return _error(readFailure!, 'internal_error', 'The server failed.');
    }
    if (method == 'GET') return _read(path);
    final body = request.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    final participation = RegExp(r'/participations/([^/]+)$').firstMatch(path);
    if (path.endsWith('/participations') && method == 'POST') {
      return _add(body);
    }
    if (participation != null && method == 'PUT') {
      return _update(Id.parse(participation.group(1)!), body);
    }
    if (participation != null && method == 'DELETE') {
      return _remove(Id.parse(participation.group(1)!));
    }
    if (path.endsWith('/teams') && method == 'POST') {
      teamCreations.add(body);
      final team = Team(
        id: Id.parse(body['id']! as String),
        contestId: contestId,
        name: body['name']! as String,
      );
      _teams.add(team);
      return _json(team.toJson(), 201);
    }
    if (path.endsWith('/team-memberships') && method == 'POST') {
      membershipAdds.add(body);
      final membership = TeamMembership(
        id: Id.parse(body['id']! as String),
        teamId: Id.parse(body['team_id']! as String),
        contestParticipationId: Id.parse(
          body['contest_participation_id']! as String,
        ),
        contestId: contestId,
      );
      _memberships.add(membership);
      return _json(membership.toJson(), 201);
    }
    final membershipPath = RegExp(r'/team-memberships/([^/]+)$')
        .firstMatch(path);
    if (membershipPath != null && method == 'DELETE') {
      final id = Id.parse(membershipPath.group(1)!);
      membershipRemovals.add(id);
      _memberships.removeWhere((m) => m.id == id);
      return http.Response('', 204);
    }
    return _error(404, 'not_found', 'Unknown request $method $path');
  }

  http.Response _read(String path) {
    if (path.endsWith('/configuration')) {
      return _json(matrixConfiguration(options).toJson());
    }
    if (path.endsWith('/participations')) {
      return _json({
        'participations': [for (final p in _participations) p.toJson()],
      });
    }
    if (path.endsWith('/participants')) {
      return _json({
        'participants': [for (final p in _profiles) p.toJson()],
      });
    }
    if (path.endsWith('/team-memberships')) {
      return _json({
        'team_memberships': [for (final m in _memberships) m.toJson()],
      });
    }
    if (path.endsWith('/teams')) {
      return _json({
        'teams': [for (final t in _teams) t.toJson()],
      });
    }
    if (path.endsWith('/roles')) {
      return _json({
        'roles': [
          SystemRoles.pilot.toJson(),
          SystemRoles.helper.toJson(),
          SystemRoles.teamManager.toJson(),
        ],
      });
    }
    if (path.endsWith('/matrix')) {
      return _json((drawn ? drawnMatrix() : CurrentMatrix()).toJson());
    }
    if (path.endsWith('/scores')) {
      return _json({
        'scores': [
          if (withScores)
            {
              'placeholder': ScorePlaceholder(
                id: _id('0018', 1),
                contestId: contestId,
                contestParticipationId: personParticipationId(1),
                assignmentId: _id('0004', 101),
                state: ScorePlaceholderState.official,
                scoreRevision: 1,
              ).toJson(),
              'official_score': null,
            },
        ],
        'rounds': const [],
      });
    }
    return _json(contest.toJson());
  }

  http.Response _add(Map<String, dynamic> body) {
    additions.add(body);
    if (addFailure != null) {
      return _error(addFailure!, 'internal_error', 'The server failed.');
    }
    final profile = Id.parse(body['participant_profile_id']! as String);
    final roleId = body['role_id'] as String?;
    final helper = roleId == SystemRoles.helperId.value;
    final added = ContestParticipation(
      id: Id.parse(body['id']! as String),
      contestId: contestId,
      participantProfileId: profile,
      roleId: helper ? SystemRoles.helperId : SystemRoles.pilotId,
      roleName: helper ? 'Helper' : 'Pilot',
      roleType: helper ? RoleType.nonFlier : RoleType.pilot,
      scoringUuid: ScoringUuid.create(),
    );
    _participations.add(added);
    return _json(added.toJson(), 201);
  }

  http.Response _update(Id id, Map<String, dynamic> body) {
    updates.add((id: id, body: body));
    final failure = updateFailures[id];
    if (failure != null) {
      return _error(failure.$1, failure.$2, 'The change was rejected.');
    }
    final index = _participations.indexWhere((p) => p.id == id);
    final stored = _participations[index];
    if (stored.revision != body['base_revision']) {
      return _error(409, 'stale_revision', 'The participant changed.');
    }
    final roleId = body['role_id'] as String?;
    final role = roleId == null
        ? null
        : [
            SystemRoles.pilot,
            SystemRoles.helper,
            SystemRoles.teamManager,
          ].firstWhere((r) => r.id.value == roleId);
    final updated = ContestParticipation(
      id: stored.id,
      contestId: contestId,
      participantProfileId: stored.participantProfileId,
      classification: body['classification'] as String?,
      roleId: role?.id ?? stored.roleId,
      roleName: role?.displayName ?? stored.roleName,
      roleType: role?.type ?? stored.roleType,
      participantNumber: stored.participantNumber,
      scoringUuid: stored.scoringUuid,
      retiredAtRound: body['retired_at_round'] as int?,
      revision: stored.revision + 1,
    );
    _participations[index] = updated;
    return _json({...updated.toJson(), 'recalculation_warning': warning});
  }

  http.Response _remove(Id id) {
    removals.add(id);
    if (removalRefused.contains(id) ||
        (withScores && id == personParticipationId(1))) {
      return _error(
        409,
        'has_assignments',
        'a participant with flight assignments cannot be removed; retire '
            'the pilot instead',
      );
    }
    _participations.removeWhere((p) => p.id == id);
    _memberships.removeWhere((m) => m.contestParticipationId == id);
    return http.Response('', 204);
  }

  /// Changes the stored participation of person [n] behind the page's back,
  /// so the next save is stale.
  void changeElsewhere(int n) {
    final index = _participations.indexWhere(
      (p) => p.id == personParticipationId(n),
    );
    final p = _participations[index];
    _participations[index] = ContestParticipation(
      id: p.id,
      contestId: p.contestId,
      participantProfileId: p.participantProfileId,
      classification: 'Expert',
      roleId: p.roleId,
      roleName: p.roleName,
      roleType: p.roleType,
      scoringUuid: p.scoringUuid,
      revision: p.revision + 1,
    );
  }
}

/// Pumps the Participants page against [server] in a window of [size].
Future<void> pumpParticipantsPage(
  WidgetTester tester,
  ParticipantsServer server, {
  Size size = const Size(1280, 1000),
  UnsavedChangesGuard? guard,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: contestParticipantsPath(matrixContestId),
    routes: [
      GoRoute(
        path: contestParticipantsPath(matrixContestId),
        builder: (context, state) =>
            ContestParticipantsPage(contestId: matrixContestId, guard: guard),
      ),
      GoRoute(
        path: contestMatrixPath(matrixContestId),
        builder: (context, state) => const Text('Matrix stub'),
      ),
      GoRoute(
        path: contestConfigurationPath(matrixContestId),
        builder: (context, state) => const Text('Configuration stub'),
      ),
      GoRoute(
        path: contestWorkspacePath(matrixContestId),
        builder: (context, state) => const Text('Workspace stub'),
      ),
      GoRoute(
        path: contestScoringPath(matrixContestId),
        builder: (context, state) => const Text('Scoring stub'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
