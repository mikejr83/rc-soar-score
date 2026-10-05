import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../schema/tables/landing_tables_table.dart';
import '../schema/tables/landing_results_table.dart';
import '../schema/tables/discipline_profiles_table.dart';
import '../schema/tables/discipline_config_fields_table.dart';
import '../schema/tables/discipline_score_fields_table.dart';
import '../schema/tables/discipline_validations_table.dart';
import '../schema/tables/discipline_formulas_table.dart';
import '../schema/tables/discipline_rules_table.dart';
import '../schema/tables/contest_configuration_presets_table.dart';
import '../schema/tables/contest_configuration_revisions_table.dart';
import '../schema/tables/participant_profiles_table.dart';
import '../schema/tables/roles_table.dart';
import '../schema/tables/contest_participations_table.dart';
import '../schema/tables/teams_table.dart';
import '../schema/tables/team_memberships_table.dart';
import '../schema/tables/model_catalogs_table.dart';
import '../schema/tables/contest_model_links_table.dart';
import 'entity_store.dart';
import 'table_mapper.dart';

/// The entity types a database can store, by `entity_type`.
class EntityStores {
  EntityStores(Iterable<EntityStore<Object>> stores)
    : _byType = {for (final store in stores) store.entityType: store};

  /// Every store of [db]'s profile.
  factory EntityStores.forDatabase(SoarScoreDatabase db) => EntityStores([
    EntityStore<core.Contest>(
      entityType: 'Contest',
      mapper: TableMapper(db, db.contests),
      decode: core.Contest.fromJson,
      encode: (contest) => contest.toJson(),
    ),
    EntityStore<core.LandingTable>(
      entityType: 'LandingTable',
      mapper: TableMapper(
        db,
        db.landingTables,
        jsonColumns: landingTablesJsonColumns,
      ),
      decode: core.LandingTable.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.LandingResult>(
      entityType: 'LandingResult',
      mapper: TableMapper(
        db,
        db.landingResults,
        jsonColumns: landingResultsJsonColumns,
      ),
      decode: core.LandingResult.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.DisciplineProfile>(
      entityType: 'DisciplineProfile',
      mapper: TableMapper(
        db,
        db.disciplineProfiles,
        jsonColumns: disciplineProfilesJsonColumns,
      ),
      decode: core.DisciplineProfile.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.DisciplineConfigField>(
      entityType: 'DisciplineConfigField',
      mapper: TableMapper(
        db,
        db.disciplineConfigFields,
        jsonColumns: disciplineConfigFieldsJsonColumns,
      ),
      decode: core.DisciplineConfigField.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.DisciplineScoreField>(
      entityType: 'DisciplineScoreField',
      mapper: TableMapper(
        db,
        db.disciplineScoreFields,
        jsonColumns: disciplineScoreFieldsJsonColumns,
      ),
      decode: core.DisciplineScoreField.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.DisciplineValidation>(
      entityType: 'DisciplineValidation',
      mapper: TableMapper(
        db,
        db.disciplineValidations,
        jsonColumns: disciplineValidationsJsonColumns,
      ),
      decode: core.DisciplineValidation.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.DisciplineFormula>(
      entityType: 'DisciplineFormula',
      mapper: TableMapper(
        db,
        db.disciplineFormulas,
        jsonColumns: disciplineFormulasJsonColumns,
      ),
      decode: core.DisciplineFormula.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.DisciplineRule>(
      entityType: 'DisciplineRule',
      mapper: TableMapper(
        db,
        db.disciplineRules,
        jsonColumns: disciplineRulesJsonColumns,
      ),
      decode: core.DisciplineRule.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.ContestConfigurationPreset>(
      entityType: 'ContestConfigurationPreset',
      mapper: TableMapper(
        db,
        db.contestConfigurationPresets,
        jsonColumns: contestConfigurationPresetsJsonColumns,
      ),
      decode: core.ContestConfigurationPreset.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ContestConfigurationRevision>(
      entityType: 'ContestConfigurationRevision',
      mapper: TableMapper(
        db,
        db.contestConfigurationRevisions,
        jsonColumns: contestConfigurationRevisionsJsonColumns,
      ),
      decode: core.ContestConfigurationRevision.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.ParticipantProfile>(
      entityType: 'ParticipantProfile',
      mapper: TableMapper(
        db,
        db.participantProfiles,
        jsonColumns: participantProfilesJsonColumns,
      ),
      decode: core.ParticipantProfile.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.Role>(
      entityType: 'Role',
      mapper: TableMapper(db, db.roles, jsonColumns: rolesJsonColumns),
      decode: core.Role.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ContestParticipation>(
      entityType: 'ContestParticipation',
      mapper: TableMapper(
        db,
        db.contestParticipations,
        jsonColumns: contestParticipationsJsonColumns,
      ),
      decode: core.ContestParticipation.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.Team>(
      entityType: 'Team',
      mapper: TableMapper(db, db.teams, jsonColumns: teamsJsonColumns),
      decode: core.Team.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.TeamMembership>(
      entityType: 'TeamMembership',
      mapper: TableMapper(
        db,
        db.teamMemberships,
        jsonColumns: teamMembershipsJsonColumns,
      ),
      decode: core.TeamMembership.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ModelCatalog>(
      entityType: 'ModelCatalog',
      mapper: TableMapper(
        db,
        db.modelCatalogs,
        jsonColumns: modelCatalogsJsonColumns,
      ),
      decode: core.ModelCatalog.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ContestModelLink>(
      entityType: 'ContestModelLink',
      mapper: TableMapper(
        db,
        db.contestModelLinks,
        jsonColumns: contestModelLinksJsonColumns,
      ),
      decode: core.ContestModelLink.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
  ]);

  final Map<String, EntityStore<Object>> _byType;

  /// The store for [entityType]; throws an [ArgumentError] for an unknown one.
  EntityStore<Object> of(String entityType) =>
      _byType[entityType] ??
      (throw ArgumentError.value(
        entityType,
        'entityType',
        'has no store in this database',
      ));
}
