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
- GitHub issues #120, #342, #343, #344, #345, #250, #285, #145, #92, #123 (open, checked 10 Oct 2026)

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

The following decisions resolve the earlier inconsistencies and become the canonical implementation spec for the widget:

- Current round = the latest round with accepted scores.
- Current group = the latest group within that round.
- Missing scores = any group within a round before the current frontier that is not fully scored.
- Unflown round is not a separate row; it is folded into missing-scores handling behind the frontier.
- The round summary uses a wrapping grid of round tiles rather than a single compact strip.
- The widget is shown once a matrix exists, even before the contest is Running.
- The “Where we are” headline includes the current round/group plus latest accepted score when available.
- The needs-attention list includes: missing scores, open review requests, rejected sync change.
- The empty state is: “Nothing needs attention.”

## What can be implemented today

The data plumbing for the **progress part** is in place:

- `ApiClient.scores(Id)` → `ContestScores` already returns every score slot plus `RoundProgress` (`roundId`, `ordinal`, `scored`, `total`) per round. `scored`/`total` follow the retirement-aware rules (`ScoresService`, the matrix excludes retired pilots).
- `ApiClient.matrix(Id)` → `CurrentMatrix` with rounds, groups and assignments, so:
  - "K missing" = `total − scored` per round;
  - the current round is the latest round with `scored > 0`;
  - "not flown" = a round ahead of the latest scored round with `scored == 0`;
  - "not drawn" (seeded) = rounds of the intended total beyond the drawn rounds.
- `RoundProgressView.of(...)` already exists in the contest app (`lib/services/matrix/round_progress_view.dart`) with the right state set (not flown / in progress / scored / cancelled) — the same widget the matrix page headers use, so the card should reuse it rather than re-derive states.
- "Latest accepted score" and "current group" (for the "Where we are" sub-line) are specified in **#342** (`latestScore`, `currentGroup`) but that ticket is open, so those facts are not loaded anywhere yet.

Therefore, buildable now without any new data work:

1. **A presentational `ProgressCard` widget**
   — round tiles in all five states, the "Where we are" headline (minus the latest-score sub-line until #342 lands), the lag note, and the empty state. It consumes `ContestScores` + `CurrentMatrix`, both already fetchable. Its per-round derivations (missing counts, frontier, unflown detection) should be a small pure function with unit tests on hand-built `ContestScores`, mirroring #342's test list.2. **The "missing scores" needs-attention row** — the same derivation (rounds behind the frontier that are incomplete, plus unflown rounds) with the per-round detail list.

Not buildable without stubs or fakes:

- **Open review requests** — `ApiClient` has no review-requests method and there is no server handler (`packages/soar_score_api_handlers/lib/handlers/` has no review handler); the model exists (`ReviewRequest`, `ReviewRequestState`) but nothing is exposed. Gated by #285 → #145.
- **Rejected sync change** and the "everything has synced" part of the empty state — the contest app has no sync status today. Gated by #92.
- **Link targets** — the Scoring page (#123) does not exist yet, so tiles and rows would be inert until it does; deep-linking a round/group also depends on #123 supporting it.

## Outstanding tickets that gate the full card

| Design piece                                                                                              | Gate                                                    | Status (10 Oct 2026) |
| --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | -------------------- |
| Page layout: two columns, card order (next step → needs attention → progress), placement of the card      | #120 Contest workspace shell                            | Open                 |
| Facts loading: `WorkspaceFactsLoader`, `rounds`, `latestScore`, `currentGroup`, partial-failure behaviour | #342 Workspace: facts for the next-step card            | Open                 |
| Next-step card sharing the card's column and facts (context for layout work)                              | #343 resolver, #344 widget                              | Open                 |
| "Open review requests" row (repository, API, client read)                                                 | #285 Repository: review requests → #145 review workflow | Open                 |
| "Rejected sync change" row and the synced part of the empty state                                         | #92 Sync status and conflict UI in the contest app      | Open                 |
| "See rejected change" deep link into the status bar                                                       | #92 (status bar sync details, #253)                     | Open                 |
| Tile/row links to Scoring at a round/group                                                                | #123 Official score entry screen (F5J)                  | Open                 |
| Locked-by / completed-by wording the copy can reference                                                   | #345 Audit trail + per-contest read API                 | Open                 |
| Completion dialog's "missing scores" group (reuses this card's derivations)                               | #250 Contest state controls in the workspace            | Open                 |

## Recommended sequencing

1. Build the `ProgressCard` widget and its pure per-round derivations now, with tests; keep it unplaced (no page wiring), so #120 can drop it into the layout as specified.
2. Model the "missing scores" attention row on the same derivations so #250 and the eventual attention card share one rule set — do not write a second copy.
3. Leave review-requests and sync rows out until #285/#145 and #92 land; the empty-state copy should not claim "everything has synced" until sync status is available.
4. When #342 lands, move the `rounds`/`latestScore`/`currentGroup` derivations into `WorkspaceFacts` and point the card at it (per #120's note to reuse `WorkspaceFacts` rather than loading the same data twice).
