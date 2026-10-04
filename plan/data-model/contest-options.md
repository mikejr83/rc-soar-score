# Contest Options

Everything a director can set for a contest, where each setting is stored, what it defaults to, and when it can change. The settings fall into three kinds. This document is the definition of the core options; the discipline's own fields are defined by its profile.

## The three kinds of setting

1. **Core options.** Defined by the platform and listed below. Stored in the `core` part of a [ContestConfigurationRevision](entities/contest_configuration_revision.md).
2. **Discipline options.** The configurable fields of the discipline profile, such as target or working time, points per second, and the F5J height penalties and motor-restart mode. They are [DisciplineConfigField](entities/discipline_configfield.md) rows with defaults, and the director may change the values as house rules. They are stored in the `discipline` part of the same revision. The director cannot change the discipline's formulas or rules, and cannot change the discipline itself once it is set.
3. **Settings stored elsewhere.**
   - The **landing table** is a link to another record, so it is a column on the revision (`landing_table_id`), not part of the JSON.
   - **Groups per round** is set when the director draws. It is stored on each matrix revision's draw settings and on each round, because a later extension or a redraw of the remaining rounds can use a different number. The configuration screen shows it, but it is not part of the configuration revision.

## How the settings are stored

A configuration revision holds the **full resolved settings**, not only the director's changes:

```json
{
  "core": {
    "group_score_mode": "Normalized",
    "rounding_mode": "Round",
    "decimal_places": 1,
    "drop_after_rounds": []
  },
  "discipline": { "working_time": 600, "points_per_second": 1.0 }
}
```

- A new contest starts from the **platform defaults**, then the profile's `default_options`, then the discipline fields' own defaults. If the director copies a preset or a previous contest, that configuration is the starting point instead.
- Storing every value means a revision never changes meaning, even if a later app version changes a platform default.
- A discipline field is an **override** of the official profile when its value differs from the field's default. That is found by comparison when the settings are read, and no flag is stored. Overrides are shown to the director and never change the shared profile.
- Each change the director saves creates a new revision as a copy with the edited values. The current revision is the one with the highest number.

## Core options

| Key                           | Type and allowed values                         | Platform default   | Group         | Notes                                                                                                                                                         |
| ----------------------------- | ----------------------------------------------- | ------------------ | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `teams_enabled`               | on or off                                       | off                | Structural    | Turns on teams                                                                                                                                                |
| `team_pilot_count`            | integer, 1 or more                              | none               | Recalculating | Number of pilot scores counted for the team result. Required when `teams_enabled`. A team with fewer pilots counts them all                                   |
| `team_protection`             | on or off                                       | off                | Structural    | Only valid when `teams_enabled`. Copied into the matrix revision's draw settings                                                                              |
| `roles_enabled`               | on or off                                       | off                | Structural    | Lets participants be given roles other than Pilot                                                                                                             |
| `draw_mode`                   | `StandardManOnMan` or `SeededManOnMan`          | `StandardManOnMan` | Structural    | Copied into the draw settings as the configured mode                                                                                                          |
| `preliminary_rounds`          | integer, 1 or more                              | 1                  | Structural    | Only valid for `SeededManOnMan`                                                                                                                               |
| `lane_mode`                   | `None` or `Random`                              | `None`             | Structural    | With `None`, pilots are not assigned a lane                                                                                                                   |
| `group_score_mode`            | `Raw`, `Normalized`, or `Time`                  | `Normalized`       | Recalculating | Profile default for ALES is `Time`                                                                                                                            |
| `rounding_mode`               | `Round` or `Truncate`                           | `Round`            | Recalculating | Applied once, to the final group score. Profile default for F3J is `Truncate`                                                                                 |
| `decimal_places`              | integer, 0 to 3                                 | 1                  | Recalculating | Profile defaults: F3J 1, F5J 1. ALES and Thermal are not specified in the requirements and take the platform default                                          |
| `drop_after_rounds`           | ascending list of up to two integers, 1 or more | empty (no drops)   | Recalculating | `[4]` drops each pilot's lowest round score once round 4 is complete. `[4, 8]` drops a second once round 8 is complete. Non-droppable zeros are never dropped |
| `tiebreaker_enabled`          | on or off                                       | off                | Recalculating | Turns on the automatic tie-breakers                                                                                                                           |
| `classes_enabled`             | on or off                                       | off                | Presentation  | Allows a class for each pilot                                                                                                                                 |
| `models_enabled`              | on or off                                       | off                | Presentation  | Tracks the models each pilot enters                                                                                                                           |
| `participant_numbers_enabled` | on or off                                       | off                | Presentation  | Gives every participant a number from one running sequence                                                                                                    |
| `review_requests_enabled`     | on or off                                       | on                 | Presentation  | Lets participants request a review of a score they submitted                                                                                                  |
| `public_update_mode`          | `Automatic`, `RoundCompletion`, or `Manual`     | `RoundCompletion`  | Presentation  | When eligible results are copied to the public projection                                                                                                     |
| `intended_total_rounds`       | integer, 1 or more, optional                    | none               | Presentation  | Only valid for `SeededManOnMan`. Shown on cards and the public site, for example "Round 4 of 8". Has no effect on the draw                                    |

