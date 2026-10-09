import '../models/id.dart';
import '../models/sync/sync_cursor.dart';

/// Abstract persistence contract for [SyncCursor]s, how far each installation
/// has synchronized a contest or an owner's system data.
///
/// Backend only: writes record no `MutationRecord`.
abstract interface class SyncCursorRepository {
  Future<SyncCursor?> findById(Id id);

  /// The cursor of [installationId] for [contestId], or `null`.
  Future<SyncCursor?> findForContest({
    required Id installationId,
    required Id contestId,
  });

  /// The cursor of [installationId] for the system data of [ownerAccountId],
  /// or `null`.
  Future<SyncCursor?> findForOwner({
    required Id installationId,
    required Id ownerAccountId,
  });

  /// Every cursor of [installationId], oldest first by id.
  Future<List<SyncCursor>> listForInstallation(Id installationId);

  /// Stores [cursor], replacing the stored one with the same id. The database
  /// refuses a second cursor for the same installation and scope.
  Future<SyncCursor> save(SyncCursor cursor);

  /// Removes the cursor with [id]; returns whether one existed.
  Future<bool> remove(Id id);
}
