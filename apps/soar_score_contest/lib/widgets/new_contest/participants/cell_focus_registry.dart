import 'package:flutter/widgets.dart';

/// An editable column in the participant rows.
enum ParticipantColumn { role, classification, team, model, modelId }

/// Focus nodes for the participant cells, so the validation summary can
/// jump to a cell and Enter can move to the same column in the next row.
class CellFocusRegistry {
  final Map<(String, ParticipantColumn), FocusNode> _nodes = {};

  /// The order of the rows on screen (profile ids), for moving down.
  List<String> rowOrder = const [];

  FocusNode node(String rowId, ParticipantColumn column) => _nodes.putIfAbsent((
    rowId,
    column,
  ), () => FocusNode(debugLabel: '$rowId/${column.name}'));

  /// Focuses [column] in the row below [rowId], if there is one.
  void moveDown(String rowId, ParticipantColumn column) {
    final index = rowOrder.indexOf(rowId);
    if (index >= 0 && index + 1 < rowOrder.length) {
      node(rowOrder[index + 1], column).requestFocus();
    }
  }

  /// Drops the nodes of rows that are gone.
  void retain(Set<String> rowIds) {
    _nodes.removeWhere((key, node) {
      final gone = !rowIds.contains(key.$1);
      if (gone) {
        node.dispose();
      }
      return gone;
    });
  }

  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    _nodes.clear();
  }
}
