import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soar_score_core/soar_score_core.dart';

import '../dto/add_participation_request.dart';
import '../dto/contest_action_request.dart';
import '../dto/create_contest_request.dart';
import '../dto/create_participant_request.dart';
import '../dto/health_dto.dart';
import '../dto/save_configuration_request.dart';
import '../dto/update_contest_request.dart';
import '../dto/update_participant_request.dart';
import '../dto/update_participation_request.dart';
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
