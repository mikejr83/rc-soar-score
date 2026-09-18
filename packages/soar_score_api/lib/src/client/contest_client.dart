import 'package:soar_score_core/soar_score_core.dart';

/// HTTP client for contest API endpoints.
class ContestClient {
  final String baseUrl;

  ContestClient({required this.baseUrl});

  /// Fetch contest data from the server.
  Future<Contest?> getContest() async {
    // Stub
    return null;
  }

  /// Submit flight data to the server.
  Future<void> submitFlight(Flight flight) async {
    // Stub
  }
}
