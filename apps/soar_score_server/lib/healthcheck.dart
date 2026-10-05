import 'dart:io';

/// The port the container health check probes: `PORT`, or 8080 when unset or
/// invalid (the server itself rejects an invalid `PORT` at startup).
int healthcheckPort(Map<String, String> environment) {
  final port = int.tryParse(environment['PORT'] ?? '');
  return port != null && port >= 1 && port <= 65535 ? port : 8080;
}

/// Whether `GET /health` on this machine's [port] answers 200 within
/// [timeout].
///
/// The runtime image is `scratch`, with no shell or curl, so the server
/// binary probes itself (`server --healthcheck`).
Future<bool> checkHealth(
  int port, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/health'),
    );
    final response = await request.close().timeout(timeout);
    await response.drain<void>();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
