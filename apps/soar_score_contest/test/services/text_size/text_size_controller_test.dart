import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/text_size/preferred_text_scaler.dart';
import 'package:soar_score_contest/services/text_size/text_size.dart';
import 'package:soar_score_contest/services/text_size/text_size_controller.dart';
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
  test('defaults to the standard size', () async {
    final controller = TextSizeController(store: _store());
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.size, TextSize.standard);
  });

  test('a chosen size is stored and read back by a new controller', () async {
    final store = _store();
    final first = TextSizeController(store: store);
    addTearDown(first.dispose);

    await first.setSize(TextSize.extraLarge);
    expect(first.size, TextSize.extraLarge);

    final second = TextSizeController(store: store);
    addTearDown(second.dispose);
    await second.load();
    expect(second.size, TextSize.extraLarge);
  });

  test('each account keeps its own size', () async {
    final store = _store();
    final account = _SwitchableAccount('a');
    final controller = TextSizeController(store: store, account: account);
    addTearDown(controller.dispose);

    await controller.setSize(TextSize.large);
    account.switchTo('b');
    await pumpEventQueue();
    expect(controller.size, TextSize.standard);

    await controller.setSize(TextSize.extraLarge);
    account.switchTo('a');
    await pumpEventQueue();
    expect(controller.size, TextSize.large);
  });

  test('an unreadable stored value reads as the standard size', () async {
    final store = _store();
    const raw = LocalUiKey<String>(
      name: 'text_size',
      defaultValue: '',
      encode: _identity,
      decode: _asString,
    );
    await store.set(localUiAccountId, raw, 'huge');
    final controller = TextSizeController(store: store);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.size, TextSize.standard);
    expect(textSizeKey.defaultValue, TextSize.standard);
  });

  test('without a store the size lives in memory', () async {
    final controller = TextSizeController();
    addTearDown(controller.dispose);

    expect(await controller.setSize(TextSize.large), isTrue);

    expect(controller.size, TextSize.large);
    expect(controller.persists, isFalse);
  });

  group('PreferredTextScaler', () {
    test('standard leaves the device scale alone', () {
      final scaler = PreferredTextScaler.of(
        const TextScaler.linear(1.1),
        TextSize.standard,
      );

      expect(scaler.scale(10), closeTo(11, 1e-9));
    });

    test('multiplies the device scale by the chosen factor', () {
      final scaler = PreferredTextScaler.of(
        const TextScaler.linear(1.2),
        TextSize.large,
      );

      expect(scaler.scale(10), closeTo(15, 1e-9));
    });

    test('never magnifies beyond the maximum', () {
      final scaler = PreferredTextScaler.of(
        const TextScaler.linear(3),
        TextSize.extraLarge,
      );

      expect(scaler.scale(10), maxCombinedTextScale * 10);
    });

    test('equal scalers compare equal', () {
      expect(
        PreferredTextScaler.of(TextScaler.noScaling, TextSize.large),
        PreferredTextScaler.of(TextScaler.noScaling, TextSize.large),
      );
    });
  });
}

Object? _identity(String value) => value;
String _asString(Object? data) => data as String;
