import 'package:flutter/widgets.dart';

import 'services/connectivity/app_connectivity.dart';

/// Exposes the app-wide connectivity monitor to the widget tree.
///
/// Mirrors `ApiClientInherited`: the monitor is created once in `main()`
/// when a bootstrap is present and handed in by `SoarScoreContestApp`;
/// widgets reach it through [appConnectivityOf]. The tree renders without
/// the provider (and therefore without the connectivity indicators) when
/// no bootstrap exists, e.g. in tests that pump the app bare.
class AppConnectivityInherited extends InheritedWidget {
  const AppConnectivityInherited({
    super.key,
    required this.monitor,
    required super.child,
  });

  final AppConnectivity monitor;

  @override
  bool updateShouldNotify(AppConnectivityInherited oldWidget) =>
      monitor != oldWidget.monitor;
}

/// The app-wide [AppConnectivity] monitor, or `null` when no bootstrap
/// client is provided (the landing page then renders exactly as pre-feature).
AppConnectivity? appConnectivityOf(BuildContext context) =>
    context
        .dependOnInheritedWidgetOfExactType<AppConnectivityInherited>()
        ?.monitor;
