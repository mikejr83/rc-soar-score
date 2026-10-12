import 'package:flutter/material.dart';

import '../../../services/workspace/next_step/next_step_target.dart';
import '../../../services/workspace/next_step/next_step_tone.dart';

/// The icon on a reason line; with the lead text, it keeps the tone from
/// being colour alone.
IconData nextStepToneIcon(NextStepTone tone) => switch (tone) {
  NextStepTone.info => Icons.info_outline,
  NextStepTone.warning => Icons.warning_amber_outlined,
  NextStepTone.blocked => Icons.lock_outline,
  NextStepTone.positive => Icons.task_alt,
};

/// The colour of a reason line, from the theme's roles.
Color nextStepToneColor(ColorScheme scheme, NextStepTone tone) =>
    switch (tone) {
      NextStepTone.info => scheme.primary,
      NextStepTone.warning => scheme.tertiary,
      NextStepTone.blocked => scheme.error,
      NextStepTone.positive => scheme.secondary,
    };

/// The icon on a button, or `null` for a plain text button.
IconData? nextStepTargetIcon(NextStepTarget target) => switch (target) {
  NextStepTarget.configuration => Icons.arrow_forward,
  NextStepTarget.participants => Icons.person_add,
  NextStepTarget.matrix => Icons.grid_view,
  NextStepTarget.openScoring => Icons.how_to_reg,
  NextStepTarget.scoring => Icons.scoreboard,
  NextStepTarget.completeDialog => Icons.flag,
  NextStepTarget.publish => Icons.public,
  NextStepTarget.reports => Icons.summarize,
  NextStepTarget.unlock => Icons.lock_open,
  NextStepTarget.dismissSuggestion => null,
};
