import '../models/discipline/discipline_profile_with_rules.dart';
import '../models/id.dart';

/// Abstract persistence contract for discipline profiles and the rows that
/// define them.
///
/// Profiles are system data: they are installed from what the app ships or
/// synchronized down, and a client never edits one.
abstract interface class DisciplineProfileRepository {
  /// The profile with [id] and its child rows, or `null` when it is not
  /// stored.
  Future<DisciplineProfileWithRules?> findById(Id id);

  /// Every published profile, by type and version.
  Future<List<DisciplineProfileWithRules>> listPublished();

  /// Stores a system [profile] and its child rows in one transaction, so a
  /// profile is complete or absent.
  ///
  /// Idempotent: returns `false` and changes nothing when a profile with the
  /// same id is already stored, `true` when it was added. System data is
  /// seeded, so no mutation is recorded. Throws a `StateError`, storing
  /// nothing, when the profile's default landing table is not stored.
  Future<bool> installSystemProfile(DisciplineProfileWithRules profile);
}
