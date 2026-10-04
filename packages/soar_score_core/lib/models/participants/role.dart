import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/role_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'role.g.dart';

/// A label for the people in a contest, either a pilot or a non-flier.
///
/// A role with no owner is system data; one owned by a director is that
/// director's data and can only be a non-flier. See
/// `plan/data-model/entities/role.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class Role extends Equatable implements Synchronizable {
  Role({
    required this.id,
    this.ownerAccountId,
    required String displayName,
    required this.type,
    DateTime? archivedAt,
    this.revision = 0,
  }) : displayName = requireNotBlank(displayName, 'displayName'),
       archivedAt = archivedAt?.toUtc() {
    if (ownerAccountId != null && type != RoleType.nonFlier) {
      throw ArgumentError('a director can only add non-flier roles');
    }
    requireNonNegative(revision, 'revision');
  }

  factory Role.fromJson(Map<String, Object?> json) => _$RoleFromJson(json);

  @override
  final Id id;

  /// The director who defined the role; null for a system role.
  final Id? ownerAccountId;

  final String displayName;
  final RoleType type;

  /// When the role was retired from use; it cannot be assigned afterwards.
  final DateTime? archivedAt;

  @override
  final int revision;

  bool get isSystem => ownerAccountId == null;
  bool get isArchived => archivedAt != null;

  @override
  String get entityType => 'Role';

  @override
  SyncScope get syncScope => isSystem ? SyncScope.system : SyncScope.director;

  Map<String, Object?> toJson() => _$RoleToJson(this);

  @override
  List<Object?> get props => [
    id,
    ownerAccountId,
    displayName,
    type,
    archivedAt,
    revision,
  ];
}
