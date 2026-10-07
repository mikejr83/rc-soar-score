# Design brief: New Contest Wizard — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **New Contest Wizard** in the contest director's administration app. It's a guided, multi-step flow that creates a new contest. Please produce a canvas/prototype with every step, its key states, and the responsive behaviour.

**Users:** contest directors (CDs) at a flying field or at home before an event. They often work on a tablet, sometimes a laptop, sometimes outdoors in bright sun, and sometimes offline. Most aren't power users. They know their discipline's rules well, but they don't set up a contest often.

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger** (admin). It must still work with browser text zoom and large system fonts. Dense tables need a responsive fallback (horizontal scroll or stacked rows).
- **Never use color alone for state.** Every status has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements.

**Existing app shell (the wizard lives inside it):**

- A persistent shell with a navigation rail on the left (expandable to labels on wide windows; destinations: Contests, Participants, Roles, Landings) and a context-aware FAB.
- A header with the title and breadcrumbs or back navigation.
- A content area with **one clear primary action per workflow step**.
- A persistent **status bar at the bottom** showing connectivity, sync state, and so on.
- The Contests and Participants pages use a list + detail (master/detail) layout that collapses to a single pane on narrow widths.
- The "Create contest" action on the Contests page opens the wizard at `/contest-administration/contests/new`.

Decide whether the wizard takes over the content area inside the shell (rail still visible) or runs as a focused, full-height flow. Explain your choice.

## Wizard-wide behaviour

- **7 steps:** 1 Details & copy source → 2 Discipline → 3 Participant options → 4 Participants → 5 Scoring & publication defaults → 6 Draw options → 7 Summary & create.
- Show progress and step titles. Users can go back to earlier steps and jump to visited steps without losing valid values.
- Each step **saves a local draft automatically**. A draft is not a contest and doesn't appear in contest lists. Show that the draft is saved, but don't make it noisy.
- **Validation:** required fields are checked before moving on. Errors show **inline next to the field** and in a **summary at the top of the step**.
- **Leaving with unsaved changes** shows a leave-page warning. Ordinary navigation doesn't use modals. Confirmation dialogs are only for destructive or multi-step actions.
- States to design: loading, empty, offline/remote-unavailable, validation error, save failed (keep entered values, offer retry and cancel), and conflict.

## Step-by-step requirements

### 1. Contest details & copy source

- Required: contest name, start date, end date, venue/host.
- Optional: city, state/province, country, and time zone (defaults to the device time zone; the user can pick another).
- **Copy source** (optional), with four modes: _don't copy_ / _copy configuration only_ / _copy configuration + all pilots_ / _copy configuration + a selected subset of pilots_ (for fly-offs).
  - Local contests are always available. Public contests can be searched only when online, so show that clearly when offline.
  - Show the chosen source, copy mode, and selected pilots in a summary.
  - Copying **never** brings scores, matrix, publication history, invitations, or audit history. Say so near the control.
  - If the source fails to load, the user can remove it and continue.

### 2. Discipline

- Pick exactly one: **ALES, F3J, F5J, Thermal Duration**. Unsupported or placeholder disciplines appear but can't be selected.
- Each **selection card** shows: name, task type, default target or working time, landing-bonus summary, and discipline-specific rules.
- Changing discipline after values exist clears incompatible values, so ask for **confirmation first**.
- Overrides happen after creation, so note that the defaults can be adjusted later.

### 3. Participant options

- Toggles (all off by default unless copied): **Teams, Contest pilot numbers, Classes, Contest roles, Pilot models**.
- Teams on → a required "pilots counted for team score" field (positive integer), and team protection becomes available.
- Models on → the participants step will ask for model name and ID.
- Each option shows **how it changes what's required in the participant step**. Progressive disclosure fits here.

### 4. Participants (the most complex step; needs the most attention)

