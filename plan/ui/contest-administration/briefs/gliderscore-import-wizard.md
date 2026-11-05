# Design brief: GliderScore Import Wizard (redesign) — Soar Score contest app

Date: 2026-11-05. For the design tool.

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. The contest administration app can already **import GliderScore data** (GliderScore is the Windows program most directors use today). It works, but it grew in phases and lives in two modal dialogs. I need it redesigned as a proper guided flow that **fits the app's structure**, the way the New Contest Wizard does. Please produce a canvas/prototype with every step, the key states, and the responsive behaviour.

**Users:** contest directors (CDs) moving off GliderScore, mostly on a Windows laptop at home, occasionally at the field. This is also the alpha testers' main way in: they bring finished GliderScore competitions over to check Soar Score against what they know. They know GliderScore's vocabulary (competition, pilot number, class, re-flight, retired) and are suspicious of anything that might lose or alter their data. Trust and clarity matter more than speed.

**Platform:** Flutter, Material 3, **native Windows build only** (reads a local `.mdb` file through a helper; the web build does not have the feature). Use the app's theme tokens and standard M3 components. Must work with large system fonts and text zoom. **Never use colour alone for state**: every status has text plus an icon or shape and an accessible label. Full keyboard access, visible focus, screen-reader announcements. Brand rules: one orange element per area of a screen; no retyped wordmark.

## Where it lives today (and why it's awkward)

