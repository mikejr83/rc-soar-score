# FlightResult

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md, plan/architecture-requirements/discipline-scoring.md  
**Purpose:** The calculated result of one flight, stored so it can be shown without recomputing. It holds the raw points, the landing points, the flight penalty, and the normalized round result that the results screens display. It is derived data: always recomputable from the flight's official components, the contest configuration, and the discipline, never an input to anything, and replaced whenever it is recomputed.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ScorePlaceholder  
**Child entities:** None

## Relationships

- Belongs to one ScorePlaceholder (`score_placeholder_id`), the flight it calculates, and records the OfficialScore version it was computed from (`official_score_id`)
- Belongs to a Contest (`contest_id`, denormalized for scoping) and a ContestParticipation (`contest_participation_id`, denormalized for reading)
- Is credited to a Round (`credited_round_id`, denormalized from the placeholder's assignment)
- Read, with other flights, to compute ParticipationStanding and TeamStanding

## Fields/Properties

| Field                      | Type        | Required | Default | Description                                                                                                                                                                                                   |
| -------------------------- | ----------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7      | Yes      | -       | Stable identity                                                                                                                                                                                               |
| `contest_id`               | UUIDv7      | Yes      | -       | FK Contest (denormalized)                                                                                                                                                                                     |
| `score_placeholder_id`     | UUIDv7      | Yes      | -       | FK ScorePlaceholder. Unique: one current result per flight                                                                                                                                                    |
| `official_score_id`        | UUIDv7      | Yes      | -       | FK OfficialScore version this result was computed from                                                                                                                                                        |
| `contest_participation_id` | UUIDv7      | Yes      | -       | FK ContestParticipation (denormalized)                                                                                                                                                                        |
| `credited_round_id`        | UUIDv7      | Yes      | -       | FK Round the flight is credited to (denormalized)                                                                                                                                                             |
| `outcome`                  | enum        | Yes      | -       | `Scored` or `Zero`. A zero keeps its reason in the official components. Not-entered and retired rounds have no flight and no row                                                                              |
| `raw_points`               | Decimal     | Yes      | -       | The discipline raw score for the flight: flight points plus any landing bonus minus penalties, never below zero. Shown as "Points" or "Raw"                                                                   |
| `landing_points`           | Decimal     | No       | -       | Landing points awarded. Null when the discipline has no landing score or the landing bonus was forfeited                                                                                                      |
| `flight_penalty_points`    | Decimal     | No       | -       | Total penalty points deducted from the flight's raw points: the discipline's own penalties (late landing, launch height) plus any `flight_penalty` entered with the score. Null when none. Shown as "Penalty" |
| `cumulative_penalty`       | Integer     | No       | -       | Copy of the official score's cumulative penalty, so the result can show the flight in which it was given. Null when none was applied; zero when one was applied and removed                                   |
| `group_score`              | Decimal     | Yes      | -       | The normalized round result for the group, rounded or truncated once as configured. Shown as "Score"                                                                                                          |
| `is_selected`              | Bool        | Yes      | true    | Whether this flight supplies the pilot's round result for its credited round. For a re-flight, the discipline's result-selection rule decides which flight is selected                                        |
| `is_preliminary`           | Bool        | Yes      | -       | True while the group or round is incomplete, for example scores are missing or a review is open. A preliminary result is never presented as official                                                          |
| `config_revision_id`       | UUIDv7      | Yes      | -       | FK ContestConfigurationRevision the result was computed under                                                                                                                                                 |
| `matrix_revision_id`       | UUIDv7      | Yes      | -       | FK MatrixRevision in force when it was computed                                                                                                                                                               |
| `calculation_version`      | String      | Yes      | -       | Version of the calculation logic used                                                                                                                                                                         |
| `computed_at`              | timestamptz | Yes      | -       | When the result was computed                                                                                                                                                                                  |

## Invariants and Constraints

- Everything here is derived. It is recomputable from the official components, the configuration, the matrix, and the discipline, and must come out identical. It is never an input to a score, a review, or any other record
- Numeric values are exact decimals, never floating point. Intermediate values are not rounded; only `group_score` is rounded or truncated, once, as configured
- All-zero groups produce a zero `group_score` with no division by zero. Retired pilots are excluded from the group maximum used for normalization
- Among the flights credited to one round for one participation, exactly one scored flight is selected
- A result is stale when its `config_revision_id`, `matrix_revision_id`, or `calculation_version` differs from the current ones. A stale result must be recomputed before it is shown as official
- When an official score changes, the affected group's results and every standing from that round onward are recomputed

## Lifecycle

Created or replaced by the calculator whenever its inputs change: a new official score version, a configuration change, a matrix change, or a calculation version change. Superseded values are not kept. The record of what was shown is the publication.

## Privacy and Scope

- Internal to contest administration and participant results. Public values reach the public site only through a publication, which freezes the values shown
- Participant views receive only the results their access permits

## Audit and Synchronization

- Written only by the calculator: the service, or the active administration installation while offline. Other clients receive results read-only
- Never merged and never part of a conflict. If two sources disagree, the authority recomputes
- The service recomputes after it receives changed raw scores and does not trust uploaded results
