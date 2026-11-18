import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Roles in the database.
class RoleRepository extends DriftRepository implements core.RoleRepository {
  RoleRepository(super.db, {super.stores});

  late final _roles = store<core.Role>('Role');

  @override
  Future<List<core.Role>> listVisibleTo({core.Id? ownerAccountId}) async => [
    for (final role in await _roles.all(orderBy: 'display_name, id'))
      if (role.isSystem || role.ownerAccountId == ownerAccountId) role,
  ];

  @override
  Future<core.Role?> findById(core.Id id) => _roles.find(id);

  @override
  Future<core.Role> save(
    core.Role role, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(role, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final role = await _roles.find(id);
        if (role == null) return false;
        await context.delete(role, metadata: metadata);
        return true;
      });

  /// Installs [role] unless its row exists.
  @override
  Future<bool> installSystemRole(core.Role role) async =>
      await installSystemRoles([role]) > 0;

  /// Installs the roles not stored yet in one statement and returns how many
  /// were new. A stored role is never overwritten.
  Future<int> installSystemRoles(Iterable<core.Role> roles) {
    final list = roles.toList();
    for (final role in list) {
      if (!role.isSystem) {
        throw ArgumentError.value(
          role.id.value,
          'role',
          'must be a system role with no owner',
        );
      }
    }
    return _roles.insertMissingJson([for (final r in list) _roles.encode(r)]);
  }
}
