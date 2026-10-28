import 'package:flutter/material.dart';

import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/draft_validation.dart';
import '../../services/participants/participant_option.dart';
import 'participant_option_tile.dart';

/// Step 3: the options that define contest-specific participant data. Each
/// option says how it changes the Participants step, Teams reveals its
/// required count, and a preview lists the resulting columns.
class ParticipantOptionsStep extends StatefulWidget {
  const ParticipantOptionsStep({
    super.key,
    required this.draft,
    required this.onToggle,
    required this.onTeamPilotCount,
    required this.teamPilotCountFocus,
    required this.showErrors,
  });

  final ContestDraft draft;

  /// Called when an option's switch is flipped (the page confirms turning
  /// Teams off when it would remove values).
  final void Function(ParticipantOption option, bool value) onToggle;

  final ValueChanged<String> onTeamPilotCount;
  final FocusNode teamPilotCountFocus;
  final bool showErrors;

  @override
  State<ParticipantOptionsStep> createState() => _ParticipantOptionsStepState();
}

class _ParticipantOptionsStepState extends State<ParticipantOptionsStep> {
  late final TextEditingController _teamPilotCount = TextEditingController(
    text: widget.draft.teamPilotCount,
  );

  @override
  void didUpdateWidget(ParticipantOptionsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A copy source can change the count while this step is open.
    if (widget.draft.teamPilotCount != _teamPilotCount.text) {
      _teamPilotCount.text = widget.draft.teamPilotCount;
    }
  }

  @override
  void dispose() {
    _teamPilotCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final draft = widget.draft;
    final countError = widget.showErrors
        ? DraftValidation.teamPilotCount(draft)
        : null;

    Widget panel(Widget child) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );

    Widget note(IconData icon, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );

    Widget? details(ParticipantOption option) {
      if (option == ParticipantOption.teams) {
        return panel(
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  key: const ValueKey('team-pilot-count'),
                  controller: _teamPilotCount,
                  focusNode: widget.teamPilotCountFocus,
                  keyboardType: TextInputType.number,
                  onChanged: widget.onTeamPilotCount,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Pilots counted for team score *',
                    helperText: 'Best N pilots per team make the team score.',
                    errorText: countError,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: note(
                    Icons.shield_outlined,
                    'Team protection is now available in Draw options. It '
                    'keeps teammates out of the same group.',
                  ),
                ),
              ),
            ],
          ),
        );
      }
      final text = option.note;
      return text == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: note(Icons.info_outline, text),
            );
    }

    final columns = <(IconData, String, String)>[
      (Icons.person_outline, 'Name', ''),
      (Icons.mail_outline, 'Email', ''),
      if (draft.has(ParticipantOption.roles))
        (Icons.badge_outlined, 'Role', ''),
      if (draft.has(ParticipantOption.classes))
        (Icons.workspace_premium_outlined, 'Class', 'required'),
      if (draft.has(ParticipantOption.teams))
        (Icons.diversity_3, 'Team', 'optional'),
      if (draft.has(ParticipantOption.pilotNumbers))
        (Icons.pin_outlined, 'Pilot no.', 'provisional'),
      if (draft.has(ParticipantOption.models))
        (Icons.flight, 'Models', 'not recorded yet'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: 'Participant options',
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            // color: scheme.surfaceContainerLow,
            child: Column(
              children: [
                for (final (index, option)
                    in ParticipantOption.values.indexed) ...[
                  if (index > 0)
                    Divider(height: 1, color: scheme.outlineVariant),
                  ParticipantOptionTile(
                    option: option,
                    value: draft.has(option),
                    fromSource: draft.optionsFromSource.contains(option),
                    onChanged: (value) => widget.onToggle(option, value),
                    details: details(option),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          container: true,
          label: 'Columns preview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Columns in the Participants step',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (icon, label, requirement) in columns)
                    Chip(
                      avatar: Icon(icon, size: 18),
                      label: Text.rich(
                        TextSpan(
                          text: label,
                          children: [
                            if (requirement.isNotEmpty)
                              TextSpan(
                                text: ' $requirement',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
