import 'package:flutter/material.dart';

import '../participants/participant_row.dart';
import '../participants/participant_row_style.dart';
import 'participants_controller.dart';
import 'row_outcome.dart';
import 'stored_participant.dart';

/// How the Participants page draws each row: its edited cells, state, the
/// note under it and what is locked.
extension ParticipantsRowStyles on ParticipantsController {
  ParticipantRowStyle styleOf(ParticipantRow base) {
    final row = base as StoredParticipant;
    final id = row.rowId;
    final changed = cellsChanged(id);
    final state = stateOf(id);
    final scoring = rules.isScoring(row);
    final invalid = changed.isNotEmpty && isInvalid(row);

    ParticipantRowNote? note;
    if (invalid && teamTooLong(row)) {
      note = ParticipantRowNote(
        tone: ParticipantNoteTone.error,
        text:
            'Team names can be up to ${ParticipantsController.maxTeamName} '
            'characters. This one has ${row.team.trim().length}.',
      );
    } else if (state.outcome == RowOutcome.failed) {
      note = ParticipantRowNote(
        tone: ParticipantNoteTone.error,
        text: 'Not saved. ${state.message ?? ''}'.trim(),
        actionLabel: 'Undo row changes',
        actionIcon: Icons.undo,
        onAction: () => undoRow(id),
      );
    } else if (state.outcome == RowOutcome.stale) {
      note = ParticipantRowNote(
        tone: ParticipantNoteTone.warning,
        text:
            'This participant was changed elsewhere. Refresh to see the '
            'latest.',
        actionLabel: 'Refresh',
        actionIcon: Icons.refresh,
        onAction: () => refreshRow(id),
      );
    }

    final ParticipantStatus? status;
    if (saving && changed.isNotEmpty) {
      status = const ParticipantStatus(
        'Saving…',
        Icons.sync,
        tone: ParticipantStatusTone.primary,
        busy: true,
      );
    } else if (invalid) {
      status = ParticipantStatus(
        teamTooLong(row) ? 'Fix team' : 'Needs class',
        Icons.error,
        tone: ParticipantStatusTone.error,
      );
    } else if (state.outcome == RowOutcome.failed) {
      status = const ParticipantStatus(
        'Not saved',
        Icons.error,
        tone: ParticipantStatusTone.error,
      );
    } else if (state.outcome == RowOutcome.stale) {
      status = const ParticipantStatus(
        'Changed elsewhere',
        Icons.sync_problem,
        tone: ParticipantStatusTone.warning,
      );
    } else if (changed.isNotEmpty) {
      status = const ParticipantStatus(
        'Unsaved',
        Icons.edit,
        tone: ParticipantStatusTone.primary,
      );
    } else if (state.outcome == RowOutcome.added) {
      status = ParticipantStatus(
        state.late ? 'Added late' : 'Added',
        Icons.person_add,
        tone: ParticipantStatusTone.primary,
      );
    } else if (state.outcome == RowOutcome.saved) {
      status = const ParticipantStatus(
        'Saved',
        Icons.check_circle,
        tone: ParticipantStatusTone.success,
      );
    } else if (!scoring) {
      status = const ParticipantStatus('Non-flying', Icons.badge);
    } else if (rules.issuesOf(row).isNotEmpty) {
      status = const ParticipantStatus(
        'Needs class',
        Icons.error,
        tone: ParticipantStatusTone.error,
      );
    } else {
      status = const ParticipantStatus('', Icons.circle);
    }

    return ParticipantRowStyle(
      changed: changed,
      highlighted: id == highlightId || state.outcome == RowOutcome.added,
      status: status,
      note: note,
      locked: saving || adminLocked,
      lockedReason: adminLocked
          ? 'Administration is locked. Unlock to change.'
          : null,
      readOnly: readOnly,
      hasFlights: hasFlights(row),
      notPlaced: drawn && scoring && row.number == null,
    );
  }
}
