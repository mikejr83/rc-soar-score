import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
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
    this.onSendInvitations,
    this.onCopyLink,
    this.invitationsReason,
    this.sendCount = 0,
  });

  final ParticipantsController controller;
  final bool narrow;
  final VoidCallback onAddNew;
  final ValueChanged<ParticipantProfile> onAddProfile;
  final VoidCallback onRemove;

  /// Sends invitations for the selected pilots that have none; `null` when
  /// that is not possible now ([invitationsReason] says why).
  final VoidCallback? onSendInvitations;

  /// Copies the one selected pilot's link; `null` when not possible now.
  final VoidCallback? onCopyLink;

  /// Why sending is off, in words, or `null`.
  final String? invitationsReason;

  /// How many selected pilots would get an invitation.
  final int sendCount;

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
    final l10n = AppLocalizations.of(context);
    final invitations = SizedBox(
      height: 56,
      child: MenuAnchor(
        menuChildren: [
          MenuItemButton(
            key: const ValueKey('invitations-send'),
            leadingIcon: const Icon(Icons.campaign),
            onPressed: onSendInvitations,
            child: Text(
              sendCount > 0
                  ? l10n.invitationsMenuSendCount(sendCount)
                  : l10n.invitationsMenuSend,
            ),
          ),
          MenuItemButton(
            key: const ValueKey('invitations-copy'),
            leadingIcon: const Icon(Icons.link),
            onPressed: onCopyLink,
            child: Text(l10n.invitationsMenuCopy),
          ),
        ],
        builder: (context, menu, _) => Tooltip(
          message: invitationsReason ?? '',
          child: OutlinedButton.icon(
            key: const ValueKey('invitations-menu'),
            onPressed: () => menu.isOpen ? menu.close() : menu.open(),
            icon: const Icon(Icons.qr_code_2),
            label: Text(l10n.invitationsMenu),
          ),
        ),
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
        if (c.readOnly && narrow) ...[
          // A completed contest changes nothing, but its links stay valid and
          // can still be copied.
          search,
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [invitations]),
        ] else if (c.readOnly)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              invitations,
            ],
          )
        else if (narrow) ...[
          search,
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [add, invitations, remove],
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              add,
              const SizedBox(width: 12),
              invitations,
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
