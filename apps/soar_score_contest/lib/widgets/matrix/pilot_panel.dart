import 'package:flutter/material.dart';

import '../../services/matrix/draw_form_check.dart';
import '../../services/matrix/matrix_grid_model.dart';
import '../../services/matrix/matrix_pilot.dart';
import '../../services/matrix/team_marker.dart';
import 'matrix_colors.dart';
import 'team_badge.dart';

/// The panel for the highlighted pilot: where they fly in every round, the
/// opponents with how often each meets them (repeats marked) and the pilots
/// they never meet. On a tablet it docks beside the grid; on a narrow screen
/// it docks under it. Either way it can be closed and never covers the grid.
class PilotPanel extends StatelessWidget {
  const PilotPanel({
    super.key,
    required this.model,
    required this.pilot,
    required this.markers,
    required this.bottom,
    this.sheetHeight = 380,
    required this.onClose,
  });

  final MatrixGridModel model;
  final MatrixPilot pilot;
  final TeamMarkers markers;

  /// A bottom sheet (narrow) instead of a side sheet (tablet).
  final bool bottom;
  final VoidCallback onClose;

  /// The height of the bottom sheet; shorter on a short screen so the grid
  /// keeps room.
  final double sheetHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final opponents = model.opponentsOf(pilot.participationId);
    final met = [
      for (final o in opponents)
        if (o.$2 > 0) o,
    ];
    final never = [
      for (final o in opponents)
        if (o.$2 == 0) o,
    ];
    final marker = markers.of(pilot.teamId);
    final first = pilot.name.split(' ').first;
    final places = [
      for (final round in model.rounds)
        if (model.placeOf(pilot.participationId, round) case (
          final group,
          final lane,
        ))
          'R${round.ordinal} · ${DrawFormCheck.groupLetter(group)}'
              '${model.hasLanes && lane != null ? ' · L$lane' : ''}',
    ];

    Widget section(String title, String sub, List<(MatrixPilot, int)> rows) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            Text(
              sub,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            for (final (other, count) in rows)
              _OpponentRow(
                pilot: other,
                count: count,
                marker: markers.of(other.teamId),
                showTeam: markers.ordered.isNotEmpty,
              ),
          ],
        );

    final sections = [
      section(
        'Opponents (${met.length} of ${opponents.length})',
        'Most meetings first. Repeats are marked.',
        met,
      ),
      section(
        'Never meets (${never.length})',
        never.isEmpty
            ? 'Meets every other pilot at least once.'
            : 'Pilots in no group with $first.',
        never,
      ),
    ];

    final header = Padding(
      padding: EdgeInsets.fromLTRB(bottom ? 20 : 16, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(Icons.person_pin, color: scheme.primary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pilot.name, style: theme.textTheme.titleMedium),
                Text(
                  [
                    if (pilot.number != null) 'No. ${pilot.numberText}',
                    if (markers.ordered.isNotEmpty) marker?.name ?? 'No team',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('clear-highlight'),
            tooltip: 'Clear highlight (Esc)',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );

    final body = ListView(
      padding: EdgeInsets.fromLTRB(bottom ? 20 : 16, 0, bottom ? 20 : 16, 12),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final place in places)
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                // A Container with an alignment grows to the full row, which
                // stacks the chips; the width factor keeps each as wide as
                // its text.
                child: Center(
                  widthFactor: 1,
                  child: Text(place, style: theme.textTheme.bodySmall),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (bottom)
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final s in sections) SizedBox(width: 300, child: s),
            ],
          )
        else
          for (final s in sections) ...[s, const SizedBox(height: 16)],
      ],
    );

    return Semantics(
      container: true,
      label: 'Opponents of ${pilot.name}',
      child: Material(
        key: const ValueKey('pilot-panel'),
        color: scheme.surfaceContainerLow,
        elevation: bottom ? 3 : 1,
        borderRadius: bottom
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: bottom ? null : 320,
          height: bottom ? sheetHeight : null,
          child: Column(
            children: [
              if (bottom)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              header,
              Expanded(child: body),
              if (!bottom)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'Select the pilot again or press Esc to clear.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpponentRow extends StatelessWidget {
  const _OpponentRow({
    required this.pilot,
    required this.count,
    required this.marker,
    required this.showTeam,
  });

  final MatrixPilot pilot;
  final int count;
  final TeamMarker? marker;
  final bool showTeam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = MatrixColors.of(context);
    final text = count == 0
        ? ''
        : count == 1
        ? 'once'
        : '$count times';
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        spacing: 8,
        children: [
          if (pilot.number != null)
            Container(
              constraints: const BoxConstraints(minWidth: 26, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(pilot.numberText, style: theme.textTheme.labelSmall),
            ),
          if (showTeam) TeamBadge(marker: marker),
          Expanded(child: Text(pilot.name)),
          if (count > 1) Icon(Icons.repeat, size: 16, color: colors.warn),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: count > 1 ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
