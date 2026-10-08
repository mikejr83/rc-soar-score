import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soar_score_core/services/contest_scores.dart';
import 'package:soar_score_core/services/landing_table_view.dart';
import 'package:soar_score_core/services/role_usage.dart';
import 'package:soar_score_core/services/score_entry_result.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../dto/add_participation_request.dart';
import '../dto/add_team_member_request.dart';
import '../dto/contest_action_request.dart';
import '../dto/create_contest_request.dart';
import '../dto/create_landing_table_request.dart';
import '../dto/create_participant_request.dart';
import '../dto/create_role_request.dart';
import '../dto/create_team_request.dart';
import '../dto/draw_matrix_request.dart';
import '../dto/enter_score_request.dart';
import '../dto/health_dto.dart';
import '../dto/late_add_request.dart';
import '../dto/move_assignment_request.dart';
import '../dto/redraw_matrix_request.dart';
import '../dto/rename_role_request.dart';
import '../dto/save_configuration_request.dart';
import '../dto/update_contest_request.dart';
import '../dto/update_participant_request.dart';
import '../dto/update_participation_request.dart';
import '../dto/update_team_request.dart';
import '../errors/api_exception.dart';
import '../errors/api_http_error.dart';
import '../errors/api_network_error.dart';

/// Supplies the bearer token for authenticated requests, or `null` when the
/// route is public.
///
/// The callback is asynchronous so an identity layer (ticket 010) can
/// acquire or refresh a token on demand before the request is sent.
typedef TokenProvider = Future<String?> Function();

