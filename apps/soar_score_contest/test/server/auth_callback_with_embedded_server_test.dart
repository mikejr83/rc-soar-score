import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/server/auth_callback_server.dart';
import 'package:soar_score_contest/server/embedded_server.dart';

/// The sign-in callback listener is separate from the embedded API, so the
/// embedded guard (#425) must not affect the browser's secret-less GET.
void main() {
  test(
    'the callback page loads for a browser while the API is guarded',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('soar_score_cb_test');
      final probe = await ServerSocket.bind('localhost', 0);
      final port = probe.port;
      await probe.close();
      final embedded = await startEmbeddedServer(
        '${tempDir.path}${Platform.pathSeparator}soar_score.db',
      );
      final callback = AuthCallbackServer(
        port: port,
        appScheme: 'com.soarscore.contest',
      );
      final http = HttpClient();
      try {
        await callback.start();
        final request = await http.getUrl(
          Uri.parse('http://localhost:$port/callback?code=abc&state=xyz'),
        );
        request.headers.set('origin', 'https://tenant.auth0.com');
        final response = await request.close();
        await response.drain<void>();
        expect(response.statusCode, 200);

        final api = await http.getUrl(
          embedded.baseUrl.resolve('/api/v1/roles'),
        );
        expect((await api.close()).statusCode, 401);
      } finally {
        http.close(force: true);
        await callback.stop();
        await embedded.close();
        tempDir.deleteSync(recursive: true);
      }
    },
  );
}
