# Design brief: Contest Participants page — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Participants page of an existing contest** in the contest director's administration app. It is where a director chooses who takes part in the contest and edits their contest-specific data (role, class, team, model) after the contest has been created. Please produce a canvas/prototype with the page layouts, the participant list, adding and removing people, editing, the states, and the responsive behaviour.

The list is the same list as step 4 of the New Contest Wizard ([new-contest-wizard.md](new-contest-wizard.md)), now working on stored data. Keep the visual language of the wizard's step 4 (table, stacked cards when narrow, team avatar, provisional number) so a director who has just created a contest recognises the page. The difference is that nothing here is a draft: people already exist in the contest, some may already fly in a drawn matrix, and the contest may be running.

**Users:** contest directors (CDs), at home before an event, at the field on a tablet in bright sun the morning of, sometimes offline. They add late entries, fix a misspelled class, swap a team, remove someone who did not show up. They are not power users and are often interrupted, so the page must be safe to leave and come back to.

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger** (admin). It must still work with browser text zoom and large system fonts. The table needs a stacked-card fallback at about 800 px, and rows grow rather than clip at large text sizes.
- **Never use colour alone for state.** Every status has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements. Rows expose their context ("Participant 7 of 24: Ana Silva, Pilot, Class Open").

**Existing app shell (the page lives inside it):**

- A persistent shell with a navigation rail on the left. Inside a contest the rail destinations include the contest workspace, Configuration, **Participants** (this page), Matrix, Scoring, Reports and Sync.
- A slim header naming the current page with the contest name, and a status area (lifecycle, participant scoring, administration lock, current round).
- A content area with **one clear primary action per page state**. Here: `Add participant`.
- A persistent **status bar at the bottom** showing connectivity and sync state.
- The page is reached at `/contest-administration/contests/{contestId}/participants`. The workspace's "Open Participants" next-step button leads here when the contest has fewer than 2 scoring pilots.
- Use the shared page states (loading skeleton, retryable error, empty state) and the shared page banner, so this page behaves like the others.

## Rules the design must respect

