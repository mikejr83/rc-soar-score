# Design brief: Scoring Sheet report — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Scoring Sheet** report: the display in the report viewer, its filter and options, and its printed pages. It is one of four initial reports. It fits into the shared frame (Reports page, viewer, running header and footer, print flow) defined in [reports.md](reports.md). **Design this report's content, filters and options, and its printed pages. Do not redesign the frame.**

The sheet is a **form that people write on**. It carries the draw (who flies in each round and group) and **blank cells** for officials to record every score component for every pilot, by hand, as flights finish. It is typically used at regional, national or world level contests, where the paper record is required. The data later goes into the app through the Scoring page.

**Users:** timekeepers, scorers and officials at the field, using a clipboard and a pen, often in wind and sun. The sheet must be easy to write on, easy to read at arm's length, and easy to key in from afterwards. The director only prints it.

**Platform and visual language:** Flutter, Material 3 for everything outside the sheet. The sheet is an unthemed paper document: black on white, a neutral typeface, no theme colours, every mark surviving a black-and-white laser printer or a photocopier. Tablet and larger. It must work with browser text zoom and large system fonts. Never use colour alone for state. The sheet exposes real table semantics to screen readers.

## Reference: the sheets directors use today

Directors currently print these from GliderScore. A seven-page output for a 14-round contest (3 groups per round, 4 to 5 pilots per group) is attached to this brief as a reference. It is a reference, not a template: the requirements in this brief win where they differ. I read it as text, so row heights and rules are not described. What it shows:

- **Heading.** "{Contest} - Scoring Sheets - Duration", the club and date in brackets, then the vendor's web address. The new heading is "Official Scoring - {Contest_Name}" with the venue and dates under it. Drop the vendor line and the discipline suffix.
- **Columns.** Name, Freq, Ctry, Club, **Time**, **Lndg**, **Height**, a **Lndg Over 75m** column, **Motor ReStarted**, **Sfty Plty** (a safety penalty), **Re-Fly?**, **Org Rnd** and **Signature**. The new sheet drops frequency, country and Org Rnd (decided), calls the penalty "Penalty", and replaces Signature with **Validated**, a blank text spot.
- **Org Rnd** is pre-printed with the group's own round number. This release has **no Original round column**; do not add it.
- **Hierarchy.** "ROUND 1" in capitals (the new headings use Title Case: "Round 1"), then "Group 1" indented under it, with the pilots listed beneath. Column headings repeat at the top of every page. The date and time are at the left of the footer and the page number at the right.
- **Page breaks.** A group is **split across pages** with a "Group 1 (Cont)" header on the next page, and a round header can end up at the foot of a page. The new design must not split a group that fits on a page (see Pagination).
- **Names** are "Surname, Given", one pilot per row.
- **What the new design should improve on.** Rows are tight and not ruled, so there is little room to write. Headings are cramped ("Lndg Over 75m", "Sfty Plty"). Group splits make it hard to find a pilot's row at a glance.

## The report

### Heading

- The heading on **every page** reads **"Official Scoring - {Contest_Name}"**.
- Under it, a subheading with the **venue and the contest dates**.
- The round and group are in the page's table headers, and the page footer carries "Page X of Y".

The default orientation is **portrait** if the columns fit, otherwise **landscape**. Say what you recommend. The F5J column set, with all optional columns on, is wide.

### Table

A table that officials write into. One table per group, grouped by round.

**Leading columns** (printed, pre-filled from the draw):

- **Lane number**: only when lane assignment is enabled for the contest. It is the **first column**.
- **Pilot name**, formatted "Surname, Given" in normal capitalization (not all capitals).
- **Club**
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
- **Reflight**: a blank **text spot**, not a tick box. Officials use it for several purposes of their own, for example to mark the pilots selected for a re-flight or those entitled to one.
- **Validated**: a blank **text spot**, wide enough for initials or a short note. Officials often initial it to show the sheet was checked against the electronic entry, and sometimes use it for other official purposes. It can be hidden.

There is **no Original round column** in this release.

Every writable cell is large enough for handwriting in a pen. State the **minimum row height and cell widths in millimetres**; recommend at least 9 mm rows. Tick boxes are real boxes, large enough to tick, not glyphs. Cells have visible rules, not just whitespace. Allow for the component's unit and format as a small hint in the column heading ("Time mm:ss", "Height m", "Landing pts") so the writer enters it consistently.

### Order and header rows

- Rows are ordered by **round, then group**.
- A **header row where each round starts** and a **header row where each group starts**, both spanning the table.
- Pilots within a group are in **ascending lane order** when lane assignment is enabled, otherwise in **alphabetical order by surname**.

The two header levels are **headings in normal Title Case**, for example "Round 3" and "Group B" (never all capitals). Use different heading levels to show the hierarchy (a level-two style for the round, a level-three style for the group), and keep them distinct without colour: scale, weight, rules and the label text itself. Include the **group's size and the working time** in the group heading ("Group B · 7 Pilots · Working Time 10:00").

### Pagination

- A **group stays together on one page** when it fits.
- A round header never sits alone at the bottom of a page.
- **A page break never splits a group.** Group A may end one page and the later groups of the same round start the next; that is fine.
- **A round does not start a new page.** The only time a round moves to a new page is when its heading would sit at the foot of one page while its first group overflows to the next: the heading then moves with the group.
- When a round continues on a new page, the round heading repeats with "(Continued)".
- **Column headings repeat on every page.**
- There are **no spare blank rows**; a pilot who joined late is added by hand.

Show the continuous (round-after-round) layout, with a round heading that moves to the next page with its first group. Show a printed example of three pages in landscape for a 28-pilot contest with four groups, and a one-page portrait example.

## Options

A panel group titled **Options**. Each can be shown or hidden:

- **Club**
- **Team** (only when the contest has teams)
- **Pilot number** (only when the contest uses pilot numbers)
- **Pilot class** (only when the contest uses classes)
- **Validated**

A column the contest does not use is not offered. Design the toggles, their defaults, and what a hidden column gives back (the freed width goes to the writable cells, which get wider). Recommended defaults: Club off, Validated on, the contest-enabled Team, Pilot number and Pilot class on. Show the **page count** in the panel as options change.

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
5. The **printed pages**: one page; three pages with group-keeping and "(continued)" headers; the heading that moves with its group; Letter and A4; portrait and landscape.
6. The round-range filter and its states.
7. All states listed above.
8. A short rationale covering writability, the page-break rules, and any component or token additions.
9. Questions and spec ambiguities. List them; don't silently resolve them.

Light theme first. Show one dark-theme viewer screen to prove the sheet stays black on white.

## Decisions made

These were open and are settled. Design to them.

1. **Leading column.** Lane number, when lane assignment is enabled; ascending by lane. Without lanes, pilots are in alphabetical order by surname. No ordinal column.
2. **Country.** Omitted. Frequency is omitted too.
3. **Reflight.** A blank text spot that officials use as they see fit. Not a tick box, and not necessarily "requested".
4. **Round per page.** Not needed. A round moves to a new page only when its heading would be alone at the foot of a page with its first group overflowing.
5. **Working time.** Shown in the group heading.
6. **Validated.** Kept, a blank text spot for officials' initials or other official use.
7. **Cell type.** Validated and Reflight are text spots, not tick boxes.
8. **Spare rows.** None.
9. **Original round.** Not in this release.
10. **Headings.** Round and group headings are in Title Case at two heading levels, not all capitals. A group is never split across pages.
11. **Signature.** No signature block or column.

## Questions to carry into the design

None open from the requirements. List any you find.
