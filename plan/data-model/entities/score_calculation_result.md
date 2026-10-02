# ScoreCalculationResult

**SEEMS TO HAVE ISSUES - REVISIT REQS**

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md  
**Purpose:** Derived result with provenance for a score component set. All results derived, versioned, and reproducible.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ScoreComponentSet  
**Child entities:** None

## Relationships

- Derived from a specific score component set (cites version)
- Stored separately from score data for reproducibility
- Captures all calculation stages for traceability

## Fields/Properties

| Field                  | Type                                                                                                  | Required | Default | Description                                                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | UUIDv7                                                                                                | Yes      | -       | Stable identity                                                                                                                                                     |
| `official_score_id`    | UUIDv7                                                                                                | Yes      | -       | FK to score's official score                                                                                                                                        |
| `config_revision_id`   | UUIDv7                                                                                                | Yes      | -       | Each revision is immutable, so a score can say exactly which rules it was entered or calculated under, and historical results can be explained or recomputed later. |
| `calculation_stage`    | enum{RawFlightScore,DisciplineRaw,GroupRaw,ContestRaw,DroppedRounds,FinalContestScore,TeamScore,Rank} | Yes      | -       | Calculation stage                                                                                                                                                   |
| `raw_flight_score`     | float                                                                                                 | No       | -       | Raw flight score computed from components                                                                                                                           |
| `discipline_raw_score` | float                                                                                                 | No       | -       | Sum/matrix of raw flight scores within discipline                                                                                                                   |
| `group_raw_score`      | float                                                                                                 | No       | -       | Sum of discipline raw scores for group                                                                                                                              |
| `contest_raw_score`    | float                                                                                                 | No       | -       | Sum of group raw scores across all disciplines                                                                                                                      |
| `rounds_dropped_count` | int                                                                                                   | No       | 0       | Number of rounds dropped in calculation                                                                                                                             |
| `team_score`           | float                                                                                                 | No       | -       | Team's cumulative score for this pilot                                                                                                                              |
| `rank`                 | int                                                                                                   | No       | -       | Overall contest ranking                                                                                                                                             |
| `calculation_version`  | string                                                                                                | Yes      | -       | Version of calculation logic used                                                                                                                                   |
| `computed_at`          | timestamp                                                                                             | Yes      | -       | When result was computed                                                                                                                                            |

## Invariants and Constraints

- All results derived, versioned, and reproducible
- Pipeline: raw→discipline raw→group→contest total→dropped→ranking/team
- Score revision history kept at score level, not result
- All calculations preserve original units and avoid floating-point
- All-zero groups produce zero without division by zero
- Missing, explicit zero, and retired outcomes remain distinguishable
- Results derived from versioned component sets for auditability

## Lifecycle

Computational output. New results computed and stored when scores, configuration, or calculation version changes.

## Privacy and Scope

- Internal to contest administration
- Part of audit trail for calculation validation
- Not shown to general public

## Audit and Synchronization

- Derived from versioned component sets
- Recalculated when scores, configuration, or calculation version changes
- Mutations: creation only (append-only computational history)
- Idempotent: same inputs produce same outputs
