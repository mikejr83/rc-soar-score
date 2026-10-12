/// Which step the workspace's next-step card shows.
enum NextStepKind {
  publishResults,
  viewReports,
  finishConfiguration,
  addPilots,
  drawMatrix,
  redrawMatrix,
  startScoring,
  enterScores,
  completeAllScores,
  completeIdle,
  drawNextSeededRound,
  continueScoring,

  /// Shown instead of a completion suggestion the director dismissed.
  continueScoringAfterDismissal,

  /// Replaces a step that needs a change the administration lock rejects.
  unlock,
}
