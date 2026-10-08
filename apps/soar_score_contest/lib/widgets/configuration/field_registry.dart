import 'package:flutter/widgets.dart';

/// The keys and focus nodes of the page's settings, so the error summary and
/// the section list can scroll to a setting and focus its control.
class FieldRegistry {
  final Map<String, GlobalKey> _rows = {};
  final Map<String, FocusNode> _focus = {};

  /// The key of the row of setting [key].
  GlobalKey rowKey(String key) => _rows.putIfAbsent(key, GlobalKey.new);

  /// The focus node of the control of setting [key].
  FocusNode focusNode(String key) =>
      _focus.putIfAbsent(key, () => FocusNode(debugLabel: key));

  /// Scrolls to setting [key] and focuses its control.
  void reveal(String key) {
    final context = _rows[key]?.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    ).then((_) => _focus[key]?.requestFocus());
  }

  void dispose() {
    for (final node in _focus.values) {
      node.dispose();
    }
  }
}
