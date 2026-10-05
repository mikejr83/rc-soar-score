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

/// `Authority`.
const authorityValues = [
  'Director',
  'Participant',
  'Helper',
  'System',
  'Administrator',
];

/// `MutationOutcome`.
const mutationOutcomeValues = [
  'Pending',
  'Accepted',
  'Rejected',
  'Conflict',
  'Skipped',
];

/// `TombstoneStatus`.
const tombstoneStatusValues = ['Pending', 'Acknowledged'];

/// `ConflictResolution`.
const conflictResolutionValues = ['Pending', 'Automatic', 'Manual'];

/// `ConflictResolutionChoice`.
const conflictResolutionChoiceValues = [
  'KeptAccepted',
  'TookCompeting',
  'Merged',
];

/// `AuditAction`.
const auditActionValues = [
  'StateTransition',
  'ScoreAttempt',
  'ScoreReview',
  'InvitationIssued',
  'InvitationReplaced',
  'InvitationRevoked',
  'InvitationDeliveryRequested',
  'InvitationAccessed',
  'InvitationAccessFailed',
  'PublicationAttempt',
  'DelistRequested',
  'DelistDecided',
  'DelistWithdrawn',
  'Redaction',
  'Conflict',
  'ConflictAccepted',
  'ConflictRejected',
  'Deletion',
  'Restoration',
  'InstallationActivation',
];

/// `AuditOutcome`.
const auditOutcomeValues = ['Success', 'Rejected', 'Conflict'];

/// Core enum name to the list above, for the comparison test.
const enumValueLists = {
  'LifecycleState': lifecycleStateValues,
  'ScoringAccess': scoringAccessValues,
  'AdminLock': adminLockValues,
  'Authority': authorityValues,
  'MutationOutcome': mutationOutcomeValues,
  'TombstoneStatus': tombstoneStatusValues,
  'ConflictResolution': conflictResolutionValues,
  'ConflictResolutionChoice': conflictResolutionChoiceValues,
  'AuditAction': auditActionValues,
  'AuditOutcome': auditOutcomeValues,
};
