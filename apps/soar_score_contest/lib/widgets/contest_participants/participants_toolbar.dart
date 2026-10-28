import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/contest_participants/participants_controller.dart';
import '../../services/participants/participant_candidate.dart';
import '../participants/participant_search_field.dart';

/// Everything above the list acts at once: the search field (which filters
/// the list and offers saved profiles to add), Add participant and Remove.
/// Edits made in the list wait behind the Save bar below it.
class ParticipantsToolbar extends StatelessWidget {
  const ParticipantsToolbar({
    super.key,
    required this.controller,
    required this.narrow,
    required this.onAddNew,
    required this.onAddProfile,
    required this.onRemove,
  });

  final ParticipantsController controller;
  final bool narrow;
  final VoidCallback onAddNew;
  final ValueChanged<ParticipantProfile> onAddProfile;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = controller;
    final canAdd = c.canEdit && !c.saving;
    final selected = c.selection.length;
    final removeOff =
        !c.canEdit || c.saving || selected == 0 || c.selectionHasFlights;

    final search = ParticipantSearchField(
      // Without the right to add, the field only filters the list.
      profiles: canAdd ? c.profiles : const [],
      selected: c.memberProfileIds,
      offline: false,
      onQueryChanged: c.setQuery,
      onAdd: (ParticipantCandidate candidate) {
        final profile = c.profiles
            .where((p) => p.id == candidate.profileId)
            .firstOrNull;
        if (profile != null) onAddProfile(profile);
      },
    );
    // While edits wait for Save, Add steps down so Save is the only filled
    // action.
    final add = SizedBox(
      height: 56,
      child: c.hasUnsaved
          ? FilledButton.tonalIcon(
              key: const ValueKey('add-participant-new'),
              onPressed: canAdd ? onAddNew : null,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add participant'),
            )
          : FilledButton.icon(
              key: const ValueKey('add-participant-new'),
              onPressed: canAdd ? onAddNew : null,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add participant'),
            ),
    );
    final remove = SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        key: const ValueKey('remove-participants'),
        onPressed: removeOff ? null : onRemove,
        icon: const Icon(Icons.person_remove_outlined),
        label: Text(selected == 0 ? 'Remove' : 'Remove $selected'),
      ),
    );
    final reason = !c.canEdit
        ? null
        : c.selectionHasFlights
        ? 'The selection contains a pilot with flights, so it can’t be '
              'removed. Deselect them to remove the others, or retire pilots '
              'in Scoring.'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.readOnly)
          search
        else if (narrow) ...[
          search,
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [add, remove]),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              add,
              const SizedBox(width: 12),
              remove,
            ],
          ),
        if (reason != null) ...[
          const SizedBox(height: 8),
          Row(
            key: const ValueKey('remove-reason'),
            children: [
              Icon(Icons.block, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(child: Text(reason, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ],
      ],
    );
  }
}
