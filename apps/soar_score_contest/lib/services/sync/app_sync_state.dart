import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'sync_scope_summary.dart';

/// The whole sync state the screens read.
class AppSyncState extends Equatable {
  const AppSyncState({this.syncing = false, this.scopes = const {}});

  /// Whether a sync is running now.
  final bool syncing;

  /// The scopes the engine has looked at so far.
  final Map<SyncScopeKey, SyncScopeSummary> scopes;

  /// The summary of [scope], or null before the engine has looked at it.
  SyncScopeSummary? of(SyncScopeKey scope) => scopes[scope];

  @override
  List<Object?> get props => [syncing, scopes];
}
