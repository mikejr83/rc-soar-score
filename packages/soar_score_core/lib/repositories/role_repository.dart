import '../models/id.dart';
import '../models/participants/role.dart';

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
}
