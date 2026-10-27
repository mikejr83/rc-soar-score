import 'package:flutter/foundation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/participants/participant_row.dart';
import '../../services/participants/participant_row_style.dart';
import 'cell_focus_registry.dart';

/// What the participant table and cards need to show and edit the rows.
class ParticipantEditing {
  const ParticipantEditing({
    required this.rules,
    required this.roles,
    required this.focus,
    required this.selected,
    required this.onToggleSelected,
    required this.onUpdate,
    this.styleOf = _plainStyle,
  });

  static ParticipantRowStyle _plainStyle(ParticipantRow row) =>
      const ParticipantRowStyle();

  final ParticipantListRules rules;

  /// The configured roles (Pilot first).
  final List<Role> roles;

  final CellFocusRegistry focus;

  /// Selected rows, by [ParticipantRow.rowId].
  final Set<String> selected;
  final ValueChanged<ParticipantRow> onToggleSelected;

  /// Replaces a row (matched by [ParticipantRow.rowId]).
  final ValueChanged<ParticipantRow> onUpdate;

  /// How each row is drawn beyond its values (edited cells, state, locks).
  final ParticipantRowStyle Function(ParticipantRow row) styleOf;
}
