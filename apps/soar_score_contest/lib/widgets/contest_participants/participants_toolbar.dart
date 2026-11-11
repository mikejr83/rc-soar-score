import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/contest_participants/participants_controller.dart';
import '../../services/participants/participant_candidate.dart';
import '../participants/participant_search_field.dart';

/// Search filters the list and offers saved profiles to add; Add participant
/// opens the editor. Both additions take effect immediately.
/// Edits made in the list wait behind the Save bar below it.
class ParticipantsToolbar extends StatelessWidget {
  const ParticipantsToolbar({
    super.key,
    required this.controller,
    required this.narrow,
    required this.onAddNew,
    required this.onAddProfile,
  });

  final ParticipantsController controller;
  final bool narrow;
  final VoidCallback onAddNew;
  final ValueChanged<ParticipantProfile> onAddProfile;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l10n = AppLocalizations.of(context);
    final canAdd = c.canEdit && !c.saving;
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
              label: Text(l10n.shellAddParticipant),
            )
          : FilledButton.icon(
              key: const ValueKey('add-participant-new'),
              onPressed: canAdd ? onAddNew : null,
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.shellAddParticipant),
            ),
    );
    if (c.readOnly) return search;
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [add]),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: search),
        const SizedBox(width: 12),
        add,
      ],
    );
  }
}
