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
export 'sync/drift_replicated_change_applier.dart';
export 'sync/drift_sync_store.dart';
export 'sync/drift_unit_of_work.dart';
export 'sync/entity_store.dart';
export 'sync/entity_stores.dart';
export 'sync/sql_placeholders.dart';
export 'sync/table_mapper.dart';
export 'repositories/contest_repository.dart';
export 'repositories/contest_configuration_revision_repository.dart';
export 'repositories/contest_participation_repository.dart';
export 'repositories/drift_repository.dart';
export 'repositories/flight_result_repository.dart';
export 'repositories/matrix_assignment_repository.dart';
export 'repositories/matrix_revision_repository.dart';
export 'repositories/official_score_repository.dart';
export 'repositories/participant_profile_repository.dart';
export 'repositories/participation_standing_repository.dart';
export 'repositories/repository.dart';
export 'repositories/round_group_repository.dart';
export 'repositories/round_repository.dart';
export 'repositories/score_attempt_repository.dart';
export 'repositories/score_placeholder_repository.dart';
export 'repositories/team_membership_repository.dart';
export 'repositories/team_repository.dart';
export 'repositories/team_standing_repository.dart';
