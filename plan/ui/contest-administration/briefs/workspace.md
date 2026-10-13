# Design brief: Contest Workspace — Soar Score (Contest Administration app)

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. I need a design for the **Contest Workspace**, the first page a contest director sees after opening a contest. Please produce a canvas/prototype with the page layout for each lifecycle stage, the state controls and their dialogs, the progress view, and the responsive behaviour.

**The problem to solve:** today the workspace shows a card with the contest's dates, timezone, host, and location, and then a list of buttons (Configuration, Participants, Matrix, Scoring, Reports) that repeat the navigation rail. It tells the director nothing they couldn't see in the rail. The workspace should be the contest's **home**: what this contest is, where it stands, what to do next, and the controls that change its state. Do not mirror the rail. Link to other pages **in context** (for example "4 pilots missing scores in round 3" links to Scoring at that round), not as a menu.

**Users:** contest directors (CDs). Before the event they work at home on a laptop or tablet, setting up and checking readiness. On contest day they're at the flying field on a tablet, often outdoors in bright sun, sometimes offline, glancing at the workspace between rounds to answer "Are we on track? Who hasn't scored? Can I start the next round?" They are busy and interrupted; the page has to be readable in a few seconds.

**Platform and visual language:**

- Flutter, **Material 3**. Use standard M3 components and theme tokens; don't invent bespoke widgets unless needed. Any custom value should work as a theme token.
- Current theme: seed/primary `#006399` (deep sky blue), secondary `#2D6A4F` (field green), tertiary `#D97706` (high-viz amber, used for timers and highlights), light surface `#F8FAFC`, 12px corner radius on cards, card elevation 2, centered app-bar titles. Dark theme exists too.
- Target is **tablet and larger** (admin). It must still work with browser text zoom and large system fonts.
- **Never use colour alone for state.** Every status has text plus an icon or shape plus an accessible label. Full keyboard access, visible focus, and screen-reader announcements.

**Existing app shell (the page lives inside it):**

- A persistent shell with a contest-scoped navigation rail on the left (expandable to labels on wide windows). Once a contest is open the rail lists: **Workspace** (this page), Configuration, Matrix, Scoring, Reports. Participants and Publication pages for the contest are planned. The page is at `/contest-administration/contests/:id/workspace`.
- A slim header naming the page, with the **contest name** and breadcrumbs or back navigation to the contest list.
- A **shell status panel** under the header on every contest page: a read-only summary of the contest's lifecycle, participant scoring, and administration lock. **Keep it read-only.** The workspace is where those values change; design how a status-panel value links to its control on the workspace (for example, it scrolls to and focuses that control). Don't repeat the same summary strip on the workspace; show each value beside its control instead.
- A content area with **one clear primary action per page state**.
- A persistent **status bar at the bottom** showing connectivity, sync state, and so on.

## Contest state model (must be respected exactly)

These are **separate values**. Never merge them into one status or infer one from another.

| Value               | Values                                                     | Notes                                                                                                                                                                                                                                                                 |
| ------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Lifecycle           | Created, Configuring, Ready, Running, Completed            | Created: details only. Configuring: configuration saved. Ready: valid matrix, no score yet (falls back to Configuring if a change invalidates the matrix). Running: first score accepted. Completed: closed by the director (suggested after 48 hours without scores) |
| Participant scoring | Open, Closed                                               | Whether pilots and helpers can enter their own scores. Independent of lifecycle, but Completed closes it                                                                                                                                                              |
| Administration      | Unlocked, Locked                                           | Locked blocks every configuration, participant, and matrix change                                                                                                                                                                                                     |
| Publication         | Unpublished, Published                                     | Publishing copies the contest to the public site. A published contest keeps updating according to the public update policy                                                                                                                                            |
| Visibility          | Unlisted, Public (Delisted after an approved request)      | Only once published. First publish is Unlisted                                                                                                                                                                                                                        |
| Overall results     | Shown, Hidden (through round N, expires 24 hours after on) | Hides overall scores and placing on the public site and participant views. Ends when turned off, when the contest completes, or after 24 hours                                                                                                                        |
| Local archive       | Archived, Not archived                                     | Local to this installation; never deletes data                                                                                                                                                                                                                        |

