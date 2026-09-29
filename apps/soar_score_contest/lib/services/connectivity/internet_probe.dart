import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Seam around the platform network-interface reporter used for the
/// internet indicator (decision D10: the *internet* side is injectable for
/// unit tests; the API side is tested through `ApiClient`'s own transport
/// injection instead).
abstract interface class InternetProbe {
  /// A probe's initial `PlatformException` (no platform support on this
  /// host) must be rethrown so the monitor can hide the indicator (D8).
  Future<List<ConnectivityResult>> check();

  /// Subscribes to connection changes. The probe owns the underlying
  /// subscription and cancels it in [dispose].
  StreamSubscription<List<ConnectivityResult>> subscribe(
    ValueChanged<List<ConnectivityResult>> onChanged,
  );

  /// Releases any platform channel resources.
  void dispose();
}

/// [InternetProbe] backed by `package:connectivity_plus` — the shared
/// `Connectivity.instance` channel on web, Windows, Android, and iOS.
class ConnectivityInternetProbe implements InternetProbe {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  Future<List<ConnectivityResult>> check() =>
      Connectivity().checkConnectivity();

  @override
  StreamSubscription<List<ConnectivityResult>> subscribe(
    ValueChanged<List<ConnectivityResult>> onChanged,
  ) {
    _subscription = Connectivity().onConnectivityChanged.listen(onChanged);
    return _subscription!;
  }

  @override
  void dispose() => _subscription?.cancel();
}
