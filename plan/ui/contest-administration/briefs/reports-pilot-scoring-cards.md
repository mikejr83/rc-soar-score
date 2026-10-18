# Design brief: Pilot Scoring Cards report — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Pilot Scoring Cards** report: the display in the report viewer, its filter and options, and its printed pages. It is one of four initial reports. It fits into the shared frame (Reports page, viewer, running header and footer, print flow) defined in [reports.md](reports.md). **Design this report's content, filters and options, and its printed pages. Do not redesign the frame.**

A pilot scoring card is a **physical card** a pilot (or their helper) keeps and writes on. It lists every flight the pilot will fly: round, group, lane. It has a spot to write each score component. It carries a **QR code** that takes the pilot straight to their online scoring page. The director prints the cards onto sheets, cuts them out and hands one to each pilot.

**Users:** the director, who prints and cuts the cards (often a hundred pilots at a championship) with a household inkjet, and pilots and helpers, who read and write on the card at the field, in sun and wind, with the QR code scanned by a phone. Printing must be reliable on an inkjet in "document quality", and the cards must be easy to cut square.

**Platform and visual language:** Flutter, Material 3 for everything outside the sheet. The sheet is an unthemed paper document: black on white, a neutral typeface, no theme colours, every mark surviving a black-and-white inkjet. Tablet and larger. It must work with browser text zoom and large system fonts. Never use colour alone for state. The preview exposes the cards to screen readers as labelled groups (one per pilot).

## Reference: the cards directors use today

Directors currently print these from GliderScore. A seven-page output for a 14-pilot, 14-round contest (14 cards, **two cards per page side by side**) is attached to this brief as a reference. It is a reference, not a template: the requirements in this brief win where they differ. I read it as text, so the QR code, if the page has one, is not described here. What it shows:

- **Card header.** "{Contest} {Club} {Date}" in a line across the top of each card, as the requirement says.
- **Identity.** The pilot's name as "Given SURNAME" (for example "Gordon BUCKLAND"), then frequency, country and FAI number at the right. The new card drops frequency and country (decided: no report shows frequency; no country column). It keeps the FAI and National ID.
- **A printed link.** Under the name the card prints the **full online scoring link in text**, with the contest and pilot in the query string. The new design must decide whether to keep a printed link (see the questions).
- **Table.** One row per round, columns: Round, Group, Time, Landing, Height, a **">75m"** column, a **"ReStart"** column, Penalty, Timer, Submitted. The new table adds Lane when lanes are on, and "Validated" replaces "Submitted". The order of the writable columns is otherwise the same as the requirement.
- **Pre-filled values.** In this output the scores are already printed in the cells: time as `9:57`, the landing points (`40`), and the height in metres (`119`). A motor restart is a "Yes" under the ReStart column. Pre-filled values look **exactly like handwriting space filled in**; there is nothing to tell them from a blank cell. The new Pre-fill option must make them distinguishable (see Options).
- **Rows.** All 14 rounds fit on a half-page card at a small row height, with no room to write over a pre-filled cell. Rounds that were not scored leave blank cells.
- **Footer.** The vendor's web address under each card. Drop it.
- **What the new design should improve on.** The card has no cut guides or borders, so cutting is by eye. Rows are tight and not ruled, which is poor for handwriting. The printed link is long. The ">75m" and "ReStart" headings are cramped and unlabelled as tick boxes. The Submitted column is unclear to a pilot.

## The report

The sheet is made of **cards**. One card per pilot, laid out several to a page.

### Card header

A small line across the **top of each card**, in plain small text (not title text) with the **contest name, venue and date**. It is there so a loose card is traceable to its contest.

### Pilot identity

The **main title of the card is the pilot's identity**:

- The pilot's **name**, large.
- Smaller, beneath or beside it: **club**, **FAI ID and National ID** (those that exist), **class** and **team**. Class and team show only when the contest uses them.

Show a pilot with every field, a pilot with only a name, and a pilot with a very long name or club. Say how a long name wraps or shrinks (recommended: shrink to a floor of 14 pt, then wrap to two lines; never truncate on paper).

### QR code

If online scoring has been enabled, show a **QR code** on the card. It must be large enough for an inkjet in "document quality" to print without trouble, so scanning does not need high resolution:

