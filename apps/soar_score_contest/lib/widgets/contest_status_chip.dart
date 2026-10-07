import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The lifecycle state of a contest as an outlined chip with a state icon;
/// a running contest is picked out in the tertiary (amber) colour.
class ContestStatusChip extends StatelessWidget {
  const ContestStatusChip({super.key, required this.state});

  final LifecycleState state;

  /// The state's display name, e.g. `Running`.
  static String label(LifecycleState state) =>
      '${state.name[0].toUpperCase()}${state.name.substring(1)}';

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
    final color = switch (state) {
      LifecycleState.running => scheme.tertiary,
      LifecycleState.ready => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
    return Chip(
      avatar: Icon(_icon(state), size: 18, color: color),
      label: Text(label(state)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: state == LifecycleState.running
            ? scheme.tertiary
            : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
