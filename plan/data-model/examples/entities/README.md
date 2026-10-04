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

All files describe the same ALES contest, so identifiers line up across files. Every identifier has the form `019c0000-0000-7000-8000-0000000000NN` (illustrative UUIDv7 values), except `scoring_uuid`, which is a UUIDv4.

| Thing                   | Value                                                                                                           |
| ----------------------- | --------------------------------------------------------------------------------------------------------------- |
| Director                | Dana Whitfield, account `…0001`, owner of the contest and of all profiles                                       |
| Pilots                  | Sam Ortega, Alex Chen, Riley Nakamura, Morgan Reyes, and Taylor Brooks (a guest)                                |
| Timekeeper              | Jo Park, a `NonFlier`                                                                                           |
| Teams                   | Boulder Thermals (Sam, Alex) and Longmont Lofters (Riley, Morgan). Taylor flies without a team                  |
| Contest                 | "Front Range ALES Open", `…0010`, 17-18 October 2026, America/Denver, `Running`                                 |
| Discipline              | The ALES profile and the 1 m to 10 m landing table (50 down to 5 points) from [ales.md](../disciplines/ales.md) |
| Configuration revision  | `…0070`, `Time` group scoring, 600 s target                                                                     |
| Matrix                  | Revision `…0080`, 8 rounds, 2 groups per round (3 + 2 pilots), team protection on                               |
| Round 1                 | Finished and locked. Group 1: Sam, Riley, Taylor. Group 2: Alex, Morgan                                         |
| Round 2                 | In progress. Group 1: Alex, Morgan, Taylor. Group 2: Sam, Riley. Group 3 is a re-flight of round 1 group 1      |
| Notable flights         | Alex's motor restart in round 1 and out of bounds landing in round 2. Taylor's rejected review request          |
| Standings after round 1 | Morgan 1045.0, Sam 1040.0, Riley 1024.4, Taylor 948.1, Alex 0.0. Longmont Lofters lead the teams                |
| Publication             | `…00b0`, published after round 1                                                                                |

## Conventions

- Timestamps are ISO 8601 strings in UTC. Decimals are written as JSON numbers.
- Absent optional values are written as `null` so every column is visible.
- Credentials and secrets are placeholders. A real `protected_credential` is a hash, and the raw credential is never stored.
- JSON columns (`config`, `payload`, `raw_components`, and so on) show a realistic shape. Their inner keys are defined by the owning entity or discipline profile.
