import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/landing_input_unit.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'landing_table.g.dart';

/// An immutable landing bonus table, created together with its results.
///
/// A table with no owner is system data; one owned by a director is that
/// director's data. See `plan/data-model/entities/landing_table.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class LandingTable extends Equatable implements AppendOnly {
  LandingTable({
    required this.id,
    this.ownerAccountId,
    required String name,
    required this.inputUnit,
    required DateTime createdAt,
  }) : name = requireNotBlank(name, 'name'),
       createdAt = createdAt.toUtc();

  factory LandingTable.fromJson(Map<String, Object?> json) =>
      _$LandingTableFromJson(json);

  @override
  final Id id;

  /// The director who created it; null for a table shipped by the system.
  final Id? ownerAccountId;

  final String name;

  /// What the entry keys mean: a distance from the marker, or the points.
  final LandingInputUnit inputUnit;

  final DateTime createdAt;

  bool get isSystem => ownerAccountId == null;

  @override
  String get entityType => 'LandingTable';

  @override
  SyncScope get syncScope => isSystem ? SyncScope.system : SyncScope.director;

  Map<String, Object?> toJson() => _$LandingTableToJson(this);

  @override
  List<Object?> get props => [id, ownerAccountId, name, inputUnit, createdAt];
}