## What the page contains

Decide the layout and hierarchy, and explain it. Expect it to change emphasis by lifecycle: before the draw the page is about **getting ready**; on contest day it's about **progress**; after completion it's about **results and publication**.

### 1. Next step (the primary action)

A single, prominent "what to do next" with one primary button, driven by the lifecycle and readiness. Design each:

- **Created:** "Finish the configuration" → Configuration.
- **Configuring, not ready:** show what's missing → the page that fixes it. Examples: "Add at least 2 scoring pilots", "Configuration is incomplete: working time is missing".
- **Configuring, ready to draw:** "Draw the matrix" → Matrix page (the draw happens there).
- **Ready (matrix drawn, no scores):** "Open participant scoring" or "Enter scores for round 1, group A" → Scoring, depending on participant scoring access: "Open participant scoring" while it is closed, "Enter scores for round 1, group A" once it is open. There is no self-scoring setting in the configuration (decision #366), so do not branch on one.
- **Running:** "Continue scoring: round 3, group B" → Scoring at the latest relevant round and group. In **Seeded** mode, when all scores for the drawn rounds are in and verified: "Draw round 5" → Matrix.
- **Running, looks finished** (every round with any score has all scores, or 48 hours without a score): "Complete the contest" with the reason it's suggested. This is a suggestion; the director decides.
- **Completed:** "Publish results" if unpublished, else "View reports".

### 2. Readiness checklist (before the contest runs)

A short checklist that shows each requirement as done, not done, or warning, with text and an icon, each linking to where it's fixed:

- Configuration saved and valid (and the configuration revision).
- Discipline and landing table chosen.
- At least two scoring pilots (show the count; teams and classes when enabled).
- Matrix drawn (revision, rounds, groups, group sizes) and whether the configuration has changed since the draw ("Matrix drawn with lanes off; lanes are now Random").
- Optional items, clearly marked optional: participant numbers assigned, publication, scoring access opened.

Collapse or hide it once the contest is running; say which.

### 3. Progress (contest day)

Design this fully from the requirements even though scoring isn't built yet; the implementation will stub it until the data exists. Show the pre-draw and "no scores yet" states as well.

- **Where we are:** latest round and group with accepted scores, and the matrix size ("Round 3 of 8, group B of 4"). In Seeded mode: preliminary rounds complete or not, and intended total rounds ("Round 4 of 8 planned").
- **Round progress:** for each round, scored / not flown / in progress, with counts of pilots scored. A compact per-round strip or list; it must stay readable for 10 rounds.
- **Needs attention:** pilots missing scores in flown rounds (count, with a link to the list), **open score-review requests**, and **sync conflicts or rejected changes**. Each item has a count, a plain explanation, and a link to resolve it. Show the "nothing needs attention" state.
- Pilots lagging is normal (people forget to enter scores after their group). Don't make a lagging pilot look like an error; distinguish "missing in a finished round" from "not yet entered in the current round".

### 4. Contest controls (state actions)

The controls that change the contest's state. Each shows its **current value**, the **action**, and, when disabled, the **reason beside it**. Design one pattern for all of them.

- **Participant scoring:** Open / Close. Closing stops pilots and helpers from entering scores; the director can still enter them.
- **Administration lock:** Lock / Unlock, with a confirmation that lists what becomes blocked (configuration, participants, matrix changes).
- **Hide overall results:** turn on (shows "hidden through round N, ends at <time>"), turn off. Explain the 24-hour expiry in plain words. Show the countdown state.
- **Complete contest:** only when running. The confirmation shows missing scores and unflown rounds, and says completion closes participant scoring and ends result hiding. Authorized score corrections remain possible after completion.
- **Publication:** Unpublished: "Publish". Published: last published time, visibility (Unlisted or Public) with a way to change it, the public update policy (from configuration, read-only here with a link), and "Request delisting". Publishing is a separate flow (it checks participants against the global list); the workspace starts it and shows its result. Design the entry point and result, not the whole flow.
- **Archive locally:** Archive / Unarchive, with a note that it doesn't delete anything and isn't synced. Keep it low in the hierarchy.

**Every transition** shows the current value, the requested value, the affected scope, and the result. Use a confirmation dialog only for destructive or multi-step actions (lock, complete, publish, delist). Simple toggles (open/close scoring, hide results) take effect directly with a snackbar and undo where safe. Say which you chose for each.

**Failure:** a stale revision or a rejected transition leaves the page unchanged and shows why, with retry or refresh. Show one example (for example "Someone else locked this contest. Refresh to see the current state.").

**Offline:** some actions need the server (publish, visibility, delisting). Show them disabled with "Needs a connection" when offline; local actions still work.

### 5. Contest facts

Compact reference information, quiet in the hierarchy:

- Dates, timezone, host/venue, location.
- Discipline (with "house rules" marker if any discipline option differs from the official profile, linking to Configuration).
- Participants: scoring pilots, other participants, teams, classes when enabled.
- Matrix: revision, rounds, groups per round, lanes on or off.
- Configuration revision and when it was last saved.

### 6. Recent activity

The last few audit events (who did what, when): configuration saved, matrix drawn, scoring opened, scores corrected, published. A "View all" link (the audit view is a later page; leave the link and say where it would go). Show an empty state for a new contest.

## Lifecycle variations to show

Show the whole page for each of these, so the change in emphasis is visible:

1. **Created** (just made in the wizard; nothing configured).
2. **Configuring, not ready** (one pilot, configuration valid).
3. **Ready** (matrix drawn, scoring closed, unpublished).
4. **Running** mid-contest (round 3 of 8; scoring open; 4 pilots missing scores; 1 open review request; published, Public; results hidden through round 3).
5. **Running, Seeded**, between rounds (all scores in; "Draw round 5").
6. **Completed** (read-only except score corrections and publication; unpublished, so "Publish results" is the next step).
7. **Locked** (administration locked while running; show which controls are disabled and why).

## States

Loading; contest not found (bad link); unavailable (remote API unreachable; show what's still known locally); load failed with retry; offline (server-only actions disabled); transition in progress (control busy, repeated tap ignored); transition rejected; conflict.

## Deliverables

1. **Page layout** inside the shell on tablet landscape (~1280px, rail expanded) for each lifecycle variation above, and the Running page on narrow (~800px).
2. **Next step** variants for each lifecycle stage, including the "looks finished" suggestion.
3. **Readiness checklist** with mixed done, missing, and warning items.
4. **Progress:** round strip for 3 and 10 rounds; needs-attention list with items and empty.
5. **Contest controls:** the shared control pattern; each control in its states (enabled, disabled with reason, busy); the confirmation dialogs (lock, complete, publish, delist); result hiding with countdown; offline.
6. **Status panel link:** how a value in the shell status panel takes the director to its control.
7. **Failure states:** rejected transition; stale revision; loading; unavailable.
8. A short rationale covering the layout and how it shifts by lifecycle, how you avoided duplicating the rail and the status panel, where you used progressive disclosure, and any component or token additions to the M3 theme.
9. Any questions or spec ambiguities you hit. List them; don't silently resolve them. Known one: the UI README lists visibility as Private, Hidden, or Public, while the business requirements and data model use Unlisted, Public, and Delisted. This brief uses the data model's terms.

Light theme first. Show one dark-theme screen (the Running page) to prove the tokens hold up.
