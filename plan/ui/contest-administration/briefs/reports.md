# Design brief: Reports page and report viewer — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Reports page** in the contest director's administration app, and for the **report viewer** that every report opens in. The page lists the reports and documents a director can produce for a contest. The viewer shows one report, lets the director filter and set options for it, and prints it.

The initial release has four reports. Each has its own brief that builds on this one, so design the page and the viewer here as a **shared frame** that all four fit into:

- [Overall Standings](reports-overall-standings.md) — results, tabular, landscape.
- [Draw Matrix](reports-draw-matrix.md) — who flies with whom in every round and group.
- [Scoring Sheet](reports-scoring-sheet.md) — blank grids for officials to write scores on.
- [Pilot Scoring Cards](reports-pilot-scoring-cards.md) — cut-out cards, one set per pilot.

Please produce a canvas/prototype with the Reports page in each state, the viewer frame with a stand-in report (use Overall Standings), the filter and options panel, the displayed-versus-printable treatment, the print flow, and the responsive behaviour. The four reports are designed in their own briefs; do not design their content here.

**Users:** contest directors (CDs) and their helpers. Reports are used two ways. **Before the contest** at home on a laptop or tablet: print the matrix, the sheets and the cards, often for a big championship. **During and after the contest**, at the flying field on a tablet or at a laptop in the scoring tent: run the standings between rounds, hand a printout to the announcer, reprint a card for a pilot who lost theirs. They are busy and interrupted. They want to find the report, set a few filters and press print.

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger**. The standard Material 3 window size classes apply (compact under 600dp, medium 600 to 839dp, expanded 840dp and up), with no custom breakpoints. It must work with browser text zoom and large system fonts. Dense tables may scroll horizontally on screen.
- **Never use colour alone for state.** Every status has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements.
- **The sheet is not themed.** The report itself is a paper document. Inside the report sheet use black on white, a neutral typeface, and no theme colours, whatever the app theme (including dark). Every mark on the sheet must survive a **black-and-white laser printer**: shading and an icon or text marker, never colour alone.

**Existing app shell (the Reports page lives inside it):**

