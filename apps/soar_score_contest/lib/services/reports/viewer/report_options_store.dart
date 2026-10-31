import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import 'report_options_key.dart';

/// The report viewer's options, remembered per account in the [LocalUiStore]
/// and shared by every contest: one entry per report kind.
///
/// [load] reads the whole account map (the viewer applies its kind's entry);
/// [set] writes the whole map with one kind's entry replaced, so a reset of
/// one report needs no read-modify-write race. Without a store the options
/// live in memory only, like the theme and the hidden panels.
class ReportOptionsStore {
  ReportOptionsStore(this.store, this.accountId);

  /// `null` when no store is available: the options are not kept.
  final LocalUiStore? store;

  /// The account whose options this store reads and writes.
  final String accountId;

  /// Whether the choices are remembered across restarts.
  bool get hasStore => store != null;

  /// The options stored for the account; empty when there are none.
  Future<Map<String, Map<String, String>>> load() =>
      store?.get(accountId, reportOptionsKey) ?? Future.value(const {});

  /// Remembers [options] for [kindKey] and returns whether it was saved.
  Future<bool> set(String kindKey, Map<String, String> options) async {
    final store = this.store;
    if (store == null) {
      return true;
    }
    final map = await load();
    return store.set(
      accountId,
      reportOptionsKey,
      {...map, kindKey: Map<String, String>.unmodifiable(options)},
    );
  }

  /// Forgets the options of [kindKey]; `null` forgets every report's.
  /// Returns whether it was saved.
  Future<bool> reset([String? kindKey]) async {
    final store = this.store;
    if (store == null) {
      return true;
    }
    if (kindKey == null) {
      return store.remove(accountId, reportOptionsKey);
    }
    final map = await load();
    if (!map.containsKey(kindKey)) {
      return true;
    }
    final rest = Map<String, Map<String, String>>.of(map)
      ..remove(kindKey);
    return rest.isEmpty
        ? store.remove(accountId, reportOptionsKey)
        : store.set(accountId, reportOptionsKey, rest);
  }
}
