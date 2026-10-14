import '../../models/id.dart';
import '../../repositories/sync_scope_key.dart';

/// The two id columns a scope fills in sync records: exactly one is set.
extension SyncScopeIds on SyncScopeKey {
  Id? get contestIdOrNull => switch (this) {
    ContestScopeKey(:final contestId) => contestId,
    _ => null,
  };

  Id? get ownerAccountIdOrNull => switch (this) {
    DirectorScopeKey(:final ownerAccountId) => ownerAccountId,
    _ => null,
  };
}
