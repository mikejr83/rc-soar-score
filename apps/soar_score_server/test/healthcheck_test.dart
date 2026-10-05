import 'dart:io';

import 'package:soar_score_server/healthcheck.dart';
import 'package:test/test.dart';

void main() {
  group('healthcheckPort', () {
    test('defaults to 8080', () {
      expect(healthcheckPort({}), 8080);
      expect(healthcheckPort({'PORT': ''}), 8080);
      expect(healthcheckPort({'PORT': 'abc'}), 8080);
      expect(healthcheckPort({'PORT': '70000'}), 8080);
    });

    test('reads PORT', () {
      expect(healthcheckPort({'PORT': '9000'}), 9000);
    });
  });

  group('checkHealth', () {
    late HttpServer server;

    Future<int> serve(int status) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..statusCode = status
          ..close();
      });
      return server.port;
    }

    tearDown(() => server.close(force: true));

    test('is true when /health answers 200', () async {
      expect(await checkHealth(await serve(200)), isTrue);
    });

    test('is false when /health answers 500', () async {
      expect(await checkHealth(await serve(500)), isFalse);
    });

    test('is false when nothing listens', () async {
      final port = await serve(200);
      await server.close(force: true);
      expect(await checkHealth(port), isFalse);
    });
  });
}
