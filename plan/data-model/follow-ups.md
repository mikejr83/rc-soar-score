# Follow-ups for the UI Documents and Tickets

The data model, the architecture requirements, and the business requirements were reconciled on this branch. The UI documents under `plan/ui` and some tickets still describe the old model. This brief lists what to change, file by file, so a UI session can start from it.

Where to look for the new rules:

- [contest-options.md](contest-options.md) for every setting a director can make, its default, and when it can change
- [reconciliation-findings.md](reconciliation-findings.md) for what was settled and what is still open
- the entity documents under [entities](entities/) and the [ERD](ERD.md)

## Vocabulary changes

| Old                                                     | New                                                                                                                                                                             |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Visibility `Private`, `Hidden`, `Public`                | Visibility `Unlisted` or `Public`. A contest that is not published is private to its director. `Delisted` is set only by an administrator                                       |
| `PendingDelete`, `Restored`, `Deleted`, deletion status | Gone. Deleting a contest deletes the director's data and never removes a publication. Removing a publication is a delist request (`pending`, `approved`, `denied`, `withdrawn`) |
| Hiding a contest to keep the outcome secret             | Hiding **overall results**: standings are shown as of a round, round scores and flight-group positions stay visible                                                             |
| A participant-entered "Cumulative Penalty"              | A generic **Flight Penalty** entered with the score, and a director-only **Cumulative Penalty**                                                                                 |
| `participation_status` (Pending, Accepted, Active, ...) | `retired_at_round`. An invitation's progress is shown from the invitation                                                                                                       |
| Shared participant profiles                             | A director's profiles are private. A participant offers a **directory entry** that directors copy from                                                                          |
| `ScoreCalculationResult`                                | Stored, recomputable `FlightResult`, `ParticipationStanding`, and `TeamStanding`                                                                                                |
| Landing bonus tables with a revision                    | Immutable landing tables, not tied to a discipline                                                                                                                              |
| `RoundConfig`                                           | `Round`, and the core option `lane_mode`                                                                                                                                        |

## UI documents

### `contest-administration/README.md`

- Contest state presentation: remove the deletion status and the `Private`/`Hidden`/`Public` values. Show lifecycle, participant scoring, administration lock, publication (`Unpublished` or `Published`), visibility (`Unlisted` or `Public`) when published, results hiding (off, or hidden through round N), and local archive.
- Remove the sentence that `PendingDelete` blocks scoring and publication updates.

### `contest-administration/main-page.md`

- Opening a contest: remove the `PendingDelete` and `Deleted` rows.
- Deleting or delisting: rewrite. Any contest can be deleted after confirmation. For a published contest the warning must say the publication remains, loses its link to the contest, and can no longer be updated. A separate **Request delisting** action creates a delist request that an administrator decides. The director can withdraw it while pending. Nothing becomes read-only while a request is pending.
- Roles manager: roles are archived, not deleted. There are no permissions, and an "Official" role is only a label. `Pilot` stays immutable.
- Landing bonuses: manage landing tables that are immutable once created, so a change means a new table. Each entry has a key, a label, and points, and the unit of the key is meters, feet, or points. A table is not tied to a discipline.
- Participant manager: add searching the participant directory and copying an entry into the director's own record, with the email shown as "available to the system" when the participant hides it.

### `contest-administration/contest-workspace.md`

- Configuration groups: use the four groups in `contest-options.md` (structural, scoring rules, recalculating, presentation) and show which can still change in the current lifecycle state. Explain that the discipline field values and the landing table are fixed once the contest is running, and note that a guided fix is planned for a later version.
- A structural change after a draw: warn and offer to redraw the unscored rounds. The director decides, because printed cards for redrawn rounds must be reprinted.
- State actions: add **hide or show overall results** (ends when turned off, when the contest completes, or after 24 hours; the standings stay at the round that was current when it was turned on). Add group and score locks next to the round and contest locks, and show the active installation with the reactivate action.
- Publication: remove the `Private` and `Hidden` values and the pending deletion text. The first publish defaults to **Unlisted**.

### `contest-administration/new-contest-wizard.md`

- Step 5: the contest is created unpublished, with no visibility. Defaults: review requests **on**, group score mode, rounding, and decimals from the discipline profile, and no dropped rounds. Dropped rounds are up to two round numbers, "after round N".
- Add the tie-breaker option, the team pilot count when teams are on, and the optional intended total rounds for seeded contests.
- Draw step: groups per round is entered here and belongs to the draw, not the configuration. Lane mode is none or random.
- Participants step: roles and classes are as before, but a role shows its name as a snapshot, and every participant, officials included, gets one number from one sequence at the first draw.

### `contest-administration/matrix.md`

- Moving a scored pilot is an explicit **reset**: the old score stays in the history and stops counting, and the pilot enters the score again. There is no transfer of a score between groups. Also offer a reset in place (a move to the same slot) for a score entered in the wrong place.
- Adding a late pilot after scores exist: placed in groups that have not flown and have space, up to the largest group size of the original draw. If none has space, say so and offer a redraw of the later unscored rounds, without redrawing on its own. Rounds a late pilot never makes up count as zeros.
- Re-flights: the three methods (move to a group, random draw, re-fly the entire group), re-flight groups numbered after the regular groups, and the group heading "Group 3, re-flight 1". Offers, responses, and notifications are optional in the first release.
- Group locks: lock and unlock a group.

### `contest-administration/official-scoring.md`

