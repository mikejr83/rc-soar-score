import '../models/id.dart';
import '../models/participants/role.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for roles.
abstract interface class RoleRepository {
  /// The system roles and the roles owned by [ownerAccountId], by name.
  ///
  /// With no [ownerAccountId], only the system roles. Archived roles are
  /// included, so a participation's role always resolves.
  Future<List<Role>> listVisibleTo({Id? ownerAccountId});

  /// Stores a system [role].
  ///
  /// Idempotent: returns `false` and changes nothing when a role with the
  /// same id is already stored, `true` when it was added. System data is
  /// seeded, so no mutation is recorded. Throws an `ArgumentError` when
  /// [role] has an owner.
  Future<bool> installSystemRole(Role role);

  Future<Role?> findById(Id id);

  /// Inserts [role], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when [role] was read at an older
  /// revision. Returns the role as stored.
  Future<Role> save(Role role, {required MutationMetadata metadata});

  /// Deletes the role with [id]; returns whether a row was removed.
  ///
  /// A role that a participation uses cannot be deleted.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
