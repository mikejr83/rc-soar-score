import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/contests_view.dart';
import 'status_chip.dart';

/// A contest in the list: name, dates, place and where it stands. Tapping it
/// opens the contest; [onOpenResults], when set, opens the public results.
class ContestCard extends StatelessWidget {
  const ContestCard({
    required this.name,
    required this.dates,
    required this.phase,
    required this.onTap,
    this.location,
    this.onOpenResults,
    this.busy = false,
    super.key,
  });

  final String name;

  /// Already formatted for the language, such as `Sat, Oct 10, 2026 to Sun,
  /// Oct 11, 2026`.
  final String dates;
  final String? location;
  final ContestPhase phase;
  final VoidCallback? onTap;

  /// Null when the contest has no public results.
  final VoidCallback? onOpenResults;

  /// Shows that the contest is being opened.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);
    final (label, icon, style) = switch (phase) {
      ContestPhase.inProgress => (
        l10n.contestPhaseInProgress,
        Icons.flight,
        StatusChipStyle.filled,
      ),
      ContestPhase.invited => (
        l10n.contestPhaseInvited,
        Icons.mail_outline,
        StatusChipStyle.outlined,
      ),
      ContestPhase.completed => (
        l10n.contestPhaseCompleted,
        Icons.check_circle_outline,
        StatusChipStyle.tonal,
      ),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: busy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          dates,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                        if (location != null)
                          Text(
                            location!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(label: label, icon: icon, style: style),
                      const SizedBox(height: 8),
                      if (busy)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      else
                        Icon(Icons.chevron_right, color: muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (onOpenResults != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: TextButton.icon(
                  onPressed: onOpenResults,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.contestPublicResults),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
