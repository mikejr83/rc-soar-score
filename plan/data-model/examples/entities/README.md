# Entity JSON Examples

One example row for every entity in the [data model](../../README.md), written as the JSON the API and the sync stream carry. Field names, enum values, and nullability follow the [entity specifications](../../entities/).

## Contents

- [Identity, Participants and Access](identity-participants-access.md) - Account, AccountIdentity, AccountPublicProfile, ParticipantProfile, ParticipantAccountLink, ParticipantDirectoryEntry, ContestParticipation, Invitation
- [Teams, Roles and Models](teams-roles-models.md) - Role, Team, TeamMembership, ModelCatalog, ContestModelLink
- [Contest and Configuration](contest-configuration.md) - Contest, ContestConfigurationRevision, ContestConfigurationPreset
- [Disciplines and Landing Tables](disciplines.md) - DisciplineProfile, DisciplineConfigField, DisciplineScoreField, DisciplineValidation, DisciplineFormula, DisciplineRule, LandingTable, LandingResult
- [Matrix, Assignments and Re-flights](matrix-assignments-reflights.md) - MatrixRevision, Round, RoundGroup, MatrixAssignment, ReFlight, ReFlightParticipant
- [Scores, Results and Reviews](scores-results-reviews.md) - ScorePlaceholder, ScoreAttempt, OfficialScore, FlightResult, ParticipationStanding, TeamStanding, ReviewRequest
- [Publication](publication.md) - PublicationIdentity, PublicationProjection, PublicationParticipant, DelistRequest
- [Synchronization and Audit](synchronization-audit.md) - Installation, InstallationActivation, SyncCursor, MutationRecord, ConflictRecord, Tombstone, AuditEvent

## The shared scenario

All files describe the same small ALES contest, so identifiers line up across files. Every identifier has the form `019c0000-0000-7000-8000-0000000000NN` (illustrative UUIDv7 values), except `scoring_uuid`, which is a UUIDv4.

| Thing                  | Value                                                                                                           |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| Director               | Dana Whitfield, account `…0001`, profile owner and contest owner                                                |
| Pilots                 | Sam Ortega (participation `…0040`), Alex Chen (participation `…0041`)                                           |
| Timekeeper             | Jo Park (participation `…0042`), a `NonFlier`                                                                   |
| Contest                | "Front Range ALES Open", `…0010`, 17-18 October 2026, America/Denver                                            |
| Discipline             | The ALES profile and the 1 m to 10 m landing table (50 down to 5 points) from [ales.md](../disciplines/ales.md) |
| Configuration revision | `…0070`                                                                                                         |
| Matrix revision        | `…0080`, round 1 `…0081`, round 2 `…0082`                                                                       |
| Sam's round 1 flight   | assignment `…0084`, placeholder `…00a0`, landing within 3 m (40 points)                                         |
| Alex's zero flights    | round 1 motor restart (`…00a7`), round 2 out of bounds (`…00ab`)                                                |
| Publication            | `…00b0`                                                                                                         |

## Conventions

- Timestamps are ISO 8601 strings in UTC. Decimals are written as JSON numbers.
- Absent optional values are written as `null` so every column is visible.
- Credentials and secrets are placeholders. A real `protected_credential` is a hash, and the raw credential is never stored.
- JSON columns (`config`, `payload`, `raw_components`, and so on) show a realistic shape. Their inner keys are defined by the owning entity or discipline profile.
