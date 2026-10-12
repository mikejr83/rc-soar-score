import 'package:equatable/equatable.dart';

import 'next_step_tone.dart';

/// The line under a step that says why it is the step: a bold [lead] and
/// then [text].
class NextStepReason extends Equatable {
  const NextStepReason({
    required this.lead,
    required this.text,
    required this.tone,
  });

  final String lead;
  final String text;
  final NextStepTone tone;

  @override
  List<Object?> get props => [lead, text, tone];
}
