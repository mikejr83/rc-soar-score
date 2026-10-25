import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/draw_form_check.dart';
import 'progress/progress_headline.dart';
import 'progress/progress_summary.dart';
import 'workspace_facts.dart';

/// What the shell status panel shows about the round being scored, as plain
/// values the widget words.
class ShellRoundItem extends Equatable {
  const ShellRoundItem._(this.kind, {this.round, this.total, this.group});

  /// The item for [facts], or `null` when the panel shows none: the contest is
  /// still a draft, nothing is drawn, or the scores could not be read.
  static ShellRoundItem? of(WorkspaceFacts facts) {
    final state = facts.contest.lifecycleState;
    if (state == LifecycleState.created ||
        state == LifecycleState.configuring) {
      return null;
    }
    final headline = ProgressSummary.of(facts).headline;
    return switch (headline.stage) {
      ProgressStage.noMatrix || ProgressStage.scoresUnavailable => null,
      ProgressStage.noScores => const ShellRoundItem._(
        ShellRoundKind.notStarted,
      ),
      ProgressStage.finished => const ShellRoundItem._(ShellRoundKind.finished),
      ProgressStage.inProgress => ShellRoundItem._(
        ShellRoundKind.inProgress,
        round: headline.currentRound,
        total: headline.totalRounds,
        group: headline.currentGroup,
      ),
    };
  }

  final ShellRoundKind kind;
  final int? round;
  final int? total;

  /// The group number (1 is group A) being scored, if known.
  final int? group;

  /// The group's letter, if known.
  String? get groupLetter =>
      group == null ? null : DrawFormCheck.groupLetter(group! - 1);

  @override
  List<Object?> get props => [kind, round, total, group];
}

enum ShellRoundKind { notStarted, inProgress, finished }
