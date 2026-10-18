# Design brief: Overall Standings report — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Overall Standings** report: the display in the report viewer, its filter and options, and its printed pages. It is one of four initial reports. It fits into the shared frame (Reports page, viewer, status banner, running header and footer, print flow) defined in [reports.md](reports.md). **Design this report's content, filters and options, and its printed pages. Do not redesign the frame.** Use the frame from the Reports brief as given.

The report shows every pilot in order of placing, with the total and the score for each round. It may be run mid-contest. It is the report a director hands to the announcer between rounds and prints for the awards.

**Users:** contest directors and scorers, at a laptop in the scoring tent or a tablet at the field. They glance at it to answer "who is leading", "what did pilot X score in round 4", and "which round did we drop". It is also printed for the pilots' briefing board.

**Platform and visual language:** Flutter, Material 3 for everything outside the sheet (the filter panel, options, banner). The sheet itself is an unthemed paper document: black on white, a neutral typeface, no theme colours, and every mark must survive a black-and-white laser printer (shading plus a text or shape marker, never colour alone). Tablet and larger; the screen version may scroll horizontally. It must work with browser text zoom and large system fonts. Never use colour alone for state; every status has text, an icon or shape, and an accessible label. The sheet exposes real table semantics (column headers, row context) to screen readers.

## The report

### Heading

- Title: **"Overall Results - {Contest_Name}"**.
- A subheading under it with the contest details: venue, dates, discipline, and the number of rounds shown ("Rounds 1 to 6 of 8"). If the round filter is not "All rounds", the subheading says so.
- The result status stamp (Official, Preliminary, Estimated) from the shared frame sits with the heading.

### Table

