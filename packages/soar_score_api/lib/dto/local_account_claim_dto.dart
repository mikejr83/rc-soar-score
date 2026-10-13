import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'local_account_claim_dto.g.dart';

/// The answer to `POST /api/v1/account/local-claims`: the Local account that
/// is now claimed and when. The caller already knows which account claimed
/// it, so the registered account's id is not repeated.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
@UtcTimestampConverter()
class LocalAccountClaimDto {
  const LocalAccountClaimDto({
    required this.localAccountId,
    required this.claimedAt,
  });

  factory LocalAccountClaimDto.fromJson(Map<String, dynamic> json) =>
      _$LocalAccountClaimDtoFromJson(json);

  final Id localAccountId;
  final DateTime claimedAt;

  Map<String, dynamic> toJson() => _$LocalAccountClaimDtoToJson(this);
}
