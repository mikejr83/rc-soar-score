import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/services/new_contest/draft_persistence.dart';

import '../../support/fake_draft_persistence.dart';

void main() {
  final now = DateTime(2026, 10, 7, 10, 42);

  test('every update is saved and time-stamped', () async {
    final persistence = FakeDraftPersistence();
    final store = ContestDraftStore(persistence: persistence, clock: () => now);
    addTearDown(store.dispose);

    await store.update(const ContestDraft(name: 'Cup'));

    expect(store.draft.name, 'Cup');
    expect(persistence.saved.single.name, 'Cup');
    expect(store.savedAt, now);
    expect(store.saveFailed, isFalse);
  });

  test('a failed save keeps the values and can be retried', () async {
    final persistence = FakeDraftPersistence()..failing = true;
    final store = ContestDraftStore(persistence: persistence, clock: () => now);
    addTearDown(store.dispose);

    await store.update(const ContestDraft(name: 'Cup'));
    expect(store.saveFailed, isTrue);
    expect(store.draft.name, 'Cup');
    expect(store.savedAt, isNull);

    persistence.failing = false;
    await store.retry();
    expect(store.saveFailed, isFalse);
    expect(store.savedAt, now);
  });

  test('dismissing a failure keeps the values; discard starts over', () async {
    final store = ContestDraftStore(
      persistence: FakeDraftPersistence()..failing = true,
    );
    addTearDown(store.dispose);

    await store.update(const ContestDraft(name: 'Cup'));
    store.dismissFailure();
    expect(store.saveFailed, isFalse);
    expect(store.draft.name, 'Cup');

    store.discard();
    expect(store.draft.name, isEmpty);
    expect(store.savedAt, isNull);
  });

  group('restoring a stored draft', () {
    final stored = FoundStoredDraft(const ContestDraft(name: 'Cup'), now);

    test('finds the account draft once, and continuing takes it up', () async {
      final persistence = FakeDraftPersistence()..stored['local'] = stored;
      final store = ContestDraftStore(persistence: persistence);
      addTearDown(store.dispose);

      expect(store.needsRestore, isTrue);
      final offer = await store.restore();
      expect(offer, same(stored));
      // Until the director decides, the same offer comes back.
      expect(store.needsRestore, isTrue);

      store.continueWith(stored);
      expect(store.needsRestore, isFalse);
      expect(await store.restore(), isNull);
      expect(store.draft.name, 'Cup');
      expect(store.savedAt, now);
      expect(store.hasDraft, isTrue);
    });

    test('starting fresh drops the draft and its stored copy', () async {
      final persistence = FakeDraftPersistence()..stored['local'] = stored;
      final store = ContestDraftStore(persistence: persistence);
      addTearDown(store.dispose);

      await store.restore();
      store.discard();
      await Future<void>.delayed(Duration.zero);

      expect(store.hasDraft, isFalse);
      expect(persistence.stored, isEmpty);
    });

    test('nothing stored, or no persistence, offers nothing', () async {
      final empty = ContestDraftStore(persistence: FakeDraftPersistence());
      addTearDown(empty.dispose);
      expect(await empty.restore(), isNull);

      final memoryOnly = ContestDraftStore();
      addTearDown(memoryOnly.dispose);
      expect(memoryOnly.needsRestore, isFalse);
      expect(await memoryOnly.restore(), isNull);
    });

    test('a draft in memory is not replaced by the stored one', () async {
      final persistence = FakeDraftPersistence();
      final store = ContestDraftStore(persistence: persistence);
      addTearDown(store.dispose);
      await store.update(const ContestDraft(name: 'Typed'));
      persistence.stored.remove('local');
      persistence.stored['other'] = stored;

      expect(await store.restore(), isNull);
      expect(store.draft.name, 'Typed');
    });

    test('another account never sees the first account draft', () async {
      final persistence = FakeDraftPersistence()..stored['local'] = stored;
      final store = ContestDraftStore(persistence: persistence);
      addTearDown(store.dispose);
      await store.restore();
      store.continueWith(stored);

      persistence.account = 'user:b';
      expect(store.needsRestore, isTrue);
      expect(await store.restore(), isNull);
      expect(store.hasDraft, isFalse);

      // The first account's stored draft is untouched, and later saves go to
      // the second account.
      await store.update(const ContestDraft(name: 'B'));
      expect(
        (persistence.stored['local']! as FoundStoredDraft).draft.name,
        'Cup',
      );
      expect(
        (persistence.stored['user:b']! as FoundStoredDraft).draft.name,
        'B',
      );
    });

    test(
      'leaving before choosing keeps the offer for the next visit',
      () async {
        final persistence = FakeDraftPersistence()..stored['local'] = stored;
        final store = ContestDraftStore(persistence: persistence);
        addTearDown(store.dispose);

        expect(await store.restore(), same(stored));
        // The wizard closed without a choice; opening it again asks again.
        expect(store.needsRestore, isTrue);
        expect(await store.restore(), same(stored));
        expect(persistence.stored, isNotEmpty);

        store.continueWith(stored);
        expect(store.needsRestore, isFalse);
      },
    );

    test('a failed delete is reported and retried', () async {
      final persistence = FakeDraftPersistence()..stored['local'] = stored;
      final store = ContestDraftStore(persistence: persistence);
      addTearDown(store.dispose);
      await store.restore();

      persistence.failing = true;
      await store.discard();
      expect(store.hasDraft, isFalse);
      expect(store.saveFailed, isTrue);
      expect(persistence.stored, isNotEmpty);

      persistence.failing = false;
      await store.retry();
      expect(store.saveFailed, isFalse);
      expect(persistence.stored, isEmpty);
    });
  });
}
