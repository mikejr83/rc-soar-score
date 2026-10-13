# Progress and Needs Attention — Implementation Analysis

Analysis of the "Progress and needs attention" section (Section 4) of the Contest Workspace design brief, mapped against the current Soar Score codebase to determine what can be implemented today and which outstanding work gates the full card. This consolidates the model/service/API analysis done while designing the card.

Source files examined:

- `plan/ui/contest-administration/briefs/workspace.md` (the design brief, Section 4 "Progress")
- `plan/ui/contest-administration/contest-workspace.md` (the page requirement)
- `packages/soar_score_core/lib/services/contest_scores.dart` (`ContestScores`, `ScoreSlot`, `RoundProgress`)
- `packages/soar_score_core/lib/services/scores_service.dart` (`ScoresService.list`)
- `packages/soar_score_core/lib/services/f5j_results_input.dart` (the retirement-aware "incomplete" rule)
- `packages/soar_score_core/lib/services/matrix/matrix_service.dart` (draw excludes retired pilots)
- `packages/soar_score_core/lib/models/scores/{score_placeholder,official_score,review_request,score_attempt}.dart`
- `packages/soar_score_core/lib/models/matrix/{current_matrix,round,round_group,matrix_assignment}.dart`
- `packages/soar_score_core/lib/models/participants/contest_participation.dart`
- `packages/soar_score_core/lib/enums/{score_placeholder_state,review_request_state}.dart`
- `packages/soar_score_api/lib/client/api_client.dart` (client surface)
- `packages/soar_score_api_handlers/lib/handlers/scores_handlers.dart`
- `packages/soar_score_data/lib/repositories/{score_placeholder,matrix_assignment}_repository.dart`
- `apps/soar_score_contest/lib/services/matrix/round_progress_view.dart` (`RoundProgressView`, the matrix page's round states)
- `apps/soar_score_contest/lib/pages/contest_workspace_page.dart` (current workspace page)
- Claude design workspace export: `Contest Workspace Canvas.dc.html` (section 4) and `Contest Workspace.dc.html` (the live component, attention and progress sections)
- GitHub issues #120, #342, #343, #344, #345, #250, #285, #145, #92, #123 (status rechecked 13 Oct 2026; #120 and #342 to #344 are now closed)

## What the design specifies

The **Progress and needs attention** card answers "are we on track, and what needs a look right now?" It has two parts.

### 1. Round strip

A horizontal row of chips, one per round of the current matrix, showing how far each round has been scored. From the brief's lifecycle examples: a completed round, the current round ("Round 4 of 8 · scoring in progress"), an unflown round, and upcoming rounds. Each state carries an icon plus text — never colour alone.

### 2. Needs-attention list

A short list of things that need a director's attention, each linking to the page where it is fixed (the Scoring page at the relevant round). From the brief's Running example ("4 pilots missing scores in round 3", "1 open review request"):

- **Missing scores** — a round that a later round has overtaken but is not fully scored: "Round N — K missing".
- **Unflown round** — a round before the current round with no scores at all: "Round N not flown".
- **Open review request** — a pilot's score review still awaiting a decision: "Review from Pilot — Round N".
- **Empty state** — when nothing needs attention: "Everything is up to date."

Rows are aggregated **per round** (no per-group rows); group-level detail lives on the Scoring page. The current round follows the same rule as rounds: the latest round with scores.

## What the design canvas adds (section 4, checked against the live component)

The rendered canvas refines the brief in ways the analysis above does not capture. The live component (`Contest Workspace.dc.html`, sections `ws-sec-attention` and `ws-sec-progress`) is the reference implementation; canvas frames 4a–4g show its variants.

### Progress card

- A **"Where we are" headline** above the tiles: large "Round 3 of 8" with a quiet sub-line "Group B of 4 · latest accepted score 13:31". Before the contest it reads "No scores yet · N rounds · M groups of K · matrix revision R"; after it, "Final · All N rounds flown · completed {when} · {total} scores".
- A **"lag note"** (informational, not a warning): while the current round is in progress, "Round N, group G: K of M pilots haven't entered scores yet. That's normal right after a group lands. They count as missing only once the round is finished." This is the design's answer to the "missing vs. not yet entered" question (canvas §9.8): a round is treated as finished once a later round has a score.
- The tiles are a **wrapping grid of buttons** (`minmax(100px,1fr)`), not a single row of chips. Each tile: label "Round N", count "13/24" (or "—" when not drawn), a state line, an icon, and a 4 px progress bar.
- Tile states and their styling (icon never stands in for text):
  - `done`, complete — `check_circle`, "Scored", neutral border;
  - `done`, incomplete — `warning`, "K missing", **warning-coloured border** (this is the "warning outline and a count" the canvas caption describes);
  - `prog` — primary colour and tinted background, `timelapse`, "In progress";
  - `undrawn` (seeded mode, rounds past the drawn set) — dashed border, `grid_off`, "Not drawn";
  - `notFlown` — `radio_button_unchecked`, "Not flown".
- Every tile opens **Scoring at that round**; the accessible label carries the full state ("Round 3: In progress, 13 of 24 pilots scored. Open in Scoring.").
- Empty state: dashed outline, "No matrix yet — round progress appears here once the matrix is drawn."
- The card shows while Running and after completion (final progress); before Running it shows only once a matrix exists (frame 4e is the not-drawn variant).

### Needs attention

- Each row: an icon + **count badge** (pill), a title, a body with per-round detail, and a **link button** to where it is fixed.
- Rows the component renders:
  - **Missing scores** — "N pilots missing scores in finished rounds", per-round list ("Round 2: 1, Round 3: 3"), link to Scoring;
  - **Open review requests** — "N review requests open", pilot and round, link to the review on the Scoring page;
  - **Rejected sync change** (frame 4f) — "1 change rejected by the server", what was rejected and why, link "See rejected change" into the status bar's sync details;
  - **Empty state** — `check_circle`, "Nothing needs attention", with a confirmation line: finished rounds have every score, no review requests are open, and everything has synced. The empty-state copy depends on sync status as well as scores.
- "Unflown round" from the brief is **not a separate row** in the component — an unflown round behind the frontier is folded into the missing-scores aggregation. That is consistent with the per-round rule above; the design keeps the list to three row types.

## Resolved design decisions for the progress widget

The following decisions resolve the earlier inconsistencies and are the implementation spec for the widget:

- Current round = the latest round **by ordinal** with accepted scores. This is not the round of the most recent score by time: a correction to an earlier round must not move the frontier.
- Current group = the latest group within that round.
- A round is finished once a later round has a score. Missing scores = any group within a finished round that is not fully scored.
- Unflown round is not a separate row; it is folded into missing-scores handling behind the frontier.
- The round summary uses a wrapping grid of round tiles rather than a single compact strip.
- The card is shown only once a matrix exists (`contest-workspace.md`, `WorkspaceLayoutPlan`). Canvas frame 4e ("Before the draw", the "No matrix yet" state) is **dropped**: it would compete with the setup checklist before the draw. The "No matrix yet" state remains only as a fallback when scores are unavailable.
- The “Where we are” headline includes the current round and group plus the latest accepted score when available.
- The needs-attention list includes: missing scores, open review requests, rejected sync change. The review and sync rows arrive with their own gates.
- The empty-state title is “Nothing needs attention.” Its confirmation line says only what the app can verify: until review requests and sync status exist it reads “Every finished round has all its scores.” and widens as each source lands.

## Status of the code (13 Oct 2026)

Corrections to the earlier version of this analysis:

- #120, #342, #343 and #344 are **closed**. `WorkspaceFacts` already carries `rounds`, `latestScore` and `currentGroup`, `WorkspaceFactsLoader` loads scores, and `WorkspaceLayoutPlan` places the `progress` and `attention` slots. Both slots still show a placeholder card.
- `RoundProgress` is **not** retirement-aware. `ScoresService.list` counts every live assignment, so a pilot who retired at or before a round leaves that round permanently "missing". `f5j_results_input.dart` applies the rule; the progress counts do not. Fixed by #371.
- `WorkspaceFacts.latestScore` is the newest score by `setAt`; the frontier must be derived by ordinal (see above).
- `contest_workspace_page.dart` passed `hasAttentionItems: false` with a comment naming #345. #345 is the audit trail; the list is owned by its own ticket (#374).
- `contestScoringPath` takes no round, and the Scoring page is a placeholder until #123.

## What can be built today

- Round tiles in all states, the headline, the lag note, and the missing-scores row. All read data already loaded in `WorkspaceFacts`, plus the round's group count and a total-scores count.
- `RoundProgressView.of(...)` is reused for tile states, not re-derived.
- The final headline leaves out “completed {when}” until `completedAt` exists (#345).

Not buildable yet:

- **Open review requests**: `ApiClient` has no review-request read and there is no server handler. The model exists (`ReviewRequest`, `ReviewRequestState`). Gated by #285 then #145.
- **Rejected sync change** and the “everything has synced” part of the empty state: the contest app has no sync status. `ConflictRecord` exists in core but is not exposed. Gated by #92.
- **Link targets**: the Scoring page (#123) does not exist, so tiles and rows open the placeholder until it does. The route parameter is added now; #123 honours it.

## Tickets

| Work                                                                         | Ticket | Milestone           | Depends on              |
| ---------------------------------------------------------------------------- | ------ | ------------------- | ----------------------- |
| Leave retired pilots out of round progress counts                            | #371   | M1 F5J online slice | none                    |
| Progress summary derivation (tiles, headline, missing by round, shared rule) | #372   | M1 F5J online slice | #371                    |
| Progress card widget and wiring                                              | #373   | M1 F5J online slice | #372                    |
| Needs-attention list with the missing-scores row                             | #374   | M1 F5J online slice | #372                    |
| Open review requests row                                                     | #375   | M3 Self-scoring     | #374, #285, #145        |
| Rejected sync change row and full empty-state copy                           | #376   | M4 Offline and sync | #374, #92, #253         |
| Tile and row deep links at a round and group                                 | #123   | M1 F5J online slice | honours the route param |
| Completion dialog's “missing scores” group reuses the #372 rule              | #250   | M1 F5J online slice | #372                    |
| Locked-by / completed-by wording and the final headline's “completed {when}” | #345   | M1 F5J online slice | none                    |

## Recommended sequencing

1. #371 and #372 in parallel; the derivation tests do not need the fix to be written, but the counts are only right once it lands.
2. #373 and #374 once #372 is in. They share the missing-scores rule; do not write a second copy.
3. Check the demo data has a Running contest with a short finished round (#305) so the cards show something.
4. #375 and #376 when their gates land. They add a source each and widen the empty-state sentence; the card does not change.
