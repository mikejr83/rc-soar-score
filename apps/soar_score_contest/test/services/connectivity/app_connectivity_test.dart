import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';
import 'package:soar_score_contest/services/connectivity/internet_probe.dart';

final _baseUrl = Uri.parse('http://contest-site.example:8085/api');

const _serverPayload =
    '{"name":"soar_score_server","displayName":"Soar Score API Server","version":"0.1.0"}';
const _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// `InternetProbe` stand-in for unit tests (decision D10): records calls and
/// can emit change events on demand.
class FakeInternetProbe implements InternetProbe {
  FakeInternetProbe({List<ConnectivityResult>? initialResults})
    : results = initialResults ?? const [ConnectivityResult.wifi],
      _controller = StreamController<List<ConnectivityResult>>.broadcast();

  /// Results returned by [check].
  List<ConnectivityResult> results;

  /// Thrown by [check] when non-null (e.g. a `PlatformException` for D8).
  Object? checkError;

  int checkCalls = 0;
  bool disposed = false;

  final StreamController<List<ConnectivityResult>> _controller;

  /// Emits a connection-change events to every subscriber.
  void emit(List<ConnectivityResult> newResults) => _controller.add(newResults);

  @override
  Future<List<ConnectivityResult>> check() async {
    checkCalls++;
    if (checkError != null) {
      throw checkError!;
    }
    return results;
  }

  @override
  StreamSubscription<List<ConnectivityResult>> subscribe(
    ValueChanged<List<ConnectivityResult>> onChanged,
  ) {
    return _controller.stream.listen(onChanged);
  }

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }
}

