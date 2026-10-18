import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soar_score_core/soar_score_core.dart';

import '../dto/activate_installation_request.dart';
import '../dto/add_participation_request.dart';
import '../dto/add_team_member_request.dart';
import '../dto/claim_local_account_request.dart';
import '../dto/contest_action_request.dart';
import '../dto/contest_archive_dto.dart';
import '../dto/create_contest_request.dart';
import '../dto/create_landing_table_request.dart';
import '../dto/create_participant_request.dart';
import '../dto/create_role_request.dart';
import '../dto/create_team_request.dart';
import '../dto/draw_matrix_request.dart';
import '../dto/enter_score_request.dart';
import '../dto/health_dto.dart';
import '../dto/import_gliderscore_request.dart';
import '../dto/local_account_claim_dto.dart';
import '../dto/late_add_request.dart';
import '../dto/move_assignment_request.dart';
import '../dto/public_publication_dto.dart';
import '../dto/public_publication_summary_dto.dart';
import '../dto/publish_contest_request.dart';
import '../dto/register_installation_request.dart';
import '../dto/redraw_matrix_request.dart';
import '../dto/rename_role_request.dart';
import '../dto/resolve_conflict_request.dart';
import '../dto/save_configuration_request.dart';
import '../dto/set_visibility_request.dart';
import '../dto/sync_exchange_request.dart';
import '../dto/sync_exchange_response.dart';
import '../dto/sync_info_dto.dart';
import '../dto/sync_mutation_result.dart';
import '../dto/system_data_response.dart';
import '../dto/update_contest_request.dart';
import '../dto/update_participant_request.dart';
import '../dto/update_participation_request.dart';
import '../dto/update_team_request.dart';
import '../errors/api_exception.dart';
import '../errors/api_http_error.dart';
import '../errors/api_network_error.dart';
import '../errors/sync_refused_error.dart';

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

  /// `POST /api/v1/account/local-claims` — claims the installation's Local
  /// account [request] into the signed-in account.
  ///
  /// Repeating a claim for the same account returns the same answer. A Local
  /// account another account claimed is an [ApiHttpError] with status 409.
  Future<LocalAccountClaimDto> claimLocalAccount(
    ClaimLocalAccountRequest request,
  ) async {
    final uri = _resolve('/api/v1/account/local-claims');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<LocalAccountClaimDto>(
      response,
      uri,
      LocalAccountClaimDto.fromJson,
    );
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
  ///
  /// The entry is followed by a recalculation, retried once. When it fails
  /// twice the score is still stored, the results read as stale, and
  /// [ScoreEntryResult.recalculationWarning] carries the notice (ticket 297).
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

  /// `GET /api/v1/contests/{id}/assignments/{assignmentId}/scores/history` —
  /// every submission to one slot, oldest first: the official revisions with
  /// their reasons, and the attempts that never became official.
  Future<ScoreHistory> scoreHistory(Id id, Id assignmentId) async {
    final uri = _resolve(
      '/api/v1/contests/${id.value}/assignments/'
      '${assignmentId.value}/scores/history',
    );
    final response = await _send('GET', uri);
    return _decode<ScoreHistory>(response, uri, ScoreHistory.fromJson);
  }

  /// `GET /api/v1/contests/{id}/results` — the standings and team totals as
  /// of the latest scored round. `preliminary` is set while rounds are
  /// unscored or the stored results are stale.
  Future<ContestResults> results(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/results');
    final response = await _send('GET', uri);
    return _decode<ContestResults>(response, uri, ContestResults.fromJson);
  }

  /// `GET /api/v1/contests/{id}/results/rounds/{ordinal}` — every flight
  /// result of one round, grouped by group. A round that does not exist is an
  /// [ApiHttpError] with status 400.
  Future<RoundResults> roundResults(Id id, int ordinal) async {
    final uri = _resolve(
      '/api/v1/contests/${id.value}/results/rounds/$ordinal',
    );
    final response = await _send('GET', uri);
    return _decode<RoundResults>(response, uri, RoundResults.fromJson);
  }

  /// `POST /api/v1/contests/{id}/results/recalculation` — rebuilds the
  /// results from the official scores now and returns them. A contest that
  /// has no configuration, or whose discipline is not calculated yet, is an
  /// [ApiHttpError] with status 409.
  Future<ContestResults> recalculateResults(Id id) async {
    final uri = _resolve('/api/v1/contests/${id.value}/results/recalculation');
    final response = await _send('POST', uri);
    return _decode<ContestResults>(response, uri, ContestResults.fromJson);
  }

  /// `POST /api/v1/contests/{id}/publication` — publishes the contest as it
  /// is now and returns the publication (`publication_id`, `visibility` and
  /// a summary of the `current_projection`).
  ///
  /// The first publish is Unlisted. Repeating the same `client_mutation_id`
  /// returns the first projection. Only the contest's director may publish
  /// (403); a contest that changed since `source_contest_revision`
  /// (`stale_source_revision`), stale results (`results_stale`), a delisted
  /// publication or a contest not ready to publish is an [ApiHttpError] with
  /// status 409. The embedded server answers 409 `publishing_not_available`.
  Future<Map<String, Object?>> publishContest(
    Id contestId,
    PublishContestRequest request,
  ) async {
    final uri = _resolve('/api/v1/contests/${contestId.value}/publication');
    final response = await _send('POST', uri, body: request.toJson());
    return _decode<Map<String, Object?>>(response, uri, (json) => json);
  }

  /// `GET /api/v1/contests/{id}/publication` — the director's view of the
  /// publication. A contest that was never published is a 404.
  Future<Map<String, Object?>> publication(Id contestId) async {
    final uri = _resolve('/api/v1/contests/${contestId.value}/publication');
    final response = await _send('GET', uri);
    return _decode<Map<String, Object?>>(response, uri, (json) => json);
  }

  /// `PATCH /api/v1/contests/{id}/publication/visibility` — switches the
  /// publication between `Unlisted` and `Public`. A delisted publication is
  /// an [ApiHttpError] with status 409.
  Future<Map<String, Object?>> setPublicationVisibility(
    Id contestId,
    SetVisibilityRequest request,
  ) async {
    final uri = _resolve(
      '/api/v1/contests/${contestId.value}/publication/visibility',
    );
    final response = await _send('PATCH', uri, body: request.toJson());
    return _decode<Map<String, Object?>>(response, uri, (json) => json);
  }

  /// `GET /public/publications` — the Public publications, newest first, with
  /// no sign-in. [limit] is at most 100 (the server's default is 50) and
  /// [offset] skips the first entries.
  ///
  /// A server that does not publish contests is an [ApiHttpError] with status
  /// 409 and code `publishing_not_available`.
  Future<List<PublicPublicationSummaryDto>> publicPublications({
    int? limit,
    int? offset,
  }) async {
    final query = <String, String>{
      'limit': ?limit?.toString(),
      'offset': ?offset?.toString(),
    };
    var uri = _resolve('/public/publications');
    if (query.isNotEmpty) uri = uri.replace(queryParameters: query);
    final response = await _send('GET', uri);
    return _decode<List<PublicPublicationSummaryDto>>(
      response,
      uri,
      (json) => [
        for (final item in json['publications'] as List<dynamic>)
          PublicPublicationSummaryDto.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `GET /public/publications/{id}` — the current projection of a Public or
  /// Unlisted publication, with no sign-in.
  ///
  /// An unknown or delisted publication is an [ApiHttpError] with status 404;
  /// a server that does not publish contests is one with status 409 and code
  /// `publishing_not_available`.
  Future<PublicPublicationDto> publicPublication(Id id) async {
    final uri = _resolve('/public/publications/${id.value}');
    final response = await _send('GET', uri);
    return _decode<PublicPublicationDto>(
      response,
      uri,
      PublicPublicationDto.fromJson,
    );
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

  /// `GET /api/v1/sync/info` — the version ranges the service accepts.
  Future<SyncInfoDto> syncInfo() async {
    final uri = _resolve('/api/v1/sync/info');
    final response = await _sendSync('GET', uri);
    return _decode<SyncInfoDto>(response, uri, SyncInfoDto.fromJson);
  }

  /// `POST /api/v1/installations` — registers an installation for the
  /// caller's account. Registering the same id again returns the stored row.
  Future<Installation> registerInstallation(
    RegisterInstallationRequest request,
  ) async {
    final uri = _resolve('/api/v1/installations');
    final response = await _sendSync('POST', uri, body: request.toJson());
    return _decode<Installation>(response, uri, Installation.fromJson);
  }

  /// `GET /api/v1/installations` — the caller's installations.
  Future<List<Installation>> installations() async {
    final uri = _resolve('/api/v1/installations');
    final response = await _sendSync('GET', uri);
    return _decode<List<Installation>>(
      response,
      uri,
      (json) => [
        for (final item in json['installations'] as List<dynamic>)
          Installation.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// `POST /api/v1/installations/{id}/revoke` — revokes an installation, for
  /// example a lost device. Returns the revoked row.
  Future<Installation> revokeInstallation(Id id) async {
    final uri = _resolve('/api/v1/installations/${id.value}/revoke');
    final response = await _sendSync('POST', uri);
    return _decode<Installation>(response, uri, Installation.fromJson);
  }

  /// `POST /api/v1/contests/{id}/activations` — makes an installation the
  /// contest's administration installation, ending the previous one.
  ///
  /// Throws [SyncRefusedError] with `reclaim_requires_sync` when a reclaim
  /// is attempted before the installation has pulled and reconciled.
  Future<InstallationActivation> activateInstallation(
    Id contestId,
    ActivateInstallationRequest request,
  ) async {
    final uri = _resolve('/api/v1/contests/${contestId.value}/activations');
    final response = await _sendSync('POST', uri, body: request.toJson());
    return _decode<InstallationActivation>(
      response,
      uri,
      InstallationActivation.fromJson,
    );
  }

  /// `POST /api/v1/sync/exchange` — pushes unsent mutations and pulls the
  /// changes after the cursor for one scope.
  ///
  /// Throws [SyncRefusedError] when the service refuses the versions. A
  /// rejected mutation is not an error; it is a result in the response.
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) async {
    final uri = _resolve('/api/v1/sync/exchange');
    final response = await _sendSync('POST', uri, body: request.toJson());
    return _decode<SyncExchangeResponse>(
      response,
      uri,
      SyncExchangeResponse.fromJson,
    );
  }

  /// `GET /api/v1/sync/system-data` — system data after [afterSequence].
  /// Pass the previous response's `nextPageToken` as [pageToken] to continue.
  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  }) async {
    final uri = _resolve('/api/v1/sync/system-data').replace(
      queryParameters: {
        'after_sequence': '$afterSequence',
        'page_token': ?pageToken,
      },
    );
    final response = await _sendSync('GET', uri);
    return _decode<SystemDataResponse>(
      response,
      uri,
      SystemDataResponse.fromJson,
    );
  }

  /// `POST /api/v1/sync/conflicts/{conflictId}/resolve` — submits the
  /// director's decision for a conflict. Repeating [request] returns the
  /// original result.
  Future<SyncMutationResult> resolveConflict(
    Id conflictId,
    ResolveConflictRequest request,
  ) async {
    final uri = _resolve('/api/v1/sync/conflicts/${conflictId.value}/resolve');
    final response = await _sendSync('POST', uri, body: request.toJson());
    return _decode<SyncMutationResult>(
      response,
      uri,
      SyncMutationResult.fromJson,
    );
  }

  /// `GET /api/v1/contests/{id}/download` — the complete contest, for
  /// initializing a replacement installation.
  Future<ContestArchiveDto> downloadContest(Id contestId) async {
    final uri = _resolve('/api/v1/contests/${contestId.value}/download');
    final response = await _sendSync('GET', uri);
    return _decode<ContestArchiveDto>(
      response,
      uri,
      ContestArchiveDto.fromJson,
    );
  }

  /// `GET /api/v1/contests/{id}/export` — everything in the download plus
  /// audit history, conflicts, tombstones and pending mutations.
  Future<ContestArchiveDto> exportContest(Id contestId) async {
    final uri = _resolve('/api/v1/contests/${contestId.value}/export');
    final response = await _sendSync('GET', uri);
    return _decode<ContestArchiveDto>(
      response,
      uri,
      ContestArchiveDto.fromJson,
    );
  }

  /// `POST /api/v1/imports/gliderscore` — reads the GliderScore `.mdb` at
  /// [path] on the machine the embedded server runs on and returns its tables
  /// as a snapshot for the wizard to review. [tables] limits which tables are
  /// included; `null` includes every table, in database order.
  ///
  /// Only the native Windows build serves this route; the hosted server and
  /// the web build answer 503 `import_unavailable`.
  Future<GliderScoreImportResult> importGliderScore(
    String path, {
    List<String>? tables,
  }) async {
    final uri = _resolve('/api/v1/imports/gliderscore');
    final response = await _send(
      'POST',
      uri,
      body: ImportGliderscoreRequest(path: path, tables: tables).toJson(),
    );
    return _decode<GliderScoreImportResult>(
      response,
      uri,
      _gliderScoreImportResultFromJson,
    );
  }

  GliderScoreImportResult _gliderScoreImportResultFromJson(
    Map<String, dynamic> json,
  ) {
    final tables = <GliderScoreTable>[];
    for (final item in json['tables'] as List<dynamic>) {
      final tableJson = item as Map<String, dynamic>;
      final rows = <Map<String, Object?>>[];
      for (final row in tableJson['rows'] as List<dynamic>) {
        rows.add(Map<String, Object?>.from(row as Map<dynamic, dynamic>));
      }
      tables.add(
        GliderScoreTable(
          name: tableJson['name'] as String,
          rows: rows,
          rowCount: tableJson['rowCount'] as int,
          rowCapExceeded: tableJson['rowCapExceeded'] as bool,
        ),
      );
    }
    return GliderScoreImportResult(
      id: Id.parse(json['id'] as String),
      sourceDbFile: json['sourceDbFile'] as String,
      tables: tables,
    );
  }

  /// `POST /api/v1/contests/import` — imports an export, keeping every
  /// identifier.
  ///
  /// Throws [SyncRefusedError] with `contest_exists` rather than overwrite a
  /// contest that is already there.
  Future<ContestArchiveDto> importContest(ContestArchiveDto archive) async {
    final uri = _resolve('/api/v1/contests/import');
    final response = await _sendSync('POST', uri, body: archive.toJson());
    return _decode<ContestArchiveDto>(
      response,
      uri,
      ContestArchiveDto.fromJson,
    );
  }

  /// Like [_send], but turns a refusal that names a sync reason code into a
  /// [SyncRefusedError].
  Future<http.Response> _sendSync(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _send(method, uri, body: body);
    } on ApiHttpError catch (error) {
      final reason = SyncReasonCode.tryParse(error.error?.code);
      if (reason == null) rethrow;
      throw SyncRefusedError(
        error.message,
        reason: reason,
        statusCode: error.statusCode,
        body: error.body,
        requestUri: error.requestUri,
      );
    }
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
