import 'package:flutter/material.dart';

/// One labelled value in a [DetailSectionCard].
class DetailItem {
  const DetailItem(this.label, this.value);

  final String label;

  /// Shown as an em dash when null or blank.
  final String? value;
}

/// A titled card of label/value pairs laid out in up to three columns.
class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<DetailItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 24.0;
                final columns = constraints.maxWidth >= 520
                    ? 3
                    : constraints.maxWidth >= 320
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: 16,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _display(item.value),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _display(String? value) =>
      value == null || value.trim().isEmpty ? '—' : value;
}
