# ParticipationStanding

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md, plan/architecture-requirements/discipline-scoring.md  
**Purpose:** A pilot's overall standing in a contest as of a given round, stored so the overall results can be shown without recomputing. There is one row per pilot for each completed round, so the results can be shown as of any round and the overall results can be hidden as of a round. It is derived data, recomputable from flight results and the contest configuration, and replaced whenever it is recomputed.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ContestParticipation  
**Child entities:** None

## Relationships

- Belongs to a ContestParticipation (`contest_participation_id`) with the Pilot role, and to a Contest (`contest_id`, denormalized)
- Computed from the selected FlightResults up to the as-of round and the cumulative penalties on the pilot's official flights
- A pilot's per-round scores shown beside the standing are the selected FlightResults for each round; they are not repeated here

## Fields/Properties

| Field                      | Type        | Required | Default | Description                                                                                                                                                                                                                                                 |
| -------------------------- | ----------- | -------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7      | Yes      | -       | Stable identity                                                                                                                                                                                                                                             |
| `contest_id`               | UUIDv7      | Yes      | -       | FK Contest (denormalized)                                                                                                                                                                                                                                   |
| `contest_participation_id` | UUIDv7      | Yes      | -       | FK ContestParticipation                                                                                                                                                                                                                                     |
| `as_of_round`              | int         | Yes      | -       | Round ordinal the standing is as of. Not a foreign key, because a round can be superseded                                                                                                                                                                   |
| `place`                    | int         | Yes      | -       | Overall place as of the round. Tied pilots share a place                                                                                                                                                                                                    |
| `is_tied`                  | Bool        | Yes      | false   | True when the tie is unresolved after the discipline's tie-breaking rules and any director-enabled tie-breaker                                                                                                                                              |
| `raw_total`                | Decimal     | Yes      | -       | Sum of the pilot's selected round scores up to the round, before dropped rounds and cumulative penalties. Shown as "Raw Score"                                                                                                                              |
| `dropped_rounds`           | JSON        | Yes      | []      | Round ordinals dropped as of this round, chosen after the round scores and penalty metadata are known. Non-droppable zeros are never included                                                                                                               |
| `penalty_total`            | Decimal     | Yes      | 0       | Sum of the cumulative penalties applied to the pilot's official flights up to the round, counting every flight on a current assignment whether or not it is selected, dropped, or re-flown. An absent penalty counts as 0. Never removed by a dropped round |
| `overall_score`            | Decimal     | Yes      | -       | Kept round scores minus the penalty total. Shown as "Score"                                                                                                                                                                                                 |
| `is_preliminary`           | Bool        | Yes      | -       | True while any round up to the as-of round is incomplete for this pilot or the ranking, for example a missing score or an open review                                                                                                                       |
| `config_revision_id`       | UUIDv7      | Yes      | -       | FK ContestConfigurationRevision the standing was computed under                                                                                                                                                                                             |
| `matrix_revision_id`       | UUIDv7      | Yes      | -       | FK MatrixRevision in force when it was computed                                                                                                                                                                                                             |
| `calculation_version`      | String      | Yes      | -       | Version of the calculation logic used                                                                                                                                                                                                                       |
| `computed_at`              | timestamptz | Yes      | -       | When the standing was computed                                                                                                                                                                                                                              |

## Invariants and Constraints

- (`contest_participation_id`, `as_of_round`) is unique
- Only pilots have standings. Non-fliers never do
- Everything here is derived and recomputable. It is never an input, and numeric values are exact decimals, never floating point
- A round the pilot did not fly counts as a zero. A retired round and a round with no assignment credited to it are evaluated as zeros by the calculation without any record, and a retired pilot's zeros are excluded from group normalization
- The percentage of the winning score shown on screen is computed from `overall_score` and the leader's `overall_score`, and is not stored
- Pipeline order: selected round scores, dropped rounds, cumulative penalties, overall score, then ranking
- A standing is stale when its stamps differ from the current configuration revision, matrix revision, or calculation version, and is recomputed before it is shown as official
- While overall results are hidden, only standings with `as_of_round` up to the hidden-through round are served

## Lifecycle

Recomputed by the calculator whenever a flight result, a cumulative penalty, a retirement, a configuration revision, a matrix revision, or the calculation version changes, from the earliest affected round onward. Superseded values are not kept.

## Privacy and Scope

- Internal to the contest and participant views. The public site receives standings only through a publication, which freezes the values shown for each completed round

## Audit and Synchronization

- Written only by the calculator. Other clients receive standings read-only, and they are never merged
- The service recomputes after it receives changed raw scores and does not trust uploaded standings