/// Waits until [condition] holds (draining real microtasks between polls).
Future<void> _flushUntil(bool Function() condition) async {
  while (!condition()) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late FakeInternetProbe probe;
  late AppConnectivity monitor;
  var monitorDisposed = false;

  /// Builds an `AppConnectivity` on top of a real `ApiClient` and the given
  /// [MockClient] — the documented `soar_score_api` test methodology: the real
  /// request path, a fake transport, never a bespoke prober function (D9).
  AppConnectivity createMonitor({
    required MockClient httpClient,
    InternetProbe? internetProbe,
    Duration poll = const Duration(milliseconds: 300),
    Duration maxPoll = const Duration(seconds: 30),
    Duration timeout = const Duration(seconds: 2),
    bool assumeOnline = false,
  }) {
    final client = ApiClient(baseUrl: _baseUrl, httpClient: httpClient);
    final created = AppConnectivity(
      client: client,
      internetProbe: internetProbe ?? probe,
      initialPollInterval: poll,
      maxPollInterval: maxPoll,
      assumeOnline: assumeOnline,
      probeTimeout: timeout,
    );
    addTearDown(() {
      client.close();
      if (!monitorDisposed) {
        created.dispose();
      }
    });
    monitor = created;
    return created;
  }

  void disposeMonitor() {
    monitorDisposed = true;
    monitor.dispose();
  }

  setUp(() {
    probe = FakeInternetProbe();
    monitorDisposed = false;
  });

  tearDown(() {
    if (!probe.disposed) {
      probe.dispose();
    }
  });

  group('AppConnectivity', () {
    test('starts unknown, then reports both indicators available', () async {
      monitor = createMonitor(
        httpClient: MockClient(
          (request) async =>
              http.Response(_serverPayload, 200, headers: _jsonHeaders),
        ),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );

      expect(monitor.internetStatus, ConnectivityStatus.available);
      expect(monitor.internetLastObservedAt, isNotNull);
      expect(monitor.supportsConnectivity, isTrue);
      expect(monitor.apiStatus, ConnectivityStatus.available);
      expect(monitor.apiLastSuccessfulAt, isNotNull);
      expect(monitor.apiLastError, isNull);
    });

    test('reports internet unavailable when there is no connection', () async {
      probe = FakeInternetProbe(
        initialResults: const [ConnectivityResult.none],
      );
      monitor = createMonitor(
        httpClient: MockClient(
          (request) async =>
              http.Response(_serverPayload, 200, headers: _jsonHeaders),
        ),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );

      expect(monitor.internetStatus, ConnectivityStatus.unavailable);
      expect(monitor.internetLastObservedAt, isNotNull);
    });

    test('keeps the last successful time across an HTTP failure and '
        'recovers on the next success', () async {
      var failing = false;
      final captured = <http.Request>[];
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          captured.add(request);
          return failing
              ? http.Response('{"error":"boom"}', 500, headers: _jsonHeaders)
              : http.Response(_serverPayload, 200, headers: _jsonHeaders);
        }),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );
      final firstSuccess = monitor.apiLastSuccessfulAt;
      expect(firstSuccess, isNotNull);

      failing = true;
      monitor.retryApi();
      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.unavailable,
      );
      expect(monitor.apiLastError, 'HTTP 500');
      expect(monitor.apiLastSuccessfulAt, firstSuccess);

      failing = false;
      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );
      expect(monitor.apiLastError, isNull);
      expect(monitor.apiLastSuccessfulAt, isNotNull);
      expect(monitor.apiLastSuccessfulAt!.isAfter(firstSuccess!), isTrue);
      expect(captured.length, greaterThanOrEqualTo(3));
    });

    test('classifies a transport failure as a network error', () async {
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          throw http.ClientException('connection refused', request.url);
        }),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.unavailable,
      );

      expect(monitor.apiLastError, 'Network error');
      expect(monitor.apiLastSuccessfulAt, isNull);
    });

    test('classifies a hanging server as a timeout', () async {
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          await Future<void>.delayed(const Duration(seconds: 30));
          return http.Response(_serverPayload, 200, headers: _jsonHeaders);
        }),
        timeout: const Duration(milliseconds: 300),
        poll: const Duration(seconds: 30),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.unavailable,
      );

      expect(monitor.apiLastError, 'Timed out');
    });

    test('classifies an unexpected error without crashing', () async {
      monitor = createMonitor(
        httpClient: MockClient(
          // A 2xx body that is not a JSON object becomes a plain ApiException.
          (request) async =>
              http.Response('not json', 200, headers: _jsonHeaders),
        ),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.unavailable,
      );

      expect(monitor.apiLastError, 'Unknown error');
    });

    test('an internet change event re-probes the API once', () async {
      final captured = <http.Request>[];
      var failing = true;
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          captured.add(request);
          if (failing) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          return failing
              ? http.Response('{"error":"down"}', 500, headers: _jsonHeaders)
              : http.Response(_serverPayload, 200, headers: _jsonHeaders);
        }),
        poll: const Duration(seconds: 30),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.unavailable,
      );
      expect(captured.length, 1);

      // The server recovers and a connectivity-change event arrives: it must
      // trigger exactly one re-probe (single-flight: events while a probe is
      // in flight are skipped, never chained).
      failing = false;
      final probesBeforeEvent = captured.length;
      probe.emit(const [ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      probe.emit(const [ConnectivityResult.none]);

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );

      expect(captured.length, probesBeforeEvent + 1);
      expect(monitor.internetStatus, ConnectivityStatus.unavailable);
      expect(monitor.apiLastError, isNull);
    });

    test('stops probing once the API is reachable', () async {
      var calls = 0;
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          calls++;
          return http.Response(_serverPayload, 200, headers: _jsonHeaders);
        }),
        poll: const Duration(milliseconds: 50),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(calls, 1);
      expect(monitor.apiStatus, ConnectivityStatus.available);
    });

    test(
      'retries a failed probe with a growing delay up to the maximum',
      () async {
        final times = <DateTime>[];
        monitor = createMonitor(
          httpClient: MockClient((request) async {
            times.add(DateTime.now());
            return http.Response('down', 503);
          }),
          poll: const Duration(milliseconds: 50),
          maxPoll: const Duration(milliseconds: 100),
        );

        await _flushUntil(() => times.length >= 5);
        final gaps = [
          for (var i = 1; i < times.length; i++)
            times[i].difference(times[i - 1]).inMilliseconds,
        ];
        expect(gaps[0], inInclusiveRange(40, 90));
        expect(gaps[1], greaterThanOrEqualTo(90));
        expect(gaps[3], lessThan(190));
        expect(monitor.apiStatus, ConnectivityStatus.unavailable);
      },
    );

    test(
      'reportUnreachable starts probing and reportReachable stops it',
      () async {
        var calls = 0;
        monitor = createMonitor(
          httpClient: MockClient((request) async {
            calls++;
            return http.Response(_serverPayload, 200, headers: _jsonHeaders);
          }),
          poll: const Duration(milliseconds: 50),
        );
        await _flushUntil(
          () => monitor.apiStatus == ConnectivityStatus.available,
        );

        monitor.reportUnreachable();
        expect(monitor.apiStatus, ConnectivityStatus.unavailable);
        await _flushUntil(() => calls >= 2);
        expect(monitor.apiStatus, ConnectivityStatus.available);

        monitor.reportUnreachable();
        monitor.reportReachable();
        final seen = calls;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(calls, seen);
        expect(monitor.apiStatus, ConnectivityStatus.available);
      },
    );

    test('a build that assumes it is online never probes or polls', () async {
      var calls = 0;
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          calls++;
          return http.Response('down', 503);
        }),
        poll: const Duration(milliseconds: 20),
        assumeOnline: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(calls, 0);
      expect(monitor.apiStatus, ConnectivityStatus.available);

      monitor.retryApi();
      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.unavailable,
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(calls, 1);
    });

    test('pause holds the retries and resume probes at once', () async {
      var calls = 0;
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          calls++;
          return http.Response('down', 503);
        }),
        poll: const Duration(milliseconds: 50),
      );
      await _flushUntil(() => calls >= 1);
      monitor.pause();
      final seen = calls;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(calls, seen);

      monitor.resume();
      await _flushUntil(() => calls > seen);
    });

    test('retryInternet re-checks the network interface', () async {
      monitor = createMonitor(
        httpClient: MockClient(
          (request) async =>
              http.Response(_serverPayload, 200, headers: _jsonHeaders),
        ),
      );
      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );
      expect(monitor.internetStatus, ConnectivityStatus.available);

      probe.results = const [ConnectivityResult.none];
      await monitor.retryInternet();
      expect(monitor.internetStatus, ConnectivityStatus.unavailable);

      probe.results = const [ConnectivityResult.wifi];
      await monitor.retryInternet();
      expect(monitor.internetStatus, ConnectivityStatus.available);
      expect(monitor.internetLastObservedAt, isNotNull);
    });

    test('retryApi re-probes the server', () async {
      var failing = true;
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          return failing
              ? http.Response('{"error":"down"}', 500, headers: _jsonHeaders)
              : http.Response(_serverPayload, 200, headers: _jsonHeaders);
        }),
        poll: const Duration(seconds: 30),
      );

      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.unavailable,
      );
      expect(monitor.apiLastError, 'HTTP 500');

      failing = false;
      monitor.retryApi();
      await _flushUntil(
        () => monitor.apiStatus == ConnectivityStatus.available,
      );
      expect(monitor.apiLastError, isNull);
      expect(monitor.apiLastSuccessfulAt, isNotNull);
    });

    test(
      'hides the internet indicator when the first check reports no platform '
      'support (D8)',
      () async {
        probe = FakeInternetProbe()
          ..checkError = PlatformException(code: 'unsupported');
        monitor = createMonitor(
          httpClient: MockClient(
            (request) async =>
                http.Response(_serverPayload, 200, headers: _jsonHeaders),
          ),
          poll: const Duration(seconds: 30),
        );

        await _flushUntil(
          () => monitor.apiStatus == ConnectivityStatus.available,
        );

        expect(monitor.supportsConnectivity, isFalse);
        expect(monitor.internetStatus, ConnectivityStatus.unknown);
        expect(monitor.internetLastObservedAt, isNull);

        // Retry is a no-op once the host is known to be unsupported.
        await monitor.retryInternet();
        expect(monitor.supportsConnectivity, isFalse);
        expect(probe.checkCalls, 1);
        // The API indicator is unaffected.
        expect(monitor.apiStatus, ConnectivityStatus.available);
      },
    );

    test('dispose cancels the poll timer, subscription, and probe', () async {
      final captured = <http.Request>[];
      monitor = createMonitor(
        httpClient: MockClient((request) async {
          captured.add(request);
          return http.Response('down', 503);
        }),
        poll: const Duration(milliseconds: 100),
      );
      await _flushUntil(() => captured.isNotEmpty);

      disposeMonitor();
      final countAtDispose = captured.length;
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(captured.length, countAtDispose);
      expect(probe.disposed, isTrue);
    });

    test('apiTarget is the host and port of the client baseUrl', () async {
      monitor = createMonitor(
        httpClient: MockClient(
          (request) async =>
              http.Response(_serverPayload, 200, headers: _jsonHeaders),
        ),
      );

      expect(monitor.apiTarget, 'contest-site.example:8085');
    });
  });
}
