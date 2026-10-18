# Design brief: Overall Standings report — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Overall Standings** report: the display in the report viewer, its filter and options, and its printed pages. It is one of four initial reports. It fits into the shared frame (Reports page, viewer, status banner, running header and footer, print flow) defined in [reports.md](reports.md). **Design this report's content, filters and options, and its printed pages. Do not redesign the frame.** Use the frame from the Reports brief as given.

The report shows every pilot in order of placing, with the total and the score for each round. It may be run mid-contest. It is the report a director hands to the announcer between rounds and prints for the awards.

**Users:** contest directors and scorers, at a laptop in the scoring tent or a tablet at the field. They glance at it to answer "who is leading", "what did pilot X score in round 4", and "which round did we drop". It is also printed for the pilots' briefing board.

**Platform and visual language:** Flutter, Material 3 for everything outside the sheet (the filter panel, options, banner). The sheet itself is an unthemed paper document: black on white, a neutral typeface, no theme colours, and every mark must survive a black-and-white laser printer (shading plus a text or shape marker, never colour alone). Tablet and larger; the screen version may scroll horizontally. It must work with browser text zoom and large system fonts. Never use colour alone for state; every status has text, an icon or shape, and an accessible label. The sheet exposes real table semantics (column headers, row context) to screen readers.

## Reference: the report directors use today

Directors currently run this report from GliderScore. Its options dialog and a four-page printed output are attached to this brief as references (a 14-pilot, 14-round F5J contest). Pilots and directors know it, so **keep what works and fix what does not**. It is a reference, not a template: the requirements above and below win where they differ. What it shows:

- **Options dialog before the run.** Sections: _Report Scope_ (country, club and class filters; a "Restricted scope scoring" checkbox; a pilot multi-select reading "14 pilots selected"), _F3J / F5J Fly-Offs_ (a fly-off checkbox and a preliminary-competition picker), _Show/Hide_ (Country, Registration with an FAI number picker, Club, Team, Pilot start numbers, Pilot class, Flight details, Percent, Raw score) and _Rounds_ ("All flown, or from N to N"). Options the contest does not use are **greyed out, not removed**. Buttons: Save as File, Preview, Print, Cancel. The new design replaces the modal dialog with the live filter and options panel of the shared viewer, so **Preview is always on screen** and **Save as File maps to Save as PDF** (see the Reports brief and the questions below).
- **Heading.** "{Contest} - Overall Results", then the club and date in brackets, then the vendor's web address. The new heading is "Overall Results - {Contest_Name}" with the contest details beneath it; drop the vendor line.
- **Columns.** Rank, Name (shown as "SURNAME, Given"), Country, Club, Score, Percent, Raw score, then Rnd1 to RndN.
- **Dropped rounds** are marked with an **asterisk before the score** (for example `*949.95`, and `*0.00` for a dropped zero). It works in black and white.
- **Flight details** are a **labelled stack of lines under each round score**, with the labels (Time, Landing, Height) printed once in a small column to the left of the round columns for that pilot. Time is `m:ss` (`9:55`), Landing is the **points** (`50.0`, and `0`), Height is metres (`105m`). A pilot with details on takes about four lines instead of one.
- **Pagination.** Pilots are never split across pages: a pilot's whole block (score line plus detail lines) stays together. Rows paginate first (pilots 1 to 10 on page 1, 11 to 14 on page 2), **then the next set of columns** (Rnd12 to Rnd14 on pages 3 and 4, with the same pilot split as pages 1 and 2). The continuation pages repeat the heading, the Rank and Name columns and the round column headings. The footer has the date and time at the left and the page number at the right.
- **What the new design should improve on.** The legacy continuation pages also repeat Country and Club, which the new requirement says is not needed. Round columns are narrow and the scores in adjacent columns are hard to tell apart without rules. There is no legend for the asterisk. Pilots' details rows have no rules between pilots. Ranks are not visually linked to the rows they belong to when details are on.

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

A **dropped round's cell is highlighted**. On the printed page, highlight means a light grey fill **plus** a visible marker that works without colour. The current report uses an **asterisk before the value** (`*949.95`), so directors already read it. Recommended: keep the asterisk, add the grey fill, and put a legend in the footer ("\* = dropped round"). Show parentheses or a "D" tag only if you find the asterisk fails, and justify it. On screen use the same marker with a tonal fill.

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

  The requirement says the details sit "in smaller text under the round score". The current report does exactly that, and adds **row labels** (Time, Landing, Height) in a small column at the left of the pilot's block so a reader knows which line is which. Design both: (a) small unlabelled lines with one legend for the whole page, and (b) labelled lines with a label column that appears only when Flight details is on. Recommend one (recommended: b, since an unlabelled stack of numbers is error-prone). In either case:
  - Time is `m:ss`, landing is the **points** (not the display value), launch height is metres with a unit.
  - A pilot's **block never splits across pages**.
  - Rules or alternate shading separate one pilot's block from the next, so a block reads as one unit, and the rank sits at the top of its block.
  - Say how a missing component (no time recorded) looks, distinct from zero.

