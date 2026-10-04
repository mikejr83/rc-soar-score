/// The text stored for each enumerated column, exactly as in the entity
/// documents. A test compares every list here with the `@JsonValue` texts of
/// the matching `soar_score_core` enum, so a drift between them fails.
library;

/// `LifecycleState`.
const lifecycleStateValues = [
  'Created',
  'Configuring',
  'Ready',
  'Running',
  'Completed',
];

/// `ScoringAccess`.
const scoringAccessValues = ['Closed', 'Open'];

/// `AdminLock`.
const adminLockValues = ['Unlocked', 'Locked'];

/// Core enum name to the list above, for the comparison test.
const enumValueLists = {
  'LifecycleState': lifecycleStateValues,
  'ScoringAccess': scoringAccessValues,
  'AdminLock': adminLockValues,
};
