import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/workspace/workspace_control.dart';
import '../../services/workspace/workspace_control_target.dart';

/// How long a control stays highlighted after the status panel sent the
/// director to it.
const Duration workspaceHighlightDuration = Duration(milliseconds: 2500);

/// Takes the director to a control card: scrolls it into view, moves focus to
/// its first action and highlights it for [workspaceHighlightDuration].
///
/// The page owns one and hands each [WorkspaceControlSlot] its [anchorFor] and
/// [nodeFor]. The highlight is the slot's `highlighted` look, so it is not
/// colour alone; the focus ring stays after the highlight fades.
class WorkspaceFocusController extends ChangeNotifier {
  final Map<WorkspaceControl, GlobalKey> _anchors = {};
  final Map<WorkspaceControl, FocusNode> _nodes = {};
  Timer? _timer;
  WorkspaceControl? _highlighted;

  /// The control that is highlighted now, if any.
  WorkspaceControl? get highlighted => _highlighted;

  /// The key of [control]'s card, for scrolling to it.
  GlobalKey anchorFor(WorkspaceControl control) =>
      _anchors.putIfAbsent(control, GlobalKey.new);

  /// The focus scope around [control]'s card.
  FocusNode nodeFor(WorkspaceControl control) => _nodes.putIfAbsent(
    control,
    () => FocusNode(debugLabel: 'workspace-${control.id}'),
  );

  /// Scrolls to [target]'s control, focuses it and highlights it. Returns
  /// `false`, changing nothing, when the control is not on the page.
  ///
  /// With [animate] false (reduced motion) the scroll jumps.
  bool focus(WorkspaceControlTarget target, {required bool animate}) {
    final control = target.control;
    final context = anchorFor(control).currentContext;
    if (context == null) {
      return false;
    }
    Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeInOut,
    );
    final node = nodeFor(control);
    final firstAction = node.traversalDescendants.firstOrNull;
    // A card with no action to focus (a disabled control) takes the focus
    // itself, so its reason text is what a screen reader says.
    (firstAction ?? node).requestFocus();
    _highlight(control);
    return true;
  }

  void _highlight(WorkspaceControl control) {
    _timer?.cancel();
    _highlighted = control;
    notifyListeners();
    _timer = Timer(workspaceHighlightDuration, () {
      _highlighted = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}
