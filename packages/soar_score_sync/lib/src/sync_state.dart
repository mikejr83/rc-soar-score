import 'package:soar_score_core/soar_score_core.dart';

import 'sync_scope_state.dart';

/// The whole sync state, emitted on `SyncEngine.states`.
class SyncState {
  const SyncState({
    required this.installationId,
    this.scopes = const {},
    this.syncing = false,
  });

  /// The active installation's identity, shown so the director can tell
  /// installations apart.
  final Id installationId;

  final Map<SyncScopeKey, SyncScopeState> scopes;

  /// Whether a sync is running now.
  final bool syncing;

  /// Changes made after the last successful sync are not recoverable if this
  /// installation is lost. The warning is persistent, so it is always true.
  bool get warnUnrecoverableChanges => true;

  SyncState copyWith({
    Map<SyncScopeKey, SyncScopeState>? scopes,
    bool? syncing,
  }) => SyncState(
    installationId: installationId,
    scopes: scopes ?? this.scopes,
    syncing: syncing ?? this.syncing,
  );
}
