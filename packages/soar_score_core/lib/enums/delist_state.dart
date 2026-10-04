import 'package:json_annotation/json_annotation.dart';

/// Where a delist request stands.
///
/// Serializes as the exact text in `plan/data-model/entities/delist_request.md`.
enum DelistState {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('denied')
  denied,
  @JsonValue('withdrawn')
  withdrawn,
}
