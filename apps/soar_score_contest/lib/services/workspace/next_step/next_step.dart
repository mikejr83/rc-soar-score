import 'package:equatable/equatable.dart';

import 'next_step_action.dart';
import 'next_step_kind.dart';
import 'next_step_reason.dart';

/// The one step the workspace suggests, with its words.
class NextStep extends Equatable {
  const NextStep({
    required this.kind,
    required this.title,
    required this.body,
    required this.primary,
    this.isSuggestion = false,
    this.reason,
    this.secondary,
    this.note,
  });

  final NextStepKind kind;

  /// A suggestion shows the eyebrow "SUGGESTED NEXT STEP" and can be
  /// dismissed; any other step shows "NEXT STEP".
  final bool isSuggestion;

  final String title;
  final String body;
  final NextStepReason? reason;
  final NextStepAction primary;
  final NextStepAction? secondary;
  final String? note;

  String get eyebrow => isSuggestion ? 'SUGGESTED NEXT STEP' : 'NEXT STEP';

  @override
  List<Object?> get props => [
    kind,
    isSuggestion,
    title,
    body,
    reason,
    primary,
    secondary,
    note,
  ];
}
