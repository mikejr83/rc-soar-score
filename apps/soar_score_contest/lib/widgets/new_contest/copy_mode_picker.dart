import 'package:flutter/material.dart';

import '../../services/new_contest/copy_mode.dart';

/// The four copy modes as a radio group of labelled tiles.
class CopyModePicker extends StatelessWidget {
  const CopyModePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CopyMode value;
  final ValueChanged<CopyMode> onChanged;

  static const double _minTileWidth = 240;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Copy mode',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + _gap) / (_minTileWidth + _gap))
            .floor()
            .clamp(1, CopyMode.values.length);
        final width = (constraints.maxWidth - _gap * (columns - 1)) / columns;
        return Wrap(
          spacing: _gap,
          runSpacing: 4,
          children: [
            for (final mode in CopyMode.values)
              SizedBox(
                width: width,
                child: _CopyModeTile(
                  mode: mode,
                  selected: mode == value,
                  onTap: () => onChanged(mode),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CopyModeTile extends StatelessWidget {
  const _CopyModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final CopyMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '${mode.label}. ${mode.description}',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? scheme.onSurface.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('copy-mode-${mode.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mode.label, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        mode.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
