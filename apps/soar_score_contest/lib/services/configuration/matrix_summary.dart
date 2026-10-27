import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/fairness_view.dart';
import 'setting_keys.dart';

/// The facts about a drawn matrix the configuration page shows: its revision,
/// its rounds, the smallest and largest group of any round and the options it
/// was drawn with.
class MatrixSummary {
  const MatrixSummary({
    required this.revisionNumber,
    required this.lastRound,
    required this.minGroupSize,
    required this.maxGroupSize,
    this.groupsPerRound,
    this.drawnWith = const {},
    this.fairness,
  });

  /// `null` until a matrix is drawn.
  static MatrixSummary? of(CurrentMatrix matrix) {
    final revision = matrix.revision;
    if (revision == null) {
      return null;
    }
    final sizes = <(Id, int), int>{};
    for (final assignment in matrix.assignments) {
      if (assignment.supersededByAssignmentId != null) {
        continue;
      }
      final key = (assignment.scheduledRoundId, assignment.group);
      sizes[key] = (sizes[key] ?? 0) + 1;
    }
    final counts = sizes.values;
    final fairness = revision.fairnessSummary;
    return MatrixSummary(
      revisionNumber: revision.revisionNumber,
      lastRound: revision.lastRound,
      minGroupSize: counts.isEmpty ? 0 : counts.reduce((a, b) => a < b ? a : b),
      maxGroupSize: counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b),
      groupsPerRound: revision.drawConfig['groups_per_round'] as int?,
      drawnWith: {
        SettingKeys.teamProtection: revision.drawConfig['team_protection'],
        SettingKeys.allowBackToBack: revision.drawConfig['allow_back_to_back'],
        SettingKeys.laneMode: revision.drawConfig['lane_mode'],
        SettingKeys.drawMode: revision.drawConfig['configured_draw_mode'],
      },
      fairness: fairness == null ? null : FairnessView.of(fairness),
    );
  }

  final int revisionNumber;

  /// The last round the matrix covers.
  final int lastRound;
  final int minGroupSize;
  final int maxGroupSize;
  final int? groupsPerRound;

  /// The values of the settings the draw recorded (`team_protection`,
  /// `lane_mode` and `draw_mode`), by setting key; missing ones were not
  /// recorded.
  final Map<String, Object?> drawnWith;

  /// The fairness summary of the draw; `null` when it recorded none.
  final FairnessView? fairness;
}
