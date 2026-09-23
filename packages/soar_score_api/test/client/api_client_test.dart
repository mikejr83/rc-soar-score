import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:test/test.dart';

void main() {
  group('ApiClient', () {
    // Deliberately arbitrary host and port: the client must build request
    // URLs purely from the caller-supplied baseUrl — never a hard-coded
    // host or port.
    final baseUrl = Uri.parse('http://contest-site.example:8085/api');
    const serverPayload =
        '{"name":"soar_score_server","displayName":"Soar Score API Server","version":"0.1.0"}';
    const jsonHeaders = <String, String>{
      'content-type': 'application/json; charset=utf-8',
    };

    late List<http.Request> captured;
    late MockClient mockClient;
    late ApiClient client;

    setUp(() {
      captured = <http.Request>[];
      mockClient = MockClient((request) async {
        captured.add(request);
        return http.Response(serverPayload, 200, headers: jsonHeaders);
      });
      client = ApiClient(baseUrl: baseUrl, httpClient: mockClient);
    });

    tearDown(() => client.close());

    Future<Object?> expectError(Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (error) {
        return error;
      }
      return null;
    }

    test('health() resolves /health against the given baseUrl and decodes the payload', () async {
      final health = await client.health();

      expect(
        health,
        const HealthDto(
          name: 'soar_score_server',
          displayName: 'Soar Score API Server',
          version: '0.1.0',
        ),
      );
      expect(captured, hasLength(1));
      final request = captured.single;
      expect(request.method, 'GET');
      expect(request.url, baseUrl.resolveUri(Uri.parse('/health')));
      expect(request.headers['accept'], 'application/json');
      expect(request.headers, isNot(contains('authorization')));
    });

    test('works with a different arbitrary baseUrl', () async {
      final localBaseUrl = Uri.parse('http://localhost:1234');
      final localClient = ApiClient(
        baseUrl: localBaseUrl,
        httpClient: mockClient,
      );
      addTearDown(localClient.close);

      await localClient.health();

      expect(captured.single.url, Uri.parse('http://localhost:1234/health'));
    });

    test('sends the Bearer token returned by the token provider', () async {
      final seen = <http.Request>[];
      final authedClient = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((request) async {
          seen.add(request);
          return http.Response(serverPayload, 200, headers: jsonHeaders);
        }),
        tokenProvider: () async => 'test-token-123',
      );
      addTearDown(authedClient.close);

      await authedClient.health();

      expect(seen.single.headers['authorization'], 'Bearer test-token-123');
    });

    test(
      'omits the Authorization header when the token provider returns null',
      () async {
        final publicClient = ApiClient(
          baseUrl: baseUrl,
          httpClient: mockClient,
          tokenProvider: () async => null,
        );
        addTearDown(publicClient.close);

        await publicClient.health();

        expect(captured.single.headers, isNot(contains('authorization')));
      },
    );

    test(
      'throws ApiHttpError with status and body for non-2xx responses',
      () async {
        final errorClient = ApiClient(
          baseUrl: baseUrl,
          httpClient: MockClient(
            (request) async => http.Response(
              '{"error":"forbidden"}',
              403,
              headers: jsonHeaders,
            ),
          ),
        );
        addTearDown(errorClient.close);

        final error = await expectError(() async => await errorClient.health());

        expect(error, isA<ApiHttpError>());
        final httpError = error as ApiHttpError;
        expect(httpError.statusCode, 403);
        expect(httpError.body, '{"error":"forbidden"}');
        expect(httpError.requestUri, baseUrl.resolveUri(Uri.parse('/health')));
      },
    );

    test('throws ApiNetworkError when the transport fails', () async {
      final offlineClient = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((request) async {
          throw http.ClientException('connection refused', request.url);
        }),
      );
      addTearDown(offlineClient.close);

      final error = await expectError(() async => await offlineClient.health());

      expect(error, isA<ApiNetworkError>());
      final networkError = error as ApiNetworkError;
      expect(networkError.cause, isA<http.ClientException>());
      expect(networkError.requestUri, baseUrl.resolveUri(Uri.parse('/health')));
    });

    test(
      'throws ApiException when the body cannot be decoded as a JSON object',
      () async {
        final junkClient = ApiClient(
          baseUrl: baseUrl,
          httpClient: MockClient(
            (request) async =>
                http.Response('not json', 200, headers: jsonHeaders),
          ),
        );
        addTearDown(junkClient.close);

        final error = await expectError(() async => await junkClient.health());

        expect(error, isA<ApiException>());
        expect(error, isNot(isA<ApiHttpError>()));
        expect(error, isNot(isA<ApiNetworkError>()));
      },
    );
  });
}