/// Shared HTTP client for talking to the Soar Score API.
///
/// The target server is never hard-coded: [baseUrl] is required and
/// caller-supplied, so the same client code serves the web build pointed
/// at the deployed `soar_score_server` and the Windows build pointed at a
/// local embedded instance (tickets 017/018) with no client-side platform
/// branching.
///
/// [httpClient] is injected for testability; a default [http.Client] is
/// used when none is given. [tokenProvider] should return `null` for public
/// routes (such as `health()`); no `Authorization` header is sent in that
/// case.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.tokenProvider,
  }) : _httpClient = httpClient ?? http.Client();

  /// Base URI of the target server, e.g. `Uri.parse('https://api.example.com')`.
  /// Relative route paths are resolved against this value.
  final Uri baseUrl;

  /// Optional bearer-token provider; `null` means no token is ever sent.
  final TokenProvider? tokenProvider;

  final http.Client _httpClient;

  /// Closes the underlying [http.Client].
  ///
  /// Clients that were injected by the caller are owned by the caller;
  /// closing them here is harmless.
  void close() => _httpClient.close();

  /// `GET /health` — public server identity and liveness payload.
  Future<HealthDto> health() async {
    final uri = _resolve('/health');
    final response = await _send('GET', uri);
    return _decode<HealthDto>(response, uri, HealthDto.fromJson);
  }

  /// `GET /api/v1/contests` — the contests stored on the target server.
  Future<List<Contest>> contests() async {
    final uri = _resolve('/api/v1/contests');
    final response = await _send('GET', uri);
    return _decode<List<Contest>>(
      response,
      uri,
      (json) => [
        for (final item in json['contests'] as List<dynamic>)
          Contest.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `GET /api/v1/contests/{id}` — one contest.
  ///
  /// A missing contest is an [ApiHttpError] with status 404.
  Future<Contest> contest(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}');
    final response = await _send('GET', uri);
    return _decode<Contest>(response, uri, Contest.fromJson);
  }

  /// `POST /api/v1/contests` — creates a contest owned by the caller.
  ///
  /// Repeating the same [request] returns the contest it created; the same
  /// id with different content is an [ApiHttpError] with status 409.
  Future<Contest> createContest(CreateContestRequest request) async {
    final uri = _resolve('/api/v1/contests');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<Contest>(response, uri, Contest.fromJson);
  }

  /// `PUT /api/v1/contests/{id}` — replaces the identity, schedule and
  /// location of contest [id].
  Future<Contest> updateContest(Id id, UpdateContestRequest request) async {
    final uri = _resolve('/api/v1/contests/${id.value}');
    final response = await _send('PUT', uri, body: request.toJson());
    return _decode<Contest>(response, uri, Contest.fromJson);
  }

  /// `POST /api/v1/contests/{id}/actions` — applies a director action such as
  /// completing or locking the contest.
  Future<Contest> applyContestAction(
    Id id,
    ContestActionRequest request,
  ) async {
    final uri = _resolve('/api/v1/contests/${id.value}/actions');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<Contest>(response, uri, Contest.fromJson);
  }

  /// `GET /api/v1/contests/{id}/configuration` — the latest configuration
  /// revision of contest [id].
  ///
  /// A contest with no configuration yet is an [ApiHttpError] with status
  /// 404.
  Future<ContestConfigurationRevision> configuration(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/configuration');
    final response = await _send('GET', uri);
    return _decode<ContestConfigurationRevision>(
      response,
      uri,
      ContestConfigurationRevision.fromJson,
    );
  }

  /// `GET /api/v1/contests/{id}/configuration/revisions` — every
  /// configuration revision of contest [id], oldest first.
  Future<List<ContestConfigurationRevision>> configurationRevisions(
    Id id,
  ) async {
    final uri = _resolve(
      '/api/v1/contests/${id.value}/configuration/revisions',
    );
    final response = await _send('GET', uri);
    return _decode<List<ContestConfigurationRevision>>(
      response,
      uri,
      (json) => [
        for (final item in json['revisions'] as List<dynamic>)
          ContestConfigurationRevision.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /api/v1/contests/{id}/configuration` — stores the next
  /// configuration revision and returns it with the contest as it is after
  /// the change (the contest's revision and lifecycle state may have moved).
  Future<SavedConfiguration> saveConfiguration(
    Id id,
    SaveConfigurationRequest request,
  ) async {
    final uri = _resolve('/api/v1/contests/${id.value}/configuration');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<SavedConfiguration>(
      response,
      uri,
      SavedConfiguration.fromJson,
    );
  }

  /// `GET /api/v1/participants` — the caller's participant profiles.
  Future<List<ParticipantProfile>> participants() async {
    final uri = _resolve('/api/v1/participants');
    final response = await _send('GET', uri);
    return _decode<List<ParticipantProfile>>(
      response,
      uri,
      (json) => [
        for (final item in json['participants'] as List<dynamic>)
          ParticipantProfile.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `GET /api/v1/participants/{id}` — one of the caller's profiles.
  Future<ParticipantProfile> participant(Id id) async {
    final uri = _resolve('/api/v1/participants/${id.value}');
    final response = await _send('GET', uri);
    return _decode<ParticipantProfile>(
      response,
      uri,
      ParticipantProfile.fromJson,
    );
  }

  /// `POST /api/v1/participants` — creates a profile owned by the caller.
  ///
  /// Repeating the same [request] returns the profile it created; the same id
  /// with different content is an [ApiHttpError] with status 409.
  Future<ParticipantProfile> createParticipant(
    CreateParticipantRequest request,
  ) async {
    final uri = _resolve('/api/v1/participants');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<ParticipantProfile>(
      response,
      uri,
      ParticipantProfile.fromJson,
    );
  }

  /// `PUT /api/v1/participants/{id}` — replaces the details of profile [id].
  Future<ParticipantProfile> updateParticipant(
    Id id,
    UpdateParticipantRequest request,
  ) async {
    final uri = _resolve('/api/v1/participants/${id.value}');
    final response = await _send('PUT', uri, body: request.toJson());
    return _decode<ParticipantProfile>(
      response,
      uri,
      ParticipantProfile.fromJson,
    );
  }

  /// `DELETE /api/v1/participants/{id}` — deletes profile [id].
  ///
  /// A profile that is in a contest is an [ApiHttpError] with status 409.
  Future<void> deleteParticipant(Id id) async {
    await _send('DELETE', _resolve('/api/v1/participants/${id.value}'));
  }

  /// `GET /api/v1/landing-tables` — the system landing tables and the
  /// caller's own, each marked with whether it is in use.
  Future<List<LandingTableView>> landingTables() async {
    final uri = _resolve('/api/v1/landing-tables');
    final response = await _send('GET', uri);
    return _decode<List<LandingTableView>>(
      response,
      uri,
      (json) => [
        for (final item in json['landing_tables'] as List<dynamic>)
          LandingTableView.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /api/v1/landing-tables` — creates a landing table owned by the
  /// caller.
  Future<LandingTableView> createLandingTable(
    CreateLandingTableRequest request,
  ) async {
    final uri = _resolve('/api/v1/landing-tables');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<LandingTableView>(response, uri, LandingTableView.fromJson);
  }

  /// `DELETE /api/v1/landing-tables/{id}` — removes one of the caller's
  /// tables.
  ///
  /// A system table, or a table in use, is an [ApiHttpError] with status 409.
  Future<void> deleteLandingTable(Id id) async {
    await _send('DELETE', _resolve('/api/v1/landing-tables/${id.value}'));
  }

  /// `GET /api/v1/roles` — the system roles and the caller's own roles.
  Future<List<Role>> roles() async {
    final uri = _resolve('/api/v1/roles');
    final response = await _send('GET', uri);
    return _decode<List<Role>>(
      response,
      uri,
      (json) => [
        for (final item in json['roles'] as List<dynamic>)
          Role.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /api/v1/roles` — adds a non-flier role owned by the caller.
  ///
  /// Repeating the same [request] returns the role it created. A name the
  /// caller already has is an [ApiHttpError] with status 409.
  Future<Role> createRole(CreateRoleRequest request) async {
    final uri = _resolve('/api/v1/roles');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<Role>(response, uri, Role.fromJson);
  }

  /// `PUT /api/v1/roles/{id}` — renames the caller's role [id].
  ///
  /// A system role is an [ApiHttpError] with status 409.
  Future<Role> renameRole(Id id, RenameRoleRequest request) async {
    final uri = _resolve('/api/v1/roles/${id.value}');
    final response = await _send('PUT', uri, body: request.toJson());
    return _decode<Role>(response, uri, Role.fromJson);
  }

  /// `DELETE /api/v1/roles/{id}` — deletes the caller's role [id].
  ///
  /// A system role, or a role a contest participant has, is an
  /// [ApiHttpError] with status 409.
  Future<void> deleteRole(Id id) async {
    await _send('DELETE', _resolve('/api/v1/roles/${id.value}'));
  }

  /// `GET /api/v1/roles/{id}/usage` — the contests with participants in role
  /// [id].
  Future<List<RoleUsage>> roleUsage(Id id) async {
    final uri = _resolve('/api/v1/roles/${id.value}/usage');
    final response = await _send('GET', uri);
    return _decode<List<RoleUsage>>(
      response,
      uri,
      (json) => [
        for (final item in json['usage'] as List<dynamic>)
          RoleUsage.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `GET /api/v1/contests/{id}/participations` — who takes part in contest
  /// [id], in the order they were added.
  Future<List<ContestParticipation>> participations(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/participations');
    final response = await _send('GET', uri);
    return _decode<List<ContestParticipation>>(
      response,
      uri,
      (json) => [
        for (final item in json['participations'] as List<dynamic>)
          ContestParticipation.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /api/v1/contests/{id}/participations` — adds one of the caller's
  /// profiles to contest [id].
  ///
  /// Repeating the same [request] returns the participation it created; the
  /// profile already being in the contest, or a Completed contest, is an
  /// [ApiHttpError] with status 409.
  Future<ContestParticipation> addParticipation(
    Id id,
    AddParticipationRequest request,
  ) async {
    final uri = _resolve('/api/v1/contests/${id.value}/participations');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<ContestParticipation>(
      response,
      uri,
      ContestParticipation.fromJson,
    );
  }

  /// `PUT /api/v1/contests/{id}/participations/{participationId}` — changes
  /// the role, classification or retirement of a participation.
  Future<ContestParticipation> updateParticipation(
    Id id,
    Id participationId,
    UpdateParticipationRequest request,
  ) async {
    final uri = _resolve(
      '/api/v1/contests/${id.value}/participations/${participationId.value}',
    );
    final response = await _send('PUT', uri, body: request.toJson());
    return _decode<ContestParticipation>(
      response,
      uri,
      ContestParticipation.fromJson,
    );
  }

  /// `DELETE /api/v1/contests/{id}/participations/{participationId}` —
  /// removes a participant from the contest.
  ///
  /// One with flight assignments is an [ApiHttpError] with status 409.
  Future<void> removeParticipation(Id id, Id participationId) async {
    await _send(
      'DELETE',
      _resolve(
        '/api/v1/contests/${id.value}/participations/${participationId.value}',
      ),
    );
  }

  /// `GET /api/v1/contests/{id}/teams` — the teams of contest [id], by name.
  Future<List<Team>> teams(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/teams');
    final response = await _send('GET', uri);
    return _decode<List<Team>>(
      response,
      uri,
      (json) => [
        for (final item in json['teams'] as List<dynamic>)
          Team.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /api/v1/contests/{id}/teams` — creates a team.
  ///
  /// Repeating the same [request] returns the team it created; the name
  /// already being used in the contest is an [ApiHttpError] with status 409.
  Future<Team> createTeam(Id id, CreateTeamRequest request) async {
    final uri = _resolve('/api/v1/contests/${id.value}/teams');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<Team>(response, uri, Team.fromJson);
  }

  /// `PUT /api/v1/contests/{id}/teams/{teamId}` — renames a team.
  Future<Team> updateTeam(Id id, Id teamId, UpdateTeamRequest request) async {
    final uri = _resolve('/api/v1/contests/${id.value}/teams/${teamId.value}');
    final response = await _send('PUT', uri, body: request.toJson());
    return _decode<Team>(response, uri, Team.fromJson);
  }

  /// `DELETE /api/v1/contests/{id}/teams/{teamId}` — deletes a team with its
  /// memberships.
  ///
  /// A team with pilots, once a matrix is drawn, is an [ApiHttpError] with
  /// status 409.
  Future<void> deleteTeam(Id id, Id teamId) async {
    await _send(
      'DELETE',
      _resolve('/api/v1/contests/${id.value}/teams/${teamId.value}'),
    );
  }

  /// `GET /api/v1/contests/{id}/team-memberships` — who is on which team in
  /// contest [id].
  Future<List<TeamMembership>> teamMemberships(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/team-memberships');
    final response = await _send('GET', uri);
    return _decode<List<TeamMembership>>(
      response,
      uri,
      (json) => [
        for (final item in json['team_memberships'] as List<dynamic>)
          TeamMembership.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /api/v1/contests/{id}/team-memberships` — puts a participant on a
  /// team.
  ///
  /// A participant already on a team, or a pilot once a matrix is drawn, is
  /// an [ApiHttpError] with status 409.
  Future<TeamMembership> addTeamMember(
    Id id,
    AddTeamMemberRequest request,
  ) async {
    final uri = _resolve('/api/v1/contests/${id.value}/team-memberships');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<TeamMembership>(response, uri, TeamMembership.fromJson);
  }

  /// `DELETE /api/v1/contests/{id}/team-memberships/{membershipId}` — takes a
  /// participant off their team.
  Future<void> removeTeamMember(Id id, Id membershipId) async {
    await _send(
      'DELETE',
      _resolve(
        '/api/v1/contests/${id.value}/team-memberships/${membershipId.value}',
      ),
    );
  }

  /// `GET /api/v1/contests/{id}/matrix` — the contest's current matrix:
  /// the latest finalized revision with its rounds, groups and assignments.
  /// Empty (no revision) until the first draw.
  Future<CurrentMatrix> matrix(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/matrix');
    final response = await _send('GET', uri);
    return _decode<CurrentMatrix>(response, uri, CurrentMatrix.fromJson);
  }

  /// `POST /api/v1/contests/{id}/matrix/draws` — draws and finalizes the
  /// first matrix.
  ///
  /// Repeating the same [request] returns the matrix it drew. A contest that
  /// is not being configured, is locked, or already has a matrix is an
  /// [ApiHttpError] with status 409; settings the draw cannot meet (no
  /// pilots, more groups than pilots, a team larger than the groups under
  /// team protection) are status 400.
  Future<CurrentMatrix> drawMatrix(Id id, DrawMatrixRequest request) async {
    final uri = _resolve('/api/v1/contests/${id.value}/matrix/draws');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<CurrentMatrix>(response, uri, CurrentMatrix.fromJson);
  }

  /// Moves the pilot of assignment [assignmentId] of contest [contestId] to
  /// another slot of the matrix and returns the current matrix.
  ///
  /// Repeating the same [request] changes nothing more. A move the contest
  /// cannot take (locked, a lane taken, a teammate in the group, a locked
  /// group or score without an override, nothing changed) is an
  /// [ApiHttpError] with status 409; a missing reason or a slot that does
  /// not exist is status 400.
  Future<CurrentMatrix> moveAssignment(
    Id contestId,
    Id assignmentId,
    MoveAssignmentRequest request,
  ) async {
    final uri = _resolve(
      '/api/v1/contests/${contestId.value}/matrix/assignments/'
      '${assignmentId.value}/moves',
    );
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<CurrentMatrix>(response, uri, CurrentMatrix.fromJson);
  }

  /// `GET /api/v1/contests/{id}/scores` — every score slot of the contest's
  /// current matrix with its current official score, and the scored and
  /// total count of each round.
  Future<ContestScores> scores(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/scores');
    final response = await _send('GET', uri);
    return _decode<ContestScores>(response, uri, ContestScores.fromJson);
  }

  /// `POST /api/v1/contests/{id}/assignments/{assignmentId}/scores` — enters
  /// [request] as the official score of one pilot in one group, and returns
  /// the stored score with the calculated flight.
  ///
  /// Repeating the same `client_mutation_id` returns the first entry. A
  /// locked contest, group or score, a contest that is not being flown, or a
  /// slot whose score changed since it was read is an [ApiHttpError] with
  /// status 409; components the discipline refuses are status 400.
  Future<ScoreEntryResult> enterScore(
    Id contestId,
    Id assignmentId,
    EnterScoreRequest request,
  ) async {
    final uri = _resolve(
      '/api/v1/contests/${contestId.value}/assignments/'
      '${assignmentId.value}/scores',
    );
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<ScoreEntryResult>(response, uri, ScoreEntryResult.fromJson);
  }

  /// Places a pilot who joined late, or who is making up a missed round, in
  /// a group of contest [contestId] and returns the current matrix.
  ///
  /// Repeating the same [request] changes nothing more. A late add the
  /// contest cannot take (locked, no open spot, a group that already has
  /// scores, a lane taken, a teammate in the group, a retired pilot) is an
  /// [ApiHttpError] with status 409; a missing reason or a slot that does not
  /// exist is status 400.
  Future<CurrentMatrix> lateAdd(Id contestId, LateAddRequest request) async {
    final uri = _resolve(
      '/api/v1/contests/${contestId.value}/matrix/late-adds',
    );
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<CurrentMatrix>(response, uri, CurrentMatrix.fromJson);
  }

  /// Adds rounds to the matrix of contest [contestId], or draws its unscored
  /// tail again, and returns the current matrix.
  ///
  /// Repeating the same [request] returns the matrix it drew. A contest that
  /// has no matrix, is locked, or whose rounds to replace have scores or a
  /// locked group is an [ApiHttpError] with status 409; settings the draw
  /// cannot meet, or a first round beyond one past the last round, are status
  /// 400.
  Future<CurrentMatrix> redrawMatrix(
    Id contestId,
    RedrawMatrixRequest request,
  ) async {
    final uri = _resolve('/api/v1/contests/${contestId.value}/matrix/redraws');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<CurrentMatrix>(response, uri, CurrentMatrix.fromJson);
  }

  Uri _resolve(String path) => baseUrl.resolveUri(Uri.parse(path));

  /// Sends a [method] request for the absolute [uri], with [body] as JSON
  /// when given, and returns its 2xx [http.Response].
  ///
  /// Throws [ApiHttpError] for non-2xx responses and [ApiNetworkError] for
  /// transport failures.
  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{'accept': 'application/json'};
    final token = await tokenProvider?.call();
    if (token != null) {
      headers['authorization'] = 'Bearer $token';
    }
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.headers['content-type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw ApiHttpError(
        'request to $uri failed with status ${response.statusCode}',
        statusCode: response.statusCode,
        requestUri: uri,
        body: utf8.decode(response.bodyBytes),
      );
    } on http.ClientException catch (error) {
      throw ApiNetworkError(
        'could not reach $uri: $error',
        cause: error,
        requestUri: uri,
      );
    }
  }

  T _decode<T>(
    http.Response response,
    Uri requestUri,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('body is not a JSON object');
      }
      return fromJson(decoded);
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      throw ApiException(
        'could not decode response from $requestUri: $error',
        requestUri: requestUri,
      );
    }
  }
}
