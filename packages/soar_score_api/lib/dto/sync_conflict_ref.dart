import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'sync_conflict_ref.g.dart';

/// A `ConflictRecord` the exchange created or touched. A record with
/// [requiresAction] false is silent and never shown as needing a decision.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SyncConflictRef {
  const SyncConflictRef({required this.id, required this.requiresAction});

  factory SyncConflictRef.fromJson(Map<String, dynamic> json) =>
      _$SyncConflictRefFromJson(json);

  final Id id;
  final bool requiresAction;

  Map<String, dynamic> toJson() => _$SyncConflictRefToJson(this);
}
