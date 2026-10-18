# Design brief: Draw Matrix report — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Draw Matrix** report: the display in the report viewer, its filter and options, and its printed pages. It is one of four initial reports. It fits into the shared frame (Reports page, viewer, running header and footer, print flow) defined in [reports.md](reports.md). **Design this report's content, filters and options, and its printed pages. Do not redesign the frame.**

The report shows each round and group, and the pilots flying in them. It is the document pinned to the board at the field, so pilots find their round, group and lane. It is the most often printed document before a contest.

**Users:** contest directors printing before the event, and pilots reading the printout standing in front of a board, often from a distance, sometimes in the sun. Legibility on paper matters more than anything else on this report.

**Platform and visual language:** Flutter, Material 3 for everything outside the sheet. The sheet is an unthemed paper document: black on white, a neutral typeface, no theme colours, every mark surviving a black-and-white laser printer. Tablet and larger. It must work with browser text zoom and large system fonts. Never use colour alone for state. The sheet exposes real table semantics to screen readers.

## Reference: the report directors use today

Directors currently run this report from GliderScore. Two printed outputs for a 14-round contest (3 groups per round, 5 pilots per group) are attached to this brief as references: a **two-column** one (three pages) and a **single-column** one (seven pages). It is a reference, not a template: the requirements in this brief win where they differ. What it shows:

- **Heading.** "{Contest} - Draw - Duration" (the discipline name is part of the title), the club and date in brackets, then the vendor's web address. The new heading is the contest name with "Flight Matrix" and a venue and dates subheading. Drop the vendor line and the discipline suffix (decided: the title is the contest name with "Flight Matrix").
- **The single-column output** is the non-compact version. One table runs down the page with the column headings (Name, Freq, Country, Club, Org Rnd) repeated at the top of every page, and **seven pages** for 14 rounds. The hierarchy is by indentation and case: "ROUND 1" in capitals, "Group 1" indented under it, pilots indented further. It works, but a round or group header can end up **alone at the bottom of a page** (a "ROUND 3 / Group 1" header at the foot of page 1 and the same pair repeated at the top of page 2), and a group can be split across pages. The new design must not do either (see Pagination).
- **Two columns of tables on every page** (the compact output), flowing down the left column and then the right column, each with its **own column headings** (Name, Freq, Ctry, Org Rnd). Rounds 1 to 3 fill the left column of page 1 and rounds 4 to 6 the right. The new **Compact mode** reproduces this layout; the default view is a single column.
- **Header rows.** The compact output has one combined row per group ("Round 1 Group 1"); the single-column output has a round header with group headers beneath it. The new design has a round header row and a group header row, as the requirements say, and each spans all columns.
- **Names** are "Surname, Given". Pilot rows are airy, so the report is long (14 rounds take three pages two-column and seven pages single-column).
- **The compact output keeps a group together** at the bottom of a column or moves it to the next; the single-column output does not. The new design keeps groups together in both.
- **Extra columns** the new report does not have: radio frequency and country (decided: no report shows either) and "Org Rnd" (the round the pilot belongs to, repeated on every row). Do not add them.
- **Footer.** The date and time at the left and the page number at the right.
- **What the new design should improve on.** The combined group header makes it hard to see where a round starts. The airy rows waste paper in the default view, and in compact mode the page is dense without clear separation between the two table columns. Column headings are repeated per column but the round is not repeated when a round spans the column break.

## The report

### Heading

- The contest name across the top, with **"Flight Matrix"** beside or under it.
- A subheading with the **venue and the dates**.
- The matrix revision sits in the shared footer. If the matrix has only some rounds drawn (Seeded mode), the subheading says "Rounds 1 to 4 drawn".

The default orientation is **portrait**, because the table is tall and narrow.

### Table

A tabular layout. One row per pilot per group. Columns:

- **Lane number**: shown only when lanes are turned on for the contest. It is the **first column**, so a pilot scanning for their lane finds it at the left.
- **Pilot name**, formatted "Surname, Given" in normal capitalization (not all capitals).
- **Team**: only when the contest has teams.
- **Pilot number**: only when the contest uses pilot numbers.
- **Pilot class**: only when the contest uses classes.

A column that does not apply is **not shown** and takes no space. Show the table with all columns and with the minimum (name only).

