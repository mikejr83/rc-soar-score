import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsed_areas_key.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_area.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
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

const _other = CollapsibleArea(id: 'other_panel', defaultOpen: false);

void main() {
  test('registered area ids are unique', () {
    final ids = [for (final area in collapsibleAreas) area.id];
    expect(ids.toSet().length, ids.length);
    expect(collapsibleAreas, contains(matrixSummaryArea));
  });

  test('an area starts at its default', () async {
    final controller = CollapsibleAreasController(store: _store());
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.isOpen(matrixSummaryArea), isTrue);
    expect(controller.isOpen(_other), isFalse);
  });

  test('a layout fallback applies until the user chooses', () async {
    final controller = CollapsibleAreasController(store: _store());
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.isOpen(matrixSummaryArea, fallback: false), isFalse);
    await controller.setOpen(matrixSummaryArea, true);
    expect(controller.isOpen(matrixSummaryArea, fallback: false), isTrue);
  });

  test('a hidden area is remembered by a new controller', () async {
    final store = _store();
    final first = CollapsibleAreasController(store: store);
    addTearDown(first.dispose);
    expect(await first.setOpen(matrixSummaryArea, false), isTrue);

    final second = CollapsibleAreasController(store: store);
    addTearDown(second.dispose);
    await second.load();
    expect(second.isOpen(matrixSummaryArea), isFalse);
    expect(second.isOpen(_other), isFalse);
  });

  test('each account keeps its own choices', () async {
    final store = _store();
    final account = _SwitchableAccount('a');
    final controller = CollapsibleAreasController(
      store: store,
      account: account,
    );
    addTearDown(controller.dispose);

    await controller.setOpen(matrixSummaryArea, false);
    account.switchTo('b');
    await pumpEventQueue();
    expect(controller.isOpen(matrixSummaryArea), isTrue);

    account.switchTo('a');
    await pumpEventQueue();
    expect(controller.isOpen(matrixSummaryArea), isFalse);
  });

  test('reset restores every area to its default', () async {
    final store = _store();
    final controller = CollapsibleAreasController(store: store);
    addTearDown(controller.dispose);
    await controller.setOpen(matrixSummaryArea, false);
    await controller.setOpen(_other, true);

    expect(await controller.resetAll(), isTrue);

    expect(controller.isOpen(matrixSummaryArea), isTrue);
    expect(controller.isOpen(_other), isFalse);
    final fresh = CollapsibleAreasController(store: store);
    addTearDown(fresh.dispose);
    await fresh.load();
    expect(fresh.isOpen(matrixSummaryArea), isTrue);
  });

  test('an unreadable stored value reads as the defaults', () async {
    final store = _store();
    const raw = LocalUiKey<String>(
      name: 'area_choices',
      defaultValue: '',
      encode: _identity,
      decode: _asString,
    );
    await store.set(localUiAccountId, raw, 'not a map');
    final controller = CollapsibleAreasController(store: store);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isOpen(matrixSummaryArea), isTrue);
    expect(areaChoicesKey.defaultValue, isEmpty);
  });

  test('without a store a choice lasts in memory', () async {
    final controller = CollapsibleAreasController();
    addTearDown(controller.dispose);

    expect(await controller.setOpen(matrixSummaryArea, false), isTrue);
    expect(controller.isOpen(matrixSummaryArea), isFalse);
  });
}

Object? _identity(String value) => value;

String _asString(Object? data) => data as String;
