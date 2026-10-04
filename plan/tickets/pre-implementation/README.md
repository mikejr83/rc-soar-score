# Pre-Implementation Tickets

Outstanding questions that need to be answered before implementation begins. Each ticket is a markdown file in this folder, named `<NNN>-<category>-<slug>.md`.

## How to use

- Each ticket has a **Category**, **Priority**, **Status**, **Context**, **Questions**, **Decisions Needed**, and **Sources**.
- Answer the questions, record the decision, and flip `Status` from `Open` to `Decided` (add a `Decision:` line summarizing the answer).
- Priority is a guide for ordering, not a hard gate: **High** items block core architecture or the scoring pipeline; **Medium** items shape features; **Low** items are edge cases that can be deferred.

## Index by category

### Data Model / Schema

| Ticket                                           | Title                                                    | Priority |
| ------------------------------------------------ | -------------------------------------------------------- | -------- |
| [001](001-data-team-membership-cardinality.md)   | Team Membership Cardinality (Ready)                      | Medium   |
| [002](002-data-lane-assignment-revision.md)      | Lane Assignment: Derived or Independent Revision (Ready) | Medium   |
| [003](003-data-matrix-revision-granularity.md)   | Matrix Revision Granularity (Ready)                      | High     |
| [004](004-data-config-override-scope.md)         | Configuration Override Scope (Ready)                     | Medium   |
| [011](011-data-participant-identity-matching.md) | Participant Identity and Cross-Contest Matching (Ready)  | High     |
| [012](012-data-score-status-enum.md)             | Score Outcome Status: Not Entered, Zero, Retired (Ready) | Medium   |

### Scoring Engine

| Ticket                                                 | Title                                                          | Priority |
| ------------------------------------------------------ | -------------------------------------------------------------- | -------- |
| [005](005-scoring-f5j-reference-height.md)             | F5J Height Penalty: Reference Height Default and Scope (Ready) | High     |
| [006](006-scoring-time-vs-normalized-rounding.md)      | Time vs. Normalized Group-Score Rounding                       | Medium   |
| [007](007-scoring-f3j-late-landing-penalty.md)         | F3J Fixed Late-Landing Penalty                                 | Medium   |
| [008](008-scoring-normalized-retired-pilot.md)         | Normalized Scoring: Retired Pilot in Group Maximum (Ready)     | Low      |
| [009](009-scoring-f5j-nondroppable-all-zeros.md)       | F5J Non-Droppable Zero: All-Zeros Edge Case (Ready)            | Low      |
| [010](010-scoring-recalculation-invalidation-scope.md) | Recalculation Invalidation Scope (Ready)                       | Medium   |

### Offline Sync

| Ticket                                       | Title                                        | Priority |
| -------------------------------------------- | -------------------------------------------- | -------- |
| [013](013-sync-score-edit-conflict.md)       | Score Edit Conflict Resolution (Ready)       | High     |
| [014](014-sync-matrix-score-ordering.md)     | Matrix Change + Score Entry Ordering (Ready) | High     |
| [015](015-sync-partial-failure-atomicity.md) | Partial Failure Mid-Sequence (Ready)         | Medium   |
| [016](016-sync-config-contention.md)         | Concurrent Config Edits (Ready)              | Low      |

### Access / Permissions

| Ticket                                            | Title                                                  | Priority |
| ------------------------------------------------- | ------------------------------------------------------ | -------- |
| [017](017-access-helper-role-capabilities.md)     | Helper Role Capabilities (Ready)                       | High     |
| [018](018-access-pilot-helper-score-conflict.md)  | Pilot Self-Scoring vs. Helper Scoring Conflict (Ready) | Medium   |
| [019](019-access-public-site-draft-visibility.md) | Public Site Visibility of In-Progress Scores           | Medium   |
| [020](020-access-director-penalty-authority.md)   | Director Penalty and Disqualification Authority        | Low      |

### Contest State Machine

| Ticket                                       | Title                                 | Priority |
| -------------------------------------------- | ------------------------------------- | -------- |
| [021](021-state-mid-contest-redraw.md)       | Mid-Contest Draw Regeneration (Ready) | High     |
| [022](022-state-publish-unpublish-rules.md)  | Publish/Unpublish Rules for Results   | Medium   |
| [023](023-state-contest-ended-reversible.md) | Is "Contest Ended" Reversible?        | Low      |
| [024](024-state-round-completion-gate.md)    | Round Completion Gate                 | Medium   |

### Matrix / Draw

| Ticket                                           | Title                                               | Priority |
| ------------------------------------------------ | --------------------------------------------------- | -------- |
| [025](025-matrix-draw-engine-recommendations.md) | Adopt GliderScore Research Recommendations (Ready)  | High     |
| [026](026-matrix-seeded-round-order.md)          | Seeded Round Order (Leaders First vs. Last) (Ready) | High     |
| [027](027-matrix-seeded-team-protection.md)      | Seeded + Team Protection                            | Medium   |
| [028](028-matrix-back-to-back-constraint.md)     | Back-to-Back Constraint                             | Low      |
| [029](029-matrix-lane-count-source.md)           | Lane Count (Configured vs. Derived)                 | Low      |
| [030](030-matrix-fairness-score-scale.md)        | Fairness Score 0–100% Scale Anchor                  | Low      |

### UI / UX

| Ticket                                  | Title                                      | Priority |
| --------------------------------------- | ------------------------------------------ | -------- |
| [031](031-ui-score-review-workflow.md)  | Score Review Workflow (Pilot View) (Ready) | High     |
| [032](032-ui-offline-capable-pages.md)  | Offline-Capable Pages                      | Medium   |
| [033](033-ui-score-entry-responsive.md) | Responsive Layout for Score Entry          | Medium   |

### Business Rules

| Ticket                                            | Title                                                          | Priority |
| ------------------------------------------------- | -------------------------------------------------------------- | -------- |
| [034](034-business-reflight-decline-limits.md)    | Re-Flight Decline Limits                                       | Medium   |
| [035](035-business-reflight-better-of-scoring.md) | Re-Flight "Better Of" Scoring                                  | Medium   |
| [036](036-business-out-of-bounds-measurement.md)  | Out-of-Bounds Landing Distance Measurement (Ready)             | Low      |
| [037](037-business-no-altitude-recorded.md)       | F5J "No Altitude Recorded" — Purpose and Drop Behavior (Ready) | Low      |
| [038](038-business-ales-thermal-overflight.md)    | ALES/Thermal Target-Time Over-Flight (Ready)                   | Medium   |

## Suggested answer order (High priority first)

### Addressed

1. ~~005~~ — F5J reference height default and scope ✅
2. ~~011~~ — Participant identity and cross-contest matching ✅
3. ~~003~~ — Matrix revision granularity ✅
4. ~~013~~ — Offline sync: score edit conflict resolution ✅
5. ~~014~~ — Offline sync: matrix change + score entry ordering ✅
6. ~~017~~ — Helper role capabilities ✅
7. ~~021~~ — Mid-contest draw regeneration ✅
8. ~~026~~ — Seeded round order (leaders first vs. last) ✅
9. ~~031~~ — Score review workflow (pilot view) ✅

### Remaining

(None listed here, but several tickets are still `Open`. See [data-model-triage.md](data-model-triage.md) for which of them affect the data model.)
