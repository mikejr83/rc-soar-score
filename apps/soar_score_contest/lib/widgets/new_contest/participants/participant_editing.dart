import 'package:flutter/foundation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/new_contest/contest_draft.dart';
import '../../../services/new_contest/draft_participant.dart';
import 'cell_focus_registry.dart';

/// What the participant table and cards need to show and edit the rows.
class ParticipantEditing {
  const ParticipantEditing({
    required this.draft,
    required this.roles,
    required this.focus,
    required this.selected,
    required this.onToggleSelected,
    required this.onUpdate,
  });

  final ContestDraft draft;

  /// The configured roles (Pilot first).
  final List<Role> roles;

  final CellFocusRegistry focus;

  /// Selected rows, by profile id.
  final Set<String> selected;
  final ValueChanged<DraftParticipant> onToggleSelected;

  /// Replaces a row (matched by profile id).
  final ValueChanged<DraftParticipant> onUpdate;
}
