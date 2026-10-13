// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_local_account_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimLocalAccountRequest _$ClaimLocalAccountRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ClaimLocalAccountRequest', json, ($checkedConvert) {
  final val = ClaimLocalAccountRequest(
    localAccountId: $checkedConvert(
      'local_account_id',
      (v) => const IdConverter().fromJson(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'localAccountId': 'local_account_id'});

Map<String, dynamic> _$ClaimLocalAccountRequestToJson(
  ClaimLocalAccountRequest instance,
) => <String, dynamic>{
  'local_account_id': const IdConverter().toJson(instance.localAccountId),
};
