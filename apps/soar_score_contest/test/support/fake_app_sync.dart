import 'dart:async';

import 'package:soar_score_contest/services/sync/app_sync.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/refused_change.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// An [AppSync] with a state the test sets, recording what screens ask.
class FakeAppSync implements AppSync {
  FakeAppSync({this.available = true, AppSyncState? state})
    : _state = state ?? const AppSyncState();

  @override
  final bool available;

  AppSyncState _state;
  final _controller = StreamController<AppSyncState>.broadcast();

  /// The scopes screens asked to refresh, and to sync now.
  final refreshed = <SyncScopeKey>[];
  final synced = <SyncScopeKey>[];

  /// What [refusedChanges] answers.
  List<RefusedChange> refused = const [];

  @override
  AppSyncState get state => _state;

  set state(AppSyncState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  Stream<AppSyncState> get states => _controller.stream;

  @override
  Future<void> refresh(SyncScopeKey scope) async => refreshed.add(scope);

  @override
  Future<void> syncNow(SyncScopeKey scope) async => synced.add(scope);

  @override
  Future<List<RefusedChange>> refusedChanges(SyncScopeKey scope) async =>
      refused;
}
