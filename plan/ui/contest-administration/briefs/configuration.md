# Design brief: Contest Configuration — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Contest Configuration page** in the contest director's administration app: where the director reviews and changes everything that defines how one contest is run and scored. Please produce a canvas/prototype with the page structure, every section, the save flow, the lifecycle-dependent locking, and the responsive behaviour.

**The problem to solve:** the current page was a placeholder. It's one long column of cards, most values are read-only text, the discipline's own settings and the landing table aren't shown at all, and Save sits at the bottom of a long scroll. It also carries controls that don't belong (scoring access and the administration lock, which now live on the Workspace) and a "Draw matrix" button (drawing now happens only on the Matrix page).

**Users:** contest directors (CDs). Most configuration happens at home before the event on a laptop or tablet: they set up the contest in the New Contest Wizard, then come back here over the following days or weeks to adjust it as pilots register and the date nears. On contest day they may need to fix something at the field, on a tablet, in bright sun, sometimes offline. They know their discipline's rules well but don't configure contests often, so every option needs a plain one-line explanation.

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger** (admin). It must still work with browser text zoom and large system fonts.
- **Never use colour alone for state.** Every status (changed, overridden, locked, invalid) has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements.

**Existing app shell (the page lives inside it):**

- A persistent shell with a contest-scoped navigation rail on the left (expandable to labels on wide windows): Workspace, **Configuration** (this page), Matrix, Scoring, Reports. The page is at `/contest-administration/contests/:id/configuration`.
- A slim header naming the page, with the contest name and breadcrumbs or back navigation.
- A **shell status panel** under the header on every contest page: a read-only summary of lifecycle, participant scoring, and administration lock.
- A content area with **one clear primary action per page state**. Here that is **Save configuration** when there are unsaved changes.
- A persistent **status bar at the bottom** showing connectivity, sync state, and so on.
- Related briefs: [workspace.md](workspace.md) (contest controls), [matrix.md](matrix.md) (the draw form and its disabled-reason pattern, reused here), [landings.md](landings.md) (the landing-table entry list, reused here as a preview), and [new-contest-wizard.md](new-contest-wizard.md) (which sets most of these values first; keep the controls consistent with it).

## Page structure

A **single scrolling page divided into sections**, with:

- An **in-page section list**: a side list on tablet landscape that tracks the scroll position (scroll-spy) and jumps to a section; a horizontally scrolling chip row on narrow widths. Each entry shows a marker when its section has unsaved changes, errors, or is locked, with text and an icon, not just a dot.
- **One draft for the whole page.** Edits anywhere join the same draft; nothing saves on its own.
- A **sticky save bar** that appears when the draft differs from the saved configuration: the number of changed settings, the combined **impact** of those changes (see below), **Save configuration** (primary), and **Discard changes**. It stays visible while scrolling. Say where it docks (bottom of the content area, above the status bar, is the default) and how it avoids covering the last field.
- A page header area: "Configuration revision 7 · saved 2 hours ago by you" and, if useful, a link to revision history (a later page; leave the link and say where it goes).

## Sections

In this order. Each section has a title, a one-line purpose, and its settings. Each setting has a label, a control, a one-line explanation, and (when relevant) a unit.

### 1. Contest details

Name (required), start and end date (required), timezone, host/venue (required), city, state/province, country. These are contest details, not revisioned configuration, and don't affect the matrix or scores. Say so quietly.

### 2. Discipline and rules

- **Discipline** (ALES, F3J, F5J, or Thermal Duration) and its rules version: **read-only**. The discipline never changes once set. Explain that in one line.
- **Discipline options**: the discipline's own settings, which differ by discipline. They come from the discipline profile, each with a type, unit, default, and validation. Design for any set of number, decimal, on/off, and choice fields rendered from that definition, and show these real examples:
  - **F3J:** Working time (seconds, default 600), Points per second (1.0), Fractional seconds.
  - **F5J:** Working time (600 s), Points per second (1.0), Fractional seconds, Motor restart mode (choice, default "allowed"), Reference launch height (200 m), Minor penalty per metre, and the other height penalties.
  - **ALES:** Target time, Points per second, Fractional seconds.
