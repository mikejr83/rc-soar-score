import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/report_options_key.dart';
import 'package:soar_score_contest/services/reports/viewer/report_options_store.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

void main() {
  const account = 'acct-1';

  test('decode keeps only string -> string entries', () {
    final key = reportOptionsKeyFor('matrix');
    expect(key.decode({'cmp': '1', 'paper': 'a4', 'bad': 7}), {
      'cmp': '1',
      'paper': 'a4',
    });
    expect(key.decode('not a map'), <String, String>{});
    expect(key.decode(null), <String, String>{});
  });

  test('a set writes one kind only, leaving another kind untouched', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final options = ReportOptionsStore(store, account);
    expect(await options.load('matrix'), isEmpty);

    await options.set('matrix', {'cmp': '1', 'paper': 'a4'});
    await options.set('cards', {'up': 'two'});

    final fresh = ReportOptionsStore(store, account);
    expect(await fresh.load('matrix'), {'cmp': '1', 'paper': 'a4'});
    expect(await fresh.load('cards'), {'up': 'two'});

    // A set replaces one kind's entry without touching the other's, so a
    // write from one report never drops another's options.
    await fresh.set('matrix', {'cmp': '0'});
    expect(await fresh.load('matrix'), {'cmp': '0'});
    expect(await fresh.load('cards'), {'up': 'two'});
  });

  test('reset removes one kind; a whole reset removes every kind', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final options = ReportOptionsStore(store, account);
    await options.set('matrix', {'cmp': '1'});
    await options.set('cards', {'up': 'two'});

    await options.reset('matrix');
    expect(await options.load('matrix'), isEmpty);
    expect(await options.load('cards'), {'up': 'two'});

    await options.reset();
    expect(await options.load('matrix'), isEmpty);
    expect(await options.load('cards'), isEmpty);
    // Removing again is a no-op that still reports saved.
    expect(await options.reset(), isTrue);
  });

  test('reset of one kind removes only its own key', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final options = ReportOptionsStore(store, account);
    await options.set('matrix', {'cmp': '1'});

    expect(await options.reset('matrix'), isTrue);
    expect(
      await store.get(account, reportOptionsKeyFor('matrix')),
      <String, String>{},
    );
  });

  test('without a store the options live in memory only', () async {
    final options = ReportOptionsStore(null, account);
    expect(options.hasStore, isFalse);
    expect(await options.load('matrix'), isEmpty);
    expect(await options.set('matrix', {'cmp': '1'}), isTrue);
    expect(await options.reset('matrix'), isTrue);
    expect(await options.reset(), isTrue);
  });

  test('two accounts do not share options', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final other = ReportOptionsStore(store, 'acct-2');
    expect(await other.set('matrix', {'cmp': '1'}), isTrue);

    final own = ReportOptionsStore(store, account);
    expect(await own.load('matrix'), isEmpty);
  });
}
