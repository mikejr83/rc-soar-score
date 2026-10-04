import 'package:equatable/equatable.dart';

import '../models/id.dart';

/// Names one synchronization stream: a contest's, or a director's own data.
///
/// System data is not a key, because it only comes down and is tracked by
/// `Installation.systemDataSeq`.
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
