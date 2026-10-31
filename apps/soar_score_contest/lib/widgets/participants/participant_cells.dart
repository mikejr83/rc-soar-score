import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/participants/participant_option.dart';
import '../../services/participants/participant_row.dart';
import '../../services/participants/participant_row_style.dart';
import 'cell_focus_registry.dart';
import 'participant_editing.dart';
import 'participant_email_text.dart';
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

  /// How this row is drawn beyond its values.
  ParticipantRowStyle get style => editing.styleOf(participant);

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
    final l10n = AppLocalizations.of(context);
    final icon = switch (status) {
      ParticipantEmailStatus.has => Icons.mail_outline,
      ParticipantEmailStatus.none => Icons.unsubscribe_outlined,
      ParticipantEmailStatus.private => Icons.visibility_off_outlined,
    };
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: status.explanation(l10n),
      child: Row(
        children: [
          Icon(icon, size: prefix ? 14 : 18, color: color),
          SizedBox(width: prefix ? 4 : 6),
          Flexible(
            child: Text(
              prefix ? 'Email: ${status.label(l10n)}' : status.label(l10n),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// Plain text for a cell of a read-only list.
  Widget _plain(BuildContext context, String text, {String? semantics}) {
    final theme = Theme.of(context);
    return Semantics(
      label: semantics,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: text.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
    );
  }

  Widget role(BuildContext context) {
    final roles = editing.roles;
    final rowStyle = style;
    if (rowStyle.readOnly) {
      return _plain(
        context,
        participant.roleName,
        semantics: 'Role for ${participant.name}',
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final known = roles.any((role) => role.id == participant.roleId);
    final edited = rowStyle.changed.contains(ParticipantCell.role);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
    // A pilot with flights cannot become non-flying, and the option says why.
    bool blocked(Role role) =>
        rowStyle.hasFlights && role.type != RoleType.pilot;
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
          border: border(scheme.outline, 1),
          enabledBorder: border(
            edited ? scheme.primary : scheme.outline,
            edited ? 2 : 1,
          ),
          disabledBorder: border(Colors.transparent, 1),
          filled: rowStyle.locked,
          fillColor: scheme.onSurface.withValues(alpha: 0.12),
        ),
        hint: Text(participant.roleName),
        items: [
          for (final role in roles)
            DropdownMenuItem(
              value: role.id,
              enabled: !blocked(role),
              child: Text(
                blocked(role)
                    ? '${role.displayName} (not available: has flights)'
                    : role.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: rowStyle.locked
            ? null
            : (id) {
                final role = roles.firstWhere((role) => role.id == id);
                _update(participant.withEdits(role: role));
              },
      ),
    );
  }

  Widget classification(BuildContext context) {
    final rowStyle = style;
    if (rowStyle.readOnly) {
      return _plain(
        context,
        scoring
            ? (participant.classification.isEmpty
                  ? 'No class'
                  : participant.classification)
            : 'Not scored',
        semantics: 'Class for ${participant.name}',
      );
    }
    return ParticipantTextCell(
      key: ValueKey('class-$_id'),
      value: participant.classification,
      focusNode: _node(ParticipantColumn.classification),
      semanticLabel: 'Class for ${participant.name}',
      enabled: scoring && !rowStyle.locked,
      hint: scoring ? 'Required' : 'Not scored',
      error: issues.contains(ParticipantIssue.classification),
      changed: rowStyle.changed.contains(ParticipantCell.classification),
      suggestions: editing.rules.classes,
      height: height,
      onChanged: (value) =>
          _update(participant.withEdits(classification: value)),
      onCommit: (value) {
        final normalized = titleCase(value);
        if (normalized != participant.classification) {
          _update(participant.withEdits(classification: normalized));
        }
      },
      onSubmitted: () =>
          editing.focus.moveDown(_id, ParticipantColumn.classification),
    );
  }

  Widget team(BuildContext context) {
    final rowStyle = style;
    if (rowStyle.readOnly) {
      return _plain(
        context,
        participant.team.isEmpty ? 'No team' : participant.team,
        semantics: 'Team for ${participant.name}',
      );
    }
    return TeamCell(
      key: ValueKey('team-$_id'),
      value: participant.team,
      teams: editing.rules.teams,
      normalize: editing.rules.normalizeTeam,
      focusNode: _node(ParticipantColumn.team),
      semanticLabel: 'Team for ${participant.name}',
      height: height,
      enabled: !rowStyle.locked,
      changed: rowStyle.changed.contains(ParticipantCell.team),
      onChanged: (team) => _update(participant.withEdits(team: team)),
      onSubmitted: () => editing.focus.moveDown(_id, ParticipantColumn.team),
    );
  }

  /// The Models cell: the pilot's models, or a notice (never an error) that
  /// there are none, with the button that edits them.
  Widget modelsCell(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    if (!scoring) {
      return const SizedBox.shrink();
    }
    final models = participant.models;
    final edit = editing.editModels;
    final text = models.isEmpty
        ? Tooltip(
            message: l10n.modelsCellNoneTooltip,
            child: Text(
              l10n.modelsCellNone,
              key: ValueKey('models-none-$_id'),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          )
        : Text(
            models.map((model) => model.label).join(', '),
            key: ValueKey('models-$_id'),
            style: theme.textTheme.bodySmall,
          );
    return Row(
      children: [
        Flexible(child: text),
        if (edit != null)
          IconButton(
            key: ValueKey('edit-models-$_id'),
            tooltip: l10n.modelsEditTooltip(participant.name),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              models.isEmpty ? Icons.add : Icons.edit_outlined,
              size: 18,
            ),
            onPressed: style.locked ? null : () => edit(participant),
          ),
      ],
    );
  }

  Widget number(BuildContext context) => Text(
    editing.rules.numberLabel(participant),
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  /// The row's status: what the page says about it, or in the wizard Ready,
  /// Non-flying, or what the row needs (icon and text, not color alone).
  Widget status(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final custom = style.status;
    if (custom != null && custom.text.isEmpty) {
      return SizedBox.shrink(key: ValueKey('status-$_id'));
    }
    final (icon, text, color) = custom != null
        ? (
            custom.icon,
            custom.text,
            switch (custom.tone) {
              ParticipantStatusTone.neutral => scheme.onSurfaceVariant,
              ParticipantStatusTone.primary => scheme.primary,
              ParticipantStatusTone.success => scheme.secondary,
              ParticipantStatusTone.warning => scheme.tertiary,
              ParticipantStatusTone.error => scheme.error,
            },
          )
        : !scoring
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
        if (custom?.busy ?? false)
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
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

  /// The name, with a `Has flights` marker for a pilot who has scores.
  Widget nameBlock(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          participant.name,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        if (style.hasFlights)
          Row(
            key: ValueKey('flights-$_id'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flight, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Has flights',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
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
