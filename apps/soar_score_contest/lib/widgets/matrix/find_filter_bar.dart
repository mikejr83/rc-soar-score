import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/matrix/team_marker.dart';
import 'matrix_colors.dart';
import 'team_badge.dart';

/// Find a pilot by name or number, and show one team only. The result of
/// each is written out in words, so it is announced and never colour-only.
class FindFilterBar extends StatelessWidget {
  const FindFilterBar({
    super.key,
    required this.search,
    required this.matches,
    required this.markers,
    required this.teamSizes,
    required this.teamFilter,
    this.showNumbers = true,
    required this.onQuery,
    required this.onJump,
    required this.onTeam,
  });

  final TextEditingController search;

  /// How many pilots match the typed query.
  final int matches;
  final TeamMarkers markers;

  /// Pilots per team in the matrix.
  final Map<Id, int> teamSizes;
  final Id? teamFilter;
  final bool showNumbers;
  final ValueChanged<String> onQuery;
  final VoidCallback onJump;
  final ValueChanged<Id?> onTeam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final query = search.text.trim();
    final filtered = teamFilter == null ? null : markers.of(teamFilter);
    // The search and its result sit at the left; as in the design, the team
    // filter sits at the right end of the bar.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 12,
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: SearchBar(
                  key: const ValueKey('find-pilot'),
                  controller: search,
                  hintText: showNumbers
                      ? 'Find pilot by name or number'
                      : 'Find pilot by name',
                  elevation: const WidgetStatePropertyAll(0),
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          search.clear();
                          onQuery('');
                        },
                      ),
                  ],
                  onChanged: onQuery,
                  onSubmitted: (_) {
                    if (matches > 0) {
                      onJump();
                    }
                  },
                ),
              ),
              if (query.isNotEmpty) ...[
                Semantics(
                  liveRegion: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Icon(
                        matches > 0 ? Icons.search : Icons.search_off,
                        size: 18,
                        color: matches > 0 ? colors.warn : scheme.error,
                      ),
                      Text(
                        key: const ValueKey('search-result'),
                        matches > 0
                            ? '$matches pilot${matches == 1 ? '' : 's'} match'
                                  '${matches == 1 ? 'es' : ''}'
                            : 'No pilot matches “$query”',
                        style: TextStyle(
                          color: matches > 0 ? null : scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                if (matches > 0)
                  OutlinedButton.icon(
                    key: const ValueKey('jump-to-first'),
                    onPressed: onJump,
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Jump to first'),
                  ),
              ],
            ],
          ),
        ),
        if (markers.ordered.isNotEmpty)
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                key: const ValueKey('team-all'),
                onPressed: () => onTeam(null),
                leadingIcon: Icon(
                  Icons.check,
                  color: teamFilter == null ? null : Colors.transparent,
                ),
                child: const Text('All teams'),
              ),
              for (final (id, marker) in markers.ordered)
                MenuItemButton(
                  key: ValueKey('team-${marker.code}'),
                  onPressed: () => onTeam(id),
                  leadingIcon: Icon(
                    Icons.check,
                    color: teamFilter == id ? null : Colors.transparent,
                  ),
                  trailingIcon: Text('${teamSizes[id] ?? 0}'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      TeamBadge(marker: marker),
                      Text(marker.name),
                    ],
                  ),
                ),
              if (markers.ordered.length > TeamMarker.paletteSize)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Teams 13 and up use outlined markers. Their letters stay '
                    'unique.',
                  ),
                ),
            ],
            builder: (context, menu, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('team-filter'),
                  onPressed: markers.ordered.isEmpty
                      ? null
                      : () => menu.isOpen ? menu.close() : menu.open(),
                  style: filtered == null
                      ? FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(color: scheme.outline),
                        )
                      : null,
                  icon: Icon(
                    filtered == null ? Icons.filter_list : Icons.check,
                  ),
                  label: Text(
                    filtered == null ? 'All teams' : 'Team: ${filtered.name}',
                  ),
                ),
                if (filtered != null)
                  IconButton(
                    key: const ValueKey('clear-team'),
                    tooltip: 'Clear team filter',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onTeam(null),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
