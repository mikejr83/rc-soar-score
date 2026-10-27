import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/matrix/matrix_page_data.dart';
import '../../services/matrix/matrix_rounds_plan.dart';
import 'round_span.dart';

/// The confirmation before a draw: the only dialog on the page. It names the
/// pilots, rounds, groups and configuration revision, and says the matrix
/// can't be undone. Returns whether the director confirmed.
Future<bool> confirmDraw(
  BuildContext context, {
  required MatrixPageData data,
  required int rounds,
  required List<int> sizes,
  required bool seeded,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      Widget item(IconData icon, String text) => Row(
        spacing: 10,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          Expanded(child: Text(text)),
        ],
      );
      return AlertDialog(
        icon: Icon(Icons.grid_view, color: scheme.primary),
        title: const Text('Draw the matrix?', textAlign: TextAlign.center),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              item(
                Icons.groups_outlined,
                '${data.scoringPilots} scoring pilots',
              ),
              item(
                Icons.replay,
                '$rounds ${seeded ? 'preliminary seeded rounds' : 'rounds'}',
              ),
              item(
                Icons.grid_view,
                '${sizes.length} groups per round (${sizes.join(', ')} pilots)',
              ),
              item(
                Icons.history,
                'Configuration revision '
                '${data.configuration?.revisionNumber ?? '–'}',
              ),
              if (data.showNumbers)
                item(
                  Icons.pin_outlined,
                  'Contest pilot numbers are assigned by this draw.',
                ),
              const SizedBox(height: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 20,
                        color: scheme.onTertiaryContainer,
                      ),
                      Expanded(
                        child: Text(
                          'The matrix can’t be undone. Unscored rounds can be '
                          'redrawn afterwards.',
                          style: TextStyle(color: scheme.onTertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-draw'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Draw matrix'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// The confirmation before rounds are added or redrawn. It names the rounds,
/// groups, configuration revision and the matrix revision it changes.
/// Returns whether the director confirmed.
Future<bool> confirmRounds(
  BuildContext context, {
  required MatrixPageData data,
  required MatrixIntent intent,
  required int firstRound,
  required int rounds,
  required List<int> sizes,
}) async {
  final adding = intent == MatrixIntent.addRounds;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      final last = firstRound + rounds - 1;
      Widget item(IconData icon, String text) => Row(
        spacing: 10,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          Expanded(child: Text(text)),
        ],
      );
      return AlertDialog(
        icon: Icon(Icons.grid_view, color: scheme.primary),
        title: Text(
          adding ? l10n.matrixAddConfirmTitle : l10n.matrixRedrawConfirmTitle,
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              item(
                Icons.groups_outlined,
                l10n.matrixConfirmPilots(data.scoringPilots),
              ),
              item(
                Icons.replay,
                adding
                    ? l10n.matrixConfirmAdds(roundSpan(l10n, firstRound, last))
                    : l10n.matrixConfirmReplaces(
                        roundSpan(l10n, firstRound, last),
                      ),
              ),
              item(
                Icons.grid_view,
                l10n.matrixConfirmGroups(sizes.length, sizes.join(', ')),
              ),
              item(
                Icons.history,
                l10n.matrixConfirmConfiguration(
                  '${data.configuration?.revisionNumber ?? '–'}',
                ),
              ),
              item(
                Icons.layers_outlined,
                l10n.matrixConfirmRevision(
                  data.matrix.revision!.revisionNumber,
                ),
              ),
              const SizedBox(height: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 20,
                        color: scheme.onTertiaryContainer,
                      ),
                      Expanded(
                        child: Text(
                          adding
                              ? l10n.matrixConfirmAddNote
                              : l10n.matrixConfirmRedrawNote,
                          style: TextStyle(color: scheme.onTertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.matrixConfirmCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-rounds'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              adding ? l10n.matrixAddAction : l10n.matrixRedrawAction,
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
