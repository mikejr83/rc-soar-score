import 'package:json_annotation/json_annotation.dart';

/// Whether an account can sign in.
///
/// Serializes as the exact text in `plan/data-model/entities/account.md`.
enum AccountStatus {
  @JsonValue('active')
  active,
  @JsonValue('archived')
  archived,
}
