import 'package:soar_score_core/soar_score_core.dart';

import 'app_sync_state.dart';
import 'conflict_answer.dart';
import 'open_conflict.dart';
import 'refused_change.dart';

/// What the screens may ask of synchronization.
///
/// The native build backs it with the sync engine; the web build has nothing
/// to synchronize and uses [NoAppSync]. Screens depend on this and never on
/// the engine, so the web build contains no engine.
abstract interface class AppSync {
  /// False when this build does not synchronize (web).
  bool get available;

  AppSyncState get state;

  /// A state after every step that changes what the director sees.
  Stream<AppSyncState> get states;

  /// Reads [scope] from the local store, without contacting the service.
  Future<void> refresh(SyncScopeKey scope);

  /// Syncs [scope] now. Failures show up in [state], not as errors.
  Future<void> syncNow(SyncScopeKey scope);

  /// The changes the service refused in [scope], oldest first.
  Future<List<RefusedChange>> refusedChanges(SyncScopeKey scope);

  /// The conflicts in [scope] that wait for a decision, oldest first.
  Future<List<OpenConflict>> openConflicts(SyncScopeKey scope);

  /// Sends the director's decision for [conflict]. [payload] is the edited
  /// value and goes with [ConflictResolutionChoice.merged] only.
  Future<ConflictAnswer> resolveConflict(
    SyncScopeKey scope,
    OpenConflict conflict,
    ConflictResolutionChoice choice, {
    Map<String, Object?>? payload,
  });
}
