/// The Soar Score client sync engine (pure Dart).
///
/// Consumers import only this library.
library;

export 'src/api_client_sync_gateway.dart';
export 'src/resolve_conflict_outcome.dart';
export 'src/sync_engine.dart';
export 'src/sync_engine_config.dart';
export 'src/sync_failure_kind.dart';
export 'src/sync_gateway.dart';
export 'src/sync_scheduler.dart';
export 'src/sync_scope_state.dart';
export 'src/sync_skip_reason.dart';
export 'src/sync_state.dart';

// The poller and timer factory live in core so the web build, which has no
// sync engine, can use them too.
export 'package:soar_score_core/services/services.dart'
    show
        SyncPollContest,
        SyncPollFocus,
        SyncPollLanding,
        SyncPoller,
        SyncTimerFactory;
