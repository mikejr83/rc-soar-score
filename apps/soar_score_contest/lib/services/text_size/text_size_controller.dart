import 'package:flutter/foundation.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../ui_account/ui_account.dart';
import 'text_size.dart';

/// The app's text size, remembered per account in the [LocalUiStore].
///
/// Starts as [TextSize.standard]. [load] reads the stored choice (await it
/// before the first frame to avoid a size jump); the choice is read again
/// whenever the [UiAccount] changes. Without a store the size lives in memory
/// only.
class TextSizeController extends ChangeNotifier {
  TextSizeController({this._store, UiAccount? account})
    : _account = account ?? const FixedUiAccount() {
    _account.addListener(_accountChanged);
  }

  final LocalUiStore? _store;
  final UiAccount _account;
  TextSize _size = TextSize.standard;
  int _generation = 0;
  bool _disposed = false;

  TextSize get size => _size;

  /// Whether a chosen size is remembered across restarts.
  bool get persists => _store != null;

  /// Reads the stored size for the current account.
  Future<void> load() async {
    final store = _store;
    if (store == null) return;
    final generation = ++_generation;
    final size = await store.get(_account.id, textSizeKey);
    if (_disposed || generation != _generation || size == _size) return;
    _size = size;
    notifyListeners();
  }

  /// Applies [size] now and stores it for the current account. Returns
  /// whether it was saved: `false` means it applies until the app closes or
  /// the account changes. Without a store there is nothing to save, so that
  /// counts as saved.
  Future<bool> setSize(TextSize size) async {
    _generation++;
    if (size != _size) {
      _size = size;
      notifyListeners();
    }
    return await _store?.set(_account.id, textSizeKey, size) ?? true;
  }

  void _accountChanged() => load();

  @override
  void dispose() {
    _disposed = true;
    _account.removeListener(_accountChanged);
    super.dispose();
  }
}
