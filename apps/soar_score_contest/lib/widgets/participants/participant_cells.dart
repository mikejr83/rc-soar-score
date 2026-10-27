import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/participants/participant_option.dart';
import '../../services/participants/participant_row.dart';
import 'cell_focus_registry.dart';
import 'participant_editing.dart';
import 'participant_text_cell.dart';
import 'team_cell.dart';

/// Builds the cells of one participant row, shared by the wide table and
/// the narrow cards so both edit the same way.
class ParticipantCells {
  ParticipantCells(this.editing, this.participant, {this.height = 40});

  final ParticipantEditing editing;
  final ParticipantRow participant;

  /// The input height (taller on the touch-first cards).
  final double height;

  String get _id => participant.rowId;

  bool get scoring => editing.rules.isScoring(participant);

  List<ParticipantIssue> get issues => editing.rules.issuesOf(participant);

  bool get selected => editing.selected.contains(_id);

  FocusNode _node(ParticipantColumn column) => editing.focus.node(_id, column);

  void _update(ParticipantRow updated) => editing.onUpdate(updated);

  Widget checkbox() => Checkbox(
    value: selected,
    semanticLabel: 'Select ${participant.name}',
    onChanged: (_) => editing.onToggleSelected(participant),
  );

  Widget avatar(BuildContext context, {double size = 32}) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(
        initials(participant.name),
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// The email as a status: the address is never shown (the profile has
  /// it).
  Widget emailCell(BuildContext context, {bool prefix = false}) {
    final status = participant.emailStatus;
    final icon = switch (status) {
      ParticipantEmailStatus.has => Icons.mail_outline,
      ParticipantEmailStatus.none => Icons.unsubscribe_outlined,
      ParticipantEmailStatus.private => Icons.visibility_off_outlined,
    };
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: status.explanation,
      child: Row(
        children: [
          Icon(icon, size: prefix ? 14 : 18, color: color),
          SizedBox(width: prefix ? 4 : 6),
          Flexible(
            child: Text(
              prefix ? 'Email: ${status.label}' : status.label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget role(BuildContext context) {
    final roles = editing.roles;
    final known = roles.any((role) => role.id == participant.roleId);
    return Semantics(
      label: 'Role for ${participant.name}',
      child: DropdownButtonFormField<Id>(
        key: ValueKey('role-$_id'),
        initialValue: known ? participant.roleId : null,
        focusNode: _node(ParticipantColumn.role),
        isExpanded: true,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          constraints: BoxConstraints.tightFor(height: height),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        hint: Text(participant.roleName),
        items: [
          for (final role in roles)
            DropdownMenuItem(
              value: role.id,
              child: Text(role.displayName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (id) {
          final role = roles.firstWhere((role) => role.id == id);
          _update(participant.withEdits(role: role));
        },
      ),
    );
  }

  Widget classification() => ParticipantTextCell(
    key: ValueKey('class-$_id'),
    value: participant.classification,
    focusNode: _node(ParticipantColumn.classification),
    semanticLabel: 'Class for ${participant.name}',
    enabled: scoring,
    hint: scoring ? 'Required' : 'Not scored',
    error: issues.contains(ParticipantIssue.classification),
    suggestions: editing.rules.classes,
    height: height,
    onChanged: (value) => _update(participant.withEdits(classification: value)),
    onCommit: (value) {
      final normalized = titleCase(value);
      if (normalized != participant.classification) {
        _update(participant.withEdits(classification: normalized));
      }
    },
    onSubmitted: () =>
        editing.focus.moveDown(_id, ParticipantColumn.classification),
  );

  Widget team() => TeamCell(
    key: ValueKey('team-$_id'),
    value: participant.team,
    teams: editing.rules.teams,
    normalize: editing.rules.normalizeTeam,
    focusNode: _node(ParticipantColumn.team),
    semanticLabel: 'Team for ${participant.name}',
    height: height,
    onChanged: (team) => _update(participant.withEdits(team: team)),
    onSubmitted: () => editing.focus.moveDown(_id, ParticipantColumn.team),
  );

  /// The Models cell until models can be recorded: plain text, not
  /// focusable, and not an error.
  Widget modelsCell(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    if (!scoring) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: 'Model details can’t be recorded yet.',
      child: ExcludeFocus(
        child: Row(
          key: ValueKey('models-$_id'),
          children: [
            Icon(Icons.edit_off_outlined, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'No models information entered.',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget number(BuildContext context) => Text(
    editing.rules.numberLabel(participant),
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  /// Ready, Non-flying, or what the row needs (icon and text, not color
  /// alone).
  Widget status(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, text, color) = !scoring
        ? (Icons.badge, 'Non-flying', scheme.onSurfaceVariant)
        : issues.isNotEmpty
        ? (
            Icons.error,
            'Needs ${issues.map((issue) => issue.label).join(', ')}',
            scheme.error,
          )
        : (Icons.check_circle, 'Ready', scheme.secondary);
    return Row(
      key: ValueKey('status-$_id'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  /// The optional columns this draft shows, in order.
  static List<ParticipantOption> columnsFor(ParticipantEditing editing) => [
    for (final option in [
      ParticipantOption.roles,
      ParticipantOption.classes,
      ParticipantOption.teams,
      ParticipantOption.pilotNumbers,
      ParticipantOption.models,
    ])
      if (editing.rules.has(option)) option,
  ];
}
