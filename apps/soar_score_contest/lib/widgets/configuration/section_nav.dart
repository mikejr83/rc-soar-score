import 'package:flutter/material.dart';

import '../../services/configuration/section_id.dart';
import '../../services/configuration/section_status.dart';

/// Whether the section list is the side list (wide pages) or a row of chips
/// (narrow pages).
enum SectionNavLayout { list, chips }

/// The sections of the page: a list on the side that follows the scroll, or
/// a chip row under the status panel. Each entry names its errors, unsaved
/// changes and fixed settings in words (as an icon and a count in the chips,
/// with the words as the accessible name).
class SectionNav extends StatelessWidget {
  const SectionNav({
    super.key,
    required this.layout,
    required this.sections,
    required this.statuses,
    required this.current,
    required this.onSelect,
  });

  final SectionNavLayout layout;
  final List<SectionId> sections;
  final Map<SectionId, SectionStatus> statuses;
  final SectionId current;
  final ValueChanged<SectionId> onSelect;

  @override
  Widget build(BuildContext context) =>
      layout == SectionNavLayout.list ? _list(context) : _chips(context);

  Color _markColor(ColorScheme scheme, SectionMarkKind kind) => switch (kind) {
    SectionMarkKind.error => scheme.error,
    SectionMarkKind.unsaved => scheme.primary,
    SectionMarkKind.fixed => scheme.onSurfaceVariant,
  };

  IconData _markIcon(SectionMarkKind kind) => switch (kind) {
    SectionMarkKind.error => Icons.error,
    SectionMarkKind.unsaved => Icons.edit,
    SectionMarkKind.fixed => Icons.lock,
  };

  String _semantics(SectionId id) {
    final marks = statuses[id]?.marks ?? const [];
    return marks.isEmpty
        ? id.title
        : '${id.title}, ${marks.map((m) => m.text).join(', ')}';
  }

  Widget _list(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text(
            'On this page',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final id in sections)
          Semantics(
            button: true,
            selected: id == current,
            label: _semantics(id),
            excludeSemantics: true,
            onTap: () => onSelect(id),
            child: Material(
              color: id == current
                  ? scheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                key: ValueKey('nav-${id.name}'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelect(id),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          id.short,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: id == current
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: id == current
                                ? scheme.onSecondaryContainer
                                : scheme.onSurface,
                          ),
                        ),
                        for (final mark in statuses[id]?.marks ?? const [])
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _markIcon(mark.kind),
                                size: 16,
                                color: _markColor(scheme, mark.kind),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                mark.text,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: _markColor(scheme, mark.kind),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chips(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final id in sections)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                selected: id == current,
                label: _semantics(id),
                excludeSemantics: true,
                onTap: () => onSelect(id),
                child: ChoiceChip(
                  key: ValueKey('nav-${id.name}'),
                  selected: id == current,
                  showCheckmark: false,
                  onSelected: (_) => onSelect(id),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(id.short),
                      for (final mark in statuses[id]?.marks ?? const [])
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _markIcon(mark.kind),
                                size: 16,
                                color: _markColor(scheme, mark.kind),
                              ),
                              if (mark.count > 0)
                                Text(
                                  ' ${mark.count}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: _markColor(scheme, mark.kind),
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
        ],
      ),
    );
  }
}
