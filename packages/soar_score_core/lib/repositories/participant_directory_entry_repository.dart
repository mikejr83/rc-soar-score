import '../models/accounts/participant_directory_entry.dart';
import '../models/id.dart';

/// Abstract persistence contract for [ParticipantDirectoryEntry]s, the
/// details a person offers to directors.
///
/// Backend only: writes record no `MutationRecord`.
abstract interface class ParticipantDirectoryEntryRepository {
  Future<ParticipantDirectoryEntry?> findById(Id id);

  /// The entry of [accountId], or `null`. An account has at most one.
  Future<ParticipantDirectoryEntry?> findForAccount(Id accountId);

  /// Every entry its owner chose to list, in id order.
  Future<List<ParticipantDirectoryEntry>> listListed();

  /// Stores [entry], replacing the stored one with the same id. The database
  /// refuses a second entry for an account.
  Future<ParticipantDirectoryEntry> save(ParticipantDirectoryEntry entry);

  /// Removes the entry with [id]; returns whether one existed.
  Future<bool> remove(Id id);
}