- **Provisional**: the report may be run mid-contest. When on, the report shows up to the last round that has any score, even if that round is not fully scored. When off, only rounds with all scores are shown. **Rounds with no scores are never shown, either way.** The setting **defaults to on when there are rounds not fully scored**, and to off otherwise. A provisional round gets a column heading mark ("R5 partial: 4 of 7 scored") with text. Cells with no score show "—".

Design the **Options** controls so that Provisional also explains the default ("Round 5 is partly scored, so this is on").

## Filtering

A panel group titled **Filter** with a **round range**: a lower bound and an upper bound, inclusive. The default is **All rounds**. Design the control (two numeric dropdowns, a range slider with labels, or a segmented "All rounds / Custom" with two fields; recommend one, keyboard accessible). It must accept only rounds that have scores, and say so.

Show the output for a range: the round columns from the lower bound to the upper bound only. **Resolve the following in your design and list it in your questions:** when the director picks, for example, rounds 3 to 5, do **Rank and Total** still reflect all rounds up to round 5, or only rounds 3 to 5? The follow-up requirements say standings must be producible **as of a round**, which suggests the first. The recommended design is: Rank and Total are always the true standings **as of the upper bound** (all rounds 1 to the upper bound, with the contest's drop rule applied to that set), and the lower bound only hides earlier round columns. Make the heading say it ("Standings as of round 5; showing rounds 3 to 5"), and show a one-line note under the filter. Show the alternative if cheap.

## Printing

The report may not fit one page across. A contest with many rounds and every optional column on will **overflow horizontally**. Design the printed pages:

- **Page 1** carries the heading, Rank, Pilot name, Total, the selected optional columns, and as many round columns as fit.
- **Continuation pages** carry only: **Rank**, **Pilot name**, and the **additional rounds** that did not fit on the previous page. The optional columns are not repeated. Each continuation page repeats a short running header and the round columns' headings.
- Page order: **rows first, then columns**, as the current report does. All pilots paginate top to bottom for the first set of columns (pilots 1 to 10 on page 1, 11 to 14 on page 2), then the same pilots paginate again for the next set of columns (pages 3 and 4). Each page repeats the column headings. A pilot's block is never split across pages. Show a four-page example this way (14 pilots, 14 rounds, Flight details on), and make the page indicator say which pilots and rounds a page holds ("Pilots 11 to 14 · Rounds 12 to 14").
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
9. **Scope filters from the current report.** GliderScore lets the director limit the report by **country, club and class** and pick an arbitrary set of pilots ("14 pilots selected"). The requirements only filter by round. Are these wanted in the initial release? Recommended: no for the first release, but leave room in the Filter group for them, and design the pilot picker only if the director says yes. If yes, the Pilot Scoring Cards brief already has a pilot picker to reuse.
10. **Restricted scope scoring.** The current report has a checkbox that, with a subset of pilots, scores **only those pilots** (normalizing against the subset, so the scores and ranks change). This is a recalculation, not a view filter. The requirements do not mention it. Confirm it is out of scope, and if it is ever added, the report must say on the page that the scores are not the contest's official scores.
11. **Fly-offs.** The current report has an F3J and F5J fly-off mode that combines a preliminary competition with a fly-off. The requirements do not mention it. Confirm it is out of scope for this release.
12. **Registration column.** The current report can show the FAI number. Pilot IDs are not in the requirements' option list. Add an optional "FAI or National ID" column, or leave it out? Recommended: leave it out unless asked.
13. **Country column.** The current report shows country, and the requirements list no country column. Confirm it is omitted.
14. **Greyed-out versus hidden options.** The current dialog greys out options the contest does not use. This brief hides them, because there is nothing to explain. Confirm. If the director prefers greyed options so the full set is always visible, show the disabled reason in text.
15. **Save as File.** The current report can save the output to a file. The shared viewer has a Save as PDF fallback only when printing is unavailable. Should Save as PDF be a regular second action beside Print? Recommended: yes. It costs nothing on most platforms (it is a print destination), and directors email results. Answer in the Reports brief.
16. **Name format.** The current report prints "SURNAME, Given". Use the participant's display name, or this form? Recommended: "Surname, Given" with the surname first, for sorting by eye.
