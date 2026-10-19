import 'package:flutter/foundation.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../ui_account/ui_account.dart';
import 'collapsed_areas_key.dart';
import 'collapsible_area.dart';

/// Which collapsible areas the user has hidden or opened, remembered per
/// account in the [LocalUiStore] and shared by all contests.
///
/// [load] reads the stored choices (await it before the first frame so panels
/// do not flip after appearing); they are read again whenever the [UiAccount]
/// changes. Without a store the choices live in memory only.
class CollapsibleAreasController extends ChangeNotifier {
  CollapsibleAreasController({this._store, UiAccount? account})
    : _account = account ?? const FixedUiAccount() {
    _account.addListener(_accountChanged);
  }

  final LocalUiStore? _store;
  final UiAccount _account;
  Map<String, bool> _choices = const {};
  int _generation = 0;
  Future<void>? _loading;
  bool _disposed = false;

  /// Whether [area] is open: the user's choice, else [fallback] when a layout
  /// has its own starting state, else the area's default.
  bool isOpen(CollapsibleArea area, {bool? fallback}) =>
      _choices[area.id] ?? fallback ?? area.defaultOpen;

  /// Reads the stored choices for the current account.
  Future<void> load() {
    final store = _store;
    if (store == null) return Future.value();
    final generation = ++_generation;
    return _loading = _read(store, generation);
  }

  Future<void> _read(LocalUiStore store, int generation) async {
    final choices = await store.get(_account.id, areaChoicesKey);
    if (_disposed || generation != _generation) return;
    _choices = choices;
    _loading = null;
    notifyListeners();
  }

  /// Applies the choice now and stores it. Returns whether it was saved:
  /// `false` means it holds until the app closes or the account changes.
  /// While an account's choices are still loading, waits for them so the
  /// write builds on that account's values.
  Future<bool> setOpen(CollapsibleArea area, bool open) async {
    while (_loading != null) {
      await _loading;
      if (_disposed) return false;
    }
    return _save({..._choices, area.id: open});
  }

  /// Forgets every choice, so each area is back to its default.
  Future<bool> resetAll() => _save(const {});

  Future<bool> _save(Map<String, bool> choices) async {
    _generation++;
    _loading = null;
    _choices = choices;
    notifyListeners();
    final store = _store;
    if (store == null) return true;
    return choices.isEmpty
        ? store.remove(_account.id, areaChoicesKey)
        : store.set(_account.id, areaChoicesKey, choices);
  }

  /// The previous account's choices must not show for, or merge into writes
  /// of, the new account, so drop them before its own are read.
  void _accountChanged() {
    if (_choices.isNotEmpty) {
      _choices = const {};
      notifyListeners();
    }
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    _account.removeListener(_accountChanged);
    super.dispose();
  }
}