- One participation per person per contest. A person can't be added twice. Name and email are read from the director's reusable profile and are never copied or edited here. **Editing a row never changes the reusable profile.** Say this once, quietly, where it matters (for example in the edit control's help text).
- **Email is shown as a status** ("Has email", "None", "Private") and never as text unless the viewer may see it.
- Columns appear only for the options enabled on the contest: Team, Pilot no., Class, Role, Models. Name is always shown. A disabled option's column and control are absent, not greyed.
- **Roles:** default `Pilot`. Non-flying roles (timers, helpers, officials) get no score rows and no draw assignments, and may still be on a team. Once a pilot has a score, they **cannot be changed to a non-flying role**: the option is disabled with the reason beside it. A pilot who is drawn but has no scores can be changed: their matrix rows are removed, the change is confirmed first, and a notice says the draw needs redoing, with a link to the Matrix page's redraw.
- **Class** is shown in title case and matched ignoring case. A non-flying role has no class; changing a pilot to a non-flying role clears the class, so confirm first.
- **Team** uses existing team names plus free text, matched ignoring case. A blank name means no team. A new name creates the team.
- **Participant numbers are never editable here.** Before the first draw, show a provisional number with a label ("Provisional"); after the draw, the allocated number without the label. A person added after the draw has no number until they are placed ("Assigned when placed").
- **Class and model data are optional in practice.** Missing class or model data never blocks the draw or opening scoring (Mike, 2026-10-26; this matters mainly for large regional contests that don't use them). A pilot with no model, or no class, gets a quiet notice, never an error. It also never blocks creating the contest or adding a participant later. Non-fliers have no models and no notice.
- The only hard rule is **at least 2 scoring pilots** before a draw. Fewer than 2 shows an error-tone banner; exactly 2 shows a warning ("With fewer than 3 pilots, use 1 group per round."); 3 or more show nothing.
- **Removal:** removes the person from this contest only; the reusable profile stays. It is **refused** when the person has a score, with an explanation and a pointer to retire the pilot in Scoring instead. A drawn pilot with no scores can be removed: the confirmation says their matrix rows go too, and afterwards a notice says the draw needs redoing, with a link to the Matrix page's redraw. Retirement itself is not designed here.
- **Models are a list per pilot, not two fields.** A model belongs to the person's profile and is reusable across contests; a pilot can enter one or more in this contest (data model: `model_catalog.md`, `contest_model_link.md`). Each model has a name, an optional manufacturer, an optional model ID the contestant applied, and an optional contest ID the director applied (for example a serial number). The row shows the models as a count or short list (for example "2 models") with a way to add or edit them in a small panel or popover; do not add a column per field. Models are not storable yet (follow-up issue #594); design the cell so it can be enabled later, and until then it is read-only "Not recorded".

## Page layout

### Header area

Page title "Participants", a count line ("12 pilots, 2 non-flying"), and the banners (below). A short line shows which options are on, linking to Configuration ("Classes and teams are on. Change in Configuration.").

### Toolbar

- **Add participant** (primary): opens the existing participant editor in creation mode over the page; on save the new person is added to the contest and the list highlights their row. Cancel changes nothing.
- **Search to add** (name or email): offers the director's reusable profiles, local only for now. Results are marked **Already in this contest** (not selectable) or selectable. Selecting adds immediately.
- **Remove** for the selected rows.
- **Save** (and **Discard**) with the reason beside it when off (see Editing).

### The list

A table with a pinned header on wide windows; stacked cards on narrow ones. Columns: select checkbox, Name (with team avatar when teams are on), Email status, Role, Class, Team, Pilot no., Models. At least 24 rows must fit and scroll comfortably; expect 10 to 80 participants. Each row shows its own state: unchanged, changed (unsaved), saving, failed with message, not removable with reason.

Inline cell editing as in the wizard: Class as free text with suggestions, Team as a combobox with "Create team 'X'", Role as a select. Keyboard: arrow keys move between cells, Enter commits a cell, Esc reverts it. Bulk edit of the selected rows' team or class, as in the wizard's bulk bar.

### Editing and saving

Edits are **batched behind a Save button**, as on the Configuration page. Changing a cell marks the row changed. The Save control works like the draw action on the Matrix page: a `Save changes` button that is **always visible**, with a one-sentence reason beside it (icon, text, and a fix link where there is one) when it is off, for example "No changes to save." or "Fix 1 row before saving." While saving, the button shows progress ("Saving…") and ignores taps, and the rows are locked. A failed save never changes the page and never loses typed values: the server's message appears inline on the row and in a summary near the Save control. A stale-revision conflict replaces the reason with "Someone changed this participant. Refresh to continue." until the page reloads. Next to it, `Discard` and the count of changes ("3 unsaved changes"). Leaving the page with unsaved changes shows the shared leave warning. Adding and removing people are separate actions that take effect immediately (the removal asks for confirmation). Save sends each changed row on its own; rows that fail keep their typed values and show the reason, the others save. If someone else changed the same participant, the row says so ("This participant was changed elsewhere. Refresh to see the latest.") with a **Refresh** action that reloads the row and discards that row's unsaved cells.

Show a recalculation warning after saving a change that can affect scores (for example a role or class change in a running contest) using the existing warning wording.

### Banners (text plus icon)

1. Fewer than 2 scoring pilots: error tone, "Add at least 2 scoring pilots before the draw." with the Add participant action.
2. Exactly 2 scoring pilots: warning tone.
3. Missing class or model data: informational, lists people and the missing field ("Ana Silva: class. Ben Ortiz: no models"), each with a link that focuses the cell. Never blocking.
4. Read-only (see below).
5. Late add (see below).

## Contest stages

The page serves every lifecycle stage. Design these:

- **Before the draw** (Created, Configuring, Ready): everything editable; provisional numbers; the minimum-pilot banners matter here.
- **After the draw, running:** adding is allowed and becomes a **late add**. On `Add participant` (or adding from search) show a confirmation: "The draw has already been made. Ana Silva will be added to the contest. Place them in a group from the Matrix page. A redraw is also possible." Actions: `Add participant`, `Cancel`. The person appears with "Not placed yet" and no number. (The placement itself is designed in the Matrix brief; do not design it here. Show only the confirmation text and the row state.) Rows of pilots with flights show a small "Has flights" marker; their Remove is disabled with the reason, and the role select disables non-flying roles.
- **Administration locked:** the list is viewable; edits that change matrix inputs (role, class) are disabled with the reason ("Administration is locked. Unlock to change.") and an Unlock pointer. Adding people follows the same rule.
- **Completed, or pending deletion:** **read-only**. All inputs become plain text, add/remove/edit/save controls are hidden, and a banner states why ("This contest is completed. Participants can't be changed."). The list, search within the list and the count still work.

## States to show

- Loading (skeleton rows), load failed with retry, empty ("No participants yet. Add people you've saved before, or create a new one.") with the add controls.
- Offline: local profiles only; edits queue as the app already does for other pages; show the standard offline indication, not a bespoke one.
- Search results: found, none found, already in this contest.
- Add: new profile created, existing profile added, add failed with retry (idempotent; nothing duplicated).
- Remove: confirmation naming the people; refused (flights or scores) per person with explanation; partial success summary.
- Edit: changed, saving, saved, failed, stale revision.
- Save control: off with reason (no changes, a row to fix), ready (N changes), saving, some rows failed (summary plus inline), conflict (reload reason).
- Leave with unsaved changes.
- Late-add confirmation; locked; read-only.

## Deliverables

1. **Page layout** inside the shell on tablet landscape (~1280 px, rail expanded) with 24 participants and the options Teams, Classes, Roles, Pilot numbers on; and on narrow (~800 px) as stacked cards.
2. A second variant with only the minimum options on (no optional columns) to show the table adapts.
3. **Before the draw** (provisional numbers, fewer-than-2 banner, 2-pilot warning) and **after the draw** (allocated numbers, "Has flights" markers, late-add confirmation, "Not placed yet" row).
4. **Editing:** changed rows, the Save control in each of its states (off with reason, ready, saving, failed, conflict), a failed row, the stale-revision row, the bulk edit bar, the leave warning.
5. **Add and remove:** search with "Already in this contest", the editor over the page and the highlighted new row, the removal confirmation, and a refused removal.
6. **Informational note** for missing class/model data.
7. **Locked** and **read-only (completed)** variants.
8. **Shared states:** loading, empty, load failed, offline.
9. **Dark theme:** one screen (the after-draw list) to prove the tokens hold up.
10. A short rationale covering what is shared with wizard step 4, how Save batching and immediate add/remove are told apart, and any component or token additions to the M3 theme.
11. Any questions or spec ambiguities you hit. List them; don't silently resolve them.

Light theme first.

## Open points for the design

- Where the Save control sits (toolbar or sticky at the bottom). It must follow the Matrix page's draw action pattern; say where it goes and why.
- How to show per-row failure on the stacked card layout without making the card hard to scan.
- Model cells: how the model list and its add/edit panel look and work on a narrow card, and how "Not recorded" differs from "Missing" so it doesn't read as an error before #594 lands.
