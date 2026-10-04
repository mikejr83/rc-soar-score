/// Soar Score core: domain models, business logic, and the scoring engine.
///
/// This library is the public API of the package; consumers should import
/// only `package:soar_score_core/soar_score_core.dart`.
library;

export 'models/contest.dart';
export 'models/id.dart';
export 'models/shared/shared.dart';
export 'models/sync/sync.dart';
export 'repositories/contest_repository.dart';
export 'repositories/mutation_metadata.dart';
export 'repositories/replicated_change.dart';
export 'repositories/replicated_change_applier.dart';
export 'repositories/repository.dart';
export 'repositories/sync_scope_key.dart';
export 'repositories/sync_status.dart';
export 'repositories/sync_store.dart';
export 'repositories/unit_of_work.dart';
export 'repositories/write_context.dart';
export 'enums/enums.dart';
