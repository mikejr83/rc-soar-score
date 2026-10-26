import 'package:flutter/widgets.dart';

import 'services/storage/storage_monitor.dart';

/// Exposes the app-wide [StorageMonitor] to the widget tree.
class StorageMonitorInherited extends InheritedWidget {
  const StorageMonitorInherited({
    super.key,
    required this.monitor,
    required super.child,
  });

  final StorageMonitor monitor;

  @override
  bool updateShouldNotify(StorageMonitorInherited oldWidget) =>
      monitor != oldWidget.monitor;
}

/// The app-wide [StorageMonitor], or `null` when none is provided (tests); the
/// status bar then shows no storage indicator.
StorageMonitor? storageMonitorOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<StorageMonitorInherited>()
    ?.monitor;