### Not options

- The completion reminder after 48 hours without a score is a fixed platform value. It is advisory, and the director accepts completion.
- The flight penalty and the cumulative penalty are score components, not contest options. The flight penalty is entered with each score and is part of the round score. The cumulative penalty is not a contest option either. The director applies it to a flight on the official score.
- Scoring access, the administration lock, and the hiding of overall results are contest controls and not configuration.

### Dependencies the service enforces

- The team options need `teams_enabled`. `preliminary_rounds` and `intended_total_rounds` need `SeededManOnMan`.
- `decimal_places` is 0 to 3. `drop_after_rounds` is ascending with at most two entries.
- The discipline field values must satisfy the validation of their `DisciplineConfigField` rows.

## When each group can change

| Group                                                                                                               | Before the draw | After the draw, before any score                                   | Once running (first score entered)                         | Completed |
| ------------------------------------------------------------------------------------------------------------------- | --------------- | ------------------------------------------------------------------ | ---------------------------------------------------------- | --------- |
| **Structural** (teams, team protection, roles, draw mode, preliminary rounds, lane mode)                            | Free            | Allowed, with a warning and an offer to redraw the unscored rounds | Fixed                                                      | Fixed     |
| **Scoring rules** (the discipline's own field values, and the landing table)                                        | Free            | Free                                                               | Fixed (the landing table locks at the first landing score) | Fixed     |
| **Recalculating** (group score mode, rounding, decimal places, drop rounds, tie-breaker, team pilot count)          | Free            | Free                                                               | Allowed, and the calculated results are recomputed         | Fixed     |
| **Presentation** (classes, models, participant numbers, review requests, public update mode, intended total rounds) | Free            | Free                                                               | Free                                                       | Fixed     |

- The discipline never changes once set. The administration lock blocks every change while it is on. After completion only authorized score corrections remain.
- A change to a structural option after a draw never alters existing assignments. The application warns the director and offers a redraw of the unscored rounds, and the director decides, because printed matrix cards for redrawn rounds must be reprinted.
- A recalculating change creates a new configuration revision and every stored result is stale until it is recomputed from the raw data.

## Future: fixing a mistake after scoring starts

The first release fixes the discipline field values and the landing table once the contest is running. A director often only notices a wrong working time, target time, or landing table when the first participants start entering scores, and then they are under pressure to fix it quickly so the contest can move along. A later version should help the director recover, for example with a guided correction that shows what will be recalculated and warns about it, recorded in the audit. The first release defers this, and a mistake must be fixed before the first score is entered.
