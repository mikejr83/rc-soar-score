import 'package:soar_score_core/soar_score_core.dart';

import '../../platform/app_bootstrap.dart';
import 'app_connectivity.dart';

/// Tells [bootstrap] each time the remote API becomes reachable or stops
/// being so, as [connectivity] sees it.
///
/// Only a change is forwarded, so the native sync is not restarted by every
/// probe. The monitor is disposed with the app, which ends the listening.
void forwardReachability(AppConnectivity connectivity, AppBootstrap bootstrap) {
  var wasReachable = false;
  connectivity.addListener(() {
    final reachable = connectivity.apiStatus == ConnectivityStatus.available;
    if (reachable == wasReachable) return;
    wasReachable = reachable;
    bootstrap.remoteReachabilityChanged(reachable: reachable);
  });
}
