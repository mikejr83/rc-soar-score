import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_codec.dart';
import 'package:soar_score_contest/services/new_contest/draft_persistence.dart';
import 'package:soar_score_contest/services/new_contest/local_ui_draft_persistence.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../../support/rich_contest_draft.dart';

void main() {
  late LocalUiStore store;
  late MemoryLocalUiBackend backend;
  late LocalUiDraftPersistence persistence;
  final savedAt = DateTime.utc(2026, 10, 18, 12, 30);

  setUp(() {
    backend = MemoryLocalUiBackend();
    store = BackendLocalUiStore(backend);
    persistence = LocalUiDraftPersistence(store, account: () => 'a');
  });
  tearDown(() => store.close());

  /// Writes a raw envelope the way an older or newer app version would.
  Future<void> putRaw(String account, Object? value) async {
    final key = LocalUiKey<Object?>(
      name: 'new_contest_draft',
      defaultValue: null,
      encode: (v) => v,
      decode: (data) => data,
    );
    await store.set(account, key, value);
  }

  test('nothing stored loads as nothing', () async {
    expect(await persistence.load('a'), isA<NoStoredDraft>());
  });

  test('a saved draft loads with the time it was saved', () async {
    await persistence.save('a', richDraft(), savedAt);

    final loaded = await persistence.load('a');

    expect(loaded, isA<FoundStoredDraft>());
    loaded as FoundStoredDraft;
    expect(loaded.draft.name, 'Gator Cup F5J');
    expect(loaded.savedAt, savedAt);
  });

  test('saving a blank draft clears the stored one', () async {
    await persistence.save('a', richDraft(), savedAt);
    await persistence.save('a', const ContestDraft(), savedAt);

    expect(await persistence.load('a'), isA<NoStoredDraft>());
  });

  test('clear forgets the draft', () async {
    await persistence.save('a', richDraft(), savedAt);
    await persistence.clear('a');

    expect(await persistence.load('a'), isA<NoStoredDraft>());
  });

  test('another account does not see the draft', () async {
    await persistence.save('a', richDraft(), savedAt);

    expect(await persistence.load('b'), isA<NoStoredDraft>());
  });

  test('a draft of another version is offered for discard only', () async {
    await putRaw('a', {
      'version': ContestDraftCodec.version + 1,
      'saved_at': savedAt.toIso8601String(),
      'data': {'anything': 1},
    });

    final loaded = await persistence.load('a');

    expect(loaded, isA<UnreadableStoredDraft>());
    expect((loaded as UnreadableStoredDraft).savedAt, savedAt);
  });

  test('a damaged draft is offered for discard', () async {
    await putRaw('a', {
      'version': ContestDraftCodec.version,
      'saved_at': savedAt.toIso8601String(),
      'data': {'name': 5},
    });

    expect(await persistence.load('a'), isA<UnreadableStoredDraft>());
  });

  test('a stored blank draft is no draft', () async {
    await putRaw('a', {
      'version': ContestDraftCodec.version,
      'saved_at': savedAt.toIso8601String(),
      'data': ContestDraftCodec.encode(const ContestDraft()),
    });

    expect(await persistence.load('a'), isA<NoStoredDraft>());
  });

  test(
    'malformed envelope fields are an unreadable draft, not no draft',
    () async {
      for (final raw in <Object?>[
        {'version': ContestDraftCodec.version, 'data': {}},
        {'version': ContestDraftCodec.version, 'saved_at': 'yesterday'},
        {'version': 'one', 'saved_at': savedAt.toIso8601String()},
        'not an envelope',
        42,
      ]) {
        await putRaw('a', raw);

        expect(
          await persistence.load('a'),
          isA<UnreadableStoredDraft>(),
          reason: '$raw',
        );
      }
    },
  );

  test('text that is not JSON is an unreadable draft', () async {
    await backend.write(
      BackendLocalUiStore.storageKey('a', 'new_contest_draft'),
      '{{',
    );

    expect(await persistence.load('a'), isA<UnreadableStoredDraft>());
  });

  test('clear and save report a storage that refuses', () async {
    final refusing = LocalUiDraftPersistence(
      _RefusingStore(),
      account: () => 'a',
    );

    await expectLater(refusing.clear('a'), throwsStateError);
    await expectLater(
      refusing.save('a', richDraft(), savedAt),
      throwsStateError,
    );
  });
}

/// A store whose writes all fail.
class _RefusingStore implements LocalUiStore {
  @override
  Future<T> get<T>(String accountId, LocalUiKey<T> key) async =>
      key.defaultValue;

  @override
  Future<bool> set<T>(String accountId, LocalUiKey<T> key, T value) async =>
      false;

  @override
  Future<bool> remove<T>(String accountId, LocalUiKey<T> key) async => false;

  @override
  Stream<T> watch<T>(String accountId, LocalUiKey<T> key) =>
      const Stream.empty();

  @override
  Future<void> close() async {}
}