- Two entry buttons, both text buttons: **"Import from GliderScore…"** on the Contests page (top-right strip above the list, or under the empty state) and **"Import pilots from GliderScore…"** on the Participants page.
- Each opens a **640 px wide AlertDialog**. The competition import is one dialog that changes content across six steps: choose file → reading → competitions → pilots → confirm → result. The pilots step is an embedded copy of the separate pilot-import review. There is **no step indicator**, no persistent summary, and long lists scroll inside the dialog.
- The file chooser opens automatically when the dialog opens; cancelling closes the dialog.
- Compared with the New Contest Wizard (which takes over the shell's content area with a step list, saved progress, and a footer), the import feels bolted on.

## App structure the redesign must fit

- **Landing page** (`/contest-administration/landing`): no shell, leads to the main page. The import does not start here.
- **Main page = "Contests"** (`/contest-administration/home`): the shell starts here. The shell has a left **navigation rail** (Contests, Participants, Roles, Landings; expands to labels on wide windows), a **header** with title and back/breadcrumb, a content area, and a persistent **status bar** at the bottom (connectivity, sync). Contests and Participants use list + detail that collapses to one pane when narrow.
- **Contest scope** (once a contest is open) swaps the rail to Workspace, Configuration, Participants, Matrix, Scoring, Reports, Publication, Sync. The import is **system scope** (it creates contests), so it belongs outside any one contest.
- **New Contest Wizard** (`/contest-administration/contests/new`) is the pattern to match: it **replaces the content area, rail/header/status bar stay**; wide windows (≥1100 px) show a vertical step list beside the content, narrow ones a row of step markers (28 px indicators: Complete = check, Current = number on filled circle, Needs attention = `!` in a rounded square, Visited = solid outline, Not started = dashed outline); a footer with Back / primary action; leaving with unsaved changes warns only when something is actually unsaved.
- Existing building blocks to reuse: wizard step list/dot stepper/step indicator/footer/section card/banner, master-detail, page-state views (loading, empty, error), status chips.

**Decided by Mike (2026-11-05):** the import is a **routed full-content-area wizard** like New Contest (suggested route: `/contest-administration/contests/import`), not a dialog; the entry point below is approved; the last step is a detailed summary with no open links, and finishing returns to the Contests page. Entry point: an "Import from GliderScore" secondary action on the Contests page next to Create contest, and the same action in the empty state. Participants-page "Import pilots" stays a lighter, pilots-only flow that reuses the same pilot review screen.

## The flow (keep the logic, redesign the presentation)

Steps (show progress and titles; completed steps can be revisited until the import is applied):

1. **Choose file.** Pick a GliderScore database (`.mdb`) with the system file chooser. Show what it is, that the file is only read and never changed, and that nothing leaves the computer. Cancelling the chooser returns quietly to Contests. Include a "no GliderScore reader available on this computer" state.
2. **Reading.** Reading and mapping a large file takes a while. Show progress with the file name and a **Cancel** (cancelling drops the result; nothing has been written).
3. **Competitions.** One row per competition in the file: name, date, GliderScore class, participant count, scored-flight count. States per row:
   - **Importable**: checkbox, **none preselected**. Select all / Select none.
   - **Blocked or skipped**: no checkbox, reason in words (class not imported yet, class unsupported, settings missing/invalid, no date, nobody importable).
   - **Warnings**, expandable: team names generated ("Team 1, Team 2"), retired pilots, re-flights imported as extra groups, motor restarts kept, partly flown rounds, flights imported as zeros, landing values not in the table, other adjusted settings.
   - **Already imported before** (same competition id): "will replace the contest _X_, keeping its place in your list" plus "changed in Soar Score since: N scores entered, importing replaces them"; "file unchanged, nothing will be written"; or **refused** because the contest was synced to the server or its results are published (say what to do, in words).
   - **Number match without an id**: "a contest imported from competition number N exists; is it the same one?" with a switch ("It is the same competition: replace _X_").
   - Per chosen competition with scores: a **"Mark the contest Completed"** choice (ticked by default only when the file shows a finished competition) with the explanation: completed locks rounds and cancels unflown ones; unticked leaves it Running so scoring can continue.
   - Empty state: nothing in the file can be imported. A running "N chosen" count and a disabled Continue until one is chosen.
4. **Pilots.** The pilot review for the pilots the chosen competitions use. Groups: **New** (added), **Already in your list** (updated with new details; names never change; shows which fields), **Maybe the same person** (needs a choice: Skip / Add as new / Update _name_). Notes: test pilots (last name starting ZZ) left out, rows unusable, columns not imported, pilots with no recognised country, truncated read. A conflict row ("email and registration numbers match different people"). Pilots who flew or were drawn must be chosen, or that competition cannot be imported (explain this before it bites). The same screen is reused by the Participants-page pilots-only import.
5. **Review and import.** One summary before anything is written: contests created / replaced / unchanged, participants added and updated, flights, completed count, what is _not_ imported, and a **required confirmation** ("I understand this replaces the contest and discards N scores entered since") when any contest is replaced. Primary action: **Import**.
6. **Importing.** Writing; not cancellable once started. Progress per competition if possible.
7. **Import summary (final step).** A full-page, detailed report of what the import did, richer than the old dialog's list. It is a read-only summary: **no "Open" links or buttons to individual contests** (Mike dislikes them). Content:
   - Headline totals: contests created / replaced / unchanged / refused / failed; participants added, updated, left out; scored flights restored; contests marked Completed.
   - One section per competition with its outcome (**Imported**, **Replaced**, **Unchanged**, **Refused** with reason, **Failed** with reason in words), its contest name, date, class, participant and flight counts, the pilots added or updated, notes about participants left out, the warnings that applied (adjusted settings, team names generated, re-flights as extra groups, retirements, zeros), and the result of the comparison against GliderScore.
   - Failures: if one fails after others committed, say the others stay. Reasons include: no account to own the contest; no scoring rules for the class; settings invalid; a chosen pilot no longer in the list; drawn pilots not chosen (with GliderScore pilot numbers); and the **comparison gate** (scores did not match GliderScore for flight X; nothing of that competition is kept; list the mismatching flights).
   - What was not imported, stated plainly.
   - One primary action, **Finish**, which **returns to the Contests (contest selection) page**. No other navigation out of the summary. Leaving the summary needs no confirmation.

Also design: a whole-file failure (can't read it, wrong file type), and the "your participants changed while you were reviewing, review again" interruption on step 4 to 6.

## Behaviour and content rules

- Plain language. Users say "competition" for what is in GliderScore and "contest" for what Soar Score creates; keep that distinction and explain it once.
- An import is a **point-in-time restore**: whole or nothing for each competition, never half. Say so where it helps trust.
- Importing again replaces the earlier import in place; the contest id and list position are kept.
- Local-only: nothing is sent anywhere until the director syncs or publishes.
- Not imported: say plainly what GliderScore holds that Soar Score does not (draw seeds, team names, some columns).
- Breaking the flow mid-way (leaving the route) before step 6 loses nothing on disk; ask only if there is a chosen selection worth keeping, not for every navigation.
- All strings go through ARB localisation; design for text 40% longer than English.
- Dense lists (competitions, pilots) need a responsive fallback: stacked rows when narrow, a sticky summary/action bar when the list is long.

## States to show

Choose file (reader missing, cancelled). Reading (long, cancellable). Competitions: mixed list of importable / blocked / already imported / refused-synced / refused-published; all blocked; none chosen; many warnings; a very long list (20+ competitions). Pilots: new / update / maybe / conflict / nothing new / truncated. Review: replacing with discarded scores, nothing to import. Summary: all succeeded, mixed success and failure, comparison-gate failure with flight list. Plus: wide (≥1100 px) with step list, medium, narrow with dot stepper, large text, dark theme.

## Deliverables

1. Screens for every step and state above, wide and narrow.
2. A recommendation on entry points and on the shell integration, with your reasoning.
3. A short rationale, including what you reused from the New Contest Wizard and what is new.
4. Component notes mapping to existing widgets, so engineering can build it from the existing step list, footer and section card without new bespoke widgets where possible.

## Out of scope

The server-side/hosted importer (later), other disciplines beyond what the importer already allows, delete-contest, changes to what gets imported or how scores are verified, the pilot-review logic itself.

## References (in the repo)

- Current code: `apps/soar_score_contest/lib/widgets/competition_import/competition_import_dialog.dart`, `.../services/competition_import/competition_import.dart` (controller and step enum), `.../widgets/pilot_import/pilot_import_dialog.dart`, entry buttons in `pages/home_page.dart` and `pages/participants_page.dart`.
- Strings: `competitionImport*` and `pilotImport*` in `l10n/app_en.arb`.
- Docs: `docs/import-competitions-from-gliderscore.md`, `docs/import-pilots-from-gliderscore.md`.
- Pattern to match: `plan/ui/contest-administration/briefs/new-contest-wizard.md`, `main-page.md`, and `apps/soar_score_contest/lib/widgets/new_contest/`.
- History: `plans/phase-b-b4-wizard-plan-2026-11-04.md`, `plans/gliderscore-import-implementation-plan-2026-11-01.md` (#571 noted "no design yet"; this wizard was built without a design canvas).
