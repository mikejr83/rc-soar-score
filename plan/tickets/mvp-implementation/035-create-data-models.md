# Ticket 035 — Creation of Data Models

- **Category:** Domain / Core
- **Priority:** High
- **Status:** Open

## Context

The conceptual data model is specified across the [`plan/architecture-requirements/data/`](plan/architecture-requirements/data/README.md) documents. No domain entity classes currently exist in `packages/soar_score_core` — only the `Contest` placeholder (`packages/soar_score_core/lib/models/contest.dart`) and `Id` type (`packages/soar_score_core/lib/models/id.dart`). This ticket materializes the complete set of Dart domain models required by the architecture, including value objects, enums, and relationship mappings.

The `soar_score_core` package boundary is explicitly pure Dart with no I/O (see `packages/soar_score_core/AGENTS.md`), so all models must be serializable and independent of persistence backends.

## Models to Create

All model classes go in `packages/soar_score_core/lib/models/` (or subdirectories as appropriate). Enums go in `lib/enums/`. Value objects may live alongside their parent models or in a dedicated folder.

### Identity and Ownership

- **Account** — `accountId` (UUIDv7), firstName, lastName, emailAddress, identityProviderSubject, createdAt, updatedAt. Can own multiple contests, can link to multiple participant profiles.
- **ParticipantProfile** — `profileId` (UUIDv7), firstName, lastName, club, faiNumber, nationalOrgId, city, stateProvince, country, email, ownedByAccountId (nullable for directory), isShared, privacyPolicy, createdAt, updatedAt. Reusable across contests.
- **Contest** — Expand placeholder to full model per `contest.md`: `contestId` (UUIDv7), name, startDate, endDate, timezone, host/venue, city, stateProvince, country, ownerAccountId (nullable for anonymous/local). **State dimensions stored as separate fields**, not a combined status enum (from architecture decision): executionLifecycle (enum), scoringAccessOpen (bool or enum), administrationLocked (bool or enum), published (bool), visibility (enum), archived (bool), deletionStatus (enum). Revision tracking: revision (int), createdAt, updatedAt. Configuration fields per architecture spec.
- **ParticipantAccountLink** — `linkId` (UUIDv7), participantProfileId, accountId, consentGiven, consentTimestamp, createdAt. Many-to-many handling for email/change scenarios.

### Contest Participation

- **ParticipationLink** — `linkId` (UUIDv7), contestId, participantProfileId, class, roleRef, roleType, participantNumber (nullable), teamRef (nullable), scoringUuid, privacyOverrides, status, retiredAtRound (nullable), createdAt, updatedAt. Links participant profile to a contest; parent of assignments, score placeholders, invitations, model links.

### Teams, Roles, and Models

- **Role** — `roleId` (UUIDv7), contestId, displayName, roleType (Pilot/NonFlier), isSystemDefault, createdAt, updatedAt. Director-owned or system-default.
- **Team** — `teamId` (UUIDv7), contestId, name, scoringPilotCount, createdAt, updatedAt.
- **TeamMembership** — `membershipId` (UUIDv7), teamId, participationLinkId, role (nullable), joinedAt.
- **ModelCatalog** — `modelId` (UUIDv7), name, manufacturer, modelIdentifier, ownedByAccountId (nullable), isShared, createdAt, updatedAt.
- **ContestModelLink** — `linkId` (UUIDv7), contestId, participationLinkId, modelCatalogId (nullable), modelName, manufacturer, modelIdentifier, createdAt, updatedAt. Contest-specific snapshot linked to participation link.

### Disciplines and Configuration

- **DisciplineProfile** — `profileId` (UUIDv7), disciplineType (ALES/ThermalDuration/F3J/F5J), rulesVersion, name, configFields, scoreEntryFields, validationRules, zeroReasons, formulas, normalizationRules, roundingRules, calculationMetadata, createdAt, updatedAt. Versioned rules.
- **ContestConfigRevision** — `revisionId` (UUIDv7), contestId, disciplineProfileId, rulesVersion, configuration overrides (groupScoreMode, rounding, dropped-round policy, targetTime, pointsPerSecond, disciplineSettings), matrixRevisionId (nullable), scoreRevisionId (nullable), calculationVersion, createdBy, createdFromBaseRevision, createdAt, isCurrent.
- **LandingTable** — `tableId` (UUIDv7), name, revision, inputUnit, entries (array of key->points), createdAt, updatedAt.
- **LandingTableEntry** — key, value.

### Matrix and Assignments

