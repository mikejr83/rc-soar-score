import 'package:flutter/material.dart';

import '../../services/participants/participant_storage.dart';
import 'participant_storage_chip.dart';

/// The title block above the form: an avatar (edit only), the title, a
/// sentence under it and, for a stored participant, where it is kept.
class EditorHeader extends StatelessWidget {
  const EditorHeader({
    required this.title,
    required this.subtitle,
    this.initials,
    this.storage,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? initials;
  final ParticipantStorage? storage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        if (initials != null)
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(initials!, style: theme.textTheme.headlineSmall),
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineMedium),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (storage != null) ParticipantStorageChip(storage!),
      ],
    );
  }
}
