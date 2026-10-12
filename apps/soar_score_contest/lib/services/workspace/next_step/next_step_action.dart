import 'package:equatable/equatable.dart';

import 'next_step_target.dart';

/// A button on the next-step card.
class NextStepAction extends Equatable {
  const NextStepAction({
    required this.label,
    required this.target,
    this.round,
    this.group,
    this.enabled = true,
    this.disabledNote,
    this.busyLabel,
  });

  final String label;
  final NextStepTarget target;

  /// For [NextStepTarget.scoring] and [NextStepTarget.matrix]: the round
  /// ordinal to open at, when there is one.
  final int? round;

  /// For [NextStepTarget.scoring]: the group number (1 is group A).
  final int? group;

  final bool enabled;

  /// Why the button is disabled, when it is.
  final String? disabledNote;

  /// The label while an in-place action runs.
  final String? busyLabel;

  @override
  List<Object?> get props => [
    label,
    target,
    round,
    group,
    enabled,
    disabledNote,
    busyLabel,
  ];
}
