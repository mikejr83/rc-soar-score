import 'package:flutter/material.dart';

/// Placeholder shapes shown while an existing participant loads.
class EditorSkeleton extends StatelessWidget {
  const EditorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget block(double height, Color color, {double? width, double r = 12}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    final high = scheme.surfaceContainerHigh;
    return Semantics(
      label: 'Loading participant',
      liveRegion: true,
      // The shapes are taller than a short window; clip instead of overflow.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                block(64, high, width: 64, r: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(28, high, width: 220, r: 6),
                      const SizedBox(height: 8),
                      block(16, high, width: 140, r: 6),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            block(200, scheme.surfaceContainer),
            const SizedBox(height: 20),
            block(180, scheme.surfaceContainer),
            const SizedBox(height: 20),
            block(180, scheme.surfaceContainer),
            const SizedBox(height: 12),
            Text(
              'Loading participant…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
