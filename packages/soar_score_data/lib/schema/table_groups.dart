import 'package:drift/drift.dart';

import 'database_profile.dart';
import 'table_group.dart';

/// The group of every table, by SQL table name.
///
/// A table that is not listed cannot be created, and a test fails if one is
/// missing, so no table can silently reach the wrong executor.
const tableGroupByName = <String, TableGroup>{
  'contests': TableGroup.contest,
  'landing_tables': TableGroup.director,
  'landing_results': TableGroup.director,
  'discipline_profiles': TableGroup.system,
  'discipline_config_fields': TableGroup.system,
  'discipline_score_fields': TableGroup.system,
  'discipline_validations': TableGroup.system,
  'discipline_formulas': TableGroup.system,
  'discipline_rules': TableGroup.system,
  'contest_configuration_presets': TableGroup.director,
  'contest_configuration_revisions': TableGroup.contest,
  'participant_profiles': TableGroup.director,
  'roles': TableGroup.director,
  'contest_participations': TableGroup.contest,
  'teams': TableGroup.contest,
  'team_memberships': TableGroup.contest,
  'model_catalogs': TableGroup.director,
  'contest_model_links': TableGroup.contest,
  'mutation_records': TableGroup.contest,
  'conflict_records': TableGroup.contest,
  'audit_events': TableGroup.contest,
  'tombstones': TableGroup.director,
  'local_sync_positions': TableGroup.clientOnly,
};

/// The tables of [all] that [profile] creates, using [groups] (by default
/// [tableGroupByName]) to find each table's group.
List<TableInfo<Table, Object?>> tablesFor(
  DatabaseProfile profile,
  Iterable<TableInfo<Table, Object?>> all, {
  Map<String, TableGroup> groups = tableGroupByName,
}) => [
  for (final table in all)
    if (profile.groups.contains(
      groups[table.actualTableName] ??
          (throw StateError('Table ${table.actualTableName} has no group')),
    ))
      table,
];
