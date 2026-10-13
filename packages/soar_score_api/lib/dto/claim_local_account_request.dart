import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'claim_local_account_request.g.dart';

/// Body of `POST /api/v1/account/local-claims`.
///
/// [localAccountId] is the id of the installation's Local account. Repeating
/// the request for the same account changes nothing.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ClaimLocalAccountRequest {
  const ClaimLocalAccountRequest({required this.localAccountId});

  factory ClaimLocalAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$ClaimLocalAccountRequestFromJson(json);

  final Id localAccountId;

  Map<String, dynamic> toJson() => _$ClaimLocalAccountRequestToJson(this);
}
