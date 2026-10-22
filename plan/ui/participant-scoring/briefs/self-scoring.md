# Design brief: Participant self-scoring app — Soar Score

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. The **self-scoring app** is where pilots, and helpers on their team, look up where and when they fly and enter their own scores from a phone at the flying field. I need a design for the landing page, the invitation handler, the contests list, the helper's team overview, the pilot overview, the score entry and review pages (F5J first), and the results page.

The pages exist today only as placeholders. The job of this pass is the **layout and interaction design**, not new behaviour. Every rule below that says "see spec" is settled; design to it, do not redesign it. When a brief and a requirement document disagree, the requirement document wins.

**Users:**

- **Pilots at the field**, on a **phone**, outdoors in bright sun, between flights, one hand, a weak signal, often hurried. They need "when and where do I fly?" and a score form that is hard to get wrong.
- **Helpers** (timers, callers, team managers) on a phone. They watch several pilots on their team and enter scores for them. They need to see quickly who flies next.
- Both are often **not signed in**. They arrive by a link in an email or a QR code at the field.

This is a phone design. Tablet and desktop layouts are very low priority and need no separate design; the page must simply stay usable at wider widths.

**Platform and visual language:**

- Flutter web, **Material 3**, using the theme tokens in `packages/soar_score_ui`. The brand comes from the public site design; do not invent a separate one.
- The first release is mobile web. Native apps are a later goal, so avoid patterns that only work in a browser.
- Large touch targets, high contrast, and readable text in sunlight. Participant forms never need horizontal scrolling.
- **Never use colour alone for state.** Every status has text or an icon as well as colour.
- Full keyboard access, visible focus, and sensible screen-reader order in tables.
- Light and dark themes both ship; follow the system setting.

## Pages

Specs: [`../participant-scoring.md`](../participant-scoring.md) and [`../../../business-requirements/contest-self-scoring.md`](../../../business-requirements/contest-self-scoring.md).

### Landing page

Route `/`. The logo is plainly visible. One sentence says this is the self-scoring app. Two buttons, **Sign in** and **Sign up**, go to the identity provider. A line for someone who lost their link says to ask the contest director to send it again. No logo exists yet; leave a clear slot.

### Invitation handler

Route `/invitations/{credential}`. After the link is validated, name the participant and contest so the person can see the link is theirs, then offer **Continue as a guest**, **Sign in**, and **Create an account**. After signing in, ask "Continue as Jane Smith (pilot 12)?" once. Design the invalid-link state: it is the same message for unknown, expired, and replaced links, and tells the person to ask the contest director.

### Contests

Route `/contests`. Usually one contest. A row shows the contest name, a state (Invited, In progress, Completed), and the next round when there is one. Design the empty state ("open the link your director sent you"), and the "Is this you?" card for an email match that needs confirming.

### Team overview (helpers)

Route `/contests/{id}/team`. This is a helper's home page.

- The team name, then a list of the team's pilots. Each row shows name, pilot number, the round, group, and lane of the next flight, and one indicator when it applies: **Up now**, **Up next**, or **Just flown** (with a prompt to enter the score). Retired pilots are marked and have no indicator.
- A standings table of all teams, with the helper's team highlighted.
- A line explaining that the indicators are based on entered scores.
- Selecting a pilot opens the pilot's overview.

Show it with six pilots: one Up now, one Up next, one Just flown, one retired, and two with nothing. The Up now indicator must be unmistakable at a glance in sunlight and must not rely on colour.

### Pilot overview

Route `/contests/{id}/pilots/{pilotId}`. Contest and participant name, pilot number when enabled, scoring-access state, and a table with one row per round (round, group, lane when assigned, task type for F3K). Only the first unscored round shows **Enter**; rounds with scores show **View**; later rounds show nothing, and retired participants see future rounds as locked. A helper also sees **Back to pilots**.

The page holds three more things: a control to copy or share the invitation link, a **Retire** button with a confirmation (naming the pilot when a helper retires one), and a link to the current results. Show it with eight rounds, and in the retired state.

### Score entry and review (F5J first)

Route `/contests/{id}/pilots/{pilotId}/rounds/{roundId}`. Specs for the fields and rules are in `../../../business-requirements/disciplines/f5j.md`.

- Fields: time flown, launch height, landing (from the contest's landing table), late landing, motor restart (shown only when the contest allows it), out of bounds, no altitude recorded, and **Flight Penalty**. The cumulative penalty is shown read-only after the director applies it and is never entered here.
- Rules to show: time cannot exceed the working time; late landing removes the landing bonus; out of bounds, motor restart, and no altitude recorded disable and zero the other fields; a result that would be zero asks for confirmation first.
- After submission the form is read-only and says who entered it (the pilot or the helper by name), when, and the status.
- If someone else submits first, show the accepted score with **Request review**.
- **Request review** opens the form prefilled; Submit is off until a value changes; there is an optional explanation. After submission, modified fields are marked and the page shows the pending review. If a review is already pending, show the pending state instead of the form. Hide it when the score is Official or locked.
- Under the score: the group's results (pilot, values, raw score, round score, pending-review markers) and the participant's placement with three pilots above and below, with estimates labeled.
- Previous, next, and back navigation.

Design the group results table so it reads on a phone without horizontal scrolling.

### Results

Route `/contests/{id}/results`. Individual overall results showing only the group score for each pilot, and the team standings when teams are enabled. A link to the public site when the results are public. Mark results preliminary. Design how the two sections share the page on a phone.

### States for every page

Loading, unavailable network, invalid link, closed scoring, rejected submission, and retry. A score that is queued on the device must look clearly different from one the server has accepted. A rejected submission explains what to do next.

## Deliverables

1. **Foundations:** any additions to the M3 tokens, and the status vocabulary (Up now, Up next, Just flown, retired, preliminary, estimate, pending review, queued, accepted, rejected), each with an icon and text.
2. **Landing, handler, and contests pages** at phone width, light and dark, including the invalid-link, empty, and "Is this you?" states.
3. **Team overview** at phone width with the six-pilot example.
4. **Pilot overview** with eight rounds, and retired.
5. **F5J entry:** empty, filled, the zero-score confirmation, the read-only submitted view, the "someone else submitted first" view, and the review request form.
6. **Results** at phone width with and without team standings.
7. A short rationale: how the group results table and the placement table fit a phone, and how colour independence is achieved for each status.
8. Any questions or spec ambiguities you hit. List them; do not silently resolve them.

Light theme first. Prove that dark mode holds on at least the team overview and the F5J entry form.
