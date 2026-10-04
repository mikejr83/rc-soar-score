import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/discipline_category.dart';
import '../../enums/discipline_type.dart';
import '../../enums/profile_status.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'discipline_profile.g.dart';

/// A versioned official scoring profile of a soaring discipline.
///
/// System data, written by administrators and synchronized down only. The
/// rules live in child rows keyed by [id]. See
/// `plan/data-model/entities/discipline_profile.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class DisciplineProfile extends Equatable implements SyncScoped {
  DisciplineProfile({
    required this.id,
    required this.type,
    required this.version,
    required String name,
    this.description,
    required this.category,
    this.defaultLandingTableId,
    Map<String, Object?>? defaultOptions,
    this.status = ProfileStatus.drafted,
    this.supersededBy,
    required this.createdBy,
    required DateTime createdAt,
    this.updatedBy,
    DateTime? updatedAt,
  }) : name = requireNotBlank(name, 'name'),
       defaultOptions = defaultOptions == null
           ? null
           : Map.unmodifiable(defaultOptions),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt?.toUtc() {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'must be at least 1');
    }
    if ((status == ProfileStatus.superseded) != (supersededBy != null)) {
      throw ArgumentError(
        'superseded_by is set exactly when the status is superseded',
      );
    }
  }

  factory DisciplineProfile.fromJson(Map<String, Object?> json) =>
      _$DisciplineProfileFromJson(json);

  final Id id;
  final DisciplineType type;

  /// Rules profile version; (type, version) is unique.
  final int version;

  final String name;
  final String? description;
  final DisciplineCategory category;

  /// The system landing table the profile ships with; null for a discipline
  /// with no landing score.
  final Id? defaultLandingTableId;

  /// Core contest options whose default differs for this discipline. A
  /// profile can suggest a default, never redefine an option.
  final Map<String, Object?>? defaultOptions;

  final ProfileStatus status;

  /// The later version that supersedes this one.
  final Id? supersededBy;

  final Id createdBy;
  final DateTime createdAt;

  /// Who last modified the profile (drafts only).
  final Id? updatedBy;
  final DateTime? updatedAt;

  @override
  SyncScope get syncScope => SyncScope.system;

  Map<String, Object?> toJson() => _$DisciplineProfileToJson(this);

  @override
  List<Object?> get props => [
    id,
    type,
    version,
    name,
    description,
    category,
    defaultLandingTableId,
    defaultOptions,
    status,
    supersededBy,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];
}
