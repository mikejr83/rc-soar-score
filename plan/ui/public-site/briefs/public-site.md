# Design brief: Public site (shell, homepage, contest search and results) — Soar Score

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. The **public site** is the part anyone can open without an account: it tells people what Soar Score is, lets them find a contest, and shows published results. I need a design for the site **shell**, the **homepage**, the **contest search** page and the **contest results** pages (overall, team and flight-group views), plus the shared not-found and not-visible states. The docs and support pages reuse the shell and need only a content layout, not a bespoke design.

All of these pages exist today as unstyled Material placeholders built straight from the specs. The job of this pass is the **brand and the layout**, not new behaviour. Every rule below that says "see spec" is settled and already implemented; design to it, do not redesign it.

**Users:**

- **Pilots and their families at the field**, on a **phone**, outdoors in bright sun, between flights, checking "where am I after round 4?" and "who is in my group next?". Sunglasses, one hand, a weak mobile signal.
- **Pilots, club officers and the curious at home**, on a desktop or tablet, browsing recent contests and reading full standings.
- **Contest directors** who want a page they can link from a club forum and trust to look credible.

Phone and desktop matter equally. Results tables are the hard part: they must be scannable on a phone without turning into a wall of tiny text.

**Platform and visual language:**

- Flutter web, **Material 3**. Use standard M3 components and theme tokens; any custom value must work as a theme token in `packages/soar_score_ui` (shared by the public site, the contest administration app and the participant self-scoring app, so the public site's brand becomes the suite's brand).
- Current theme (a placeholder nobody chose deliberately; you may propose changes): seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2. Light and dark themes both exist and both ship; the site follows the system setting.
- **No logo or wordmark exists.** Logo sketches are being explored separately and the product owner will pick one. Leave a clear slot for a logo in the header and on the homepage, and propose how the wordmark and logo sit together at phone and desktop widths. The product name is "RC Soar Score" for now.
- Standard M3 window size classes (compact under 600dp, medium 600 to 839dp, expanded 840dp and up), no custom breakpoints.
- **Never use colour alone for state.** In progress versus completed, tie indicators, dropped rounds, re-flights and penalties each need text or an icon as well as colour. Full keyboard access, visible focus, and sensible screen-reader order in tables.
- Large touch targets and high contrast; the field user is in sunlight.

## The shell

A header, a page body and a footer shared by every page (`apps/soar_score_web/src/components/site-header.tsx` and `site-footer.tsx`; this brief predates the Next.js port, ADR 0005).

- **Header:** logo slot, wordmark, and the navigation: Home, Contests, Docs, Help, and a **Login** entry that links out to the contest administration app (the public site has no sign-in of its own). On compact widths the navigation collapses; propose the pattern (bottom bar, drawer or menu) and say why. Contests is the entry people use most; it should be reachable in one tap on a phone.
- **Footer:** small, with links to Docs, Support and the contest administration app, and room for a copyright line.
- **Page body:** a content column with a sensible max width on expanded screens, full-bleed tables where a table needs the room.
- The site-wide **not-found page** (unknown route) lives in the shell: say what happened, offer Home, Contests and Docs.

## Homepage

Route `/`. Spec: `../homepage.md`.

- Says what Soar Score is in a sentence or two, for someone who has never heard of it.
- Three calls to action: **Contests** (find results, primary), **Documentation / Help**, and **Login / Registration** (links out to the contest administration app).
- Room for a short "recent contests" strip or count (the search page already computes "contests in the last 30 days"); optional, say whether you would include it.
- This is the one page where the brand can be expressive: imagery or illustration of soaring is welcome if it stays fast to load and works in dark mode.

## Contest search

Route `/results/contests`. Spec: `../contest-search.md`. Implemented in `pages/results/results_page.dart`.

- A list of the **10 most recent** in-progress or completed contests, newest start date first: start date, name, venue, and an **In progress** or **Completed** indicator.
- A **summary** line: how many contests were completed or in progress in the last 30 days.
- **Filters:** name, venue, start-date range. The filters are deep-linked as query parameters; when any filter is set the list shows all matches, not just 10. Design the filter area so it is out of the way on a phone (collapsed by default) and inline on desktop.
- A **Refresh** action that reloads the list in place.
- **States:** loading, empty (no contests match; and no contests at all), load failed with retry.
- Tapping a row opens the contest.

