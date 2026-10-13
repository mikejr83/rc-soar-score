# Entity JSON Examples

Example rows for every entity in the [data model](../../README.md), written as the JSON the API and the sync stream carry. Field names, enum values, and nullability follow the [entity specifications](../../entities/).

## How the files work

- Each entity has one file, named after its specification: `team.json` goes with [entities/team.md](../../entities/team.md).
- A file is a JSON array of rows, even when it holds a single row. The rows are plain JSON with no comments or extra keys, so a model can load them directly.
- The notes below say what each file holds. Rows appear in the order the notes describe.
- `packages/soar_score_core` tests round-trip every row through its model (`toJson(fromJson(row))` equals the row). Entities without a model yet are skipped until their model lands.

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

## Identity, Participants and Access

The contest has five pilots and one timekeeper. Only Sam has an account of their own, and Taylor, a visitor, joined through an emailed link and so has a guest account. The others have no account, which is normal: the director enters them by hand.

### Account

[`account.json`](account.json) · [specification](../../entities/account.md)

A registered director, a registered pilot, a guest, and a system administrator.

### AccountAlias

[`account_alias.json`](account_alias.json) · [specification](../../entities/account_alias.md)

### AccountIdentity

[`account_identity.json`](account_identity.json) · [specification](../../entities/account_identity.md)

### AccountPublicProfile

[`account_public_profile.json`](account_public_profile.json) · [specification](../../entities/account_public_profile.md)

### ParticipantProfile

[`participant_profile.json`](participant_profile.json) · [specification](../../entities/participant_profile.md)

Dana's own copy of each participant's details. Only the owning director sees them. Taylor has no club, FAI number, or email.

### ParticipantAccountLink

[`participant_account_link.json`](participant_account_link.json) · [specification](../../entities/participant_account_link.md)

Sam's profile is linked to Sam's account because the verified email matched.

### ParticipantDirectoryEntry

[`participant_directory_entry.json`](participant_directory_entry.json) · [specification](../../entities/participant_directory_entry.md)

### ContestParticipation

[`contest_participation.json`](contest_participation.json) · [specification](../../entities/contest_participation.md)

Five pilots and the timekeeper, numbered in one running sequence. Jo's role is the director-defined `NonFlier` role, so Jo has no flights.

### Invitation

[`invitation.json`](invitation.json) · [specification](../../entities/invitation.md)

Sam has a field QR token that lasts the whole contest. Taylor was sent a magic link that expires after 24 hours.

## Teams, Roles and Models

There are two teams of two pilots. Taylor flies without a team. Team protection is on, so teammates never fly in the same group.

### Role

[`role.json`](role.json) · [specification](../../entities/role.md)

A system role has a null `owner_account_id`. The second role is defined by the director.

### Team

[`team.json`](team.json) · [specification](../../entities/team.md)

### TeamMembership

[`team_membership.json`](team_membership.json) · [specification](../../entities/team_membership.md)

### ModelCatalog

[`model_catalog.json`](model_catalog.json) · [specification](../../entities/model_catalog.md)

### ContestModelLink

[`contest_model_link.json`](contest_model_link.json) · [specification](../../entities/contest_model_link.md)

Taylor's home-built model is not in the catalog, so `model_catalog_id` is null.

## Contest and Configuration

Every setting in `config` is defined in [contest-options.md](../../contest-options.md).

### Contest

[`contest.json`](contest.json) · [specification](../../entities/contest.md)

### ContestConfigurationRevision

[`contest_configuration_revision.json`](contest_configuration_revision.json) · [specification](../../entities/contest_configuration_revision.md)

### ContestConfigurationPreset

[`contest_configuration_preset.json`](contest_configuration_preset.json) · [specification](../../entities/contest_configuration_preset.md)

## Disciplines and Landing Tables

One row of each is shown, taken from the ALES profile. The complete sets for ALES, F3J, F5J, and Thermal Duration are in [examples/disciplines](../disciplines/).

### DisciplineProfile

[`discipline_profile.json`](discipline_profile.json) · [specification](../../entities/discipline_profile.md)

### DisciplineConfigField

[`discipline_configfield.json`](discipline_configfield.json) · [specification](../../entities/discipline_configfield.md)

### DisciplineScoreField

[`discipline_scorefield.json`](discipline_scorefield.json) · [specification](../../entities/discipline_scorefield.md)

### DisciplineValidation

[`discipline_validation.json`](discipline_validation.json) · [specification](../../entities/discipline_validation.md)

### DisciplineFormula

[`discipline_formula.json`](discipline_formula.json) · [specification](../../entities/discipline_formula.md)

### DisciplineRule

[`discipline_rule.json`](discipline_rule.json) · [specification](../../entities/discipline_rule.md)

### LandingTable

[`landing_table.json`](landing_table.json) · [specification](../../entities/landing_table.md)

A system table has a null `owner_account_id`.

### LandingResult

[`landing_result.json`](landing_result.json) · [specification](../../entities/landing_result.md)

A score stores this entry's `id`, which fixes the key, the points, and the table.

## Matrix, Assignments and Re-flights

Five pilots fly in two groups per round: a group of three and a group of two. Team protection keeps teammates apart. Sam and Alex (Boulder Thermals) never fly together, and neither do Riley and Morgan (Longmont Lofters). Round 1 is finished and locked. Round 2 is in progress. After round 1, Sam's group flew with a spectator in the landing area, so the director awarded a re-flight of that whole group, flown as group 3 of round 2.

| Round | Group 1              | Group 2      | Group 3 (re-flight of round 1 group 1) |
| ----- | -------------------- | ------------ | -------------------------------------- |
| 1     | Sam, Riley, Taylor   | Alex, Morgan |                                        |
| 2     | Alex, Morgan, Taylor | Sam, Riley   | Sam, Riley, Taylor                     |

