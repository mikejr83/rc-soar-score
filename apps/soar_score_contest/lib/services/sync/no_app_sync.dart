import 'package:soar_score_core/soar_score_core.dart';

import 'app_sync.dart';
import 'app_sync_state.dart';
import 'refused_change.dart';

/// The sync of a build that does not synchronize.
class NoAppSync implements AppSync {
  const NoAppSync();

  @override
  bool get available => false;

  @override
  AppSyncState get state => const AppSyncState();

  @override
  Stream<AppSyncState> get states => const Stream.empty();

  @override
  Future<void> refresh(SyncScopeKey scope) async {}

  @override
  Future<void> syncNow(SyncScopeKey scope) async {}

  @override
  Future<List<RefusedChange>> refusedChanges(SyncScopeKey scope) async =>
      const [];
}
