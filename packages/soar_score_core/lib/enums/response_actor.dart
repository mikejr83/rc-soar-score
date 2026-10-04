import 'package:json_annotation/json_annotation.dart';

/// Who recorded a re-flight response.
///
/// Serializes as the exact text in `plan/data-model/entities/re_flight_participant.md`.
enum ResponseActor {
  @JsonValue('Participant')
  participant,
  @JsonValue('Director')
  director,
}
