import 'package:json_annotation/json_annotation.dart';

/// Whether a publication has been claimed by an account.
///
/// Serializes as the exact text in `plan/data-model/entities/publication_identity.md`.
enum ClaimStatus {
  @JsonValue('Unclaimed')
  unclaimed,
  @JsonValue('Claimed')
  claimed,
}
