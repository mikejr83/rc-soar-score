import 'package:flutter/material.dart';

/// Tells a viewer of earlier results that later rounds are not included, and
/// links to the latest results.
class EarlierRoundBanner extends StatelessWidget {
  const EarlierRoundBanner({
    required this.round,
    required this.latest,
    required this.onSeeLatest,
    super.key,
  });

  final int round;
  final int latest;
  final VoidCallback onSeeLatest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.onSurface, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.history, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'You are viewing results as of round $round.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: ' Later rounds are not included.',
                          ),
                        ],
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  alignment: Alignment.centerLeft,
                  foregroundColor: scheme.primary,
                ),
                onPressed: onSeeLatest,
                child: Row(
                  children: [
                    Expanded(
                      child: Text('See latest results, as of round $latest'),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
