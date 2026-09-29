// ignore_for_file: prefer_initializing_formals
// The public constructor parameter names are part of this monitor's
// documented API, so the initializer list stands in for initializing
// formal fields.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'internet_probe.dart';

/// App-scoped monitor behind the two landing-page connectivity indicators
/// (internet + remote API).
///
/// The two indicators are independent: a report of a network connection does
/// not imply the configured API server is reachable, and an embedded loopback
/// server is reachable without internet access (ticket 018's offline
/// behavior). State is expressed with [ConnectivityStatus] plus text in the
/// UI — never color alone (see `plan/ui/contest-administration/offline-ui.md`).
///
/// All requests to the API go through [ApiClient]'s public `health()`
/// endpoint (decision D9: the package is unmodified; its transport — not this
/// monitor — owns the HTTP plumbing). [probeTimeout] is applied with
/// [Future.timeout] because the underlying client has no default timeout
/// (D6's single acknowledged deviation from the package's own behavior).
class AppConnectivity extends ChangeNotifier {
  /// [client] is the app's single `ApiClient` (the one seam every API
  /// request goes through, decision D9); [internetProbe] is injectable for
  /// tests (decision D10); [apiPollInterval] and [probeTimeout] are the D6
  /// polling/timeout defaults.
  AppConnectivity({
    required ApiClient client,
    InternetProbe? internetProbe,
    Duration apiPollInterval = _defaultApiPollInterval,
    Duration probeTimeout = _defaultProbeTimeout,
  })  : _client = client,
        _apiPollInterval = apiPollInterval,
        _probeTimeout = probeTimeout,
        _internetProbe = internetProbe ?? ConnectivityInternetProbe() {
    _start();
  }

  static const Duration _defaultApiPollInterval = Duration(seconds: 30);
  static const Duration _defaultProbeTimeout = Duration(seconds: 10);

  final ApiClient _client;
  final InternetProbe _internetProbe;
  final Duration _apiPollInterval;
  final Duration _probeTimeout;

  ConnectivityStatus _internetStatus = ConnectivityStatus.unknown;
  DateTime? _internetLastObservedAt;
  bool _supportsConnectivity = true;
  ConnectivityStatus _apiStatus = ConnectivityStatus.unknown;
  DateTime? _apiLastSuccessfulAt;
  String? _apiLastError;
  Timer? _apiPollTimer;
  StreamSubscription<List<ConnectivityResult>>? _internetSubscription;
  bool _apiProbeInFlight = false;
  bool _internetChecking = false;
  bool _disposed = false;

  /// Current liveness of the internet indicator.
  ConnectivityStatus get internetStatus => _internetStatus;

  /// When the internet state was last observed (an initial check or a change
  /// event). Null until the first successful observation.
  DateTime? get internetLastObservedAt => _internetLastObservedAt;

  /// False when this host cannot report connection state at all (the probe's
  /// first check failed with a `PlatformException`); the UI hides the
  /// internet indicator in that case.
  bool get supportsConnectivity => _supportsConnectivity;

  /// Current liveness of the remote API indicator.
  ConnectivityStatus get apiStatus => _apiStatus;

  /// When the last successful `GET /health` round-trip completed. Kept across
  /// failures so the UI can still show "last successful connection".
  DateTime? get apiLastSuccessfulAt => _apiLastSuccessfulAt;

  /// Short text for the most recent failed probe: "Network error", an
  /// "HTTP 500"-style status message, "Timed out", or "Unknown error".
  /// Null while the indicator is available or before any failure.
  String? get apiLastError => _apiLastError;

  /// The host (and port) of the API server being probed, for the detail
  /// dialog's `Target:` line.
  String get apiTarget {
    final host = _client.baseUrl.host;
    final port = _client.baseUrl.port;
    return host.isEmpty ? 'unknown host' : port == 0 ? host : '$host:$port';
  }

