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

/// `LandingInputUnit`.
const landingInputUnitValues = ['meters', 'feet', 'points'];

/// `DisciplineType`.
const disciplineTypeValues = [
  'ALES',
  'ThermalDuration',
  'F3J',
  'F5J',
  'F3L',
  'F3K',
];

/// `DisciplineCategory`.
const disciplineCategoryValues = ['duration', 'multiple', 'other'];

/// `ProfileStatus`.
const profileStatusValues = ['drafted', 'published', 'superseded'];

/// `ConfigFieldType`.
const configFieldTypeValues = [
  'string',
  'int',
  'float',
  'bool',
  'enum',
  'landing',
];

/// `ScoreFieldType`.
const scoreFieldTypeValues = [
  'string',
  'int',
  'float',
  'bool',
  'enum',
  'date',
  'time',
  'landing',
];

/// `ScoreFieldKind`.
const scoreFieldKindValues = ['input', 'status_flag', 'derived'];

/// `FormulaType`.
const formulaTypeValues = [
  'raw',
  'intermediate',
  'penalty',
  'final',
  'normalized',
];

/// `RuleType`.
const ruleTypeValues = ['calc', 'penalty', 'zero', 'interaction', 'other'];

/// `RoleType`.
const roleTypeValues = ['Pilot', 'NonFlier'];

/// `AssignmentType`.
const assignmentTypeValues = ['Original', 'Moved', 'Reflight', 'LateAdd'];

/// `DrawMode`.
const drawModeValues = ['StandardManOnMan', 'SeededManOnMan'];

/// `ExcludedReason`.
const excludedReasonValues = [
  'SameTeam',
  'Retired',
  'NotEligible',
  'DirectorExcluded',
  'Declined',
];

/// `ExistingScoreHandling`.
const existingScoreHandlingValues = ['None', 'Reset'];

/// `FlightOutcome`.
const flightOutcomeValues = ['Scored', 'Zero'];

/// `GroupStatus`.
const groupStatusValues = ['Open', 'Locked'];

/// `NotificationState`.
const notificationStateValues = [
  'NotRequired',
  'Pending',
  'Delivered',
  'Failed',
];

/// `ReFlightParticipantRole`.
const reFlightParticipantRoleValues = [
  'Awarded',
  'Drawn',
  'GroupMember',
  'Candidate',
  'Excluded',
];

/// `ReFlightResponse`.
const reFlightResponseValues = [
  'NotRequired',
  'Pending',
  'Accepted',
  'Declined',
];

/// `ReFlightStatus`.
const reFlightStatusValues = [
  'Proposed',
  'DrawPending',
  'AwaitingResponses',
  'ReadyToFly',
  'Finalized',
  'Cancelled',
];

/// `ReFlightType`.
const reFlightTypeValues = ['MoveToGroup', 'RandomDraw', 'ReflyEntireGroup'];

/// `ResponseActor`.
const responseActorValues = ['Participant', 'Director'];

/// `ReviewRequestState`.
const reviewRequestStateValues = [
  'Submitted',
  'UnderReview',
  'Approved',
  'Rejected',
  'Superseded',
];

/// `RoundStatus`.
const roundStatusValues = ['Open', 'Locked', 'Cancelled'];

/// `ScorePlaceholderState`.
const scorePlaceholderStateValues = [
  'NotEntered',
  'Submitted',
  'InReview',
  'Official',
];

/// `AccountKind`.
const accountKindValues = ['registered', 'guest', 'local', 'deleted'];

/// `AccountStatus`.
const accountStatusValues = ['active', 'archived'];

/// `ActivationKind`.
const activationKindValues = ['Initial', 'Replacement', 'Reclaim'];

/// `ClaimStatus`.
const claimStatusValues = ['Unclaimed', 'Claimed'];

/// `DelistState`.
const delistStateValues = ['pending', 'approved', 'denied', 'withdrawn'];

/// `DelistTrigger`.
const delistTriggerValues = ['owner_request', 'account_closure'];

/// `InvitationAudience`.
const invitationAudienceValues = ['Pilot', 'Helper'];

/// `InvitationState`.
const invitationStateValues = ['Active', 'Replaced', 'Revoked', 'Expired'];

/// `InvitationType`.
const invitationTypeValues = ['MagicURL', 'QRCode'];

/// `ParticipantLinkOrigin`.
const participantLinkOriginValues = [
  'EmailMatch',
  'DirectoryPull',
  'InvitationRedemption',
];

/// `ParticipantLinkStatus`.
const participantLinkStatusValues = ['Candidate', 'Confirmed', 'Ended'];

/// `Platform`.
const platformValues = ['Web', 'Windows', 'Other'];

/// `PublicationVisibility`.
const publicationVisibilityValues = ['Unlisted', 'Public', 'Delisted'];

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
  'LandingInputUnit': landingInputUnitValues,
  'DisciplineType': disciplineTypeValues,
  'DisciplineCategory': disciplineCategoryValues,
  'ProfileStatus': profileStatusValues,
  'ConfigFieldType': configFieldTypeValues,
  'ScoreFieldType': scoreFieldTypeValues,
  'ScoreFieldKind': scoreFieldKindValues,
  'FormulaType': formulaTypeValues,
  'RuleType': ruleTypeValues,
  'RoleType': roleTypeValues,
  'AssignmentType': assignmentTypeValues,
  'DrawMode': drawModeValues,
  'ExcludedReason': excludedReasonValues,
  'ExistingScoreHandling': existingScoreHandlingValues,
  'FlightOutcome': flightOutcomeValues,
  'GroupStatus': groupStatusValues,
  'NotificationState': notificationStateValues,
  'ReFlightParticipantRole': reFlightParticipantRoleValues,
  'ReFlightResponse': reFlightResponseValues,
  'ReFlightStatus': reFlightStatusValues,
  'ReFlightType': reFlightTypeValues,
  'ResponseActor': responseActorValues,
  'ReviewRequestState': reviewRequestStateValues,
  'RoundStatus': roundStatusValues,
  'ScorePlaceholderState': scorePlaceholderStateValues,
  'AccountKind': accountKindValues,
  'AccountStatus': accountStatusValues,
  'ActivationKind': activationKindValues,
  'ClaimStatus': claimStatusValues,
  'DelistState': delistStateValues,
  'DelistTrigger': delistTriggerValues,
  'InvitationAudience': invitationAudienceValues,
  'InvitationState': invitationStateValues,
  'InvitationType': invitationTypeValues,
  'ParticipantLinkOrigin': participantLinkOriginValues,
  'ParticipantLinkStatus': participantLinkStatusValues,
  'Platform': platformValues,
  'PublicationVisibility': publicationVisibilityValues,
};
