import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/preferences/director_time.dart';
import '../../services/sync/refused_change.dart';

/// The changes the service refused: what was changed, when and why.
class RefusedChangesCard extends StatelessWidget {
  const RefusedChangesCard({super.key, required this.changes});

  /// Null while they load.
  final List<RefusedChange>? changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final changes = this.changes;
    return Card(
      key: const ValueKey('refused-changes-card'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.syncRefusedTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            if (changes == null)
              Text(l10n.syncRefusedLoading)
            else if (changes.isEmpty)
              Text(l10n.syncRefusedNone)
            else
              for (final change in changes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_name(context, change.entityType)}, changed '
                        '${DirectorTime.of(context)(change.madeAt)}',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(change.reason),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  /// What the director knows the change as; other types keep their name.
  static String _name(BuildContext context, String entityType) =>
      entityType == 'ScorePromotion'
      ? AppLocalizations.of(context).syncRefusedScorePromotion
      : entityType;
}
