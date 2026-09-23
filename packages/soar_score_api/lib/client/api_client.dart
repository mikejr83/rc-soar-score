import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dto/health_dto.dart';
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
    final response = await _get(uri);
    return _decode<HealthDto>(response, uri, HealthDto.fromJson);
  }

  Uri _resolve(String path) => baseUrl.resolveUri(Uri.parse(path));

  /// Sends a GET request for the absolute [uri] and returns its 2xx
  /// [http.Response].
  ///
  /// Throws [ApiHttpError] for non-2xx responses and [ApiNetworkError] for
  /// transport failures.
  Future<http.Response> _get(Uri uri) async {
    final headers = <String, String>{'accept': 'application/json'};
    final token = await tokenProvider?.call();
    if (token != null) {
      headers['authorization'] = 'Bearer $token';
    }
    try {
      final response = await _httpClient.get(uri, headers: headers);
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

  T _decode<T>(http.Response response, Uri requestUri, T Function(Map<String, dynamic> json) fromJson) {
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
