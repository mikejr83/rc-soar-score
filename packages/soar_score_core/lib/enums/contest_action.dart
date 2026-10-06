import 'package:json_annotation/json_annotation.dart';

/// A director action that changes a contest's lifecycle or controls.
///
/// Actions that other work causes (reaching `Configuring`, `Ready` and
/// `Running`) are not listed: configuration, the matrix and the first score
/// make those transitions themselves. See
/// `plan/architecture-requirements/contest-state-and-transitions.md`.
enum ContestAction {
  @JsonValue('complete')
  complete,
  @JsonValue('openScoring')
  openScoring,
  @JsonValue('closeScoring')
  closeScoring,
  @JsonValue('lock')
  lock,
  @JsonValue('unlock')
  unlock,
}
