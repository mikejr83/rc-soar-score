import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'sync_cursor.g.dart';

/// How far an installation has synchronized one scope.
///
/// Backend only. The position increases monotonically and is never reset. See
/// `plan/data-model/entities/sync_cursor.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class SyncCursor extends Equatable implements BackendOnly {
  SyncCursor({
    required this.id,
    required this.installationId,
    this.contestId,
    this.ownerAccountId,
    this.lastSyncedSequence = 0,
    this.lastSyncedAt,
    required this.updatedAt,
  }) {
    requireExactlyOneScope(
      contestId: contestId,
      ownerAccountId: ownerAccountId,
    );
    requireNonNegative(lastSyncedSequence, 'lastSyncedSequence');
  }

  factory SyncCursor.fromJson(Map<String, Object?> json) =>
      _$SyncCursorFromJson(json);

  final Id id;
  final Id installationId;

  /// Set for a contest's stream; exactly one of this and [ownerAccountId].
  final Id? contestId;

  /// Set for a director's own data stream.
  final Id? ownerAccountId;

  /// Highest sequence of the scope that the installation has acknowledged.
  final int lastSyncedSequence;

  final DateTime? lastSyncedAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$SyncCursorToJson(this);

  @override
  List<Object?> get props => [
    id,
    installationId,
    contestId,
    ownerAccountId,
    lastSyncedSequence,
    lastSyncedAt,
    updatedAt,
  ];
}
