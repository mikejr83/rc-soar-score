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
import '../schema/tables/import_provenance_table.dart';
import '../schema/tables/model_catalogs_table.dart';
import '../schema/tables/contest_model_links_table.dart';
import '../schema/tables/matrix_revisions_table.dart';
import '../schema/tables/rounds_table.dart';
import '../schema/tables/round_groups_table.dart';
import '../schema/tables/re_flights_table.dart';
import '../schema/tables/matrix_assignments_table.dart';
import '../schema/tables/re_flight_participants_table.dart';
import '../schema/tables/score_placeholders_table.dart';
import '../schema/tables/score_attempts_table.dart';
import '../schema/tables/official_scores_table.dart';
import '../schema/tables/review_requests_table.dart';
import '../schema/tables/flight_results_table.dart';
import '../schema/tables/participation_standings_table.dart';
import '../schema/tables/team_standings_table.dart';
import '../schema/tables/accounts_table.dart';
import '../schema/tables/account_aliases_table.dart';
import '../schema/tables/account_identities_table.dart';
import '../schema/tables/account_public_profiles_table.dart';
import '../schema/tables/participant_account_links_table.dart';
import '../schema/tables/participant_directory_entries_table.dart';
import '../schema/tables/installations_table.dart';
import '../schema/tables/installation_activations_table.dart';
import '../schema/tables/sync_cursors_table.dart';
import '../schema/tables/publication_identities_table.dart';
import '../schema/tables/publication_projections_table.dart';
import '../schema/tables/publication_participants_table.dart';
import '../schema/tables/delist_requests_table.dart';
import '../schema/tables/conflict_records_table.dart';
import '../schema/tables/invitations_table.dart';
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
    EntityStore<core.ImportProvenance>(
      entityType: 'ImportProvenance',
      mapper: TableMapper(
        db,
        db.importProvenances,
        jsonColumns: importProvenancesJsonColumns,
      ),
      decode: core.ImportProvenance.fromJson,
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
    EntityStore<core.MatrixRevision>(
      entityType: 'MatrixRevision',
      mapper: TableMapper(
        db,
        db.matrixRevisions,
        jsonColumns: matrixRevisionsJsonColumns,
      ),
      decode: core.MatrixRevision.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.Round>(
      entityType: 'Round',
      mapper: TableMapper(db, db.rounds, jsonColumns: roundsJsonColumns),
      decode: core.Round.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.RoundGroup>(
      entityType: 'RoundGroup',
      mapper: TableMapper(
        db,
        db.roundGroups,
        jsonColumns: roundGroupsJsonColumns,
      ),
      decode: core.RoundGroup.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ReFlight>(
      entityType: 'ReFlight',
      mapper: TableMapper(db, db.reFlights, jsonColumns: reFlightsJsonColumns),
      decode: core.ReFlight.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.MatrixAssignment>(
      entityType: 'MatrixAssignment',
      mapper: TableMapper(
        db,
        db.matrixAssignments,
        jsonColumns: matrixAssignmentsJsonColumns,
      ),
      decode: core.MatrixAssignment.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.ReFlightParticipant>(
      entityType: 'ReFlightParticipant',
      mapper: TableMapper(
        db,
        db.reFlightParticipants,
        jsonColumns: reFlightParticipantsJsonColumns,
      ),
      decode: core.ReFlightParticipant.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ScorePlaceholder>(
      entityType: 'ScorePlaceholder',
      mapper: TableMapper(
        db,
        db.scorePlaceholders,
        jsonColumns: scorePlaceholdersJsonColumns,
      ),
      decode: core.ScorePlaceholder.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ScoreAttempt>(
      entityType: 'ScoreAttempt',
      mapper: TableMapper(
        db,
        db.scoreAttempts,
        jsonColumns: scoreAttemptsJsonColumns,
      ),
      decode: core.ScoreAttempt.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.OfficialScore>(
      entityType: 'OfficialScore',
      mapper: TableMapper(
        db,
        db.officialScores,
        jsonColumns: officialScoresJsonColumns,
      ),
      decode: core.OfficialScore.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.ReviewRequest>(
      entityType: 'ReviewRequest',
      mapper: TableMapper(
        db,
        db.reviewRequests,
        jsonColumns: reviewRequestsJsonColumns,
      ),
      decode: core.ReviewRequest.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.FlightResult>(
      entityType: 'FlightResult',
      mapper: TableMapper(
        db,
        db.flightResults,
        jsonColumns: flightResultsJsonColumns,
      ),
      decode: core.FlightResult.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.ParticipationStanding>(
      entityType: 'ParticipationStanding',
      mapper: TableMapper(
        db,
        db.participationStandings,
        jsonColumns: participationStandingsJsonColumns,
      ),
      decode: core.ParticipationStanding.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.TeamStanding>(
      entityType: 'TeamStanding',
      mapper: TableMapper(
        db,
        db.teamStandings,
        jsonColumns: teamStandingsJsonColumns,
      ),
      decode: core.TeamStanding.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.Account>(
      entityType: 'Account',
      mapper: TableMapper(db, db.accounts, jsonColumns: accountsJsonColumns),
      decode: core.Account.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.AccountAlias>(
      entityType: 'AccountAlias',
      mapper: TableMapper(
        db,
        db.accountAliases,
        jsonColumns: accountAliasesJsonColumns,
      ),
      decode: core.AccountAlias.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.AccountIdentity>(
      entityType: 'AccountIdentity',
      mapper: TableMapper(
        db,
        db.accountIdentities,
        jsonColumns: accountIdentitiesJsonColumns,
      ),
      decode: core.AccountIdentity.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.AccountPublicProfile>(
      entityType: 'AccountPublicProfile',
      mapper: TableMapper(
        db,
        db.accountPublicProfiles,
        jsonColumns: accountPublicProfilesJsonColumns,
      ),
      decode: core.AccountPublicProfile.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.ParticipantAccountLink>(
      entityType: 'ParticipantAccountLink',
      mapper: TableMapper(
        db,
        db.participantAccountLinks,
        jsonColumns: participantAccountLinksJsonColumns,
      ),
      decode: core.ParticipantAccountLink.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.ParticipantDirectoryEntry>(
      entityType: 'ParticipantDirectoryEntry',
      mapper: TableMapper(
        db,
        db.participantDirectoryEntries,
        jsonColumns: participantDirectoryEntriesJsonColumns,
      ),
      decode: core.ParticipantDirectoryEntry.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.Installation>(
      entityType: 'Installation',
      mapper: TableMapper(
        db,
        db.installations,
        jsonColumns: installationsJsonColumns,
      ),
      decode: core.Installation.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.InstallationActivation>(
      entityType: 'InstallationActivation',
      mapper: TableMapper(
        db,
        db.installationActivations,
        jsonColumns: installationActivationsJsonColumns,
      ),
      decode: core.InstallationActivation.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.SyncCursor>(
      entityType: 'SyncCursor',
      mapper: TableMapper(
        db,
        db.syncCursors,
        jsonColumns: syncCursorsJsonColumns,
      ),
      decode: core.SyncCursor.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.PublicationIdentity>(
      entityType: 'PublicationIdentity',
      mapper: TableMapper(
        db,
        db.publicationIdentities,
        jsonColumns: publicationIdentitiesJsonColumns,
      ),
      decode: core.PublicationIdentity.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: true,
    ),
    EntityStore<core.PublicationProjection>(
      entityType: 'PublicationProjection',
      mapper: TableMapper(
        db,
        db.publicationProjections,
        jsonColumns: publicationProjectionsJsonColumns,
      ),
      decode: core.PublicationProjection.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.PublicationParticipant>(
      entityType: 'PublicationParticipant',
      mapper: TableMapper(
        db,
        db.publicationParticipants,
        jsonColumns: publicationParticipantsJsonColumns,
      ),
      decode: core.PublicationParticipant.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.DelistRequest>(
      entityType: 'DelistRequest',
      mapper: TableMapper(
        db,
        db.delistRequests,
        jsonColumns: delistRequestsJsonColumns,
      ),
      decode: core.DelistRequest.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.Invitation>(
      entityType: 'Invitation',
      mapper: TableMapper(
        db,
        db.invitations,
        jsonColumns: invitationsJsonColumns,
      ),
      decode: core.Invitation.fromJson,
      encode: (entity) => entity.toSyncJson(),
      hasRevision: false,
    ),
    EntityStore<core.AuditEvent>(
      entityType: 'AuditEvent',
      mapper: TableMapper(db, db.auditEvents),
      decode: core.AuditEvent.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.ConflictRecord>(
      entityType: 'ConflictRecord',
      mapper: TableMapper(
        db,
        db.conflictRecords,
        jsonColumns: conflictRecordsJsonColumns,
      ),
      decode: core.ConflictRecord.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.MutationRecord>(
      entityType: 'MutationRecord',
      mapper: TableMapper(db, db.mutationRecords, jsonColumns: {'payload'}),
      decode: core.MutationRecord.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
    EntityStore<core.Tombstone>(
      entityType: 'Tombstone',
      mapper: TableMapper(db, db.tombstones),
      decode: core.Tombstone.fromJson,
      encode: (entity) => entity.toJson(),
      hasRevision: false,
    ),
  ]);

  final Map<String, EntityStore<Object>> _byType;

  /// The store for [entityType]; throws a [core.UnsupportedEntityTypeError] for an unknown one.
  EntityStore<Object> of(String entityType) =>
      _byType[entityType] ??
      (throw core.UnsupportedEntityTypeError(
        entityType,
        'has no store in this database',
      ));
}
