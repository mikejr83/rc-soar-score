// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_account_claim_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalAccountClaimDto _$LocalAccountClaimDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'LocalAccountClaimDto',
  json,
  ($checkedConvert) {
    final val = LocalAccountClaimDto(
      localAccountId: $checkedConvert(
        'local_account_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      claimedAt: $checkedConvert(
        'claimed_at',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'localAccountId': 'local_account_id',
    'claimedAt': 'claimed_at',
  },
);

Map<String, dynamic> _$LocalAccountClaimDtoToJson(
  LocalAccountClaimDto instance,
) => <String, dynamic>{
  'local_account_id': const IdConverter().toJson(instance.localAccountId),
  'claimed_at': const UtcTimestampConverter().toJson(instance.claimedAt),
};
