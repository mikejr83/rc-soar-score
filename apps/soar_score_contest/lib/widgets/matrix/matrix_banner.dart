import 'package:flutter/material.dart';

/// Which colours a [MatrixBanner] uses.
enum MatrixBannerKind { error, warning }

/// A non-blocking notice with an icon, a title, a sentence and optional
/// actions. Errors are announced as alerts.
class MatrixBanner extends StatelessWidget {
  const MatrixBanner({
    super.key,
    required this.kind,
    required this.icon,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final MatrixBannerKind kind;
  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (kind) {
      MatrixBannerKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      MatrixBannerKind.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: kind == MatrixBannerKind.error,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(icon, color: foreground),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 200,
                    maxWidth: 640,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(body),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
