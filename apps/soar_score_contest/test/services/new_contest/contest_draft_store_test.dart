import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';

void main() {
  final now = DateTime(2026, 10, 7, 10, 42);

  test('every update is saved and time-stamped', () async {
    final written = <ContestDraft>[];
    final store = ContestDraftStore(
      writer: (draft) async => written.add(draft),
      clock: () => now,
    );
    addTearDown(store.dispose);

    await store.update(const ContestDraft(name: 'Cup'));

    expect(store.draft.name, 'Cup');
    expect(written.single.name, 'Cup');
    expect(store.savedAt, now);
    expect(store.saveFailed, isFalse);
  });

  test('a failed save keeps the values and can be retried', () async {
    var fail = true;
    final store = ContestDraftStore(
      writer: (_) async {
        if (fail) {
          throw StateError('storage full');
        }
      },
      clock: () => now,
    );
    addTearDown(store.dispose);

    await store.update(const ContestDraft(name: 'Cup'));
    expect(store.saveFailed, isTrue);
    expect(store.draft.name, 'Cup');
    expect(store.savedAt, isNull);

    fail = false;
    await store.retry();
    expect(store.saveFailed, isFalse);
    expect(store.savedAt, now);
  });

  test('dismissing a failure keeps the values; discard starts over', () async {
    final store = ContestDraftStore(writer: (_) async => throw StateError(''));
    addTearDown(store.dispose);

    await store.update(const ContestDraft(name: 'Cup'));
    store.dismissFailure();
    expect(store.saveFailed, isFalse);
    expect(store.draft.name, 'Cup');

    store.discard();
    expect(store.draft.name, isEmpty);
    expect(store.savedAt, isNull);
  });
}
