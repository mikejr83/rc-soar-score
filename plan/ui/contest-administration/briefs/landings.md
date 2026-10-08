# Design brief: Landings page (landing tables) — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a redesign of the **Landings page** in the contest director's administration app, and of the **New landing table** form that goes with it. Please produce a canvas/prototype with the page layouts, the entry list, the form, their states, and the responsive behaviour.

A **landing table** turns what a scorer records for a landing into landing points. Each table has a name, a unit that says what its entries mean (**Meters**, **Feet**, or **Points**), and an ordered list of **entries**. Each entry has a **label** (what the scorer picks, for example "Within 1 m" or "100 pts") and the **points** it awards. Examples:

- _F3J Standard Landing Table_ (unit Points): 101 entries, "100 pts" = 100 down to "0 pts" = 0.
- _F3J Landing Distance Table_ (unit Meters): 26 entries, "0.2m" = 100, "0.4m" = 99, … "2m" = 91, "3m" = 90, "4m" = 85, … "15m" = 30, "Over 15m" = 0.
- _ALES Standard Landing Table_ (unit Points): 11 entries, "50 pts" = 50 down to "0 pts" = 0 in steps of 5.

**The main problem to solve:** the entry list in the detail pane is a two-column table (Label, Points) stretched across a wide card. On a tablet or laptop the label sits at the far left and the points at the far right, with a big empty gap between them, so the eye loses the row. Tables are long (often 50 to 100+ entries), so this matters. Find the Material 3 way to show a long list of label/points pairs that reads row by row, stays compact on wide screens, and still fits a narrow one. Treat the entry list as one reusable component: the same row shape appears in the detail pane, in the form, and as the table preview on the contest Configuration page (separate brief, [configuration.md](configuration.md)).

**Users:** contest directors (CDs), usually at home before an event, sometimes at the field on a tablet in bright sun, sometimes offline. They check a table against their rulebook ("Is 4m worth 85?"), pick a table for a contest, and occasionally make their own by copying a system table and changing a few values.

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger** (admin). It must still work with browser text zoom and large system fonts. Long lists need a pinned header and must not truncate labels; at large text sizes rows grow rather than clip.
- **Never use colour alone for state.** Every status has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements. Lists expose column headers and row context ("Entry 12 of 26: 4m, 85 points").

**Existing app shell (the page lives inside it):**

- A persistent shell with a navigation rail on the left (expandable to labels on wide windows). In system scope (no contest selected) the rail destinations are: Contests, Participants, Roles, **Landings** (this page). The rail carries the page's add action ("New landing table") as a context-aware FAB.
- A slim header naming the current page, with breadcrumbs or back navigation.
- A content area with **one clear primary action per page state**.
- A persistent **status bar at the bottom** showing connectivity, sync state, and so on.
- The page is reached at `/contest-administration/landings`; the form at `/contest-administration/landings/new`.
- Contests, Participants, and Roles use a list + detail (master/detail) layout that collapses to a single pane on narrow widths. Landings uses the same pattern today; keep it unless you have a strong reason, and say why.

## Rules the design must respect

- **A table never changes once it is created.** There is no edit. "Create copy" opens the form prefilled from the table; saving makes a new table. Say this where it matters (detail pane, form), but don't nag.
- **System tables** ship with the app, are read-only, and are visible to everyone. **The director's own tables** ("Yours") are visible only to them.
- A director's table can be **deleted only while nothing uses it** (no contest configuration, discipline profile, or score refers to it). A table in use is **locked**. Delete needs a confirmation dialog; the delete control on a locked or system table is disabled with the reason beside it, not hidden.
- Entries are an **ordered** list. The order is the order the scorer sees in the score-entry picker. Points are whole numbers, never negative. Labels are required and unique within a table (case-insensitive).
- The unit (Meters, Feet, Points) only describes what the labels mean; it is shown to help a director choose a table for a contest. The points are always called "Points".
- The system takes the points from the entry, never from the label text, so a label like "100 pts" with 90 points is legal (if odd). Don't design validation that blocks it; a gentle hint is fine.

## Page layout

### Table list (master pane)

- Title and count, then **the director's tables first, then the system tables**, each sorted by name. Make the two sections visibly distinct (section headers, not just an icon).
- Each row: name; owner (System or Yours); unit; entry count; points range (for example "0–100 pts"); and a **lock marker with text** when the table is in use.
- Show how a long name wraps.
- Empty state for "you have no tables of your own yet" (system tables still listed), with a pointer to "Create copy" on a system table or "New landing table".
- Optional, if it earns its place: a filter by unit, or a search by name. Say whether you'd include it at 10 tables and at 40.

