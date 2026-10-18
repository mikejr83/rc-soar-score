import 'package:flutter/material.dart';

import '../matrix/fairness_view.dart';
import 'config_phase.dart';
import 'configuration_data.dart';
import 'configuration_draft.dart';
import 'draw_readiness.dart';
import 'setting_keys.dart';
import 'setting_values.dart';

/// How a readiness line reads.
enum ReadinessTone { neutral, warning, pending }

/// One line of the readiness panel, with an optional link to the fix.
class ReadinessLine {
  const ReadinessLine({
    required this.icon,
    required this.text,
    this.tone = ReadinessTone.neutral,
    this.linkLabel,
    this.fix,
  });

  final IconData icon;
  final String text;
  final ReadinessTone tone;
  final String? linkLabel;
  final BlockerFix? fix;
}

/// What the matrix readiness panel says: that the contest is completed, or
/// whether the matrix can be drawn, or what the drawn matrix was drawn with
/// and where the configuration has moved on from it.
class ReadinessSummary {
  const ReadinessSummary({
    required this.icon,
    required this.title,
    required this.ok,
    required this.facts,
    required this.lines,
  });

  /// The summary for [data] with the director's unsaved [draft], if any.
  factory ReadinessSummary.of(
    ConfigurationData data,
    ConfigurationDraft? draft,
  ) {
    // A completed contest is finished, not a problem state: no draw, no sync.
    if (data.phase == ConfigPhase.completed) {
      return const ReadinessSummary(
        icon: Icons.flag_outlined,
        title: 'Contest completed',
        ok: true,
        facts: [],
        lines: [],
      );
    }
    final matrix = data.matrix;
    final pilots = data.scoringPilots;
    if (matrix == null) {
      final readiness = DrawReadiness.evaluate(
        contest: data.contest,
        configurationProblem: data.configuration == null
            ? 'No configuration is saved yet, so the matrix can’t be drawn.'
            : null,
        scoringPilots: pilots,
        matrixDrawn: false,
      );
      if (readiness.enabled) {
        return ReadinessSummary(
          icon: Icons.check_circle,
          title: 'Ready to draw',
          ok: true,
          facts: [
            ('Scoring pilots', '$pilots'),
            if (draft != null)
              ('Draw mode', _drawModeText(draft.saved[SettingKeys.drawMode])),
          ],
          lines: [
            if (draft != null && draft.dirty)
              const ReadinessLine(
                icon: Icons.info_outline,
                text:
                    'Checked against the saved configuration. Save your '
                    'changes for the draw to use them.',
              ),
          ],
        );
      }
      return ReadinessSummary(
        icon: Icons.block,
        title: 'Can’t be drawn yet',
        ok: false,
        facts: const [],
        lines: [
          for (final blocker in readiness.blockers)
            ReadinessLine(
              icon: blocker.icon,
              text: blocker.text,
              linkLabel: blocker.linkLabel,
              fix: blocker.fix,
            ),
        ],
      );
    }
    final differences = <String>[];
    final saved = draft?.saved ?? const <String, Object?>{};
    for (final key in matrix.drawnWith.keys) {
      final drawn = matrix.drawnWith[key];
      final now = saved[key];
      if (drawn != null && now != null && '$drawn' != '$now') {
        differences.add(key);
      }
    }
    final structural = draft == null || data.phase.isRunning
        ? const <SettingChange>[]
        : draft.matrixChanges;
    return ReadinessSummary(
      icon: differences.isEmpty ? Icons.check_circle : Icons.warning_amber,
      title: differences.isEmpty
          ? 'Drawn and in sync'
          : 'Drawn with different settings',
      ok: differences.isEmpty,
      facts: [
        ('Matrix', 'Revision ${matrix.revisionNumber}'),
        ('Rounds', '${matrix.lastRound}'),
        if (matrix.groupsPerRound != null)
          ('Groups', '${matrix.groupsPerRound} per round'),
        (
          'Group sizes',
          matrix.minGroupSize == matrix.maxGroupSize
              ? '${matrix.maxGroupSize} pilots'
              : '${matrix.minGroupSize}–${matrix.maxGroupSize} pilots',
        ),
        if (_fairnessText(matrix.fairness) case final fairness?)
          ('Fairness', fairness),
      ],
      lines: [
        for (final key in differences)
          ReadinessLine(
            icon: Icons.sync_problem,
            tone: ReadinessTone.warning,
            text:
                '${draft!.catalog.byKey[key]!.label}: the matrix was drawn '
                'with ${_valueText(draft, key, matrix.drawnWith[key])}; the '
                'configuration now says ${_valueText(draft, key, saved[key])}. '
                'The matrix is unchanged until you redraw on the Matrix page.',
          ),
        if (structural.isNotEmpty)
          ReadinessLine(
            icon: Icons.edit_outlined,
            tone: ReadinessTone.pending,
            text:
                'Saving your unsaved change${structural.length > 1 ? 's' : ''} '
                'to ${lowerList([for (final c in structural) c.def.label])} '
                'will make the drawn matrix out of date.',
          ),
      ],
    );
  }

  final IconData icon;
  final String title;

  /// The contest is completed, or the matrix can be drawn, or is drawn and in
  /// sync.
  final bool ok;
  final List<(String, String)> facts;
  final List<ReadinessLine> lines;

  /// `Good draw, 92%`; `null` when the draw recorded no fairness score.
  static String? _fairnessText(FairnessView? fairness) {
    final tier = fairness?.tier;
    return tier == null ? null : '${tier.label}, ${fairness!.scoreText}';
  }

  static String _drawModeText(Object? value) =>
      value == SettingKeys.seeded ? 'Seeded Man on Man' : 'Man on Man';

  static String _valueText(
    ConfigurationDraft draft,
    String key,
    Object? value,
  ) => SettingValues.display(draft.catalog.byKey[key]!, value);

  /// `a, b and c`, with the later items starting in lower case.
  static String lowerList(List<String> items) {
    final words = [
      for (final (index, item) in items.indexed)
        index == 0 ? item : item[0].toLowerCase() + item.substring(1),
    ];
    if (words.length < 2) {
      return words.join();
    }
    return '${words.sublist(0, words.length - 1).join(', ')} and ${words.last}';
  }
}
