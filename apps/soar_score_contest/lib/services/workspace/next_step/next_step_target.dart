/// What a next-step button does. The widget (#344) maps each to behaviour;
/// [scoring] and [matrix] actions also carry a round and group.
enum NextStepTarget {
  configuration,
  participants,
  matrix,
  scoring,
  reports,
  publish,
  completeDialog,
  openScoring,
  unlock,
  dismissSuggestion,
}
