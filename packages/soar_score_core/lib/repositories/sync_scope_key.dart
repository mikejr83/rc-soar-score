import 'package:equatable/equatable.dart';

import '../models/id.dart';

/// Names one synchronization stream: a contest's, a director's own data, or
/// the system data.
///
/// An installation with no account has no `Installation` row to hold the
/// system-data position, so the client keeps it under [SystemScopeKey] like
/// any other position. System data only comes down: it has no mutations and
/// no conflicts.
sealed class SyncScopeKey extends Equatable {
  const SyncScopeKey();
}

/// The stream of one contest's data.
final class ContestScopeKey extends SyncScopeKey {
  const ContestScopeKey(this.contestId);

  final Id contestId;

  @override
  List<Object?> get props => [contestId];
}

/// The stream of one director's own data (profiles, roles, models, landing
/// tables, presets).
final class DirectorScopeKey extends SyncScopeKey {
  const DirectorScopeKey(this.ownerAccountId);

  final Id ownerAccountId;

  @override
  List<Object?> get props => [ownerAccountId];
}

/// The stream of system data (discipline profiles, system roles and system
/// landing tables). There is one, so every key is equal.
final class SystemScopeKey extends SyncScopeKey {
  const SystemScopeKey();

  @override
  List<Object?> get props => const [];
}
