# Design brief: Scoring screen (official score entry for one group) — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Scoring screen** in the contest director's administration app. This is where the director, or a local operator working for them, **enters and corrects the official scores for one group in one round**, checks them, marks them official, and locks them. Please produce a canvas/prototype with the page states, the group grid, the per-pilot entry controls, the score check, the lock actions, the save and conflict states, and the responsive behaviour.

This is the **first version, for F5J**. Design it so that other duration disciplines (F3J, ALES, Thermal Duration) change only the columns, not the page (see "Discipline columns"). Participant review requests, re-flights, and retirements are follow-up tickets. Design the page so they can be added without rearranging it (see "Room for follow-ups"), but do not design them.

**Users:** contest directors (CDs) and local operators at the flying field, on a **tablet**, outdoors in bright sun, in the gaps between flights. Timekeepers hand over a slip per pilot and the operator keys in a whole group in a minute or two, often **offline**. They are fast, interrupted, and wearing sunglasses. They need to answer quickly: "Did I enter everyone?", "Does that number look right?", "Can I lock this group and move on?"

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger**. The standard Material 3 window size classes apply (compact under 600dp, medium 600 to 839dp, expanded 840dp and up), with no custom breakpoints. **Phone is a stretch goal:** on compact widths the grid becomes a **stacked card per pilot** with the same fields and actions. It must be usable there, not optimized. It must also work with browser text zoom and large system fonts.
- **Never use colour alone for state.** Every status has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements. This covers official status, lock state, validation, and zero-score reasons.
- Large touch targets and high contrast for fields and toggles; this is a sunlight screen.

**Existing app shell (the page lives inside it):**

- A persistent shell with a contest-scoped navigation rail on the left. The page is reached from the `Scoring` rail item and from links elsewhere (the workspace next-step card, the progress tiles). It lives at `/contest-administration/contests/:id/scoring`, and carries the round and group in the route so refresh and back navigation restore them.
- A header with the title, the contest name, and breadcrumbs or back navigation. Add the current round and group to the breadcrumb.
- A shell status panel (read-only) with lifecycle, participant scoring, and administration lock, and a persistent **status bar at the bottom** with connectivity and sync state. Both are already designed; show them in the layouts. Do not merge contest statuses into one.
- One clear primary action per page state.

## Page behaviour

The page shows **one complete group of one round at a time**. The director moves between rounds and groups with navigation, not by scrolling a long list.

### Round and group navigation

- **Round:** first, previous, current, next, last. Show the current round as "Round 3 of 8" and a compact way to jump to any round (menu or segmented list).
- **Group:** first, previous, next, last within the round, plus a direct pick. Show "Group B of 4" and the group's size.
- Each round and group entry in the picker carries its **completeness** (text plus icon): no scores, some scores, all scores entered, all official, locked. This lets the director see where work remains without opening each group.
- Round and group stay in the URL. Browser back goes to the previous group. Moving to another group with **unsaved edits** asks what to do (save, discard, stay); ordinary navigation without edits uses no dialog.
- Show a **context strip** above the grid: round status (not flown, in progress, scored), group lock state and scope, and the count "5 of 7 entered · 3 official".

### Group grid

One row per pilot assigned to the group. **Non-flying participants never appear.** Unentered pilots appear as placeholder rows so the director can see who is missing.

Columns, left to right:

1. **Lane** (only when lane mode is Random) or pilot number.
2. **Team** (short marker plus text) and **pilot name**.
3. **Discipline inputs** (see "Discipline columns").
4. **Raw score** (derived, read-only).
5. **Group score** (derived, read-only).
6. **Penalty** (see "Penalties").
7. **Indicators:** participant-submission (a pilot or helper entered something) and pending-review. Both are text plus icon.
8. **Official status** per row: Not entered, Entered, Official, Locked. Text plus icon.

Pinned: the pilot column and the column headings. At medium and expanded widths all columns fit at least at tablet landscape without horizontal scrolling for the F5J set; show how it behaves at medium width and at large text sizes (rows grow, names wrap).

**Derived values** update as soon as the raw values are valid, shown as a preview and marked as "not saved" until the save succeeds. The server is the authority. If a preview differs from the saved result, show the saved value without alarm.

### Per-pilot entry (F5J)

- **Time flown**: numeric keypad. Accepts compact input: `630` means 6:30, `630.4` means 6:30.4 (decimal separator follows locale). The field **shows the parsed value** (6:30) as the director types, and rejects impossible values (seconds above 59, over working time, equal to working time) with a message, **without discarding what was typed** until corrected.
- **Launch height**: whole metres, numeric keypad, no decimal separator. Zero is not valid. Above 300 m asks "Is this correct?" inline and continues without a modal.
- **Landing**: choice from the **contest's landing table** (segmented control or chips, showing the table's label and the points it gives). Shows the selected value; becomes unavailable when Late landing is on.
- **Toggles:** Late landing, Motor restart (hidden when the contest does not allow restarts), Out of bounds (landing more than 75 m from the marker), No altitude recorded.
- **Rules the UI enforces visibly** (disabled fields show _why_ in text, not just a grey-out):
  - Late landing on → landing choice cleared and disabled.
  - Out of bounds or Motor restart on → time, height and landing are zeroed and disabled.
  - Motor restart and Out of bounds may both be on. If the contest makes restarts non-droppable, say the zero cannot be dropped.
  - No altitude recorded on → every other toggle and field is disabled; Motor restart and Out of bounds cannot be selected with it.
