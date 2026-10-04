import 'package:json_annotation/json_annotation.dart';

/// Where a contest is in its execution lifecycle.
///
/// Serializes as the exact text in `plan/data-model/entities/contest.md`.
enum LifecycleState {
  @JsonValue('Created')
  created,
  @JsonValue('Configuring')
  configuring,
  @JsonValue('Ready')
  ready,
  @JsonValue('Running')
  running,
  @JsonValue('Completed')
  completed,
}