### MatrixRevision

[`matrix_revision.json`](matrix_revision.json) · [specification](../../entities/matrix_revision.md)

Eight rounds are drawn. With four pilot pairs apart from the two protected teammates, the draw gives each of the 8 other pilot pairs 4 matchups.

### Round

[`round.json`](round.json) · [specification](../../entities/round.md)

### RoundGroup

[`round_group.json`](round_group.json) · [specification](../../entities/round_group.md)

Round 1 is locked. The re-flight group (group 3) was created when the re-flight group was finalized.

### MatrixAssignment

[`matrix_assignment.json`](matrix_assignment.json) · [specification](../../entities/matrix_assignment.md)

Thirteen rows, in three runs:

1. Rows 1 to 5: the original assignments for round 1, in group order.
2. Rows 6 to 10: the original assignments for round 2.
3. Rows 11 to 13: the re-flight assignments, created when the re-flight group was finalized. They are scheduled in round 2 and credited to round 1, as the second flight of each pilot's round 1.

### ReFlight

[`re_flight.json`](re_flight.json) · [specification](../../entities/re_flight.md)

### ReFlightParticipant

[`re_flight_participant.json`](re_flight_participant.json) · [specification](../../entities/re_flight_participant.md)

Sam was awarded the re-flight. Riley and Taylor re-fly as members of the group. Taylor has not yet acknowledged the notification.

## Scores, Results and Reviews

The contest is scored in `Time` mode: each flight earns 1 point per second, the best flight in the group is normalized to 1000, and the landing bonus is added afterward. The landing bonus is read from the contest's landing table (50 points within 1 m, down to 5 points within 10 m), and a score stores the selected landing entry's id.

Round 1 results:

| Pilot  | Group | Time (s) | Landing    | Flight points | Group best | Normalized | Landing points | Group score |
| ------ | ----- | -------- | ---------- | ------------- | ---------- | ---------- | -------------- | ----------- |
| Sam    | 1     | 585      | within 3 m | 585           | 585        | 1000.0     | 40             | 1040.0      |
| Riley  | 1     | 570      | within 1 m | 570           | 585        | 974.4      | 50             | 1024.4      |
| Taylor | 1     | 540      | within 6 m | 540           | 585        | 923.1      | 25             | 948.1       |
| Morgan | 2     | 597      | within 2 m | 597           | 597        | 1000.0     | 45             | 1045.0      |
| Alex   | 2     | 0        | none       | 0             | 597        | 0.0        | 0              | 0.0         |

Alex restarted the motor, which scores zero. In round 2, Alex's group 1 flight is out of bounds, which also scores zero. The rest of round 2 has not been scored yet.

### ScorePlaceholder

[`score_placeholder.json`](score_placeholder.json) · [specification](../../entities/score_placeholder.md)

One per flight. The first five are round 1. The next is Alex's round 2 flight, and the last is Morgan's round 2 flight, which has not been entered. The other round 2 placeholders and the three re-flight placeholders are also `NotEntered` and are left out.

### ScoreAttempt

[`score_attempt.json`](score_attempt.json) · [specification](../../entities/score_attempt.md)

A normal flight, a motor restart, and (last) an out of bounds landing. Sam, Riley, and Taylor are normal flights, Morgan too. Only one zero reason can be set, and a zero records the flight time as 0 and no landing.

### OfficialScore

[`official_score.json`](official_score.json) · [specification](../../entities/official_score.md)

A zero reason is kept in the components as `zero_reason`.

### FlightResult

[`flight_result.json`](flight_result.json) · [specification](../../entities/flight_result.md)

The out of bounds result is preliminary because round 2 group 1 is not yet complete.

### ParticipationStanding

[`participation_standing.json`](participation_standing.json) · [specification](../../entities/participation_standing.md)

Overall standings as of round 1, with no rounds dropped yet.

### TeamStanding

[`team_standing.json`](team_standing.json) · [specification](../../entities/team_standing.md)

Each team counts the scores of its best two pilots (`team_pilot_count` is 2).

### ReviewRequest

[`review_request.json`](review_request.json) · [specification](../../entities/review_request.md)

Taylor's request to change the flight time was rejected, so the score stays official.

## Publication

The publication shows the contest after round 1, as published at the end of the round.

### PublicationIdentity

[`publication_identity.json`](publication_identity.json) · [specification](../../entities/publication_identity.md)

### PublicationProjection

[`publication_projection.json`](publication_projection.json) · [specification](../../entities/publication_projection.md)

The JSON sections are frozen copies. Pilots appear only as `pilot_key`, and identifying details live in PublicationParticipant.

### PublicationParticipant

[`publication_participant.json`](publication_participant.json) · [specification](../../entities/publication_participant.md)

One row per pilot.

### DelistRequest

[`delist_request.json`](delist_request.json) · [specification](../../entities/delist_request.md)

## Synchronization and Audit

### Installation

[`installation.json`](installation.json) · [specification](../../entities/installation.md)

### InstallationActivation

[`installation_activation.json`](installation_activation.json) · [specification](../../entities/installation_activation.md)

### SyncCursor

[`sync_cursor.json`](sync_cursor.json) · [specification](../../entities/sync_cursor.md)

### MutationRecord

[`mutation_record.json`](mutation_record.json) · [specification](../../entities/mutation_record.md)

### ConflictRecord

[`conflict_record.json`](conflict_record.json) · [specification](../../entities/conflict_record.md)

### Tombstone

[`tombstone.json`](tombstone.json) · [specification](../../entities/tombstone.md)

### AuditEvent

[`audit_event.json`](audit_event.json) · [specification](../../entities/audit_event.md)