- State a **minimum size in millimetres** for the QR square (recommend at least 25 mm) and the quiet zone around it (at least four modules).
- Pure black on white. No logo in the middle, no rounded styling, no colour.
- A short caption beside it: "Scan to enter scores". Show whether to print the link in text as a fallback, and flag the security of that in the questions, because the link is an invitation to a pilot's page.
- Show the card **without** a QR code when online scoring is off, and say what takes its place so the layout does not collapse (recommended: the space is left to the scoring table, and the identity block expands).

### Scoring table

The main part of the card. A table the pilot writes in, one row per round they fly.

**Leading columns** (printed, pre-filled from the draw):

- **Round** number
- **Group**
- **Lane number** (only when lanes are on)

**Score component columns** (blank for writing, from the discipline's score-entry schema). F5J:

- **Time**
- **Landing**
- **Height**
- **Over 75m**
- **Motor restart** (only when the contest allows motor restarts)

**Trailing columns:**

- **Penalty**
- **Timer** (the timekeeper's initials or name)
- **Validated** (initials, or a tick box)

Treat the components as a list from the discipline, not as fixed. Show the F5J set in full, and **one variation** (F3J: no height) to prove it holds.

Writable cells are large enough for handwriting in a pen. State **minimum row height and cell widths in millimetres**. Recommend at least 8 mm rows on a quadrant card. Tick boxes are real boxes. Put a unit hint in the heading ("Time mm:ss", "Height m").

Rounds not drawn yet (Seeded mode, or a partly drawn matrix) do not have rows. Say what the card shows for them, if anything (recommended: nothing, and the card footer notes "Rounds 1 to 4" so a reprint after the next draw is obvious).

## Cards on the page

Cards are designed to fit into **quadrants** of a standard **Letter or A4** sheet: four to a page. Each card has the same proportions as one quarter of the page.

When the contest has **many rounds**, a quadrant is too short to hold the whole table at a writable row height, so **two cards per page** are used instead (each a half page). Design:

- **Four-up** (quadrant) and **two-up** (half page) layouts on Letter and on A4, with the margin in millimetres. Keep every card inside the printer's safe area (recommend a 6 mm unprintable margin) and say so.
- How the choice is made: a **Cards per page** setting in the Page group of the panel: Automatic (default), Four, Two. **There is no fixed round count.** The threshold follows from the content sizing: Automatic uses four-up when every round row fits in a quadrant at the minimum writable row height (with the identity block, QR code and header), and two-up otherwise. The panel says which it picked and why ("14 rounds don't fit four to a page; using two"). **Anchor: an 8-round F5J contest must fit four to a page** using the layout of the current report as a base (all F5J columns, Lane, Penalty, Timer and Validated). State the maximum number of rounds your sizing allows in four-up and in two-up, and show that 8 fits four-up and 14 needs two-up. If sizing tradeoffs let more than 8 fit, say what you gave up (row height, QR size).
- What happens if even a half page cannot hold all rounds (very long contests): recommended, the card continues on a second card for the same pilot ("Card 1 of 2"), with the identity block repeated in small. Show it.
- A **guideline border** around each card, so the cards can be cut. Draw a thin dashed cut line on the page between cards, and short crop marks at the page edges. The line must be visible on paper and **not** bleed into the card's contents. Show it in black and white.
- A footer on every card in tiny text: the **matrix revision** and the rounds covered, so a card printed before a redraw is recognisable as old.

Order of cards on the pages: by pilot **in the order chosen** (default alphabetical by name). Say whether a team's pilots print together. Recommended: alphabetical, with the team shown on the card.

## Options

A panel group titled **Options**.

**Pre-fill**: When scores have been entered, this option becomes enabled. **It is off by default.** When on, the score components already entered are printed into the matching cells of each card. Design:

- The disabled state when no scores exist, with the reason in text beside the control ("No scores have been entered yet").
- The enabled state, with helper text ("Prints the scores already entered, so pilots can check them").
- Pre-filled values must look **different from the blank writable cells** in black and white, without colour: set in a typeface or weight distinct from the blank hint text, with the cell clearly occupied. Show the card both ways. Label the card footer "Includes scores through round N" when pre-fill is on, so the card is dated.
- Pre-filled values should show **official** values, and say when a value is a participant's submission not yet made official. Ask this in the questions.

## Filtering

A panel group titled **Filter**. Two controls.

- **Rounds**: a range, with a lower and upper bound, inclusive. The default is **All rounds**. The same control as the other reports. Show a card with only rounds 3 to 6.
- **Pilots**: choose which pilots get a card. **By default every pilot is selected.** Design a selectable list with search, "Select all" and "Select none", a count ("12 of 38 selected"), and a way to select by group or by team if cheap (say if you leave them out). Remember the list has to work with a keyboard and at compact widths, where it opens in its own sheet.

The panel shows what the choices produce: **"12 cards · 3 pages"** (updated live). Show the empty selection state (no pilots chosen) with the Print button disabled and a reason in text.

## States

Design: loading and generating (cards for 100 pilots take time; show progress and keep the panel usable); the normal report; no QR code (online scoring off); **a pilot with no matrix rows** (a late-added pilot, or a withdrawn one: say whether they get a card); Pre-fill enabled, disabled, and on; the empty pilot selection; a range with no rounds; the **configuration changed since the matrix was drawn** banner; out of date (a redraw or a pilot change happened while the tab was open — a banner with Refresh, never an automatic redraw of the cards); offline (QR codes still generate, the page says the link works once the card is scanned online).

Also design the preview. On screen, the sheets are shown as pages with several cards each, at a zoom where a card is readable; the director can click a card to see it at full size. This click-to-enlarge is **screen only** and shown as such.

## Deliverables

1. The viewer with the Pilot Scoring Cards report at expanded width, with the filter and options panel and the live card and page count.
2. The **card**, at actual size, for F5J and for one variation; with and without QR; with every identity field and with a minimal one; with a long name.
3. **Writable-cell and QR specification** in millimetres, marked on one printed sample.
4. The **printed pages**: four-up and two-up on Letter and A4, the cut guides and crop marks, the safe-area margin, a "Card 1 of 2" continuation, the card footer.
5. **Pre-fill**: disabled, enabled, off, on; and how pre-filled values read in black and white.
6. The **pilot picker** and the round range, at expanded, medium and compact widths, with the live count.
7. All states listed above.
8. A short rationale covering printability on a household inkjet, the cards-per-page rule, the QR choices, the black-and-white distinctions, and any component or token additions.
9. Questions and spec ambiguities. List them; don't silently resolve them.

Light theme first. Show one dark-theme viewer screen to prove the sheet stays black on white.

## Decisions made

These were open and are settled. Design to them.

1. **Name format on the card title.** "Given Surname" in normal capitalization (not all capitals), unlike the lists, which use "Surname, Given".
2. **Four-up versus two-up.** No fixed round count; the sizing decides. An 8-round F5J contest must fit four-up, using the current report's layout as a base.
3. **No frequency or country on the card.** Frequency is in no report; country is not on the card.

## Questions to carry into the design

1. **What "online scoring enabled" means.** The requirement says to show the QR code "if online scoring has been enabled". The contest has no self-scoring setting; participant scoring is a separate Open or Closed state that changes during a contest. Which condition shows the QR code? Recommended: show it unless the invitation service is unavailable, since a card is printed before participant scoring opens.
2. **Does printing create invitations?** Each QR code is an access token for one pilot. Is a token issued when the card is generated, or does the card carry a stable link? Reprinting a card should not silently invalidate the previous one, or should it? This affects the security wording near the QR code.
3. **Link printed in text.** Print the URL under the code as a fallback? It exposes the invitation to anyone who sees the card. Recommended: no.
4. **Continuing cards.** For contests too long even for a half page, the continuation card is a proposal.
5. **Signature block.** The earlier per-round card requirement had a signature block for pilot and timer; this report has a Timer column and no signature. Confirm none is wanted.
6. **Re-flight.** The earlier requirement had a re-flight column on the card. This report does not. Confirm re-flights are written in a spare row or not at all.
7. **Pre-fill values.** Official only, or also participant submissions? Recommended: official only, with unofficial values marked.
8. **Pilots with no matrix rows.** Do withdrawn or late-added pilots get a card? Recommended: late-added yes, withdrawn no, and the picker says which.
9. **Order of cards.** Alphabetical, by pilot number, or by team? Recommended: alphabetical.
