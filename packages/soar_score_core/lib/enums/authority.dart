import 'package:json_annotation/json_annotation.dart';

/// The authority a change or audited action was made under. A local operator acts as [Authority.director].
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum Authority {
  @JsonValue('Director')
  director,
  @JsonValue('Participant')
  participant,
  @JsonValue('Helper')
  helper,
  @JsonValue('System')
  system,
  @JsonValue('Administrator')
  administrator,
}
