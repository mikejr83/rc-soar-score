import 'package:json_annotation/json_annotation.dart';

/// What kind of person or system an account stands for.
///
/// Serializes as the exact text in `plan/data-model/entities/account.md`.
enum AccountKind {
  @JsonValue('registered')
  registered,
  @JsonValue('guest')
  guest,
  @JsonValue('local')
  local,
  @JsonValue('deleted')
  deleted,
}
