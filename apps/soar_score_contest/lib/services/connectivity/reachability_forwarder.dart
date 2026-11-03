import 'package:soar_score_core/soar_score_core.dart';

import '../../platform/app_bootstrap.dart';
import 'app_connectivity.dart';

/// Tells [bootstrap] each time the remote API becomes reachable or stops
/// being so, as [connectivity] sees it.
///
/// Only a change is forwarded, so the native sync is not restarted by every
/// probe. The monitor is disposed with the app, which ends the listening.
///
/// Also the other way: what a sync finds out ([AppBootstrap.syncReachability])
/// is told to [connectivity], so the health checks stop while syncs succeed
/// and start when one finds no connection.
void forwardReachability(AppConnectivity connectivity, AppBootstrap bootstrap) {
  bootstrap.syncReachability.listen((reachable) {
    if (reachable) {
      connectivity.reportReachable();
    } else {
      connectivity.reportUnreachable();
    }
  });
  var wasReachable = false;
  connectivity.addListener(() {
    final reachable = connectivity.apiStatus == ConnectivityStatus.available;
    if (reachable == wasReachable) return;
    wasReachable = reachable;
    bootstrap.remoteReachabilityChanged(reachable: reachable);
  });
}
