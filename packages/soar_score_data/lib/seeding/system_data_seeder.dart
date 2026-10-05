import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../repositories/discipline_profile_repository.dart';
import '../repositories/landing_table_repository.dart';
import '../repositories/role_repository.dart';
import '../schema/table_group.dart';
import '../sync/drift_sync_store.dart';
import '../sync/entity_stores.dart';
import 'system_seed_outcome.dart';

/// Installs the system data the app ships (landing tables, discipline
/// profiles and system roles) so an installation that has never synchronized
/// can create and score contests offline.
///
/// One run is one transaction, in dependency order: landing tables, then
/// profiles (which name a default table), then roles. Either all of it is
/// installed or none of it is, so the app never starts with partial data.
///
/// A native database records the sequence it has installed as its
/// system-data position ([core.SystemScopeKey]). A run skips the install when
/// the stored position is at or above [sequence], and raises it otherwise,
/// never lowering it, so a later launch does not rewrite system data and
/// system data synchronized from a newer service is never overwritten. The
/// server keeps no such position (its system-data stream is separate), so on
/// a server database every run installs what is missing; an install never
/// overwrites a stored row.
///
/// Seeding is not the demo seed of sample contests. It is always on and
/// writes no `MutationRecord`.
class SystemDataSeeder {
  /// Seeds [db] with the shipped data. The data and [sequence] can be
  /// replaced, which tests use to stand in for a later version.
  SystemDataSeeder(
    this._db, {
    Iterable<core.LandingTableWithResults>? landingTables,
    Iterable<core.DisciplineProfileWithRules>? profiles,
    Iterable<core.Role>? roles,
    int sequence = core.SystemSeed.sequence,
  }) : _landingTables = List.of(landingTables ?? core.SystemLandingTables.all),
       _profiles = List.of(profiles ?? core.SystemDisciplineProfiles.all),
       _roles = List.of(roles ?? core.SystemRoles.all),
       sequence = sequence {
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'must be at least 1');
    }
  }

  final SoarScoreDatabase _db;
  final List<core.LandingTableWithResults> _landingTables;
  final List<core.DisciplineProfileWithRules> _profiles;
  final List<core.Role> _roles;

  /// The system-data sequence this run brings the database up to.
  final int sequence;

  /// Installs the shipped data, or does nothing if it is already installed.
  ///
  /// Throws, with nothing changed, if any part of the install fails.
  Future<SystemSeedOutcome> seed() => _db.transaction(() async {
    final syncStore = _db.profile.groups.contains(TableGroup.clientOnly)
        ? DriftSyncStore(_db)
        : null;
    const scope = core.SystemScopeKey();
    if (syncStore != null && await syncStore.readCursor(scope) >= sequence) {
      return SystemSeedOutcome.upToDate;
    }

    final stores = EntityStores.forDatabase(_db);
    final landingTables = LandingTableRepository(_db, stores: stores);
    final profiles = DisciplineProfileRepository(_db, stores: stores);
    final roles = RoleRepository(_db, stores: stores);
    for (final table in _landingTables) {
      await landingTables.installSystemTable(table);
    }
    for (final profile in _profiles) {
      await profiles.installSystemProfile(profile);
    }
    for (final role in _roles) {
      await roles.installSystemRole(role);
    }
    await syncStore?.writeCursor(scope, sequence);
    return SystemSeedOutcome.installed;
  });
}
