import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/report_options_key.dart';
import 'package:soar_score_contest/services/reports/viewer/report_options_store.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

void main() {
  const account = 'acct-1';

  test('decode keeps only string -> (string -> string) entries', () {
    final key = reportOptionsKey;
    expect(
      key.decode({
        'matrix': {'cmp': '1', 'paper': 'a4', 'bad': 7},
        'cards': {'up': 'two'},
        'noise': 'not a map',
        'empty': {},
      }),
      {
        'matrix': {'cmp': '1', 'paper': 'a4'},
        'cards': {'up': 'two'},
      },
    );
    expect(key.decode('not a map'), <String, Map<String, String>>{});
    expect(key.decode(null), <String, Map<String, String>>{});
  });

  test('a stored map round-trips through the backend store', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final options = ReportOptionsStore(store, account);
    expect(await options.load(), isEmpty);

    await options.set('matrix', {'cmp': '1', 'paper': 'a4'});
    await options.set('cards', {'up': 'two'});

    final fresh = ReportOptionsStore(store, account);
    expect(await fresh.load(), {
      'matrix': {'cmp': '1', 'paper': 'a4'},
      'cards': {'up': 'two'},
    });

    // A set replaces one kind's entry without touching the other's.
    await fresh.set('matrix', {'cmp': '0'});
    expect(await fresh.load(), {
      'matrix': {'cmp': '0'},
      'cards': {'up': 'two'},
    });
  });

  test('reset removes one kind; a whole reset removes the key', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final options = ReportOptionsStore(store, account);
    await options.set('matrix', {'cmp': '1'});
    await options.set('cards', {'up': 'two'});

    await options.reset('matrix');
    expect(await options.load(), {'cards': {'up': 'two'}});

    await options.reset();
    expect(await options.load(), isEmpty);
    // Reading a removed key gives the default, and removing again is a no-op.
    expect(await options.reset(), isTrue);
  });

  test('reset of one kind removes the key when it was the only one', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final options = ReportOptionsStore(store, account);
    await options.set('matrix', {'cmp': '1'});

    expect(await options.reset('matrix'), isTrue);
    expect(
      await store.get(account, reportOptionsKey),
      <String, Map<String, String>>{},
    );
  });

  test('without a store the options live in memory only', () async {
    final options = ReportOptionsStore(null, account);
    expect(options.hasStore, isFalse);
    expect(await options.load(), isEmpty);
    expect(await options.set('matrix', {'cmp': '1'}), isTrue);
    expect(await options.reset('matrix'), isTrue);
    expect(await options.reset(), isTrue);
  });

  test('two accounts do not share options', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final other = ReportOptionsStore(store, 'acct-2');
    expect(await other.set('matrix', {'cmp': '1'}), isTrue);

    final own = ReportOptionsStore(store, account);
    expect(await own.load(), isEmpty);
  });
}
