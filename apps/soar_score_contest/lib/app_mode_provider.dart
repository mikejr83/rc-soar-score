// ignore_for_file: prefer_initializing_formals

import 'package:flutter/widgets.dart';

/// Tracks and manages application mode states such as offline mode.
class AppModeNotifier extends ChangeNotifier {
  AppModeNotifier({bool isOfflineMode = false})
    : _isOfflineMode = isOfflineMode;

  bool _isOfflineMode;

  /// Whether the app is currently running in offline mode.
  bool get isOfflineMode => _isOfflineMode;

  /// Updates the offline mode status and notifies listeners if changed.
  void setOfflineMode(bool value) {
    if (_isOfflineMode == value) return;
    _isOfflineMode = value;
    notifyListeners();
  }

  /// Transitions the app into offline mode (e.g. user selected "Continue offline").
  void enterOfflineMode() => setOfflineMode(true);

  /// Exits offline mode (e.g. when signing in or reconnecting to remote server).
  void exitOfflineMode() => setOfflineMode(false);
}

/// Exposes [AppModeNotifier] to the widget tree and rebuilds dependent widgets
/// when notified.
class AppModeInherited extends InheritedNotifier<AppModeNotifier> {
  const AppModeInherited({
    super.key,
    required AppModeNotifier super.notifier,
    required super.child,
  });
}

/// Retrieves the nearest [AppModeNotifier] in the widget tree, or `null` if none exists.
AppModeNotifier? appModeOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<AppModeInherited>()?.notifier;

/// Helper to check whether the app is currently in offline mode.
bool isOfflineModeOf(BuildContext context) =>
    appModeOf(context)?.isOfflineMode ?? false;