Rows run in order of **round, then group, then lane** (or the order the matrix gives when lanes are off):

1. Round 1, Group A
2. Round 1, Group B
3. Round 1, Group C
4. ... and on, to the last round.

Two kinds of **header rows**, each spanning all columns:

- A **round header** where a round starts.
- A **group header** where a group starts. Include the group's size ("Group B · 7 pilots").

The two levels must be distinct without colour: scale, weight, rules and shading, and the label text itself ("Round 3", "Group B"). Describe the hierarchy and show it in black and white.

### Pagination

Pilots find a group on a printed page, so:

- **Never split a group across pages** when it fits on one page. A group that cannot fit starts on a new page.
- A round does not need to start a new page, but a round header should never sit alone at the bottom of a page.
- When a round continues on a new page, the round header repeats with "(continued)".
- Column headings repeat on every page.

Show a three-page example in portrait for a typical contest (30 pilots, 4 groups, 6 rounds), and a short one-page example (8 pilots, 2 groups, 2 rounds).

## Options

A panel group titled **Options**.

**Compact mode**: an on and off option.

- Smaller font.
- Minimal padding in the table.
- **Two columns of tables** on the page: the tables flow down the first column of the page, then the second.

Design the compact layout on paper: two tables side by side, each with its own column headings, round and group headers spanning only the width of its table column. Show how headings repeat. It exists to cut the number of sheets, so show the page count in the panel ("4 pages, 2 with compact mode"). State the smallest font size you use and keep it legible at a distance (name the size in points; recommend not below 9 pt).

**Additional pilot info**: shows the pilot's **club** and the pilot's **FAI or National ID**. Each of the two is its own option when this is on ("Club", "FAI ID", "National ID"). **This option is disabled and unavailable when compact mode is on.** Show the disabled state with the reason in text beside the control ("Not available in compact mode"), and show the sub-options disabled too while compact mode is on. They keep their last values and apply again when compact mode is turned off.

Design the Options group with the dependency clearly visible, without a tooltip.

## Filtering

A panel group titled **Filter** with a **round range**: lower and upper bound, inclusive. The default is **All rounds**. The output shows the rounds from the lower bound to the upper bound only. Design the control (recommend one design, keyboard accessible, the same control as in the Overall Standings brief for consistency). Only rounds that are drawn are choosable. Show the invalid range state (lower above upper).

## States

Design: loading and generating; the normal report; a contest with **no lanes**, **no teams**, **many classes**; a single-group round; a **seeded contest with only some rounds drawn**; a **configuration that differs from the settings the matrix was drawn with** (a non-blocking banner above the sheet: "The report shows the drawn matrix. Configuration has changed since."); a range with no rounds; out of date (the matrix was redrawn while the tab was open — a banner with Refresh, never an automatic change, since printed boards must be reprinted); offline.

Pilots with a long name, or a long club name, must wrap or truncate with a rule. Say which. Recommended: wrap the name, truncate nothing on paper.

## Deliverables

1. The viewer with the Draw Matrix report at expanded width, with the filter and options panel.
2. The **table** with every column, with the minimum columns, and with Additional pilot info (club and ID).
3. The **header-row hierarchy** in black and white.
4. **Compact mode** on screen and on paper, with two columns of tables, and the disabled Additional pilot info.
5. The **printed pages**: one page; three pages with group-keeping and "(continued)" headers; compact; Letter and A4.
6. The round-range filter and its states.
7. All states listed above.
8. A short rationale covering the hierarchy of headers, the page-break rules, compact mode, and any component or token additions.
9. Questions and spec ambiguities. List them; don't silently resolve them.

Light theme first. Show one dark-theme viewer screen to prove the sheet stays black on white.

## Decisions made

These were open and are settled. Design to them.

1. **Column order.** Lane first (when lanes are on), then pilot name, team, pilot number, pilot class.
2. **Lane ordering.** Without lanes, rows follow the matrix's own order within a group.
3. **Requirements typo.** "Round 4, Group C" in the row-order example is an example, not a rule.
4. **Ordinal column.** There is none when there are no pilot numbers.
5. **Compact sub-options.** Compact mode disables Additional pilot info (and its sub-options), which keep their values.
6. **Compact round headers.** Round and group headers repeat per table column.

## Questions to carry into the design

None open from the requirements. List any you find.
