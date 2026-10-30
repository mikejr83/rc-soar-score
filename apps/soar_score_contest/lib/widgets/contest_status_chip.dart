import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../l10n/app_localizations.dart';
import 'page_states/status_label.dart';

/// The lifecycle state of a contest as an outlined chip with a state icon;
/// a running contest is picked out in the tertiary (amber) colour.
class ContestStatusChip extends StatelessWidget {
  const ContestStatusChip({
    super.key,
    required this.state,
    this.field = 'Lifecycle',
  });

  final LifecycleState state;

  /// What the chip's value is called when spoken, such as `Lifecycle`.
  final String field;

  /// The state's display name, e.g. `Running`.
  static String label(AppLocalizations l10n, LifecycleState state) =>
      switch (state) {
        LifecycleState.created => l10n.lifecycleCreated,
        LifecycleState.configuring => l10n.lifecycleConfiguring,
        LifecycleState.ready => l10n.lifecycleReady,
        LifecycleState.running => l10n.lifecycleRunning,
        LifecycleState.completed => l10n.lifecycleCompleted,
      };

  static IconData _icon(LifecycleState state) => switch (state) {
    LifecycleState.running => Icons.timer,
    LifecycleState.ready => Icons.event_available,
    LifecycleState.configuring => Icons.tune,
    LifecycleState.created => Icons.edit_note,
    LifecycleState.completed => Icons.check_circle,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = label(AppLocalizations.of(context), state);
    final color = switch (state) {
      LifecycleState.running => scheme.tertiary,
      LifecycleState.ready => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
    return StatusLabel(
      field: field,
      value: text,
      child: Chip(
        avatar: Icon(_icon(state), size: 18, color: color),
        label: Text(text),
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: state == LifecycleState.running
              ? scheme.tertiary
              : scheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
