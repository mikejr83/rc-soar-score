import 'package:flutter/material.dart';

import '../../services/participants/participant_storage.dart';

/// Where a stored participant lives: synced, or only on this device.
class ParticipantStorageChip extends StatelessWidget {
  const ParticipantStorageChip(this.storage, {super.key});

  final ParticipantStorage storage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'Storage: ${storage.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              storage == ParticipantStorage.synced
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              storage.label,
              style: theme.textTheme.labelLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
