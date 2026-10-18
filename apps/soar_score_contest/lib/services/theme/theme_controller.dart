import 'package:flutter/material.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../ui_account/ui_account.dart';
import 'theme_mode_key.dart';

/// The app's theme mode, remembered per account in the [LocalUiStore].
///
/// Starts as [ThemeMode.system]. [load] reads the stored choice (await it
/// before the first frame to avoid showing the wrong theme); the choice is
/// read again whenever the [UiAccount] changes. Without a store the mode lives
/// in memory only.
class ThemeController extends ChangeNotifier {
  ThemeController({this._store, UiAccount? account})
    : _account = account ?? const FixedUiAccount() {
    _account.addListener(_accountChanged);
  }

  final LocalUiStore? _store;
  final UiAccount _account;
  ThemeMode _mode = ThemeMode.system;
  int _generation = 0;
  bool _disposed = false;

  ThemeMode get mode => _mode;

  /// Whether a chosen mode is remembered across restarts.
  bool get persists => _store != null;

  /// Reads the stored mode for the current account.
  Future<void> load() async {
    final store = _store;
    if (store == null) return;
    final generation = ++_generation;
    final mode = await store.get(_account.id, themeModeKey);
    if (_disposed || generation != _generation || mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Applies [mode] now and stores it for the current account.
  Future<void> setMode(ThemeMode mode) async {
    _generation++;
    if (mode != _mode) {
      _mode = mode;
      notifyListeners();
    }
    await _store?.set(_account.id, themeModeKey, mode);
  }

  void _accountChanged() => load();

  @override
  void dispose() {
    _disposed = true;
    _account.removeListener(_accountChanged);
    super.dispose();
  }
}
