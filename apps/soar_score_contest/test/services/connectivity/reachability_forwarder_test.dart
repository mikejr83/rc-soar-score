import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/app_bootstrap.dart';
import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';
import 'package:soar_score_contest/services/connectivity/reachability_forwarder.dart';
import 'package:soar_score_core/soar_score_core.dart';

class _Monitor extends ChangeNotifier implements AppConnectivity {
  @override
  ConnectivityStatus apiStatus = ConnectivityStatus.unknown;

  void report(ConnectivityStatus status) {
    apiStatus = status;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bootstrap implements AppBootstrap {
  final reports = <bool>[];

  @override
  void remoteReachabilityChanged({required bool reachable}) =>
      reports.add(reachable);

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  ApiClient get remoteApiClient => throw UnimplementedError();

  @override
  Future<void> close() async {}
}

void main() {
  test('forwards only changes of reachability', () {
    final monitor = _Monitor();
    final bootstrap = _Bootstrap();
    forwardReachability(monitor, bootstrap);

    monitor.report(ConnectivityStatus.checking);
    monitor.report(ConnectivityStatus.available);
    monitor.report(ConnectivityStatus.available);
    monitor.report(ConnectivityStatus.unavailable);
    monitor.report(ConnectivityStatus.available);

    expect(bootstrap.reports, [true, false, true]);
  });
}
