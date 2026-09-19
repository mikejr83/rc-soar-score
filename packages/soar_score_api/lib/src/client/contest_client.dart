import 'package:http/http.dart' as http;
import 'package:soar_score_core/soar_score_core.dart';

/// The result of probing whether the remote API is reachable.
class ApiReachabilityResult {
  /// Whether the API responded successfully to the reachability probe.
  final bool isReachable;

  /// The API base URL that was probed.
  final Uri apiBaseUrl;

  /// The time the probe was performed.
  final DateTime checkedAt;

  /// A human-readable description of the probe outcome, useful for
  /// display in the connectivity status detail view.
  final String? detail;

  const ApiReachabilityResult({
    required this.isReachable,
    required this.apiBaseUrl,
    required this.checkedAt,
    this.detail,
  });

  @override
  String toString() =>
      'ApiReachabilityResult(isReachable: $isReachable, apiBaseUrl: $apiBaseUrl, checkedAt: $checkedAt, detail: $detail)';
}

/// HTTP client for contest API endpoints.
///
/// The [httpClient] is injected so tests can supply a fake transport.
class ContestClient {
  final String baseUrl;
  final http.Client httpClient;

  ContestClient({required String baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl,
        httpClient = httpClient ?? http.Client();

  /// Fetch contest data from the server.
  Future<Contest?> getContest() async {
    // Stub
    return null;
  }

  /// Submit flight data to the server.
  Future<void> submitFlight(Flight flight) async {
    // Stub
  }

  /// Probes the API's `GET /health` endpoint to determine whether the remote
  /// API is reachable.
  ///
  /// A result is considered reachable only when the HTTP status code is 2xx.
  /// Transport failures (DNS, connection refused, timeout) and non-2xx
  /// responses report `isReachable: false` with a [ApiReachabilityResult.detail]
  /// describing the failure. This is intentionally a lightweight liveness
  /// probe, distinct from any real data request.
  Future<ApiReachabilityResult> checkApiReachable() async {
    final checkedAt = DateTime.now();
    final uri = Uri.parse('$baseUrl/health');
    try {
      final response = await httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiReachabilityResult(
          isReachable: true,
          apiBaseUrl: uri,
          checkedAt: checkedAt,
        );
      }
      return ApiReachabilityResult(
        isReachable: false,
        apiBaseUrl: uri,
        checkedAt: checkedAt,
        detail: 'API responded with HTTP ${response.statusCode}.',
      );
    } catch (e) {
      return ApiReachabilityResult(
        isReachable: false,
        apiBaseUrl: uri,
        checkedAt: checkedAt,
        detail: 'Could not reach the API: $e',
      );
    }
  }
}