- A persistent shell with a contest-scoped navigation rail on the left. The page is reached from the `Reports` rail item, at `/contest-administration/contests/:id/reports`. It is also reached from links elsewhere (for example "View reports" on a completed contest's workspace).
- A header with the title, the contest name, and breadcrumbs or back navigation.
- A read-only shell status panel (lifecycle, participant scoring, administration lock) and a persistent status bar at the bottom (connectivity and sync). Both are already designed; show them in the layouts.
- One clear primary action per page state.
- The **viewer is not inside the shell** (see "Opening a report").

## Reports page

### Purpose

Answer "which paper or results can I produce for this contest, and is it ready to produce?" Right now the page is a placeholder showing only the contest ID. It replaces that.

### Contest context strip

Above the list, one compact strip says what a report would be built from. Every report repeats these facts in its own heading or footer, so the director can tie a printout back to this state:

- **Lifecycle** (Created, Configuring, Ready, Running, Completed).
- **Matrix revision** (or "No matrix drawn").
- **Configuration revision** and **calculation version**.
- **Scoring progress**: "5 of 8 rounds fully scored · 1 round partly scored · 2 not flown". Text plus icon.
- A **result status** that says what standings would be if produced now: `Official`, `Preliminary` or `Estimated`. Define these on the page in one line each, in a short help popover, not a tooltip. See the shared definitions below.

Keep lifecycle, participant scoring and administration lock separate. The strip shows only lifecycle among them, because it is the one that matters for reports. Do not merge it with the result status.

### The list

A **grid of report cards**, two columns at expanded width and one at medium and compact. Each card has:

- A **title** and a **one-sentence brief** of what it provides, in plain language. Suggested wording:
  - Overall Standings: "Every pilot's placing, total, and score for each round."
  - Draw Matrix: "Which pilots fly in each round and group."
  - Scoring Sheet: "Blank grids for officials to write scores by hand."
  - Pilot Scoring Cards: "A printable card per pilot to record their own scores, with a QR code to their online scoring page."
- A **stylized graphic** that represents the report at a glance: a small paper thumbnail, not a screenshot. Standings: a ranked table with a highlighted cell. Matrix: stacked round and group blocks. Scoring sheet: an empty ruled grid. Cards: four cut-out cards with a QR square. Draw them in the theme's tonal palette with a plain shape language, so they work in light and dark. They are decorative; give them empty alt text and keep the title and brief as the accessible name.
- **Facts line**: page orientation and the default paper ("Landscape"), whether it needs scores, whether it needs a matrix.
- A **primary "Open" button** and nothing else competing with it. Opening the report does not print it.

Group the cards under two headings so the director sees the difference at a glance: **Results** (Overall Standings) and **Documents to print** (Draw Matrix, Scoring Sheet, Pilot Scoring Cards). The grouping is a visual choice, not a requirement; justify it or change it.

Do not add a search or filter to the list. There are four items. Leave room in the layout for more.

### Availability

A report that cannot be produced stays visible, its **Open button is disabled, and the reason sits beside it in text** (not only a tooltip). Design each:

| Report              | Unavailable when       | Reason shown                                        |
| ------------------- | ---------------------- | --------------------------------------------------- |
| Overall Standings   | No scores in any round | "No scores have been entered yet." Link to Scoring. |
| Draw Matrix         | No matrix drawn        | "The matrix has not been drawn." Link to Matrix.    |
| Scoring Sheet       | No matrix drawn        | Same, link to Matrix.                               |
| Pilot Scoring Cards | No matrix drawn        | Same, link to Matrix.                               |

Also design the **available-with-a-warning** states, which stay enabled and say so on the card:

- Standings with missing scores or open review requests: "Preliminary: 3 pilots have no score in round 4."
- A matrix, sheet or cards report when the **configuration differs from the settings the matrix was drawn with**: "Configuration has changed since the matrix was drawn. This report shows the drawn matrix."
- Seeded mode with only some rounds drawn: "Rounds 1 to 4 drawn. Rounds 5 to 8 are not drawn yet." (Printed cards for a redrawn round must be reprinted, so say it.)
- Completed contest: all reports remain available and read-only; no change to the cards beyond the lifecycle in the strip.

### Page states

Design: loading; the normal list; every unavailable and warning state above; unavailable (the data cannot be read, with retry); the **offline build** (reports are produced from local data; the strip says "Based on local data, N changes not yet synced" with a link to the sync page); and a contest with a hidden overall results setting (see "Open points").

## Opening a report

Reports are displayed **without blocking the contest application**. Pressing Open opens the report:

- **Web:** in its own browser tab.
- **Native:** in its own window.

The Reports page keeps working while a report is open, and several reports can be open at once. Design:

- The Open interaction and what the page shows after it (for example the card briefly says "Opened in a new tab" and re-enables Open; there is no blocking spinner). If the browser blocks the pop-up tab, the page shows a message with an "Open here" fallback that navigates in the same tab.
- The **viewer is outside the shell**: no rail, no status panel. It has its own slim app bar (below). Because it is a separate tab or window, it must carry its own identity: the contest name and report name in the app bar and in the tab or window title (for example "Overall Standings — {Contest}").
- Each report has a route of its own that holds its filters and options in the URL, so refreshing the tab, copying the link or reopening it restores the same view. Show nothing about the URL in the design; note the requirement.

## Report viewer (shared frame)

### Layout

An app bar, a filter and options panel, and a **sheet area**.

- **App bar:** report name and contest name; **Print** as the single primary action; an overflow menu for page setup; a close button on native windows. Print is also reachable with the usual keyboard shortcut.
- **Filter and options panel:** a side panel at expanded width, a collapsible panel above the sheet at medium width, a bottom sheet at compact width. It holds three groups, in this order, each with a heading:
  1. **Filter**: what to include (for example the round range, the pilots). Defined per report.
  2. **Options**: what to show (columns, modes). Defined per report.
  3. **Page**: paper size (Letter or A4, defaulting by locale) and orientation (the report's own default, changeable). The same on every report.
- **Sheet area:** a neutral grey backdrop with the report drawn as one or more **paper pages** on it, at a readable zoom, scrolling vertically. Offer zoom (fit width, 100 percent, and steps), and a page indicator ("Page 2 of 5").
- A **status banner** above the sheet (see below).

Changes in the filter and options panel **update the sheet live**. There is no Apply button; show a brief in-place refresh state for slow reports, not a full-page spinner.

### Displayed versus printable

"Reports will denote what is displayed vs. what is printable." Make the line between them unmistakable:

- **Everything on the paper sheet prints.** What is on the sheet is exactly what comes out.
- **Everything outside the sheet does not print**: the app bar, the panel, the banner, the page indicator, and the zoom controls. Style them with the app theme so they read as "screen only".
- Where a report has something that exists **only on screen** inside the data (for example a sticky pinned column, or a scroll affordance), show it faded and labelled "Screen only", and show how the printed version differs. Page breaks are drawn as dashed separators with "Page 2" labels, and the printed repeating parts (running header, repeated column heads) are visible on each page.
- Offer a **Print preview** toggle in the page setup, which hides screen-only affordances and shows the sheet exactly as printed. Say whether it should be the default. Recommend one.

### Status banner and printed identity

Every report must be identifiable to a specific contest, so each page carries a **running header** with contest identity (defined per report) and a **running footer** with: the report name, "Page X of Y", the generated date and time, the matrix revision, and the configuration and calculation version. Design the footer so it is small, legible in black and white, and the same across reports.

Where the report depends on scores (Overall Standings, and Pilot Scoring Cards when pre-filled), the footer and the screen banner also show the **result status**, with a visible stamp on the printed page when it is not official:

- **Official**: every score counted is official, nothing is stale. The page needs no stamp.
- **Preliminary**: some scores are missing, unreviewed, submitted by participants but not yet official, or computed under an older configuration. Stamp "PRELIMINARY" in the header or footer of every page.
- **Estimated**: some placements are estimated for missing scores. Stamp "ESTIMATED".

Use text, an icon on screen and a bordered text stamp on paper. Never colour alone. The banner states the reason in one line ("Preliminary: round 4 has 3 missing scores and 1 open review") and links to Scoring.

### Print flow

The screen **must offer to print the report**, using the user's standard machine printing interface. Design:

- The **Print** button opens the system print dialog. The design does not replace it. Show what the director sees before, and after returning.
- Say which page setup the print uses (paper, orientation) beside the button so there is no surprise in the system dialog.
- **Print failed or cancelled**: a quiet message, no data lost, retry available.
- **Printing is not available** (for example a kiosk browser): offer to save as PDF where the platform allows, and say so; otherwise explain.
- Do not retain the filter and option choices between sessions. They are only for producing this document. They do stay in the URL for refresh.

### Viewer states

Design for the stand-in report: loading; generating; **no data for the current filter** (for example a round range with nothing in it) with a "Reset filters" action; **invalid filter** (lower round above upper round) with an inline message and the sheet left on the last good result; unavailable (data cannot be read, with retry); the **report is out of date** (scores, the matrix or the configuration changed since this tab produced it — a non-blocking banner with "Refresh", never an automatic redraw under the director's eyes); offline (produced from local data, unsynced changes counted); and a contest that is no longer found.

### Accessibility

Filters are labelled controls with state announcements. The sheet exposes real table semantics (column headers and row context) to screen readers. Printing and the filter panel are reachable by keyboard in a sensible order. Describe the focus order.

## Deliverables

1. The **Reports page** at expanded (~1280px), medium (~700px) and compact (~400px) widths.
2. The **card states**: available, available with a warning, and unavailable with a reason, for each report. The four graphics.
3. The **open flow**: before, after, and the blocked-pop-up fallback.
4. The **viewer frame** at expanded, medium and compact widths with the filter, options and page panels, the status banner, and a stand-in report on a paper page.
5. The **displayed-versus-printable** treatment, including page-break drawing, the running header and footer, and the "Screen only" markers.
6. The **print flow** and its failure states.
7. The **result stamp** (Official, Preliminary, Estimated) on screen and on a black-and-white printed page.
8. **Viewer states**: loading, generating, empty filter, invalid filter, out of date, offline, unavailable.
9. A short rationale covering layout choices, why the sheet is unthemed, the live-update model, how colour independence is achieved, and any component or token additions to the M3 theme.
10. Any questions or spec ambiguities you hit. List them; don't silently resolve them.

Light theme first. Show one dark-theme screen (the viewer with the paper sheet on a dark backdrop) to prove the sheet stays black on white and the tokens hold up.

## Open points

These are decisions the requirements do not settle. Design a recommended default, show the alternative if cheap, and list the point in your questions.

1. **Result status rules.** The requirements name `official`, `preliminary` and `estimated` but do not say which one a given standings page gets. The working definitions above are mine. Confirm.
2. **Hidden overall results.** A contest can hide overall scores and placing on the public site and participant views through round N. Do the director's own reports respect that? Recommended: no, the director always sees the full standings, and the report states "Overall results are hidden from participants through round N" so a printout handed to the public is not a surprise.
3. **Standings as of a round.** Standings must be producible as of a round. Does the round filter mean that? See the Overall Standings brief.
4. **Which window API on native.** Opening a second native window may not be available on every platform. Design the fallback as navigating in place with a back affordance and say so.
5. **Page setup defaults and storage.** Paper size defaults by locale. Confirm the page setup is not stored.
