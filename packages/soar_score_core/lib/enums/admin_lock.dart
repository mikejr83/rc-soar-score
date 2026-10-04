import 'package:json_annotation/json_annotation.dart';

/// Whether scoring configuration changes are blocked.
///
/// Serializes as the exact text in `plan/data-model/entities/contest.md`.
enum AdminLock {
  @JsonValue('Unlocked')
  unlocked,
  @JsonValue('Locked')
  locked,
}
