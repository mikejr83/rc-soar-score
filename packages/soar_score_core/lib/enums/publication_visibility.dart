import 'package:json_annotation/json_annotation.dart';

/// Who can find a published contest.
///
/// Serializes as the exact text in `plan/data-model/entities/publication_identity.md`.
enum PublicationVisibility {
  @JsonValue('Unlisted')
  unlisted,
  @JsonValue('Public')
  public,
  @JsonValue('Delisted')
  delisted,
}