One row per pilot, ordered by placing. **Ties share a rank** and keep a stable secondary order (say which one the ranking uses; do not invent a tie-break rule, use whatever the contest's tie-breaker produces).

Columns, in order:

1. **Rank**: the overall rank.
2. **Pilot name**.
3. **Total score**: formatted as the contest settings say (rounding or truncation, number of decimals).
4. **Optional columns**, in the fixed order of the Options list below. None, some or all can be on.
5. **Round columns**: one per round, in round order, starting after the optional columns. Round 1 is leftmost, then Round 2, and so on. For a 14-round contest that is 14 round columns.

Round columns are **fixed width**, so the grid reads as a regular matrix and the printed pages split predictably. Show the width, and show what happens with a long score (for example "1000.0" with flight details on).

The default orientation is **landscape**.

### Dropped rounds

A **dropped round's cell is highlighted**. On the printed page, highlight means a light grey fill **plus** a visible marker that works without colour: show the value in parentheses, or add a small "D" tag, and put a legend in the footer ("D = dropped round"). Pick one, and justify it. On screen use the same marker with a tonal fill.

Design the case where a pilot's zero cannot be dropped (a F5J motor restart under the non-droppable option): that cell is not highlighted as dropped, and carries its reason marker (see Flight details).

### Per-round cells and zero reasons

A round cell shows the **round score** (the group score for that round after flight penalty, as the contest settings format it). A pilot with no score in a round that others have scored shows "—" (not 0), and with a text label for screen readers ("no score"). A zero with a reason (out of bounds, motor restart, missing altitude, retirement) shows 0 plus a short marker from the legend. Ask whether this reason marker is wanted in the standings at all (see Questions); design it as a small, optional-looking mark.

A cumulative penalty belongs to the total, not to a round. Ask where to show it (see Questions). Provide a design where the total carries a small "penalty" note and the flight in which it was given has a marker, because the public site does this.

## Options

A panel group titled **Options**, with these toggles. Describe the order, grouping and defaults.

- **Percentage of total**: the pilot's total as a percentage of the winner's. The winner is 100 percent. "5000 points when the winner has 10000 is 50 percent." Show the number of decimals (one) and a percent sign.
- **Raw score**: the sum of **all** flight scores, including dropped rounds, so it equals the total plus the dropped rounds. It tells you how a pilot did with no drop. **It is not the raw score of each round.** Say this in the toggle's helper text, in plain words, because it is easy to misread.
- **Team**, **Pilot number** and **Pilot class**: each shown only when the contest has that option on. When it does not, the toggle is not shown (not disabled; there is nothing to explain).

Two further settings, shown as a separate group titled **Detail**:

- **Flight details**: adds the values that made up each round's score, in smaller text under the round score. It depends on the discipline, so treat the detail as a list from the discipline's score-entry schema. F5J: time, landing (the points, not the display value), launch height. F3J: time, landing. Show the F5J set in full, and the F3J set as a second view to prove the pattern. Show the row height growing, and how the fixed column width holds.
- **Provisional**: the report may be run mid-contest. When on, the report shows up to the last round that has any score, even if that round is not fully scored. When off, only rounds with all scores are shown. **Rounds with no scores are never shown, either way.** The setting **defaults to on when there are rounds not fully scored**, and to off otherwise. A provisional round gets a column heading mark ("R5 partial: 4 of 7 scored") with text. Cells with no score show "—".

Design the **Options** controls so that Provisional also explains the default ("Round 5 is partly scored, so this is on").

## Filtering

A panel group titled **Filter** with a **round range**: a lower bound and an upper bound, inclusive. The default is **All rounds**. Design the control (two numeric dropdowns, a range slider with labels, or a segmented "All rounds / Custom" with two fields; recommend one, keyboard accessible). It must accept only rounds that have scores, and say so.

Show the output for a range: the round columns from the lower bound to the upper bound only. **Resolve the following in your design and list it in your questions:** when the director picks, for example, rounds 3 to 5, do **Rank and Total** still reflect all rounds up to round 5, or only rounds 3 to 5? The follow-up requirements say standings must be producible **as of a round**, which suggests the first. The recommended design is: Rank and Total are always the true standings **as of the upper bound** (all rounds 1 to the upper bound, with the contest's drop rule applied to that set), and the lower bound only hides earlier round columns. Make the heading say it ("Standings as of round 5; showing rounds 3 to 5"), and show a one-line note under the filter. Show the alternative if cheap.

## Printing

The report may not fit one page across. A contest with many rounds and every optional column on will **overflow horizontally**. Design the printed pages:

- **Page 1** carries the heading, Rank, Pilot name, Total, the selected optional columns, and as many round columns as fit.
- **Continuation pages** carry only: **Rank**, **Pilot name**, and the **additional rounds** that did not fit on the previous page. The optional columns are not repeated. Each continuation page repeats a short running header and the round columns' headings.
- Page order: all pilots for the first set of columns, then the next set of columns. Say how a long pilot list that overflows vertically interacts with this (rows first or columns first). Recommended: the pilot list is kept to one page vertically where it fits, and otherwise paginates top to bottom within each column set, repeating the column headings.
- Show the footer's "Page X of Y" and a note when columns continue: "Rounds 9 to 14 continue on page 2".
- Show the three cases as printed pages in landscape: (a) everything fits on one page, (b) rounds overflow to a second page, (c) overflow with all options on and Flight details on.
- Show the portrait fallback if the director changes orientation, even though landscape is the default.

Show the same pages at **A4 and Letter**.

## States

Design: loading and generating; the normal report; no scores yet (the report is not openable from the list, but a refresh of an open report can land here); a round range with no scored rounds; a **tie** at the top; a pilot with no scores at all; a pilot who retired; the **Provisional** report mid-contest; a report that went stale because a score changed while the tab was open; offline.

Also show the heading and footer with each result status (Official, Preliminary, Estimated).

## Deliverables

1. The viewer with the Overall Standings report at expanded width, with the filter and options panel, on a paper sheet. Include the round-range control and the Provisional default.
2. The **table** in four densities: default; with all optional columns; with Flight details (F5J set and F3J set); with both.
3. Dropped-round highlighting, on screen and printed in black and white, with the legend. Plus the non-droppable zero, the "—" for no score, and zero reasons.
4. The **printed pages**: one page; overflow to two pages; all options on; Letter and A4; the continuation page layout; the portrait fallback.
5. The **range filter**, with the "as of round" heading and the note.
6. All states listed above.
7. A short rationale covering layout choices, fixed column width, how dropped rounds and statuses are shown without colour, and any component or token additions.
8. Questions and spec ambiguities. List them; don't silently resolve them.

Light theme first. Show one dark-theme viewer screen to prove the sheet stays black on white.

## Questions to carry into the design

1. **Round filter and totals.** As above. Does the lower bound change the total? Recommended: no.
2. **Cumulative penalty display.** Where does it show on this report, if at all? The public site shows it in the flight where it was given and sums penalties in the total.
3. **Zero reasons.** Does the standings report show the reason for a zero (out of bounds, motor restart), or only the public site? A small marker is cheap but adds noise.
4. **Hidden overall results.** Does the director's report respect the hiding rule? Recommended: no, and the footer says so (see the Reports brief).
5. **Optional column order.** The requirements list Percentage, Raw score, Team, Pilot number, Pilot class. Is that the column order, or should team and number sit beside the name? Recommended: keep the listed order, so the name column and the totals stay together.
6. **Optional columns on continuation pages.** The requirement says they "do not need to be shown". Confirm that they are never shown, so the layout is predictable.
7. **Ties.** Confirm that tied pilots show the same rank, and the next rank is skipped (1, 2, 2, 4).
8. **Team standings.** Out of scope for this report. Confirm.
