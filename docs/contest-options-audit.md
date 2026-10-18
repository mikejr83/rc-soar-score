# Contest options audit

Audit of the core contest options in `plan/data-model/contest-options.md` (issue #154). Checked against master on 2026-10-18.

## How to read this

- **Persisted and validated.** Every core option is a field of `CoreOptions` (`packages/soar_score_core/lib/models/contest/core_options.dart`), which validates types, ranges and dependencies and is stored in the `core` part of a configuration revision. The contest app edits all of them except `lane_count` on the contest configuration page (`apps/soar_score_contest/lib/services/configuration/setting_catalog.dart`, rules in `configuration_validation.dart`). The state rules for when a group can change are in `contest_configuration_rules.dart`.
- **Honoured** means something other than storage and display reads the option and behaves differently.
- **Stored only** means the option is saved and shown, and nothing else reads it yet.
- Paths below are relative to `packages/soar_score_core/` unless noted.

## Recalculating options

These change standings, so each has a test in `test/scoring/recalculation/options_change_results_test.dart` that fails if the option is stored but ignored.

| Key                  | Honoured by                                                      | Proving test                    | Status   |
| -------------------- | ---------------------------------------------------------------- | ------------------------------- | -------- |
| `group_score_mode`   | `scoring/group/group_score_calculator.dart`, `ResultsService`    | `group_score_mode changes ...`  | Honoured |
| `rounding_mode`      | `scoring/group/group_score_options.dart`, `ResultsService`       | `rounding_mode changes ...`     | Honoured |
| `decimal_places`     | `scoring/group/group_score_options.dart`, `ResultsService`       | `decimal_places changes ...`    | Honoured |
| `drop_after_rounds`  | `scoring/totals/contest_total_calculator.dart`, `ResultsService` | `drop_after_rounds changes ...` | Honoured |
| `tiebreaker_enabled` | `scoring/standings/rank_pilots.dart`, `ResultsService`           | `tiebreaker_enabled breaks ...` | Honoured |
| `team_pilot_count`   | `scoring/standings/rank_teams.dart`, `ResultsService`            | `team_pilot_count changes ...`  | Honoured |

## Structural options

| Key                  | Honoured by                                                                                 | Test                                                                     | Status                   |
| -------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | ------------------------ |
| `teams_enabled`      | draw (`matrix_service.dart`), results (teams only ranked when present), configuration rules | `contest_configuration_rules_test.dart`, `matrix_handlers_test.dart`     | Honoured                 |
| `team_protection`    | draw (`matrix_service.dart`, `matrix_redraw_service.dart`)                                  | `matrix_handlers_test.dart`, `matrix_moves_handlers_test.dart`           | Honoured                 |
| `roles_enabled`      | configuration rules only (locked while running). No participant or scoring screen reads it  | `contest_configuration_rules_test.dart`                                  | Stored only              |
| `draw_mode`          | draw (`matrix_draw_builder.dart`, `matrix_service.dart`)                                    | `matrix_handlers_test.dart`, `contest_configuration_rules_test.dart`     | Honoured                 |
| `preliminary_rounds` | validation, matrix page and config drift check (app). Not used by the draw itself           | `core_options_test.dart`                                                 | Honoured in the app only |
| `lane_mode`          | draw (`basic_draw.dart`, `draw_engine.dart`, `matrix_slot_rules.dart`)                      | `matrix_moves_handlers_test.dart`, `matrix_late_adds_handlers_test.dart` | Honoured                 |
| `lane_count`         | nowhere. Not implemented                                                                    | none                                                                     | Missing, #256            |

## Presentation options

| Key                           | Honoured by                                                          | Test                                                        | Status                   |
| ----------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------- | ------------------------ |
| `classes_enabled`             | setup checklist row text only (app). No class field is shown or used | `contest_configuration_page_test.dart`                      | Stored only              |
| `models_enabled`              | nowhere                                                              | none                                                        | Stored only              |
| `participant_numbers_enabled` | matrix page and grid (app), configuration rules                      | `matrix_page_grid_test.dart`, `matrix_page_phone_test.dart` | Honoured                 |
| `review_requests_enabled`     | nowhere. The review request flow does not read it                    | none                                                        | Stored only              |
| `public_update_mode`          | `services/publication/public_update_service.dart`                    | `public_update_service_test.dart`                           | Honoured                 |
| `intended_total_rounds`       | workspace progress and next-step resolver (app)                      | `next_step_precedence_test.dart`                            | Honoured in the app only |

## Participant options

Classes, models, participant numbers, roles and teams are the options above. Participant records already hold the fields (class, models, number, role, team), but only teams and participant numbers change behaviour. Classes, models and roles are the gaps.

## Discipline-specific code in the scoring path

- Profile defaults come from discipline data: the F3J truncate and ALES time defaults live in the system profiles (`models/discipline/system/`), not in code branches.
- `ResultsService` calls `_requireF5j` and the only engine entry point is `recalculateF5jContest`, so results run for F5J contests only and any other discipline is rejected with `discipline_not_supported`. The F3J, Thermal and ALES calculators exist but are not wired into results. This is acceptable for the alpha. It needs a follow-up before other disciplines can be scored.

## Gaps and follow-ups

Follow-up issues are linked here once filed.

| Gap                                                                      | Milestone                   | Issue |
| ------------------------------------------------------------------------ | --------------------------- | ----- |
| `lane_count` not implemented                                             | Disciplines, draw, accounts | #256  |
| Results service runs F5J only                                            | Disciplines, draw, accounts | #472  |
| `roles_enabled`, `classes_enabled`, `models_enabled` stored but not used | Disciplines, draw, accounts | #473  |
| `review_requests_enabled` not read by the review request flow            | Disciplines, draw, accounts | #474  |
| `preliminary_rounds` not read by the draw (only by the app)              | Disciplines, draw, accounts | #475  |
