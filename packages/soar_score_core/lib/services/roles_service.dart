import '../enums/role_type.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/id.dart';
import '../models/participants/role.dart';
import '../models/participants/system_roles.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import 'role_usage.dart';

/// The role operations of the API: the director's own non-flier roles.
///
/// The system roles are shared and fixed, so only a role the director added
/// can be renamed or deleted, and only while no contest uses it. Every
/// operation takes the director's account id; another director's role is
/// answered as not found.
class RolesService {
  RolesService(this.repository);

  final Repository repository;

  /// The system roles and the roles [ownerAccountId] added, by name.
  Future<List<Role>> list(Id ownerAccountId) =>
      repository.roleRepository.listVisibleTo(ownerAccountId: ownerAccountId);

  /// Adds a non-flier role named [displayName] owned by [ownerAccountId].
  ///
  /// Idempotent on [id]: repeating the same request returns the stored role.
  /// The same id with another name throws an [AlreadyStoredError]. A name
  /// the director can already see (ignoring case) throws a
  /// [ContestStateError]; a blank name throws an [ArgumentError].
  Future<Role> create(
    Id ownerAccountId,
    Id id,
    String displayName, {
    required MutationMetadata metadata,
  }) async {
    final role = Role(
      id: id,
      ownerAccountId: ownerAccountId,
      displayName: displayName.trim(),
      type: RoleType.nonFlier,
    );
    final stored = await repository.roleRepository.findById(id);
    if (stored != null) {
      if (stored.ownerAccountId == ownerAccountId &&
          stored.displayName == role.displayName) {
        return stored;
      }
      throw AlreadyStoredError(entityType: 'Role', entityId: id);
    }
    await _requireFreeName(ownerAccountId, role.displayName);
    return repository.roleRepository.save(role, metadata: metadata);
  }

  /// Renames role [id].
  ///
  /// Throws a [StaleRevisionError] when [baseRevision] is not the stored
  /// revision, and a [ContestStateError] for a system role or a name that is
  /// taken. Participations keep the name they were given.
  Future<Role> rename(
    Id ownerAccountId,
    Id id,
    String displayName, {
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _requireOwned(ownerAccountId, id);
    final name = displayName.trim();
    await _requireFreeName(ownerAccountId, name, except: id);
    final renamed = Role(
      id: id,
      ownerAccountId: ownerAccountId,
      displayName: name,
      type: stored.type,
      archivedAt: stored.archivedAt,
      revision: baseRevision,
    );
    return repository.roleRepository.save(renamed, metadata: metadata);
  }

  /// Deletes role [id].
  ///
  /// A system role, or a role a participation still has, is refused with a
  /// [ContestStateError]; [usage] says where the role is used.
  Future<void> delete(
    Id ownerAccountId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    await _requireOwned(ownerAccountId, id);
    final usage = await this.usage(ownerAccountId, id);
    if (usage.isNotEmpty) {
      throw ContestStateError(
        'role_in_use',
        'the role is used in ${usage.length} contest(s); '
            'change those participants first',
      );
    }
    await repository.roleRepository.delete(id, metadata: metadata);
  }

  /// The contests that have participants in role [id], by contest name.
  ///
  /// Throws an [EntityNotFoundError] when the director cannot see the role.
  Future<List<RoleUsage>> usage(Id ownerAccountId, Id id) async {
    final roles = await list(ownerAccountId);
    if (!roles.any((role) => role.id == id)) {
      throw EntityNotFoundError(entityType: 'Role', entityId: id);
    }
    final counts = <Id, int>{};
    for (final participation
        in await repository.contestParticipationRepository.listForRole(id)) {
      counts.update(
        participation.contestId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final usage = <RoleUsage>[];
    for (final MapEntry(:key, :value) in counts.entries) {
      final contest = await repository.contestRepository.findById(key);
      if (contest == null) continue;
      usage.add(
        RoleUsage(
          contestId: key,
          contestName: contest.name,
          participantCount: value,
        ),
      );
    }
    return usage..sort(
      (a, b) =>
          a.contestName.toLowerCase().compareTo(b.contestName.toLowerCase()),
    );
  }

  /// Role [id] when [ownerAccountId] added it.
  Future<Role> _requireOwned(Id ownerAccountId, Id id) async {
    final role = await repository.roleRepository.findById(id);
    if (role == null ||
        (!role.isSystem && role.ownerAccountId != ownerAccountId)) {
      throw EntityNotFoundError(entityType: 'Role', entityId: id);
    }
    if (role.isSystem) {
      throw ContestStateError(
        'system_role',
        id == SystemRoles.pilotId
            ? 'the Pilot role is fixed: every participant starts as a pilot '
                  'and only pilots receive scores'
            : '${role.displayName} is a system role and cannot be changed',
      );
    }
    return role;
  }

  Future<void> _requireFreeName(
    Id ownerAccountId,
    String name, {
    Id? except,
  }) async {
    final taken = (await list(ownerAccountId)).any(
      (role) =>
          role.id != except &&
          role.displayName.toLowerCase() == name.toLowerCase(),
    );
    if (taken) {
      throw ContestStateError(
        'duplicate_role_name',
        'a role named "$name" already exists',
      );
    }
  }
}
