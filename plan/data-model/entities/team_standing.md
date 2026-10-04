# TeamStanding

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md, plan/architecture-requirements/data/teams-roles-models.md  
**Purpose:** A team's standing in a contest as of a given round, stored so team results can be shown without recomputing. The team score is never entered; it is the sum of the highest pilot overall scores on the team, up to the number of pilot scores the contest counts. It is derived data, recomputable from the pilots' standings, and replaced whenever it is recomputed.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Team  
**Child entities:** None

## Relationships

- Belongs to a Team (`team_id`) and a Contest (`contest_id`, denormalized)
- Computed from the ParticipationStanding records of the team's pilots as of the same round

## Fields/Properties

| Field                    | Type        | Required | Default | Description                                                                                                                              |
| ------------------------ | ----------- | -------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                     | UUIDv7      | Yes      | -       | Stable identity                                                                                                                          |
| `contest_id`             | UUIDv7      | Yes      | -       | FK Contest (denormalized)                                                                                                                |
| `team_id`                | UUIDv7      | Yes      | -       | FK Team                                                                                                                                  |
| `as_of_round`            | int         | Yes      | -       | Round ordinal the standing is as of                                                                                                      |
| `place`                  | int         | Yes      | -       | Team place as of the round. Tied teams share a place                                                                                     |
| `is_tied`                | Bool        | Yes      | false   | True when the tie is unresolved after the team tie-breakers (lowest sum of the counted pilots' places, then best individual placing)     |
| `team_score`             | Decimal     | Yes      | -       | Sum of the counted pilots' overall scores                                                                                                |
| `counted_participations` | JSON        | Yes      | []      | Participation ids of the pilots whose scores count, highest score first. Fewer than the configured number when the team has fewer pilots |
| `is_preliminary`         | Bool        | Yes      | -       | True while any counted pilot's standing is preliminary                                                                                   |
| `config_revision_id`     | UUIDv7      | Yes      | -       | FK ContestConfigurationRevision the standing was computed under                                                                          |
| `matrix_revision_id`     | UUIDv7      | Yes      | -       | FK MatrixRevision in force when it was computed                                                                                          |
| `calculation_version`    | String      | Yes      | -       | Version of the calculation logic used                                                                                                    |
| `computed_at`            | timestamptz | Yes      | -       | When the standing was computed                                                                                                           |

## Invariants and Constraints

- (`team_id`, `as_of_round`) is unique
- Only exists when the contest uses teams
- The number of pilot scores counted is the contest's configured team pilot count. A team with fewer pilots counts all of them
- Everything here is derived and recomputable, with exact decimal values. Team totals are never entered as source data
- Non-fliers are never counted
- The percentage of the winning team's score shown on screen is computed, not stored
- Stale when its stamps differ from the current configuration revision, matrix revision, or calculation version

## Lifecycle

Recomputed by the calculator whenever a counted pilot's standing changes. Superseded values are not kept.

## Privacy and Scope

- Team names and standings are visible to participants in the contest. The public site receives team standings only through a publication

## Audit and Synchronization

- Written only by the calculator. Other clients receive team standings read-only, and they are never merged