  void _start() {
    _setInternetStatus(ConnectivityStatus.checking);
    unawaited(_initialInternetCheck());
    _setApiStatus(ConnectivityStatus.checking);
    _schedulePoll();
    _probeApi();
  }

  Future<void> _initialInternetCheck() async {
    _internetChecking = true;
    try {
      final results = await _internetProbe.check();
      _publishInternetResults(results);
    } on PlatformException {
      // This host cannot report connection state (D8). The indicator is
      // hidden by `supportsConnectivity` once the tree has built.
      _supportsConnectivity = false;
      _setInternetStatus(ConnectivityStatus.unknown);
    } finally {
      _internetChecking = false;
      if (!_disposed) {
        _internetSubscription = _internetProbe.subscribe(_onConnectivityChanged);
      }
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _publishInternetResults(results);
    // An interface change is exactly the moment the API's reachability is
    // most likely to have changed (D6): re-probe immediately, single-flight.
    _probeApi();
  }

  void _publishInternetResults(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final available = result != ConnectivityResult.none;
    _internetLastObservedAt = DateTime.now();
    _setInternetStatus(
      available ? ConnectivityStatus.available : ConnectivityStatus.unavailable,
    );
  }

  void _setInternetStatus(ConnectivityStatus status) {
    // A probe or check that is in flight when dispose() runs must not notify
    // listeners after the notifier is gone.
    if (_disposed || status == _internetStatus) {
      return;
    }
    _internetStatus = status;
    notifyListeners();
  }

  void _setApiStatus(ConnectivityStatus status) {
    if (_disposed || status == _apiStatus) {
      return;
    }
    _apiStatus = status;
    notifyListeners();
  }

  void _schedulePoll() {
    _apiPollTimer?.cancel();
    _apiPollTimer = Timer.periodic(_apiPollInterval, (_) => _probeApi());
  }

  /// Probes `health()` once. Single-flight: a probe requested while one is
  /// already in flight is skipped (never chained), so fast connection flapping
  /// cannot pile up requests.
  void _probeApi() {
    if (_disposed || _apiProbeInFlight) {
      return;
    }
    _apiProbeInFlight = true;
    _setApiStatus(ConnectivityStatus.checking);
    _runApiProbe();
  }

  Future<void> _runApiProbe() async {
    final startedAt = DateTime.now();
    try {
      await _client.health().timeout(_probeTimeout);
      _apiLastError = null;
      _apiLastSuccessfulAt = startedAt;
      _setApiStatus(ConnectivityStatus.available);
    } on ApiHttpError catch (error) {
      _failApiProbe('HTTP ${error.statusCode}');
    } on ApiNetworkError {
      _failApiProbe('Network error');
    } on TimeoutException {
      _failApiProbe('Timed out');
    } on Object {
      // A decode failure (plain `ApiException`) or anything else: the probe
      // failed, but the app keeps running and the next poll retries.
      _failApiProbe('Unknown error');
    } finally {
      _apiProbeInFlight = false;
    }
  }

  void _failApiProbe(String message) {
    _apiLastError = message;
    _setApiStatus(ConnectivityStatus.unavailable);
  }

  /// Manually re-checks the internet state now (detail dialog's "Retry now").
  Future<void> retryInternet() async {
    if (_disposed || !_supportsConnectivity) {
      return;
    }
    if (_internetChecking) {
      return;
    }
    _internetChecking = true;
    _setInternetStatus(ConnectivityStatus.checking);
    try {
      _publishInternetResults(await _internetProbe.check());
    } on PlatformException {
      _supportsConnectivity = false;
      _setInternetStatus(ConnectivityStatus.unknown);
    } finally {
      _internetChecking = false;
    }
  }

  /// Manually re-probes the API now (detail dialog's "Retry now").
  void retryApi() {
    _probeApi();
  }

  @override
  void dispose() {
    _disposed = true;
    _apiPollTimer?.cancel();
    _apiPollTimer = null;
    _internetSubscription?.cancel();
    _internetSubscription = null;
    _internetProbe.dispose();
    super.dispose();
  }
}