- **MatrixRevision** — `revisionId` (UUIDv7), contestId, drawConfig, participatedParticipantLinkIds, seed, fairnessResult, createdBy, createdFromBaseRevision, reason, isFinal, calculationVersion, createdAt, createdAtUTC.
- **Round** — `roundId` (UUIDv7), matrixRevisionId, contestId, roundNumber, createdAt.
- **Group** — `groupId` (UUIDv7), roundId, matrixRevisionId, contestId, groupNumber, createdAt.
- **Assignment** — `assignmentId` (UUIDv7), matrixRevisionId, contestId, participationLinkId, scheduledRoundId, creditedRoundId, groupId, lane, assignmentType (Original/Moved/Reflight), sourceAssignmentId (nullable), actorId, reason, createdAt, updatedAt.
- **ReFlightRecord** — `reFlightId` (UUIDv7), contestId, creditedRoundId, type, sequence, status, reason, disciplineRulesVersion, calculationVersion, createdBy, finalizedBy, awardedParticipantLinkIds, drawCandidateIds, drawExclusionIds, selectedParticipantLinkIds, participantResponses, notifications, directorDecision, createdAt, finalizedAt.

### Scores and Results

- **ScorePlaceholder** — `placeholderId` (UUIDv7), assignmentId, participationLinkId, contestId, scheduledRoundId, creditedRoundId, groupId, flightAttempt, state (NotEntered/Draft/Submitted/Zero/Retired/Official/Review/Locked), createdAt. One per assignment with flight attempt dimension.
- **ScoreAttempt** — `attemptId` (UUIDv7), placeholderId, rawComponents (map), cumulativePenalty (int), zeroReason, statusReason, actorId, authority, sourceDeviceId, clientMutationId, acceptedAt, baseScoreRevision, contestConfigRevisionId, matrixRevisionId, disciplineRulesVersion, calculationVersion. Immutable; one per submission.
- **CalculationResult** — `resultId` (UUIDv7), scoreAttemptId, placeholderId, contestTotal (nullable), droppedRoundDecision (nullable), rank (nullable), teamTotal (nullable), contestConfigRevisionId, matrixRevisionId, disciplineRulesVersion, calculationVersion, calculationMetadata, createdAt.
- **ContestPenalty** — `penaltyId` (UUIDv7), contestId, participationLinkId, points, reason, imposedBy, imposedAt, appliedToCalculatedResultId (nullable), createdAt.

### Reviews and Invitations

- **ReviewRequest** — `requestId` (UUIDv7), placeholderId, currentScore, proposedRawComponents, proposedCumulativePenalty, message, requesterId, baseScoreRevision, status (Submitted/UnderReview/Approved/Rejected/Superseded), decisionActor, decisionMessage, submittedAt, decidedAt.
- **Invitation** — `invitationId` (UUIDv7), contestId, participationLinkId, credentialHash, credentialExpiry, invitationRevision, status (Issued/Delivered/Accessed/Superseded/Revoked/Expired), deliveryOutcomes, createdAt, revocationAt.

### Publication

- **PublishedContest** — `publishedContestId` (UUIDv7), sourceContestId, email, ownerAccountId (nullable), publishedContestUuid, visibility (Private/Hidden/Public), publishedAt, claimedAt.
- **PublicationRevision** — `revisionId` (UUIDv7), publishedContestId, contestInfoJson, calculationMetadata, sourceContestRevision, contestConfigRevisionId, matrixRevisionId, disciplineRulesVersion, calculationVersion, publishedAt, publishedBy.

### Synchronization and Audit

- **EntityMutation** — `mutationId` (UUIDv7), contestId, entityType, entityId, baseRevision, newRevision, payload, actorId, authority, sourceInstallationId, clientTime, serverAcceptanceTime, status (Pending/Accepted/Conflicted/Rejected/Duplicated), acceptedOnInstallationId (nullable), createdAt.
- **SyncCursor** — `cursorId` (UUIDv7), contestId, installationId, lastAckSeq, lastUpdateSeq, lastSyncedAt, createdAt, updatedAt.
- **ConflictRecord** — `conflictId` (UUIDv7), entityType, entityId, mutationIds, conflictReason, resolutionStatus (Detected/Resolved), resolvedMutationId (nullable), occurredAt, resolvedAt.
- **EntityTombstone** — `tombstoneId` (UUIDv7), entityType, entityId, contestId, deletedAt, deletedBy, deletedFromInstallation, status (Active/Expired), expiredAt.
- **AuditEvent** — `eventId` (UUIDv7), contestId, entityId, entityType, action, actorId, authority, sourceInstallationId, sourceDevice, baseRevision, resultRevision, serverTimestamp, clientTimestamp, reason, result, details, createdAt.
- **InstallationActivation** — `activationId` (UUIDv7), contestId, installationId, role (Admin/Participant), activatedAt, activatedBy, activeState, deactivatedAt.

### Enums

Create all enums as separate files in `packages/soar_score_core/lib/enums/`:

