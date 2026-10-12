import 'package:flutter/material.dart';

import '../../../services/workspace/next_step/next_step.dart';
import '../../../services/workspace/next_step/next_step_action.dart';
import '../../../services/workspace/next_step/next_step_target.dart';
import '../../../services/workspace/next_step/next_step_text.dart';
import 'next_step_icons.dart';

/// The words a screen reader says for [action]: scoring buttons name the
/// round and group they open at.
String nextStepActionLabel(NextStepAction action) {
  final round = action.round;
  if (action.target != NextStepTarget.scoring ||
      round == null ||
      action.label.toLowerCase().contains('round')) {
    return action.label;
  }
  final group = action.group;
  return group == null
      ? '${action.label} at round $round'
      : '${action.label} at round $round, group ${NextStepText.group(group)}';
}

/// The primary filled button and the optional secondary text button of a
/// step. They wrap below the text at narrow widths.
class NextStepButtons extends StatelessWidget {
  const NextStepButtons({
    super.key,
    required this.step,
    required this.busy,
    required this.onPressed,
  });

  final NextStep step;

  /// True while the primary button's in-place action runs; taps are ignored.
  final bool busy;

  final void Function(NextStepAction action) onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = step.primary;
    final secondary = step.secondary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _primary(primary),
        if (secondary != null) _secondary(secondary),
      ],
    );
  }

  Widget _primary(NextStepAction action) {
    final icon = nextStepTargetIcon(action.target);
    final enabled = action.enabled && !busy;
    final Widget label = Text(
      busy ? (action.busyLabel ?? action.label) : action.label,
    );
    final Widget button = FilledButton.icon(
      key: const ValueKey('next-step-primary'),
      onPressed: enabled ? () => onPressed(action) : null,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: label,
    );
    return Semantics(
      container: true,
      label: nextStepActionLabel(action),
      hint: action.enabled ? null : _disabledHint(action),
      excludeSemantics: true,
      button: true,
      focusable: true,
      enabled: enabled,
      onTap: enabled ? () => onPressed(action) : null,
      child: button,
    );
  }

  // The reason stays visible and is part of the button's hint, so a screen
  // reader says why the button is off.
  String? _disabledHint(NextStepAction action) {
    final parts = [
      if (step.reason != null) '${step.reason!.lead} ${step.reason!.text}',
      ?action.disabledNote,
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  Widget _secondary(NextStepAction action) => Semantics(
    container: true,
    label: nextStepActionLabel(action),
    excludeSemantics: true,
    button: true,
    focusable: true,
    enabled: !busy,
    onTap: busy ? null : () => onPressed(action),
    child: TextButton(
      key: const ValueKey('next-step-secondary'),
      onPressed: busy ? null : () => onPressed(action),
      child: Text(action.label),
    ),
  );
}
