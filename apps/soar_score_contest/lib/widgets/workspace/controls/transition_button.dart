import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/workspace/controls/contest_transition.dart';
import '../../../services/workspace/controls/transition_availability.dart';
import '../workspace_scope.dart';
import 'contest_transition_runner.dart';

/// The button of a control card for one [transition]. Disabled, with the
/// reason shown next to it by the card, when the contest's state does not
/// allow the change; busy while it runs.
class TransitionButton extends StatefulWidget {
  const TransitionButton({
    super.key,
    required this.contest,
    required this.transition,
    this.icon,
  });

  final Contest contest;
  final ContestTransition transition;
  final IconData? icon;

  @override
  State<TransitionButton> createState() => _TransitionButtonState();
}

class _TransitionButtonState extends State<TransitionButton> {
  bool _running = false;

  // The revision the change produced; the button stays busy until the page
  // shows it, so the old state cannot be changed twice.
  int? _pendingRevision;

  Future<void> _press() async {
    final scope = WorkspaceScope.of(context);
    if (!await confirmTransition(context, scope, widget.transition) ||
        !mounted) {
      return;
    }
    setState(() {
      _running = true;
    });
    final updated = await runTransition(
      context,
      scope,
      widget.contest,
      widget.transition,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _running = false;
      _pendingRevision = updated?.revision;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transition = widget.transition;
    final pending = _pendingRevision;
    final busy =
        _running || (pending != null && widget.contest.revision < pending);
    final enabled = TransitionAvailability.of(
      widget.contest,
      transition,
    ).enabled;
    final label = busy ? transition.busyLabel : transition.label;
    return FilledButton.tonalIcon(
      key: ValueKey('control-${transition.name}'),
      onPressed: enabled && !busy ? _press : null,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.icon == null
          ? null
          : Icon(widget.icon),
      label: Text(label),
    );
  }
}
