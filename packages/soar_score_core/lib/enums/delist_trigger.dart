import 'package:json_annotation/json_annotation.dart';

/// Why a delist request was raised.
///
/// Serializes as the exact text in `plan/data-model/entities/delist_request.md`.
enum DelistTrigger {
  @JsonValue('owner_request')
  ownerRequest,
  @JsonValue('account_closure')
  accountClosure,
}
