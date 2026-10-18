import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/theme/theme_controller.dart';
import 'package:soar_score_contest/services/theme/theme_mode_key.dart';
import 'package:soar_score_contest/services/ui_account/ui_account.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

class _SwitchableAccount extends ChangeNotifier implements UiAccount {
  _SwitchableAccount(this._id);

  String _id;

  @override
  String get id => _id;

  void switchTo(String id) {
    _id = id;
    notifyListeners();
  }
}

LocalUiStore _store() => BackendLocalUiStore(MemoryLocalUiBackend());

void main() {
  test('defaults to the system theme', () async {
    final controller = ThemeController(store: _store());
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.mode, ThemeMode.system);
  });

  test('a chosen mode is stored and read back by a new controller', () async {
    final store = _store();
    final first = ThemeController(store: store);
    addTearDown(first.dispose);

    await first.setMode(ThemeMode.dark);
    expect(first.mode, ThemeMode.dark);

    final second = ThemeController(store: store);
    addTearDown(second.dispose);
    await second.load();
    expect(second.mode, ThemeMode.dark);
  });

  test('each account keeps its own mode', () async {
    final store = _store();
    final account = _SwitchableAccount('a');
    final controller = ThemeController(store: store, account: account);
    addTearDown(controller.dispose);

    await controller.setMode(ThemeMode.light);
    account.switchTo('b');
    await pumpEventQueue();
    expect(controller.mode, ThemeMode.system);

    await controller.setMode(ThemeMode.dark);
    account.switchTo('a');
    await pumpEventQueue();
    expect(controller.mode, ThemeMode.light);
  });

  test('an unreadable stored value reads as the system theme', () async {
    final store = _store();
    const raw = LocalUiKey<String>(
      name: 'theme_mode',
      defaultValue: '',
      encode: _identity,
      decode: _asString,
    );
    await store.set(localUiAccountId, raw, 'sepia');
    final controller = ThemeController(store: store);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.mode, ThemeMode.system);
    expect(themeModeKey.defaultValue, ThemeMode.system);
  });

  test('without a store the mode lives in memory', () async {
    final controller = ThemeController();
    addTearDown(controller.dispose);

    await controller.setMode(ThemeMode.light);

    expect(controller.mode, ThemeMode.light);
    expect(controller.persists, isFalse);
  });
}

Object? _identity(String value) => value;
String _asString(Object? data) => data as String;