### Table detail (detail pane)

- Header: name, owner, unit, entry count, points range, and when it was created.
- Actions: **Create copy** (the primary action for a system or locked table) and **Delete** (only for an unlocked table of your own).
- Locked or system notice: why it is read-only, and that a copy is the way to change it. Today this is a tinted card under the header; replace it if there's a better M3 pattern.
- **"Used by"** (if the data is available): the contests using this table, so the director understands why it is locked. If the data isn't there, design an "In use by at least one contest" fallback and list "Used by" as a question.
- **The entry list** (see below).

### The entry list (the core of this brief)

Design the list so a director can read 100 rows quickly and match each label to its points without losing the line. Things to address:

- **Width:** the list must not stretch label and points to opposite edges of a wide pane. Consider a maximum readable width, pairing the points right next to the label, leader dots, alternating row tint (tint alone is fine here because it carries no state), or a multi-column flow for long tables on very wide screens. Pick one and explain why. Show it at ~1280px tablet landscape with the rail expanded, and at ~800px.
- **Numbers:** right-align points with tabular figures so the column scans; show the position number (1, 2, 3…) in a quiet leading column.
- **Long tables:** a pinned header while scrolling; a quick way to jump (for example "Jump to entry" or a search within the table by label or points) if you think it's needed at 100+ rows.
- **Short tables:** an 11-entry table should not look lost in a big empty card.
- **Large text:** labels wrap, points never truncate.
- Optional: a small, labelled **points profile** sparkline or bar showing how points fall across the entries, so a director can spot a typo (one entry out of sequence). Only if it stays secondary; the list is the source of truth. If you include it, it needs a text alternative.

## New landing table form

Reached from the FAB ("New landing table", empty form) or from **Create copy** (prefilled: name "Copy of …", same unit, same entries in order).

- Fields: **Name** (required), **Unit** ("What the entries mean": Meters, Feet, Points), and the **entries** list.
- Entries use the **same row shape as the detail list**, so the director sees what they'll get. Each row: position, label, points, and a remove action. A table needs at least one entry, so the last row cannot be removed (disabled with reason).
- **Add entry** appends a row and moves focus to its label. Design **reordering** (drag handle plus keyboard move up/down), because order is what the scorer sees.
- **Fast entry for long tables:** typing 100 rows one field at a time is painful. Show how keyboard flow works (Tab from label to points, Enter adds the next row). Optionally propose a **bulk paste** (paste two columns from a spreadsheet or the rulebook, preview, then accept) or a **generate** helper ("from 100 down to 0, step 1"). Mark these as optional and say which you'd ship first.
- **Validation:** inline on the field and in a summary at the top on save: name required; label required; duplicate label (name the earlier row); points required, whole number, not negative. Scroll to and focus the first error.
- **Copy differences:** when started from a copy, mark rows the director changed and show "3 entries changed from F3J Landing Distance Table". This helps them confirm they changed what they meant to.
- **Save** is the primary action; **Cancel** returns to the list. Leaving with unsaved changes shows a leave-page warning. A failed save keeps every value and shows retry. A save in progress locks the form and ignores a repeated tap.
- Reminder near Save: once created, the table can't be edited, only copied.

## States

- Loading, empty (no tables at all, which shouldn't happen but must not crash), unavailable (remote API unreachable; local tables still shown when offline), load failed with retry.
- Delete: confirmation dialog naming the table; delete rejected because the table became locked since the list loaded (message, list refreshes); delete succeeded (selection moves to the next table, with a snackbar).
- Form: default empty; prefilled from a copy; validation errors; busy; save failed; leave-page warning.

## Deliverables

1. **Page layout** inside the shell on tablet landscape (~1280px, rail expanded) with a long system table selected, and on narrow (~800px, single pane: list, then detail with back).
2. **Entry list:** long table (100 rows) and short table (11 rows); pinned header while scrolled; large text size; with and without the optional points profile.
3. **Detail states:** system table; your unlocked table (Delete enabled); your locked table (Delete disabled with reason, "Used by"); the delete confirmation.
4. **Form:** empty; prefilled from a copy with changed rows marked; reordering; validation errors (inline plus summary); busy; save failed; and (optional) bulk paste preview.
5. **Shared states:** loading; unavailable; empty "no tables of your own".
6. A short rationale covering how the list keeps label and points together on wide screens, how the row component is shared between list, form, and the Configuration preview, and any component or token additions to the M3 theme.
7. Any questions or spec ambiguities you hit. List them; don't silently resolve them.

Light theme first. Show one dark-theme screen (detail pane with a long table) to prove the tokens hold up.
