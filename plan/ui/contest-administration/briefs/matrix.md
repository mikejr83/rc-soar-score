# Design brief: Matrix screen (first draw and matrix grid) — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Matrix screen** in the contest director's administration app. The matrix is the contest's flight schedule: for each round, the pilots are split into groups that fly together. This screen is where the director **draws the first matrix** and then **inspects it**. Please produce a canvas/prototype with the page states, the draw form, the matrix grid, the pilot highlight, the fairness summary, and the responsive behaviour.

This is the basic version. Moving pilots, late adds, adding rounds, and redrawing rounds are follow-up tickets. Design the page so those actions can be added later without rearranging it (see "Room for follow-ups"), but do not design the actions themselves.

**Users:** contest directors (CDs) at a flying field or at home before an event. They often work on a tablet, sometimes a laptop, sometimes outdoors in bright sun, and sometimes offline. They know how a matrix works, but they want to answer quick questions at a glance: "Where does pilot 12 fly in round 3?", "Does anyone meet twice?", "Is this draw any good?"

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger** (admin). It must still work with browser text zoom and large system fonts. The grid is wide by nature; it may scroll horizontally, but the round headings stay pinned.
- **Never use color alone for state.** Every status has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements. Team colours, the pilot highlight, and round status are all subject to this rule.

**Existing app shell (the page lives inside it):**

- A persistent shell with a contest-scoped navigation rail on the left. Once a contest is open, the rail lists its pages: Workspace, Configuration, Participants, **Matrix** (this page), Scoring, Reports, Publication. The page is reached from the `Matrix` rail item, at `/contest-administration/contests/:id/matrix`.
- A header with the title, the current contest name, and breadcrumbs or back navigation.
- A content area with **one clear primary action per page state**. Here that is `Draw matrix` before a draw; after a draw the page is mainly for reading, so no primary action competes with the grid.
- A persistent **status bar at the bottom** showing connectivity, sync state, and so on.
- A compact contest status summary (lifecycle, participant scoring, administration lock, publication, public visibility) with separate labelled values. Never merge them into one status.
- The page renders inside the shell (the rail stays visible). Show how the grid uses the width when the rail is expanded to labels versus collapsed to icons.

## Page behaviour

The page has two modes, decided by whether a matrix exists:

1. **No matrix yet:** an empty state plus the first-draw form.
2. **Matrix drawn:** the matrix grid, the fairness summary, and the draw details. The first-draw form is gone. Reopening or reloading the page shows the same matrix.

Also design the shared page states: **loading**, **unavailable** (remote API cannot be reached), and **conflict**. A save or draw that fails never changes the page and never loses the form values.

## Mode 1: No matrix yet

### Empty state

- Says plainly that no matrix has been drawn for this contest, and that the draw is a one-time action for now (it can be redrawn later, which comes in a later release).
- The draw form sits directly below it on the same page.

### First draw form

Fields the director fills in:

- **Number of rounds** (positive integer). **Prefilled with the contest's preliminary number of rounds**, which the director entered in the draw options of the New Contest Wizard (step 6) or on the Configuration page. In Seeded mode this is the number of preliminary seeded rounds.
- **Groups per round** (positive integer). **Prefilled with the groups per round from the same draw options.**
- Both fields stay editable, because the configuration values are planning values. Show where each default came from (for example "From contest configuration: 3 groups per round") with a link to the Configuration page. Once the director changes a field, show that it differs from the configuration and offer a reset to the configured value. Changing the field here does not change the configuration. If the configuration holds no value (a contest created before these were required, or a copied contest), leave the field empty and say so.
- The prefilled values go through the same validation as typed ones, so a stale configured value (for example, groups per round that no longer fits after pilots were removed) shows the warning from the first view rather than failing on submit.
- Under the groups-per-round field, the form shows the resulting group sizes live, for example "3 groups: 7, 7, 6 pilots". It warns when any group would have fewer than two pilots. When **team protection** is on, it also shows the **minimum** number of groups (at least the size of the largest team) and says why.

Settings that come from the contest configuration are shown **read-only**, not asked again. Each links to the Configuration page so the director can change it there:

- Team protection (on or off).
- Draw mode (Man on Man or Seeded Man on Man). For **Seeded**, the form says that only the preliminary rounds are drawn now, and shows how many.
- Lane mode (none or random).
- The pilot count that the draw will use (scoring pilots only; non-flying participants are excluded) and the configuration revision.

(Team protection and Seeded order cannot both be on. That is enforced in configuration, so the form never has to show that conflict.)

**Advanced** (collapsed by default): random seed, attempts per round, seed count. Defaults come from the server (50 attempts, 3 seeds); a blank random seed means "pick one for me". Explain in one line each what the setting does.

**Confirmation.** The Draw button opens a confirmation that names the number of pilots, rounds and groups, and the configuration revision, and says the matrix cannot be undone, only redrawn later. This is the one place on the page that uses a dialog.

**Draw is a single request.** Design the busy state while it runs: the form is locked, the button shows progress, and a repeated tap is ignored. There is no progress bar and no cancel yet (those arrive later), so do not promise either. On success the page switches to Mode 2. On a rejected constraint, the server's message appears inline and in a summary at the top of the form, the entered values stay, and the page is otherwise unchanged.

### Disabled form

The draw form is shown **disabled with the reason beside it**, not hidden, when the draw is not allowed. Design one pattern for the reason and show it for each case:

- The contest is locked.
- The contest is completed.
- Fewer than two scoring pilots.
- The configuration is invalid (say what is missing and link to it).