- **Zero confirmation:** saving a row with nothing entered, or with a zeroing status on, asks the operator to acknowledge that the pilot receives a zero. Design it inline with a confirm control on the row, not a modal, because a CD may do this many times.
- **Keyboard-first rapid entry:** Tab or Enter moves to the next field, then to the next pilot's time field; the active row is clearly marked; it works with a hardware keyboard and the on-screen numeric keypad. Describe the focus order.
- Row save model: decide between **save per row** and **save the group**, and justify it. Either way, a save creates an auditable official revision and does not overwrite the original participant submission.

### Penalties

The page has two penalties, which differ. Make the difference readable without a tooltip.

- **Flight Penalty**: a non-negative whole number entered with the score. It is deducted from the flight's raw score (never below zero), so it is **dropped with the round**.
- **Cumulative Penalty**: a whole number of points the director applies by judgement. It is deducted from the total at the end, is **never dropped with its round**, and still counts if the flight is re-flown. "No penalty" is different from "a penalty that was applied and then removed (set to zero)"; show both. Removing one is an official correction.

Show how a row with each, with both, and with a removed cumulative penalty looks. Only the contest director may apply a cumulative penalty; show how the field reads for a local operator without that authority.

### Score check

A **Score check** action reports, without changing any data: missing entries, and configurable out-of-range values (for example a time or launch height outside the expected range). Design:

- The result as a list grouped by pilot, each item jumping to the row and field.
- The row-level markers (text plus icon), cleared once fixed.
- A clean result ("All 7 pilots entered, nothing out of range").

### Official status and locks

- The director **marks individual rows official**, or marks all valid rows in the group at once.
- **Lock** applies to a group, a round, or the whole contest. Design the control so the **scope** is explicit before confirming, and shows what will change ("Lock round 3: 4 groups, 28 scores").
- **Lock scope and reason are visible in the grid**: at row level, group level, and in the context strip.
- A locked score cannot be edited. Show how the row reads, and the **authorized correction workflow** to edit anyway (a recorded reason is required). Unlocking is reversible and audited.
- Lock and unlock confirm with a dialog that names the scope. Marking a row official does not.
- Design the page when entry is **not permitted** at all, with the reason shown beside the controls: contest completed, administration locked, round or group locked, and pilot not assigned to this group (matrix assignment rule). The same disabled-with-reason pattern as the matrix draw form.

### Save, error and conflict states

Design each, and make sure a failed save **never loses the values the director typed**:

- **Loading** the group.
- **Unsaved edits** (row-level and group-level indicator, with a leave-page warning).
- **Saving** (row locked, progress, no double-submit).
- **Validation error** (inline per field and a summary at the top for the group).
- **Save failed** (network or server): says whether to **retry**, **refresh**, or **resolve a conflict**, and keeps the values.
- **Stale revision:** someone else (another operator or a participant submission) changed the row since it was loaded. Show both values and let the director keep theirs, take the new one, or reload. A participant submission loses to an official decision but stays in history.
- **Unavailable** (remote API cannot be reached): in an offline-capable build, entry continues and rows show "Saved locally, waiting to sync". Show the pending state per row and the group.
- **Empty group** (every pilot absent) and **no matrix** (the page cannot open any group; link to the Matrix page).

### Discipline columns

Columns and rules come from the discipline's **score-entry schema** (field label, type, unit, precision, range, dependencies), so the design should treat the input area as a set of typed fields. Show the F5J set. Then show **one variation** to prove it holds, for example F3J (time, landing, late landing, out of bounds; no height) or ALES. Do not design every discipline.

### Room for follow-ups (do not design the actions)

Leave visible, labelled room for: a **review request** indicator that opens a panel with the proposed values, message, base revision and approve/reject (the indicator column already exists); a **history** view of superseded revisions per row; a **re-flight** action at group and round level; and a **retire pilot** action in the row menu. Show them as dimmed placeholders or omit them, but say where they go.

## Deliverables

1. The **page layout** inside the shell, on tablet landscape (~1280px) for a full group, and at medium (~700px) width. Add one compact (~400px) screen with the stacked card per pilot.
2. **Navigation:** round and group pickers with the completeness states; unsaved-edits prompt.
3. **Row states:** empty placeholder, partly entered, valid with a preview, invalid, saved, official, locked; each toggle rule (late landing, out of bounds, motor restart, no altitude); the zero confirmation; both penalties.
4. **Entry details:** the time field showing a compact input being parsed (valid and rejected); the landing choice; the launch height over 300 m question; the keyboard focus order.
5. **Score check:** result with findings, and a clean result.
6. **Locks:** the scope selector and confirmation for group, round and contest; the locked row; the correction workflow; the not-permitted reasons.
7. **Shared states:** loading, saving, validation, save failed, stale revision, unavailable or offline with pending rows, empty and no matrix.
8. A short rationale covering layout choices, the save model, where you used progressive disclosure, how colour independence is achieved for status and locks, and any component or token additions to the M3 theme.
9. Any questions or spec ambiguities you hit. List them; don't silently resolve them.

Light theme first. Show one dark-theme screen (a group part way through entry) to prove the tokens hold up.
