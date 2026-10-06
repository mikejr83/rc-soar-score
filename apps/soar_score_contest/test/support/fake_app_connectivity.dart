import 'package:flutter/foundation.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';

/// `AppConnectivity` stand-in for widget tests: static state, no platform
/// probes, and no-op retry entry points.
class FakeAppConnectivity extends ChangeNotifier implements AppConnectivity {
  @override
  bool supportsConnectivity = true;

  @override
  ConnectivityStatus internetStatus = ConnectivityStatus.available;

  @override
  ConnectivityStatus apiStatus = ConnectivityStatus.available;

  @override
  DateTime? get internetLastObservedAt => null;

  @override
  DateTime? get apiLastSuccessfulAt => null;

  @override
  String? get apiLastError => null;

  @override
  String get apiTarget => 'example.com:8080';

  @override
  Future<void> retryInternet() async {}

  @override
  void retryApi() {}
}
