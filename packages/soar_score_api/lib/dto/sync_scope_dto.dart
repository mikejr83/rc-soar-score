import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'sync_scope_dto.g.dart';

/// The scope one sync exchange covers: a contest, or the director's own data.
///
/// Exactly one of [contestId] and [ownerAccountId] is set. The unset one is
/// left out of the JSON.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
@IdConverter()
class SyncScopeDto {
  const SyncScopeDto({this.contestId, this.ownerAccountId});

  const SyncScopeDto.contest(Id this.contestId) : ownerAccountId = null;

  const SyncScopeDto.owner(Id this.ownerAccountId) : contestId = null;

  factory SyncScopeDto.fromJson(Map<String, dynamic> json) {
    final scope = _$SyncScopeDtoFromJson(json);
    if ((scope.contestId == null) == (scope.ownerAccountId == null)) {
      throw const FormatException(
        'a sync scope sets exactly one of contest_id and owner_account_id',
      );
    }
    return scope;
  }

  final Id? contestId;
  final Id? ownerAccountId;

  Map<String, dynamic> toJson() => _$SyncScopeDtoToJson(this);
}
