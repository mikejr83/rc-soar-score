import 'package:flutter/material.dart';

/// Reusable presentational score card.
///
/// Scaffold placeholder per ticket 009: carries no state and performs no
/// data access. Callers supply the title, optional subtitle, an optional
/// trailing widget (e.g. a normalized group score), and an optional body
/// [child]. Renders with the surrounding `Theme.of(context)` so it works in
/// both the contest and public app themes.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.onTap,
    super.key,
  });

  /// Card header text.
  final String title;

  /// Optional line under the title (e.g. round or discipline).
  final String? subtitle;

  /// Optional widget aligned to the header's end (e.g. a score value).
  final Widget? trailing;

  /// Optional body content below the header.
  final Widget? child;

  /// Optional tap handler; when null the card is inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        if (subtitle != null)
                          Text(subtitle!, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: 12),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