- **House rules (overrides):** a discipline option whose value differs from the official profile's default is an **override**. Mark it clearly (for example an "Official: 600 s" note and a "House rule" marker with an icon), offer **Reset to official** per option, and show a section summary such as "2 house rules". Overrides are legitimate and must not look like errors. Deviations never change the discipline itself.
- Time values: decide whether durations are entered as seconds or mm:ss and say why; the stored unit is seconds.

### 3. Landing table

- The contest's **landing table** (the key-to-points lookup scorers use for landing bonuses): show its name, owner (System or Yours), unit (Meters, Feet, or Points), entry count, and points range.
- **Change table:** a picker listing every table the director can use (system and their own), grouped as in the Landings page, with the unit visible and the **discipline's default marked** ("F3J default"). Any table can be chosen for any discipline; the unit is the hint. Selecting a table shows a **preview** using the same entry-list component as the Landings page.
- A link to the Landings page to view or create tables. Creating a table there and coming back must keep the draft.
- **Locks at the first landing score.** After that the control is disabled with the reason beside it.

### 4. Scoring

- **Group score:** Raw (raw points), Normalized (the group winner gets 1000 and others are scaled), or Time (normalized on time, then landing bonuses are added). Each option with its one-line meaning. Default comes from the discipline (Normalized; ALES is Time).
- **Rounding:** Round or Truncate, plus **Decimal places** 0 to 3. Show a live example ("987.654 → 987.7") so the effect is concrete.
- **Drop worst rounds:** up to two drops, each "after round N" (ascending; the second must be later than the first). Show it as "Drop the worst round after round 4, and a second after round 8". Explain that zero scores that can't be dropped never are.
- **Tie-breakers:** on/off.
- **Team score:** "Count the best N pilot scores" (shown when teams are on; required, 1 or more). A team with fewer pilots counts them all.

### 5. Participant options

On/off options, each with a line on what it changes on the Participants page:

- **Teams** (turning on requires the team score count above; makes team protection available).
- **Roles** (participants can have roles other than Pilot).
- **Classes** (a class per pilot, used only in reports).
- **Models** (track the models each pilot flies).
- **Participant numbers** (one running number for every participant, assigned at the first draw and fixed after. After the draw, show that numbers are assigned and can't be changed).

### 6. Participants (summary only)

Counts of scoring pilots, other participants, teams, and classes when enabled, with a link to the contest's Participants page. Participants are edited there, not here. Show a warning when there are fewer than two scoring pilots ("A matrix needs at least 2 scoring pilots").

### 7. Draw options

- **Draw mode:** Man on Man (default; maximises the variety of opponents) or Seeded Man on Man (after preliminary rounds, each new round groups pilots with similar scores).
- **Seeded only:** **Preliminary rounds** (Man on Man rounds before seeding; 1 or more, default 1) and **Intended total rounds** (optional, display only, shown as "Round 4 of 8" on score cards and the public site; has no effect on the draw).
- **Team protection** (only when teams are on): pilots on the same team never fly in the same group. Note that it raises the minimum groups per round to the size of the largest team.
- **Team protection and Seeded mode can't both be on.** The page must prevent choosing both and explain why, in both directions (choosing Seeded with protection on, and turning protection on in Seeded mode). Design how the blocked option reads and what it offers.
- **Lanes:** None or Random.
- **Groups per round** is chosen on the Matrix page at draw time, not here. After a draw, show it read-only.

### 8. Public updates and reviews

- **Public update policy:** Automatic, At round completion (default), or Manual. One line each on when the public site updates.
- **Review requests:** on/off (participants can request a review of a submitted score).

### Matrix readiness (a panel, not a section)

Configuration no longer draws the matrix. Instead, show a compact **matrix readiness** panel (decide where: top of the page, end of the Draw options section, or beside the section list on wide screens):

- **Before a draw:** whether the matrix can be drawn. If not, the reasons, using the **same disabled-reason pattern as the Matrix page draw form** (locked, completed, fewer than two scoring pilots, configuration invalid with what's missing). A **Go to matrix** link, never a draw button.
- **After a draw:** matrix revision, rounds, groups, group sizes; and when the saved configuration differs from the settings the matrix was drawn with, which setting differs and that the matrix is unchanged until the director redraws on the Matrix page.
- **Unsaved changes that affect the matrix:** say that saving them will make the drawn matrix out of date.

## Impact, lifecycle, and locking

Settings fall into four kinds, and the kind decides what saving does and when the setting can change. Show this per section (a compact label next to the section title, plus per-setting detail where a section mixes kinds), and roll it up in the save bar.

| Kind          | Settings                                                                                           | Before the draw | After the draw, before any score | Running (first score accepted)             | Completed |
| ------------- | -------------------------------------------------------------------------------------------------- | --------------- | -------------------------------- | ------------------------------------------ | --------- |
| Structural    | Teams, team protection, roles, draw mode, preliminary rounds, lanes                                | Free            | Allowed; matrix becomes outdated | Fixed                                      | Fixed     |
| Scoring rules | Discipline options, landing table                                                                  | Free            | Free                             | Fixed (landing table: first landing score) | Fixed     |
| Recalculating | Group score, rounding, decimal places, drop rounds, tie-breakers, team score count                 | Free            | Free                             | Allowed; results are recalculated          | Fixed     |
| Presentation  | Classes, models, participant numbers, review requests, public update policy, intended total rounds | Free            | Free                             | Free                                       | Fixed     |

- **Fixed** settings are shown disabled with the reason beside them (for example "Fixed once scoring has started"). Not hidden.
- **Administration locked:** the whole page is read-only, with one notice at the top and a link to the Workspace control that unlocks it.
- **Completed:** the whole page is read-only. Only score corrections remain, and those happen elsewhere.
- **Saving a change with impact** asks for confirmation that names it: "Draw mode changed. The drawn matrix (revision 2) no longer matches; redraw unscored rounds on the Matrix page." or "Decimal places changed. All results will be recalculated." Saving with no impact needs no dialog.

## Validation and save

- Validation runs as the director types. Errors appear **inline** and in a **summary at the top of the save bar or page** that links to each field. Section list entries show an error marker. Save is disabled while there are errors, with the reason.
- Dependent settings appear and disappear with their parent (team options with Teams; seeded options with Seeded). When hiding a field that holds a value, say the value will be cleared on save.
- **Busy:** the save bar shows progress, the page locks, and a repeated tap is ignored.
- **Save failed:** every entered value stays; the error shows in the save bar with **Retry** and **Discard**.
- **Conflict (stale revision):** someone else saved first (another device, or a sync). Show which settings differ between their revision and the draft, and offer **Reload and keep my changes where possible** or **Discard mine**. Design this comparison.
- **Leaving with unsaved changes** shows a leave-page warning (rail navigation, back, or closing the window). Navigating to Landings or Participants via a link from this page keeps the draft for when the director comes back; say whether you'd also warn.
- **Offline:** saving works locally and syncs later; say so in the save confirmation. No special disabled state is needed.

## States

Loading; no configuration saved yet (a contest created before configuration was required: show defaults from the discipline with a clear "not saved yet" notice and Save enabled); unavailable (remote API unreachable); load failed with retry; editing with unsaved changes; validation errors; busy; save failed; conflict; administration locked; running (partly fixed); completed (read-only).

## Deliverables

1. **Page layout** inside the shell on tablet landscape (~1280px, rail expanded) with the section list, and on narrow (~800px) with the chip row. Show the top of the page and a scrolled-down view.
2. **Every section** in its default state, for an **F5J** contest with teams on and Seeded mode (so every conditional field shows), plus Discipline options for **F3J** and **ALES**.
3. **House rules:** an overridden discipline option with the official value and reset; the section summary.
4. **Landing table:** current table; the picker with grouped tables and the default marked; the preview; locked after the first landing score.
5. **Save flow:** unsaved changes with the sticky save bar showing count and impact; the impact confirmations (matrix outdated, results recalculated); validation errors (inline, summary, section markers); busy; save failed; conflict comparison; leave-page warning.
6. **Lifecycle:** before the draw (all free); after the draw (structural warning); running (scoring rules fixed, recalculating allowed); completed (read-only); administration locked.
7. **Matrix readiness panel:** cannot draw (with reasons); can draw; drawn and in sync; drawn with configuration changed.
8. A short rationale covering the section structure and navigation, how impact and locking are communicated without colour alone, how the shared components (disabled-reason pattern, landing entry list) are reused, and any component or token additions to the M3 theme.
9. Any questions or spec ambiguities you hit. List them; don't silently resolve them.

Light theme first. Show one dark-theme screen (the page with unsaved changes and the save bar) to prove the tokens hold up.