- Penalty column: split into the **Flight Penalty** (anyone who enters the score may fill it in) and the **Cumulative Penalty** (director only). Show the cumulative penalty as none, an amount, or "zeroed out" when it was removed.
- Locks: score, group, round, and contest. Overriding a lock needs a recorded reason.
- Review approval creates a new official revision. A participant submission that lost to the director's value is a silent record in the score's history. It does not appear in the list of conflicts that need action.

### `contest-administration/participant-data.md`

- Email is optional, not required. It is private and used for matching with FAI number and national organization ID, never name.
- Remove the rule that shared profiles are read-only. A profile is always the director's own and is never shared. Replace it with the directory pull and refresh.

### `contest-administration/offline-ui.md`

- Sync status: show the contest stream and the director's own stream separately. Outbox rows are `Pending`, `Accepted`, `Rejected`, `Conflict`, or `Skipped`, each with its reason code. Silent conflict records stay out of the action list.
- Installations: list the director's devices by label, show which one is active, and provide **Reactivate as Primary and Sync** after a pull and reconcile.
- Offline deletions: show them to the director before they remove remote data.

### `contest-administration/reports.md`

- Check that standings can be shown as of a round, and that overall results respect the hiding rule.

### `participant-scoring/participant-scoring.md`

- Entry form: replace "cumulative penalty" with the generic **Flight Penalty** input. Show the cumulative penalty read-only once the director applies it.
- A reset returns a round to `Enter`. A late-added pilot may have rows credited to earlier rounds.
- Results and placement: while overall results are hidden, show placement as of the hidden-through round.
- `Request review` is hidden when the score is locked at the score, group, round, or contest level.
- Re-flight view: show which flight supplied the official result and any pending or cancelled re-flight.

### `public-site/view-contest.md`

- "Contest Not Visible": rewrite around unpublished (not found), `Unlisted` (open by link), and `Delisted`. The three example reasons for a private contest become reasons to hide overall results.
- Hidden overall results: show a banner that standings are as of round N. Round scores and flight-group positions stay.
- Overall Individual Results: show the cumulative penalty in the flight where it was given, and sum the penalties in the total. Show the flight penalty as part of each round score.
- Flight Group Scores: the "Penalty" column is the total deducted from the flight (the discipline's penalties plus any entered flight penalty).
- Pilot names come from the participant's public profile when they have one, and a redacted pilot shows `<pilot details private>`.

## New UI likely needed

- Account closure with its three choices, a participant directory settings page, and a public profile editor.
- Confirming a candidate link to a director's participant record.
- The guest claim link and the invitation recovery page.
- The anonymous publish flow with email verification (code valid 10 minutes, resend after 2).
- An administrator view of delist requests, and redaction of a participant with no account.
- Hiding overall results, and the lock controls for a group and a single score.

## Tickets

| Ticket                                                         | What to change                                                                                                                                                                                                                                                                                                                |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pre-implementation/011` (participant identity matching)       | Replace the shared-profile and "director record merged into the shared profile" decisions with the directory entry, candidate links, and a copy that stays the director's own. Matching keys stay email, FAI number, national organization ID                                                                                 |
| `pre-implementation/022` (publish and unpublish rules)         | Publication and visibility are separate, with `Unlisted` and `Public`. There is no unpublish; removal is a delist request                                                                                                                                                                                                     |
| `pre-implementation/023`, `024`, `016`, `004`, `010`           | "Calculation revision" is now stored results stamped with the revisions they were computed under. Ticket 010: the landing-table revision decision is superseded (tables are immutable), and its closed list of calculation-affecting settings moves to `contest-options.md`; the group score mode can change until completion |
| `pre-implementation/021` (mid-contest redraw)                  | Retirement is `retired_at_round`, not a status                                                                                                                                                                                                                                                                                |
| `pre-implementation/020` (penalty authority)                   | Partly answered: the cumulative penalty is director-only and the flight penalty is entered with the score. Disqualification is still open                                                                                                                                                                                     |
| `pre-implementation/007` and `031` (late landing, review flow) | The late-landing penalty stays a discipline penalty. The review proposal can carry the flight penalty but not the cumulative penalty                                                                                                                                                                                          |
| `mvp-implementation/029` and `031` (open and delete or delist) | Remove `PendingDelete`. Deleting never touches a publication, and delisting is a request                                                                                                                                                                                                                                      |
| `mvp-implementation/035` (domain models)                       | The entity inventory is now 48 entities, listed in the README. `RoundConfig`, `ScoreCalculationResult`, and `ContestPenalty` are gone; see the README for the new ones                                                                                                                                                        |
| `mvp-implementation/036` (Drift schema)                        | Same inventory, plus the Sync Scope section, composite foreign keys, enums as text with check constraints, and `scoring_uuid` as a random v4. Derived results are read-only outside the calculator                                                                                                                            |

## Models (decided 2026-10-26)

- Models belong to a participant profile, many per person, and a pilot can enter one or more of them in a contest. Missing models are a notice and never block anything. `model_id` is the contestant-applied identifier and `contest_specific_identifier` the director-applied one (serial number); both are optional.
- Code still has one `ContestModelLink` per participation, a required `model_id`, and a `ModelCatalog` owned by the director account only. Changing them is tracked in #594 and the round-model follow-up.
- The GliderScore mapping plan (outside this folder) still says one link per participation; update it with the importer ticket.

## Questions the UI will force

- How does the director "zero out" a cumulative penalty, and how is it displayed afterwards?
- What does the guest claim link look like, and where does it live?
- How are results hidden and shown again: one control, and how is the 24-hour expiry shown?
- What is the editing flow for locks at the score, group, round, and contest level?
