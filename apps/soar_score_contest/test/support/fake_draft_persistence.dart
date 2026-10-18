import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draft_persistence.dart';

/// Keeps drafts in memory, one per account, and can be told to fail saves.
class FakeDraftPersistence implements DraftPersistence {
  FakeDraftPersistence({this.account = 'local'});

  String account;

  /// Whether saves throw.
  bool failing = false;

  final Map<String, StoredDraft> stored = {};
  final List<ContestDraft> saved = [];

  @override
  String get accountId => account;

  @override
  Future<StoredDraft> load(String accountId) async =>
      stored[accountId] ?? const NoStoredDraft();

  @override
  Future<void> save(
    String accountId,
    ContestDraft draft,
    DateTime savedAt,
  ) async {
    if (failing) {
      throw StateError('storage full');
    }
    saved.add(draft);
    if (draft.isBlank) {
      stored.remove(accountId);
    } else {
      stored[accountId] = FoundStoredDraft(draft, savedAt);
    }
  }

  @override
  Future<void> clear(String accountId) async => stored.remove(accountId);
}