## Contest results

Routes under `/results/contests/:contestId`. Spec: `../view-contest.md`. Implemented in `pages/results/contest_page.dart` and `widgets/results/`.

All three views share a **contest header** (name, dates, venue, In progress or Completed) and a **round selector** (first, previous, dropdown, next, last) that applies to every view. The selected round is in the URL, so each view is "the standings as of round N". Design the header and selector once; they must stay compact on a phone because the table is the point of the page.

### Overall individual results (default view)

One row per pilot: place, name, country, score, percentage of the winning score, raw score, one column per round up to the selected round, cumulative penalty. Rules to show:

- **Tied places** share a place number with a tie indicator.
- **Dropped rounds** are visibly marked in the round column (the drop rules differ per discipline; the design only needs a marker).
- Round headers and round scores are **links** to that round's flight groups; a clicked pilot's score is scrolled into view there.
- Navigation to the **Team results** view and to the **current round's flight groups**.

On a phone this table is the hardest layout on the site. Propose how it reads at compact width: which columns pin, which scroll, whether round columns collapse into a per-pilot detail. Show it with eight rounds.

### Team results

Team place, team, team score, percentage, then each team's pilots with score, raw score, round columns and penalty. A contest with no teams never shows this view (it redirects to overall results), so no empty state is needed. A link back to overall results.

### Flight group scores

For the selected round: one table per flight group, headed by the group number and, when it applies, a **re-flight** label. Columns: name, country, time, landing score (only for disciplines that have one), discipline-specific details, points, score, penalty. A link back to overall results and to team results. Design the group heading so a pilot can find their group fast on a phone when a round has ten groups.

### Not found and not visible

Both render in place of the contest page without changing the URL.

- **Contest not found** (unknown id or delisted): spec `../contest-not-found.md`. Explain the three likely reasons, offer Contests and Home.
- **Contest not visible** (results pending or marked private): this exact copy, then a note that the page re-checks every 15 minutes and a manual check button:

  > This contest has pending results or has been marked private. It is not shown at this time. The contest will be shown after the final placing is announced and the contest director makes the results public or 48hrs after the last score entered.

### Loading and failure

Contest loading (skeleton, not a spinner, so the header area does not jump) and load failed with retry.

## Docs and support (layout only)

Routes `/docs`, `/docs/*`, `/help` and `/support`. Specs: `../docs-help.md`, `../support.md`. These are long-form pages: a heading, prose, sub-navigation between the help topics, and on the support page a plain form (name, email, user type, request type, message, captcha, thank-you state). Provide the reading layout (measure, headings, link style, the docs sub-navigation on phone and desktop) and a form layout. No bespoke design per page.

## Deliverables

1. **Brand foundation:** the palette as M3 tokens (light and dark) with usage rules, a type scale, spacing and radius, and the status vocabulary (in progress, completed, tie, dropped round, re-flight, penalty) with icon plus text for each. If you change the current palette, say what and why. A logo slot and wordmark lockup at phone and desktop widths, ready for whichever logo the product owner picks.
2. **Shell:** header and footer at compact (~400px), medium (~700px) and expanded (~1280px), light and dark; the collapsed navigation pattern; the site not-found page.
3. **Homepage** at compact and expanded, light and dark.
4. **Contest search** at compact and expanded: default list, filters open, a filtered result, the empty and failed states.
5. **Contest results:** the header and round selector; overall results with eight rounds at compact and expanded, including a tie and a dropped round; team results at expanded; flight group scores at compact with a re-flight group; not found; not visible; loading and failed.
6. **Docs and support** reading layout and the support form at compact and expanded.
7. A short rationale: how the results table works on a phone, how colour independence is achieved for each status, and any token or component additions to the M3 theme.
8. Any questions or spec ambiguities you hit. List them; do not silently resolve them.

Light theme first. Every page ships in dark mode too, so prove the tokens hold on at least the homepage and the overall results table.
