# Design brief: Scoring Sheet report — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Scoring Sheet** report: the display in the report viewer, its filter and options, and its printed pages. It is one of four initial reports. It fits into the shared frame (Reports page, viewer, running header and footer, print flow) defined in [reports.md](reports.md). **Design this report's content, filters and options, and its printed pages. Do not redesign the frame.**

The sheet is a **form that people write on**. It carries the draw (who flies in each round and group) and **blank cells** for officials to record every score component for every pilot, by hand, as flights finish. It is typically used at regional, national or world level contests, where the paper record is required. The data later goes into the app through the Scoring page.

**Users:** timekeepers, scorers and officials at the field, using a clipboard and a pen, often in wind and sun. The sheet must be easy to write on, easy to read at arm's length, and easy to key in from afterwards. The director only prints it.

**Platform and visual language:** Flutter, Material 3 for everything outside the sheet. The sheet is an unthemed paper document: black on white, a neutral typeface, no theme colours, every mark surviving a black-and-white laser printer or a photocopier. Tablet and larger. It must work with browser text zoom and large system fonts. Never use colour alone for state. The sheet exposes real table semantics to screen readers.

## The report

### Heading

- The heading on **every page** reads **"Official Scoring - {Contest_Name}"**.
- Under it, a subheading with the **venue and the contest dates**.
- The round and group are in the page's table headers, and the page footer carries "Page X of Y".

The default orientation is **portrait** if the columns fit, otherwise **landscape**. Say what you recommend. The F5J column set, with all optional columns on, is wide.

### Table

A table that officials write into. One table per group, grouped by round.

**Leading columns** (printed, pre-filled from the draw):

- **Pilot name**
- **Club**
- **Lane number** (only when lanes are on)
- **Team** (only when the contest has teams)
- **Pilot number** (only when the contest uses pilot numbers)
- **Pilot class** (only when the contest uses classes)

**Score component columns** (blank, for writing), taken from the contest discipline's score-entry schema. The F5J set:

- **Time**
- **Landing**
- **Height**
- **Over 75m** (the out-of-bounds mark: a tick box)
- **Motor restart** (a tick box; only when the contest allows motor restarts)

Treat these columns as a list from the discipline, not as fixed. Show the F5J set in full, and **one variation** (for example F3J: time, landing, over 75 m; no height) to prove the pattern. Do not design every discipline.

**Trailing columns** (blank, for writing):

- **Penalty**
- **Reflight** (a tick box; a re-flight is requested)
- **Original round** (a small number field, the round of the flight being replaced)
- **Validated** (a tick box or initials box; can be hidden)

Every writable cell is large enough for handwriting in a pen. State the **minimum row height and cell widths in millimetres**; recommend at least 9 mm rows. Tick boxes are real boxes, large enough to tick, not glyphs. Cells have visible rules, not just whitespace. Allow for the component's unit and format as a small hint in the column heading ("Time mm:ss", "Height m", "Landing pts") so the writer enters it consistently.

### Order and header rows

- Rows are ordered by **round, then group**.
- A **header row where each round starts** and a **header row where each group starts**, both spanning the table.
- Pilots within a group are in **ascending lane order** when lanes are on, otherwise in the matrix order.

The two header levels must be distinct without colour (scale, weight, rules, label text: "Round 3", "Group B"). Include the group's size and, if useful, its working time or target ("Working time 10:00"), but ask in the questions whether the second is wanted.

### Pagination

- A **group stays together on one page** when it fits.
- A round header never sits alone at the bottom of a page.
- When a round continues on a new page, the round header repeats with "(continued)".
- **Column headings repeat on every page.**
- Design whether a **round starts a new page**. Recommended: yes, because officials work one round at a time and hand off the sheet for each round. Show both a round-per-page and a continuous layout, and recommend one.
- Leave blank rows? No. A pilot who joined late is added by hand; keep one or two blank rows at the end of each group only if you recommend it and say why.

Show a printed example of three pages in landscape for a 28-pilot contest with four groups, and a one-page portrait example.

## Options

A panel group titled **Options**. Each can be shown or hidden:

- **Club**
- **Team** (only when the contest has teams)
- **Pilot number** (only when the contest uses pilot numbers)
- **Pilot class** (only when the contest uses classes)
- **Validated**

A column the contest does not use is not offered. Design the toggles, their defaults, and what a hidden column gives back (the freed width goes to the writable cells, which get wider). Recommended defaults: Club off, Validated on, the contest-enabled Team, Pilot number and Pilot class on. Confirm. Show the **page count** in the panel as options change.

## Filtering

A panel group titled **Filter** with a **round range**: lower and upper bound, inclusive. The default is **All rounds**. The same control as the other reports. Only rounds that are drawn are choosable. Show the invalid range state.

## States

Design: loading and generating; the normal report; a contest with and without lanes, teams, pilot numbers and classes; a single-group round; a seeded contest with only some rounds drawn; the **configuration changed since the matrix was drawn** banner; a range with no rounds; out of date (the matrix was redrawn while the tab was open); offline.

Also design the scoring sheet on **screen** in a way that is not misleading: the blank cells are shown as blank, not as missing data. Keep the "Screen only" markers (shared frame) off the writable cells.

## Deliverables

1. The viewer with the Scoring Sheet report at expanded width, with the filter and options panel.
2. The **table** with the F5J set and one variation, with all optional columns and with the minimum.
3. **Writable-cell specification**: heights, widths, tick boxes, unit hints. Mark them on one printed sample.
4. The **header-row hierarchy** in black and white.
5. The **printed pages**: one page; three pages with group-keeping and "(continued)" headers; round-per-page versus continuous; Letter and A4; portrait and landscape.
6. The round-range filter and its states.
7. All states listed above.
8. A short rationale covering writability, the page-break rules, and any component or token additions.
9. Questions and spec ambiguities. List them; don't silently resolve them.

Light theme first. Show one dark-theme viewer screen to prove the sheet stays black on white.

## Questions to carry into the design

1. **Leading column.** The earlier Contest Documents requirement puts a lane, pilot number or ordinal first. This report's requirement starts with the pilot name and has no ordinal. Confirm that no ordinal is wanted.
2. **Country.** The earlier Contest Documents requirement lists an optional country column. This report's does not. Confirm it is omitted.
3. **Re-flight column naming.** The earlier document says "Re-flight Requested". This report says "Reflight". Recommended label: "Re-flight". Confirm.
4. **Round per page.** Should a round start a new page? Recommended: yes.
5. **Working time in the group header.** Wanted, or noise?
6. **Signature blocks.** The earlier per-round card requirement had a signature block for pilot and timer. This sheet does not. Confirm none is wanted.
7. **Validated cell type.** Initials, or a tick box? Recommended: a box big enough for initials.
8. **Spare rows.** Add spare blank rows per group for late additions? Recommended: no.
