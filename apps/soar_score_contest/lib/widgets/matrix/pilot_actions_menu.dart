import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The pilot actions menu on the highlighted pilot. Move is shown off, with
/// the reason beside it, when the contest does not allow it.
class PilotActionsMenu extends StatelessWidget {
  const PilotActionsMenu({
    super.key,
    required this.onMove,
    required this.block,
  });

  final VoidCallback onMove;
  final String? block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopupMenuButton<void>(
      key: const ValueKey('pilot-actions'),
      tooltip: l10n.matrixPilotActions,
      padding: EdgeInsets.zero,
      iconSize: 18,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          key: const ValueKey('pilot-action-move'),
          enabled: block == null,
          onTap: onMove,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.matrixMoveMenu),
              if (block != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    block!,
                    key: const ValueKey('pilot-action-move-reason'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
