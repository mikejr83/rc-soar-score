/// Unified Soar Score data access layer.
///
/// Single package supporting both PostgreSQL (server) and SQLite (embedded)
/// via Drift's QueryExecutor abstraction. Consumers choose the executor when
/// constructing `RcSoarScoreDatabase`.
library;

export 'contests_table.dart';
export 'database.dart';
export 'migrate.dart';
export 'postgres_config.dart';
export 'schema/database_profile.dart';
export 'schema/table_group.dart';
export 'schema/table_groups.dart';
export 'seeding/demo/demo_data_seeder.dart';
export 'seeding/system_data_seeder.dart';
export 'seeding/system_seed_outcome.dart';
export 'sync/drift_replicated_change_applier.dart';
export 'sync/drift_sync_store.dart';
export 'sync/drift_unit_of_work.dart';
export 'sync/entity_store.dart';
export 'sync/entity_stores.dart';
export 'sync/sql_placeholders.dart';
export 'sync/table_mapper.dart';
export 'repositories/account_identity_repository.dart';
export 'repositories/account_public_profile_repository.dart';
export 'repositories/account_repository.dart';
export 'repositories/contest_configuration_revision_repository.dart';
export 'repositories/contest_participation_repository.dart';
export 'repositories/contest_repository.dart';
export 'repositories/delist_request_repository.dart';
export 'repositories/discipline_profile_repository.dart';
export 'repositories/drift_repository.dart';
export 'repositories/flight_result_repository.dart';
export 'repositories/installation_activation_repository.dart';
export 'repositories/installation_repository.dart';
export 'repositories/invitation_repository.dart';
export 'repositories/landing_table_repository.dart';
export 'repositories/local_account_repository.dart';
export 'repositories/matrix_assignment_repository.dart';
export 'repositories/matrix_revision_repository.dart';
export 'repositories/official_score_repository.dart';
export 'repositories/participant_account_link_repository.dart';
export 'repositories/participant_directory_entry_repository.dart';
export 'repositories/participant_profile_repository.dart';
export 'repositories/participation_standing_repository.dart';
export 'repositories/audit_event_repository.dart';
export 'repositories/publication_identity_repository.dart';
export 'repositories/publication_participant_repository.dart';
export 'repositories/publication_projection_repository.dart';
export 'repositories/publication_publisher.dart';
export 'repositories/repository.dart';
export 'repositories/role_repository.dart';
export 'repositories/round_group_repository.dart';
export 'repositories/round_repository.dart';
export 'repositories/score_attempt_repository.dart';
export 'repositories/re_flight_participant_repository.dart';
export 'repositories/re_flight_repository.dart';
export 'repositories/score_placeholder_repository.dart';
export 'repositories/sync_cursor_repository.dart';
export 'repositories/team_membership_repository.dart';
export 'repositories/team_repository.dart';
export 'repositories/team_standing_repository.dart';
