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
  Future<bool> installSystemRole(core.Role role) {
    if (!role.isSystem) {
      throw ArgumentError.value(
        role.id.value,
        'role',
        'must be a system role with no owner',
      );
    }
    return db.transaction(() async {
      if (await _roles.findJson(role.id) != null) return false;
      await _roles.upsertJson(_roles.encode(role));
      return true;
    });
  }
}
