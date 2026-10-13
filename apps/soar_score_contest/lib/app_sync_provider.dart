import 'package:flutter/widgets.dart';

import 'services/sync/app_sync.dart';
import 'services/sync/no_app_sync.dart';

/// Exposes the app's [AppSync] to the widget tree.
class AppSyncInherited extends InheritedWidget {
  const AppSyncInherited({super.key, required this.sync, required super.child});

  final AppSync sync;

  @override
  bool updateShouldNotify(AppSyncInherited oldWidget) => sync != oldWidget.sync;
}

/// The app's [AppSync]; [NoAppSync] when none is provided (tests, web).
AppSync appSyncOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<AppSyncInherited>()?.sync ??
    const NoAppSync();
