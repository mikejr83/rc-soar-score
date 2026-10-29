import 'package:flutter/material.dart';

/// The cells of a participant row that can be marked as edited.
enum ParticipantCell { role, classification, team }

/// How a row's status is coloured. The icon and the words carry the meaning
/// too, never the colour alone.
enum ParticipantStatusTone { neutral, primary, success, warning, error }

/// A row's status cell: an icon, words and, while a save runs, a spinner.
class ParticipantStatus {
  const ParticipantStatus(
    this.text,
    this.icon, {
    this.tone = ParticipantStatusTone.neutral,
    this.busy = false,
  });

  final String text;
  final IconData icon;
  final ParticipantStatusTone tone;

  /// Shows a spinner instead of [icon].
  final bool busy;
}

/// How a row's note line is coloured.
enum ParticipantNoteTone { error, warning }

/// A full-width line under a row (on a card, at its foot): what went wrong
/// with the row, with one action.
class ParticipantRowNote {
  const ParticipantRowNote({
    required this.text,
    required this.tone,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String text;
  final ParticipantNoteTone tone;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
}

/// How one row is drawn beyond its values: edited cells, its state, whether
/// it can be edited. A list that has no such states leaves the default.
class ParticipantRowStyle {
  const ParticipantRowStyle({
    this.changed = const {},
    this.highlighted = false,
    this.status,
    this.note,
    this.locked = false,
    this.lockedReason,
    this.readOnly = false,
    this.hasFlights = false,
    this.notPlaced = false,
  });

  /// The cells edited since the last save (a 2 px primary outline).
  final Set<ParticipantCell> changed;

  /// A row that was just added (a primary container tint).
  final bool highlighted;

  /// Replaces the wizard's Ready or Needs status.
  final ParticipantStatus? status;

  final ParticipantRowNote? note;

  /// Role, class and team cannot change (administration is locked, or a
  /// save is under way).
  final bool locked;
  final String? lockedReason;

  /// Plain text instead of inputs.
  final bool readOnly;

  /// The pilot has a score: not removable, and no non-flying role.
  final bool hasFlights;

  /// Added after the draw and not in a group yet.
  final bool notPlaced;

  bool get hasChanges => changed.isNotEmpty;
}
