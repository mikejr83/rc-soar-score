import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';

/// The liveness of a single connectivity indicator.
///
/// [ConnectivityStatus.unknown] is the initial state and is also used when no
/// remote API is configured: the indicator has not yet been observed, or there
/// is nothing to observe.
enum ConnectivityStatus { unknown, checking, available, unavailable }

/// The outcome of probing the local host's internet connection.
class InternetProbeResult {
  /// Whether the host can reach the wider internet.
  final bool isOnline;

  /// A human-readable description of the probe outcome for the detail view.
  final String? detail;

  const InternetProbeResult({required this.isOnline, this.detail});
}

/// Observes whether the local host has an internet connection.
///
/// [ConnectivityState] owns this abstraction so the probe can be substituted
/// in tests. On the web it is backed by the browser's connectivity API; on
/// native, by a socket probe.
abstract class InternetProbe {
  const InternetProbe();

  /// Probes whether the local host currently has an internet connection.
  ///
  /// Implementations must not throw; a probe failure is reported as
  /// [InternetProbeResult.isOnline] == false.
  Future<InternetProbeResult> probe();

  /// Binds this probe to a [ConnectivityState] for event-driven updates.
  ///
  /// The default implementation is a no-op. Web probes override this to
  /// attach browser event listeners.
  void bind(ConnectivityState owner) {}

  /// Detaches this probe from its [ConnectivityState].
  ///
  /// The default implementation is a no-op. Web probes override this to
  /// remove browser event listeners.
  void detach() {}
}

/// A native internet probe that attempts a TCP connection to a well-known,
/// highly reachable endpoint (a public DNS resolver by default).
///
/// A successful connection to any major public endpoint is treated as
/// evidence that the host has an internet connection. This answers "is there
/// internet?", which is deliberately distinct from "is the API reachable?".
class SocketInternetProbe extends InternetProbe {
  /// The endpoint to probe.
  final Uri probeTarget;

  SocketInternetProbe({Uri? probeTarget})
      : probeTarget =
            probeTarget ?? Uri.parse('tcp://1.1.1.1:53');

  @override
  Future<InternetProbeResult> probe() async {
    try {
      final socket = await Socket.connect(
        probeTarget.host,
        probeTarget.port,
        timeout: const Duration(seconds: 5),
      );
      // The connection itself is sufficient evidence of reachability.
      await socket.close();
      return const InternetProbeResult(isOnline: true);
    } catch (e) {
      return InternetProbeResult(
        isOnline: false,
        detail: 'No internet connection: $e',
      );
    }
  }
}

/// The state of one connectivity indicator (internet or remote API).
class IndicatorState {
  /// The current liveness of the indicator.
  final ConnectivityStatus status;

  /// The time the indicator was last observed, if ever.
  final DateTime? lastCheckedAt;

  /// A detail string for the indicator's detail view (a failure reason, or a
  /// note such as "No API configured").
  final String? detail;

  const IndicatorState({
    this.status = ConnectivityStatus.unknown,
    this.lastCheckedAt,
    this.detail,
  });

  /// A human-readable label for the indicator's chip text.
  String get label {
    switch (status) {
      case ConnectivityStatus.unknown:
        return 'Unknown';
      case ConnectivityStatus.checking:
        return 'CheckingÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦';
      case ConnectivityStatus.available:
        return 'Connected';
      case ConnectivityStatus.unavailable:
        return 'Not connected';
    }
  }

  bool get isAvailable => status == ConnectivityStatus.available;
  bool get isUnavailable => status == ConnectivityStatus.unavailable;
  bool get isUnknown => status == ConnectivityStatus.unknown;
  bool get isChecking => status == ConnectivityStatus.checking;
}

/// Tracks the liveness of the local host's internet connection and the remote
/// API as two independent indicators.
///
/// The two are deliberately separate: internet connectivity does not imply
/// remote API connectivity. A single shared probe ([checkNow]) observes both
/// so a manual or automatic check updates them consistently, and a
/// re-entrancy guard prevents overlapping probes.
class ConnectivityState extends ChangeNotifier {
  /// How often the background probe runs while [startMonitoring] is active.
  static const Duration defaultRefreshInterval = Duration(seconds: 30);

