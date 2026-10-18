import 'contest_draft.dart';

/// What the storage holds for an account's New Contest draft.
sealed class StoredDraft {
  const StoredDraft();
}

/// Nothing is stored.
class NoStoredDraft extends StoredDraft {
  const NoStoredDraft();
}

/// A draft saved at [savedAt] that can be loaded.
class FoundStoredDraft extends StoredDraft {
  const FoundStoredDraft(this.draft, this.savedAt);

  final ContestDraft draft;
  final DateTime savedAt;
}

/// A draft saved at [savedAt] by another version of the app, or damaged. It
/// can only be discarded.
class UnreadableStoredDraft extends StoredDraft {
  const UnreadableStoredDraft(this.savedAt);

  final DateTime? savedAt;
}

/// Keeps one New Contest draft per account across restarts.
///
/// Every call names the account, so a draft always goes back to the account
/// that made it. Calls never throw except [save], which throws when the draft
/// could not be stored so the store can report a failed save.
abstract class DraftPersistence {
  /// The account whose draft is current now.
  String get accountId;

  Future<StoredDraft> load(String accountId);

  /// Stores [draft]; a blank draft clears the stored one instead.
  Future<void> save(String accountId, ContestDraft draft, DateTime savedAt);

  Future<void> clear(String accountId);
}