The same enabling rules drive the `Draw matrix` button on the Configuration page, so the wording and the pattern should be reusable there.

If the server answers with a conflict (the contest is not in configuring state, is locked, or already has a matrix), show a conflict state with a reload action. The entered values stay.

## Mode 2: Matrix drawn

### Matrix grid

- A **round-by-group grid**: one column per round, groups stacked within the column. Each group is a card or band with a heading and its **size** (for example "Group B · 7 pilots").
- Each pilot row shows **pilot number, name, team, and role**. **Lane** appears beside the pilot **only when the lane mode is Random**. Non-flying participants never appear.
- Every round heading shows a **round status**: not flown, in progress, or scored. Text plus an icon. All rounds read "Not flown" until scoring exists, but design all three states because the page already reads the status from the round.
- Every pilot appears exactly once per round. Make that easy to verify at a glance.
- **Team marker:** a colour plus a short text or shape per team (for example a letter badge). Design for up to about 12 teams and show what happens when there are more.
- **Layout:**
  - Round headings are pinned while scrolling vertically, and the pilot-column headings are pinned while scrolling horizontally.
  - On a **narrow screen** the grid scrolls horizontally.
  - On a **tablet**, at least **three rounds** are visible without scrolling.
  - Expect 10–80 pilots, 3–10 rounds, and 2–10 groups per round. Show a small contest (6 pilots, 3 rounds, 2 groups) and a large one (60 pilots, 8 rounds, 6 groups).
  - At large text sizes, rows grow rather than truncate; show how the name wraps.

### Pilot highlight

- Choosing a pilot (tap or click, or keyboard) **highlights every appearance of that pilot across the rounds**. The highlight must not rely on colour alone: use an outline, a bold weight, and a marker icon.
- It also shows a panel with the pilot's **opponents and how often each meets the pilot**, so the director can spot repeated matchups and gaps (pilots they never meet). Sort by count, descending, then show the "never meet" list separately.
- On tablet, the panel is a side sheet or an inline strip; on narrow screens a bottom sheet. Choose one for each width and explain why. It must be dismissible and must not hide the grid.
- Choosing another pilot switches the highlight. Choosing the same pilot again, or pressing Escape, clears it.

### Find and filter

- A **search** by pilot name or number. Matches are highlighted in the grid and the search can jump to the first match. No match shows a clear "no pilot matches" message.
- A **team filter or team marker toggle**, so the director can see only one team's pilots. Describe how the filter state is announced.

### Fairness summary

- The **fairness score** as a percentage, with a one-line meaning: "0% is a random draw, 100% is the best possible". Tooltips are not enough on a tablet; the line is visible text.
- **Unmet opponents** (pairs of pilots who never meet), **max repeats** (the most times any pair meets), and **lane uniformity** when lanes are used.
- A **matchup histogram**: how many pairs meet 0, 1, 2, or more times. A simple bar chart with the values labelled; no colour-only encoding.
- **Mean absolute deviation** as a secondary figure, kept low in the hierarchy.
- Decide where the summary sits (above the grid, side panel, or collapsible) and explain why. It should be visible without scrolling on a tablet but not push the grid off the screen.
- Show a good draw (for example 92%), an average draw (about 40%), and a poor draw (near 0%). If the score can fall below 0% for a draw worse than random, show how that reads and list it as a question.

### Draw details

- Matrix revision number, configuration revision, algorithm version, **random seed** (copyable, so a draw can be reproduced), and who drew it and when. This is reference information; keep it quiet, for example in a collapsed section.

### Configuration-changed banner

When the contest's current configuration differs from the settings the matrix was drawn with (team protection, draw mode, lane mode, preliminary rounds), a **banner** says which setting differs and that the existing matrix is **unchanged**. It points to the redraw follow-up. Design it as a non-blocking, persistent notice above the grid, not a dialog. A difference never alters the matrix.

### Room for follow-ups (do not design the actions)

Leave visible, labelled room for: a pilot-level action menu (move, late add), a round-level action menu (redraw), and an "Add rounds" action. Show them as dimmed placeholders or omit them, but say where they will go, so the pinned headings and the pilot rows do not have to change later.

## Deliverables

1. The **page layout** inside the shell on tablet landscape (~1280px) for: empty plus draw form; drawn matrix with the summary; and a drawn matrix on the narrow (~800px) width.
2. **Draw form states:** default (rounds and groups prefilled from the configuration, with their source note); edited away from the configured values, with the reset action; configuration holds no value; Advanced expanded; group sizes with a warning (fewer than two pilots in a group); team-protection minimum; Seeded note; the confirmation dialog; busy; rejected constraint (inline plus summary); network failure; conflict; and the disabled form with each of the five reasons (one screen may show all five as variants).
3. **Grid states:** small and large contests; round status variants; lanes on versus off; team markers; large text size.
4. **Pilot highlight:** selected pilot on tablet (panel) and on narrow (bottom sheet), including the opponent counts and the "never meet" list; search with a match and with no match; team filter active.
5. **Fairness summary:** good, average, and poor draws; histogram; and the details section expanded.
6. **Banner and shared states:** configuration-changed banner; loading; unavailable.
7. A short rationale covering layout choices, where you used progressive disclosure, how colour independence is achieved for team markers and highlights, and any component or token additions to the M3 theme.
8. Any questions or spec ambiguities you hit. List them; don't silently resolve them.

Light theme first. Show one dark-theme screen (the drawn matrix with a highlighted pilot) to prove the tokens hold up.