- **ExecutionLifecycle** — Created, Configuring, Ready, Running, Completed
- **ScoringAccess** — Closed, Open
- **AdminLock** — Unlocked, Locked
- **Visibility** — Private, Hidden, Public
- **DeletionStatus** — None, PendingDelete, Restored, Deleted
- **RoleType** — Pilot, NonFlier
- **AssignmentType** — Original, Moved, Reflight
- **ScorePlaceholderState** — NotEntered, Draft, Submitted, Zero, Retired, Official, Review, Locked
- **SyncTarget** — Contest, ParticipantProfile
- **MutationStatus** — Pending, Accepted, Conflicted, Rejected, Duplicated
- **ConflictStatus** — Detected, Resolved
- **TombstoneStatus** — Active, Expired
- **ScoreLockScope** — Score, Group, Round, Contest
- **InvitationState** — Issued, Delivered, Accessed, Superseded, Revoked, Expired
- **ReFlightType** — Disqualification, Scratch, Dispute, Weather
- **ReFlightStatus** — Proposed, UnderReview, Approved, Rejected, Finalized
- **SyncConflictResolution** — KeepRemote, KeepLocal, Manual
- **ParticipantNumberAllocation** — Manual, Random, Seeded
- **ProfileSharingScope** — Private, Shared
- **ParticipantAccountRole** — Owner, Editor, Viewer
- **InstallationRole** — Admin, Participant
- **InvitationType** — AdminMagicUrl, ParticipantMagicUrl, FieldQrToken
- **InvitationDeliveredAs** — MagicUrl, FieldQrToken
- **ContestPenaltyType** — LateArrival, RulesViolation, EquipmentViolation, Scratch, DirectorDiscretionary

### Relationships

Implement relationships across models:

- `Account` — many contests (owner), many participant profiles (via ParticipantAccountLink)
- `Contest` — many ParticipationLinks, many MatrixRevisions, many Rounds (via MatrixRevision), many Groups (via Round), many ScorePlaceholders (via Assignment), many AuditEvents, many ContestsPenalties, many ReFlightRecords, many SyncCursors, many EntityMutations
- `ParticipationLink` — one ParticipantProfile, one Contest, many Assignments, one ContestModelLink (optional), many Invitations, many ReviewRequests (via ScorePlaceholder)
- `MatrixRevision` — many Rounds, many Assignments
- `Round` — many Groups
- `Group` — many Assignments
- `Assignment` — one ScorePlaceholder, one ParticipationLink
- `ScorePlaceholder` — many ScoreAttempts, one ScoreLock, one ReviewRequest (optional)
- `ScoreAttempt` — many CalculationResults
- `Team` — many TeamMemberships
- `TeamMembership` — one ParticipationLink
- `ParticipationLink` — one Role
- `Role` — many ParticipationLinks (via roleRef)
- `ContestConfigRevision` — one DisciplineProfile
- `DisciplineProfile` — many LandingTables
- `PublishedContest` — one Contest (source), many PublicationRevisions

## Work Items

- [ ] Implement all model classes in `packages/soar_score_core/lib/models/`.
- [ ] Implement all enum files in `packages/soar_score_core/lib/enums/`.
- [ ] Update `packages/soar_score_core/lib/soar_score_core.dart` to re-export new models and enums.
- [ ] Update `packages/soar_score_core/lib/enums/enums.dart` barrel to export all new enums.
- [ ] Ensure models include stable UUID identifiers as `Id` objects (reuse the existing `Id` type).
- [ ] Write basic unit tests verifying model construction and validation.
- [ ] Run `dart analyze` in the core package — all lints and info must be clean.

## Acceptance Criteria

- [ ] All domain entities from the architecture spec are represented as Dart classes.
- [ ] Each entity has a stable `Id` (UUIDv7) primary identifier.
- [ ] Enums exist for all state/option dimensions.
- [ ] Models are purely Dart (no I/O dependencies).
- [ ] `dart analyze` passes with no errors or warnings in `soar_score_core`.
- [ ] `dart test` passes for new model tests.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md) — Core package must exist first.

## Sources

- `plan/architecture-requirements/data/README.md` — Entity documents and relationship summary
- `plan/architecture-requirements/data/contest.md` — Contest entity
- `plan/architecture-requirements/data/accounts.md` — Account entity
- `plan/architecture-requirements/data/participants.md` — Participant profiles and participation
- `plan/architecture-requirements/data/teams-roles-models.md` — Teams, roles, and models
- `plan/architecture-requirements/data/disciplines-and-configuration.md` — Disciplines and configuration
- `plan/architecture-requirements/data/matrix-and-assignments.md` — Matrix and assignments
- `plan/architecture-requirements/data/scores-and-results.md` — Scores and results
- `plan/architecture-requirements/data/reviews-and-invitations.md` — Reviews and invitations
- `plan/architecture-requirements/data/publication.md` — Publication
- `plan/architecture-requirements/data/synchronization-and-audit.md` — Sync and audit
- `AGENTS.md` — Repository-wide coding conventions
- `packages/soar_score_core/AGENTS.md` — Core package boundaries
- Existing code patterns: `packages/soar_score_core/lib/models/contest.dart`, `packages/soar_score_core/lib/models/id.dart`
