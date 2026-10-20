import 'package:http/http.dart' as http;

/// A recording `http.BaseClient` for tests: records lifecycle calls instead of
/// touching the network, and answers every request with an empty 200 so a
/// probe resolves `available`.
class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient(this.recorder);

  /// Appends `'send'` per request and `'close'` when the client is closed.
  final List<String> recorder;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    recorder.add('send');
    return http.StreamedResponse(Stream<List<int>>.empty(), 200);
  }

  @override
  void close() {
    recorder.add('close');
    super.close();
  }
}
