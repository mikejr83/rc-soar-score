import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_search.dart';

/// A circular avatar showing the initials of [profile].
class ParticipantAvatar extends StatelessWidget {
  const ParticipantAvatar({super.key, required this.profile, this.radius = 20});

  final ParticipantProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(
        '${profile.firstName[0]}${profile.lastName[0]}'.toUpperCase(),
      ),
    );
  }
}

/// The master pane of the participant page: title and count, a search box
/// and the matching participants. A row shows the full name with the email
/// below it; the row for [selectedId] is highlighted when [highlight] is set.
class ParticipantListPane extends StatelessWidget {
  const ParticipantListPane({
    super.key,
    required this.participants,
    required this.search,
    required this.onSearch,
    required this.selectedId,
    required this.highlight,
    required this.onSelect,
  });

  /// Every participant, already sorted.
  final List<ParticipantProfile> participants;
  final String search;
  final ValueChanged<String> onSearch;
  final Id? selectedId;
  final bool highlight;
  final ValueChanged<ParticipantProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = [
      for (final profile in participants)
        if (matchesParticipantSearch(profile, search)) profile,
    ];
    final count = matches.length == participants.length
        ? '${participants.length}'
        : '${matches.length} of ${participants.length}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Participants', style: theme.textTheme.titleLarge),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '$count participants',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            key: const ValueKey('participant-search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name, email, FAI number or national ID',
            ),
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: matches.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No participants match.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final profile = matches[index];
                    final email = profile.email;
                    return ListTile(
                      key: ValueKey('participant-${profile.id.value}'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      selected: highlight && profile.id == selectedId,
                      selectedTileColor: theme.colorScheme.secondaryContainer,
                      leading: ParticipantAvatar(profile: profile),
                      title: Text('${profile.firstName} ${profile.lastName}'),
                      subtitle: email == null || email.isEmpty
                          ? null
                          : Text(email),
                      onTap: () => onSelect(profile),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