- A list/table of selected pilots and non-flying participants. Columns depend on step 3: name, email status, role, class, team, pilot number, and model.
- **Autocomplete** search by name or email. Results are marked **local, remote, or already selected**. Search source depends on connectivity (offline: local only; online: remote first). Never show email to users who aren't allowed to see it.
- **"Add participant"** opens the existing participant editor in create mode, returns to this step, and auto-selects the new person.
- Row rules:
  - **Teams:** each pilot needs a team. The picker offers existing teams plus free text, and matching ignores case. A blank team gets the next numeric team ID. A short avatar is fine as long as the full name stays available.
  - **Classes:** each pilot needs a class, shown in title case, with suggestions from earlier entries.
  - **Roles:** new participants default to the fixed `Pilot` role. Non-flying roles don't get score rows but can belong to a team.
  - Pilot numbers are assigned at the first draw. Any preview must be labelled **provisional**.
- Validation:
  - At least **2 scoring pilots**.
  - With fewer than 3 pilots, show a **non-blocking warning** suggesting 1 group per round.
  - **Block** continuing when required team, class, role, or model data is missing. Point to the rows that need fixing.
- Expect 10–80 participants. Design for bulk editing of team or class and fast keyboard entry, and show how the table becomes stacked rows when narrow.

### 5. Scoring & publication defaults

- Show the discipline defaults for review, with editable values:
  - Group-score mode: raw / normalized / time (where supported).
  - Rounding vs. truncation, plus decimal precision (0–3).
  - Dropped-round policy.
  - Participant score-review requests: on or off.
  - Public update policy: automatic / on round completion / manual.
- Say clearly that the contest is created **unpublished and private**. Publishing happens later on the contest configuration page.

### 6. Draw options

- Draw mode: **Man on Man** or **Seeded Man on Man**.
- **Groups per round** (positive integer). Show the **calculated min/max pilots per group** and update it live. It must prevent any group having fewer than 2 scoring pilots. Team protection may raise the minimum number of groups, so show that constraint.
- Preliminary number of rounds. Label it as a planning value that can change after the contest starts.
- Lane mode: none or random.
- **Team protection** (only when teams are on) can't be combined with **Seeded** mode. Choosing one disables the other and **explains why**.
- **Allow back-to-back flights**: on by default. Turning it off shows a notice that **draw fairness decreases**, and a warning if the contest is too small for the constraint.
- Seeded mode → preliminary seeded rounds (default 1, minimum 1).
- Say clearly that the matrix is **not drawn here**. That's a separate action after creation.

### 7. Summary & create

- Sections: details, copy source, discipline, participant count, enabled options, teams and classes, scoring defaults, draw options, and the round/group calculations. **Each section has an Edit action** that jumps back to its step.
- Primary action: **Create contest**. It's disabled while validation fails, and the disabled state should explain why. Design the in-progress state and guard against double submission.
- Success: go to contest configuration with a confirmation. The contest exists in _Configuring_ state, the matrix isn't drawn yet, and discipline overrides and the remaining configuration can be reviewed there.
- Failure: keep all values and show **Retry**.

## Deliverables

1. Step navigation pattern (stepper, side list, or other) with progress, a visited/valid/error indicator per step (not color alone), and draft-saved status.
2. A key screen for each of the 7 steps on **tablet landscape (~1280px)**, plus a **narrow (~800px)** version of steps 1, 4, and 6.
3. States: the validation error summary plus an inline error (step 1); offline search results (step 4); the discipline-change confirmation dialog (step 2); the team protection vs. Seeded conflict (step 6); the back-to-back-off notice (step 6); the disabled Create button with its reason; creation failed with retry; and the leave-with-unsaved-changes warning.
4. A short rationale covering layout choices, where you used progressive disclosure, and any component or token additions to the M3 theme.
5. Any questions or spec ambiguities you hit. List them; don't silently resolve them.

Light theme first. Show one dark-theme screen (step 4) to prove the tokens hold up.
