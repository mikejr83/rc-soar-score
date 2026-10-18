import 'package:flutter/material.dart';

import '../../../services/workspace/workspace_control.dart';
import '../workspace_control_slot.dart';

/// The shared layout of a control card: the title, the current value, what the
/// control reaches, and the button with the sentence that explains it when it
/// is disabled.
class ControlCardBody extends StatelessWidget {
  const ControlCardBody({
    super.key,
    required this.control,
    required this.current,
    required this.scope,
    required this.button,
    this.disabledReason,
  });

  final WorkspaceControl control;

  /// The value now, for example `Closed`.
  final String current;

  /// What the control affects.
  final String scope;

  final Widget button;

  /// Shown under the button when it is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = disabledReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(workspaceControlLabel(control), style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text.rich(
          key: ValueKey('control-${control.id}-current'),
          TextSpan(
            children: [
              const TextSpan(text: 'Now: '),
              TextSpan(
                text: current,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(scope, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: button),
        if (reason != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason,
                  key: ValueKey('control-${control.id}-reason'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
