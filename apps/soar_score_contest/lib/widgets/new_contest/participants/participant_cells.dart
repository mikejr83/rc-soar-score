import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/new_contest/draft_participant.dart';
import '../../../services/new_contest/participant_option.dart';
import '../../../services/new_contest/participant_rules.dart';
import 'cell_focus_registry.dart';
import 'participant_editing.dart';
import 'participant_text_cell.dart';
import 'team_cell.dart';

/// Builds the cells of one participant row, shared by the wide table and
/// the narrow cards so both edit the same way.
class ParticipantCells {
  ParticipantCells(this.editing, this.participant, {this.height = 40});

  final ParticipantEditing editing;
  final DraftParticipant participant;

  /// The input height (taller on the touch-first cards).
  final double height;

  String get _id => participant.profileId.value;

  bool get scoring => editing.draft.isScoring(participant);

  List<ParticipantIssue> get issues => editing.draft.issuesOf(participant);

  bool get selected => editing.selected.contains(_id);

  FocusNode _node(ParticipantColumn column) => editing.focus.node(_id, column);

  void _update(DraftParticipant updated) => editing.onUpdate(updated);

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

  /// The email as the director may see it: always for their own profiles,
  /// for remote profiles only when the person allows it.
  (IconData, String, String) get email {
    final address = participant.email;
    if (participant.source == ParticipantSource.remote &&
        !participant.emailVisible) {
      return (
        Icons.visibility_off_outlined,
        'Hidden',
        'Remote profile. This person hasn’t allowed their email to be shown.',
      );
    }
    if (address == null || address.isEmpty) {
      return (Icons.unsubscribe_outlined, 'None', 'No email entered');
    }
    return participant.source == ParticipantSource.remote
        ? (
            Icons.cloud_outlined,
            address,
            'Remote profile. Shown with permission.',
          )
        : (Icons.mail_outline, address, 'From your participant profiles');
  }

  Widget emailCell(BuildContext context, {bool prefix = false}) {
    final (icon, text, explanation) = email;
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: explanation,
      child: Row(
        children: [
          Icon(icon, size: prefix ? 14 : 18, color: color),
          SizedBox(width: prefix ? 4 : 6),
          Flexible(
            child: Text(
              prefix ? 'Email: $text' : text,
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
          _update(participant.copyWith(role: role));
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
    suggestions: editing.draft.classes,
    height: height,
    onChanged: (value) => _update(participant.copyWith(classification: value)),
    onCommit: (value) {
      final normalized = titleCase(value);
      if (normalized != participant.classification) {
        _update(participant.copyWith(classification: normalized));
      }
    },
    onSubmitted: () =>
        editing.focus.moveDown(_id, ParticipantColumn.classification),
  );

  Widget team() => TeamCell(
    key: ValueKey('team-$_id'),
    value: participant.team,
    teams: editing.draft.teams,
    normalize: editing.draft.normalizeTeam,
    focusNode: _node(ParticipantColumn.team),
    semanticLabel: 'Team for ${participant.name}',
    height: height,
    onChanged: (team) => _update(participant.copyWith(team: team)),
    onSubmitted: () => editing.focus.moveDown(_id, ParticipantColumn.team),
  );

  bool get _modelError => issues.contains(ParticipantIssue.model);

  Widget model() => ParticipantTextCell(
    key: ValueKey('model-$_id'),
    value: participant.model,
    focusNode: _node(ParticipantColumn.model),
    semanticLabel: 'Model name for ${participant.name}',
    enabled: scoring,
    hint: scoring ? 'Required' : '—',
    error: _modelError && participant.model.trim().isEmpty,
    height: height,
    onChanged: (value) => _update(participant.copyWith(model: value)),
    onSubmitted: () => editing.focus.moveDown(_id, ParticipantColumn.model),
  );

  Widget modelId() => ParticipantTextCell(
    key: ValueKey('model-id-$_id'),
    value: participant.modelId,
    focusNode: _node(ParticipantColumn.modelId),
    semanticLabel: 'Model ID for ${participant.name}',
    enabled: scoring,
    hint: scoring ? 'Required' : '—',
    error: _modelError && participant.modelId.trim().isEmpty,
    height: height,
    onChanged: (value) => _update(participant.copyWith(modelId: value)),
    onSubmitted: () => editing.focus.moveDown(_id, ParticipantColumn.modelId),
  );

  /// The provisional pilot number: scoring pilots in list order. Numbers
  /// are assigned at the first draw.
  String get provisionalNumber {
    if (!scoring) {
      return '—';
    }
    final pilots = editing.draft.participants.where(editing.draft.isScoring);
    final index = pilots.toList().indexWhere(
      (p) => p.profileId == participant.profileId,
    );
    return '${index + 1} · provisional';
  }

  Widget number(BuildContext context) => Text(
    provisionalNumber,
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
      if (editing.draft.has(option)) option,
  ];
}
