import 'package:flutter/material.dart';

import '../../services/configuration/draw_readiness.dart';

/// `Save configuration` and `Draw matrix`, kept apart: saving never draws.
class ConfigurationActionBar extends StatelessWidget {
  const ConfigurationActionBar({
    super.key,
    required this.canSave,
    required this.saving,
    required this.onSave,
    required this.drawReadiness,
    required this.onDraw,
    this.problem,
  });

  final bool canSave;
  final bool saving;
  final VoidCallback onSave;
  final DrawReadiness drawReadiness;
  final VoidCallback onDraw;

  /// Why the edited options cannot be saved, when they cannot.
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              key: const ValueKey('save-configuration'),
              onPressed: canSave && !saving ? onSave : null,
              child: Text(saving ? 'Saving…' : 'Save configuration'),
            ),
            OutlinedButton(
              key: const ValueKey('draw-matrix'),
              onPressed: drawReadiness.enabled ? onDraw : null,
              child: const Text('Draw matrix'),
            ),
          ],
        ),
        if (problem != null) ...[
          const SizedBox(height: 8),
          Text(problem!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        for (final reason in drawReadiness.reasons)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Draw matrix: $reason',
              key: const ValueKey('draw-reason'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
