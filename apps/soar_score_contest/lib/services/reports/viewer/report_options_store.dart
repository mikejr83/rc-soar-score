import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../report_kind.dart';
import 'report_options_key.dart';

/// The report viewer's options, remembered per account in the [LocalUiStore]
/// and shared by every contest: one key per report kind.
///
/// [load] reads one kind's entry; [set] writes that key alone, so two reports
/// (or two tabs) can never drop each other's options. [reset] removes one
/// kind's key, or every report kind's key when given none. Without a store
/// the options live in memory only, like the theme and the hidden panels.
///
/// A reset takes effect the next time a report opens. Another tab that has a
/// report open keeps its in-memory copy until it reloads: the UI store
/// streams changes to listeners in the same instance only, not to other
/// tabs, so a freshly opened report is the reliable point at which the reset
/// shows.
class ReportOptionsStore {
  ReportOptionsStore(this.store, this.accountId);

  /// `null` when no store is available: the options are not kept.
  final LocalUiStore? store;

  /// The account whose options this store reads and writes.
  final String accountId;

  /// Whether the choices are remembered across restarts.
  bool get hasStore => store != null;

  /// The options stored for [kindKey]; empty when there are none.
  Future<Map<String, String>> load(String kindKey) =>
      store?.get(accountId, reportOptionsKeyFor(kindKey)) ??
      Future.value(const {});

  /// Remembers [options] for [kindKey] and returns whether it was saved.
  /// Writes only that kind's key.
  Future<bool> set(String kindKey, Map<String, String> options) {
    final store = this.store;
    if (store == null) {
      return Future.value(true);
    }
    return store.set(
      accountId,
      reportOptionsKeyFor(kindKey),
      Map<String, String>.unmodifiable(options),
    );
  }

  /// Forgets the options of [kindKey]; `null` forgets every report's.
  /// Returns whether it was saved.
  Future<bool> reset([String? kindKey]) async {
    final store = this.store;
    if (store == null) {
      return true;
    }
    if (kindKey != null) {
      return store.remove(accountId, reportOptionsKeyFor(kindKey));
    }
    var saved = true;
    for (final kind in ReportKind.values) {
      saved =
          await store.remove(accountId, reportOptionsKeyFor(kind.key)) && saved;
    }
    return saved;
  }
}