  /// Whether the local host has an internet connection.
  IndicatorState internet = const IndicatorState();

  /// Whether the remote API is reachable.
  IndicatorState api = const IndicatorState();

  final InternetProbe _internetProbe;
  final ContestClient? _apiClient;
  Timer? _interval;

  bool _monitoring = false;
  bool _probing = false;

  /// Creates a connectivity state.
  ///
  /// [internetProbe] must be supplied for non-web builds (e.g. a
  /// [SocketInternetProbe]); on the web it defaults to the browser's
  /// connectivity API and is not required. [apiClient] is optional until an
  /// API base URL is configured; the API indicator remains
  /// [ConnectivityStatus.unknown] until one is supplied and the internet is
  /// available.
  ConnectivityState({
    InternetProbe? internetProbe,
    ContestClient? apiClient,
  })  : _internetProbe = internetProbe ?? _defaultInternetProbe(),
        // ignore: prefer_initializing_formals
        _apiClient = apiClient;

  /// Whether background monitoring is currently active.
  bool get isMonitoring => _monitoring;

  /// Starts background monitoring: a periodic probe runs on [refreshInterval].
  ///
  /// On the web, browser online/offline events also trigger a check. This
  /// method is idempotent: a second call while already monitoring is a
  /// no-op.
  void startMonitoring({Duration refreshInterval = defaultRefreshInterval}) {
    if (_monitoring) {
      return;
    }
    _monitoring = true;
    _interval = Timer.periodic(refreshInterval, (_) => checkNow());
    _bindWebProbe();
    checkNow();
  }

  /// Stops background monitoring and any browser event listeners.
  void stopMonitoring() {
    if (!_monitoring) {
      return;
    }
    _monitoring = false;
    _interval?.cancel();
    _interval = null;
    _detachWebProbe();
  }

  /// Runs a single connectivity check of both indicators.
  ///
  /// A check already in progress wins: a concurrent call is ignored rather
  /// than enqueued, keeping the probe count bounded.
  Future<void> checkNow() async {
    if (_probing) {
      return;
    }
    _probing = true;
    try {
      // Internet first: the API probe is only meaningful when the host can
      // reach the network at all.
      final internetResult = await _internetProbe.probe();
      _setInternet(
        status: internetResult.isOnline
            ? ConnectivityStatus.available
            : ConnectivityStatus.unavailable,
        detail: internetResult.detail,
      );

      final apiClient = _apiClient;
      if (apiClient == null) {
        _setApi(
          status: ConnectivityStatus.unknown,
          detail: 'No remote API configured.',
        );
        return;
      }
      if (!internetResult.isOnline) {
        // Keep the last API observation; the API cannot be probed without an
        // internet connection.
        return;
      }

      _setApi(status: ConnectivityStatus.checking);
      final apiResult = await apiClient.checkApiReachable();
      _setApi(
        status: apiResult.isReachable
            ? ConnectivityStatus.available
            : ConnectivityStatus.unavailable,
        detail: apiResult.detail,
      );
    } finally {
      _probing = false;
    }
  }

  /// Re-runs the shared probe. Exposed for the indicator's Retry action.
  ///
  /// Unlike [checkNow], a retry always runs: if a background probe is in
  /// flight it is allowed to complete and the retry's result supersedes it.
  Future<void> retry() async {
    _probing = false; // release the guard so this probe can run
    await checkNow();
  }

  void _setInternet({
    required ConnectivityStatus status,
    String? detail,
  }) {
    internet = IndicatorState(
      status: status,
      lastCheckedAt: DateTime.now(),
      detail: detail,
    );
    notifyListeners();
  }

  void _setApi({
    required ConnectivityStatus status,
    String? detail,
  }) {
    api = IndicatorState(
      status: status,
      lastCheckedAt: DateTime.now(),
      detail: detail,
    );
    notifyListeners();
  }

  void _bindWebProbe() {
    _internetProbe.bind(this);
  }

  void _detachWebProbe() {
    _internetProbe.detach();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

/// Resolves the default [InternetProbe] for the current platform.
///
/// On web, pass a [WebConnectivityProbe] explicitly; the default here is
/// the [SocketInternetProbe] which works on native platforms.
InternetProbe _defaultInternetProbe() {
  return SocketInternetProbe();
}
