# Design brief: Participant self-scoring app — Soar Score

## What you're designing

Soar Score is a scoring and management suite for RC sailplane (glider) soaring contests. The **self-scoring app** is where pilots, and the helpers on their team, look up where and when they fly and enter their own scores from a phone at the flying field. I need a design for the **landing page, invitation handler, contests list, helper team overview, pilot overview, score entry and review, and results**, with every state a person can land in at the field.

The pages exist today only as placeholders. The job of this pass is the **layout and interaction design**, not new behaviour. Every rule below that says "see spec" is settled and will be built as written; design to it, do not redesign it. When this brief and a requirement document disagree, the requirement document wins.

This is the **first version, for F5J**. Design the entry form so that other duration disciplines (F3J, ALES, Thermal Duration) change only the fields, not the page (see "Discipline fields"). F3K, which also shows a task type per round, and other disciplines' forms are follow-ups. Do not design them.

**Out of scope** (do not design, leave room where noted): the contest director's screens (the administration app has its own briefs), account settings and profile management, the public results site, notifications, and anything for tablet or desktop beyond keeping the layout usable.

**Users:**

- **Pilots at the field**, on a **phone**, outdoors in bright sun, between flights, one hand, a weak mobile signal, often hurried and interrupted. They need "when and where do I fly?" and a score form that is hard to get wrong. They answer quickly: "Is it my turn?", "Did my score go in?", "Where do I stand?"
- **Helpers** (timers, callers, team managers) on a phone. They watch several pilots on their team and enter scores for them. They need to see at a glance who flies next.
- Most people arrive by a **link in an email or a QR code at the field**, without an account. Some have an account and open the app from the home screen.

**Platform and visual language:**

- Flutter web, **Material 3**, using the shared theme in `packages/soar_score_ui`. Use standard M3 components and theme tokens. The three Soar Score apps share one theme, so do not fork the palette for this app.
- **Follow the RC Soar Score brand guide** (the design system at https://claude.ai/artifact/UDyXKKtdQexRQb8zsxznhK). Its tokens and rules are settled; design with them and do not invent colours. The parts that matter here:
  - **Colour:** page ground `surface`; cards, tables and the app bar on `surface-raised`; table header rows and skeleton blocks on `surface-sunken`; text `ink`, secondary text `ink-muted`, rules `hairline`. Brand orange is `brand` (#e8420c) for graphics, progress fills and headings of 24px and up, never for small text. Anything with a label on it (primary buttons, the selected round, the In progress chip) uses `brand-deep` with `on-brand` text. Orange links and small orange labels use `brand-text`. **Use one orange fill per screen region**: orange is the pie on the dial and should feel rare.
  - **Type:** League Spartan (700 and 800) for headings, Archivo for everything else including every score, and Saira Stencil One as a rare accent: one number or short word per screen at most, for example a pilot's place. Scores, places, percentages and times use the `numeric` style: tabular figures, right-aligned. Use `numeric-lg` for a pilot's own score on a phone.
  - **Shape and space:** gutters `space-4` on compact; cards pad `space-4`, with `radius-lg` corners and `shadow-card`; buttons, fields and chips at least 44px high with `radius-md` (chips `radius-pill`); the app bar is flat with a hairline (`shadow-header`).
  - **Icons:** Material Symbols Outlined, weight 400, filled only for the selected navigation item. No emoji, no second icon set.
  - **Focus:** a 2px `focus` ring offset 2px on every control, in both themes.
  - **Themes:** light and dark both ship, and every screen ships in both; the dark theme follows the system setting. The logo's own colours (`logo-bezel`, `logo-face`, `logo-light`) are for the mark and illustrations, not for UI.
- **Phone first.** The first release is mobile web, viewed almost always on a phone; native apps come later. Design at ~400px wide. Standard M3 window size classes apply (compact under 600dp, medium 600 to 839dp, expanded 840dp and up) with no custom breakpoints; tablet and desktop only need to stay usable and need no separate design. Forms never need horizontal scrolling. Everything works with browser text zoom and large system fonts.
- **Never use colour alone for state.** Every status has text plus an icon or shape plus an accessible label. The brand guide's status chips carry all three (colour, Material Symbols icon and word), and rows never change ground colour by state; the chip or cell marker carries it. Full keyboard access, visible focus, and screen-reader announcements.
- Touch targets at least 44px (the brand minimum), and larger on the entry form where a gloved or hurried thumb is likely; high contrast; this is a sunlight screen. Avoid hover-only affordances.
- **The logo is locked.** Use the supplied files and never recolour, rotate, add effects to, or retype it:
  - **Landing page:** the full lockup (mark, wordmark, and the tagline "RC GLIDER CONTEST SCORING"), at least 360px wide, with clear space of at least half the mark's height. Use the light file on light grounds and the dark file on dark grounds.
  - **App bar:** on compact widths, the mark alone at 32px. The wordmark appears only from expanded widths.
  - **Small sizes:** the full mark from 64px, `mark-small` from 32 to 63px, `mark-tiny` below 32px.
  - **App icon:** the supplied 1024px app icon.

**App chrome:** there is no shell today. Propose one that suits a phone: a top app bar (the mark at 32px, contest name, page title, back), where the account state lives (signed in with a name, or "Guest"), and how a person moves between the pages they use most (team overview or pilot overview, results). Say whether you would use a bottom bar, tabs, or plain links, and why. Keep it quiet; the form and tables are the point. Design a persistent, unobtrusive **connection indicator** (online, offline, scores waiting to send).

**Voice and copy:** write for a pilot standing at the field with a phone in one hand. Short sentences, plain words, the number first: "You are 3rd after round 4." Say "you" for the reader and "the contest director", never "the user". Use the words the FAI rules use (contests, rounds, groups, pilots, teams, re-flights, penalties), and keep round numbers and group letters as the director set them ("Round 4", "Group B"). Sentence case for headings, buttons and chips. No exclamation marks, no emoji, no "Oops". An error says what happened and what to do: "Your score could not be sent. It is saved on this phone. Check your connection and try again." Dates as "Sat 11 Oct 2026". Use real copy in every design, not lorem ipsum.

## Page behaviour

Specs: [`../participant-scoring.md`](../participant-scoring.md) and [`../../../business-requirements/contest-self-scoring.md`](../../../business-requirements/contest-self-scoring.md). Routes are shown so you know how the pages relate.

### Landing page

Route `/`. The full logo lockup, one sentence saying this is the self-scoring app for RC Soar Score, and two buttons, **Sign in** and **Sign up**, which go to the identity provider and come back. Sign in is the one orange primary button; Sign up is secondary. A short line for someone who lost their link: "Ask your contest director to send your link again." This is a small page; do not pad it.

### Invitation handler

Route `/invitations/{credential}`. The person reaches it from an email or a QR code and has no account.

- The page checks the link, then names the participant and the contest (for example "Jane Smith, pilot 12, Spring Open") so the person can see the link is theirs. Offer three choices, with the guest option as easy as the others: **Continue as a guest**, **Sign in**, **Create an account**.
- After signing in, ask once "Continue as Jane Smith (pilot 12)?" with a clear **Yes, that's me** and a way to say it is not. A person who already linked their account is not asked.
- **Invalid link:** the same message for a link that is unknown, expired, or replaced. It does not say which, and it tells the person to ask the contest director for their link. Design this state well; a person standing at the field with a dead link is stressed.
- Loading and failed-to-reach-server states.

### Contests

Route `/contests`. For signed-in accounts. Almost always one contest.

- A row per contest: name, dates, a state with icon and text (**Invited**, **In progress**, **Completed**), and the participant's next round when there is one. Selecting a row opens the contest.
- **Empty state:** "Open the link your contest director sent you." It must not read as an error.
- **"Is this you?" card:** when the account's verified email matches a participant (for example "Jane Smith in Spring Open"), ask the person to confirm. Show the card above the list, with **Yes, that's me** and **Not me**.
- Completed contests stay readable. When their results are public, a link opens them on the public site.

### Team overview (helpers)

Route `/contests/{id}/team`. A helper's home page. It exists only when the contest has teams. Pilots never see it.

- The team name, then a list of the team's pilots. Each row shows name, pilot number when enabled, and the round, group, and lane (when assigned) of the pilot's **next** flight, plus one indicator when it applies:
  - **Up now**: the pilot is in the group flying or about to fly. This must be unmistakable at a glance, in sunlight, without colour.
  - **Up next**: the pilot is in the next group that has a team pilot.
  - **Just flown**: the pilot is in the group that has just flown and has not entered a score. Include a prompt to enter it ("Enter score").
  - **Retired**: no indicator, and the row looks inactive.
- Under the list, a line that says the indicators are based on entered scores, so they can trail what is happening on the field. Make this readable, not hidden in fine print.
- **Standings of all teams**, with the helper's own team highlighted (text or icon as well as colour): place, team, and team score.
- A message when no further flight is drawn for the team ("Round 5 has not been drawn yet").
- Selecting a pilot opens that pilot's overview.

Show it with six pilots: one Up now, one Up next, one Just flown, one retired, and two with no indicator.

### Pilot overview

Route `/contests/{id}/pilots/{pilotId}`. A pilot's home page, and the page a helper reaches from the team overview (with a **Back to pilots** link). It works the same either way, as if the pilot were using it.

- Contest and participant name, pilot number when enabled, and the **scoring-access state** (open or closed) with text and icon.
- A table with a row per round: round, group, lane when assigned. Only the first round without a score shows **Enter**. Rounds with a score show **View**. Later rounds show neither, and say why when selected. For a retired participant, future rounds read as locked and counted as zero.
- A control to **copy or share the invitation link** so the person can find their way back. It confirms that the link was copied.
- A **Retire** button. The confirmation explains that all future rounds and rounds without scores will count as zero and that all score entry will be locked. When a helper retires a pilot, the confirmation names the pilot. Design the confirmation so it cannot be hit by accident, and the retired state afterwards.
- A link to the current results.

Show it with eight rounds: some scored, one next to enter, some later. Also show it when scoring is closed, when the contest is completed, and when the participant is retired.

### Score entry and review (F5J first)

Route `/contests/{id}/pilots/{pilotId}/rounds/{roundId}`. Rules for the fields are in `../../../business-requirements/disciplines/f5j.md`; follow them. This is a single-flight form for one pilot, not a grid.

**Header:** round, group, lane, the pilot's name (so a helper always knows whose score this is), and previous, next, and back navigation.

**Fields (F5J):**

- **Time flown**: numeric keypad. Match the director's Scoring screen so a person who knows one knows the other: compact input where `630` means 6:30 and `630.4` means 6:30.4 (the decimal separator follows the locale). The field **shows the parsed value** (6:30) as the person types. It rejects impossible values (seconds above 59, over the working time, equal to the working time) with a message and **without discarding what was typed** until corrected.
- **Launch height**: whole metres, numeric keypad, no decimal separator. Zero is not valid. Above 300 m asks "Is this correct?" inline and continues without a modal.
- **Landing**: a choice from the **contest's landing table** (segmented control or chips showing the label and the points it gives). Unavailable when Late landing is on.
- **Toggles:** Late landing, Motor restart (hidden when the contest does not allow restarts), Out of bounds (landing more than 75 m from the marker), No altitude recorded.
- **Flight Penalty**: an optional whole number of points for an infraction on this flight, for example flying outside the assigned group. See "Penalties".

**Rules the form enforces visibly** (disabled fields show _why_ in text, not just a grey-out):

- Late landing on: the landing choice is cleared and disabled.
- Out of bounds or Motor restart on: time, height and landing are zeroed and disabled.
- Motor restart and Out of bounds may both be on. When the contest makes restarts non-droppable, say the zero cannot be dropped.
- No altitude recorded on: every other toggle and field is disabled, and Motor restart and Out of bounds cannot be selected with it.

**Zero confirmation:** submitting with nothing entered, or with a zeroing status on, asks the person to acknowledge that the pilot receives a zero. Design it inline above the Submit button, not as a modal.

**Submit model:** one **Submit** per flight. Submit is final: the form becomes read-only and the button disappears. Design the moment before submitting so the person can check the values (a summary line such as "6:30 · 45 m · landing 50 · no penalty") and the moment after. Prevent a double submit.

**After submission (read-only):** the values as entered, the status (Submitted), who entered it (the pilot or a helper, by name), and when. Show the pilot's **cumulative penalty** if the contest director has applied one. It is read-only and never entered here; say it was applied by the director.

**Someone else submitted first:** if the pilot and a helper both have the form open and one submits, the other's form turns into the read-only view of the accepted score, explains that it was already submitted by (name) at (time), and offers **Request review**. This must not feel like an error.

**Request review:** available only when review requests are enabled, the score is in the preliminary Submitted state, and it is not locked. A pilot or a helper can request one. The form opens pre-filled with the submitted values and an optional explanation; **Submit review request** is off until a value changes. After submitting, the form is read-only again, changed fields carry an indicator, and the page says the score is **under a requested review**. If a review is already pending, show that state instead of the form. Hide the button when the score is Official or locked, and say why in a short note.

**Penalties:** the page shows two penalties that differ. Make the difference readable without a tooltip. The **Flight Penalty** is entered with the score and is dropped with the round if the round is dropped. The **Cumulative Penalty** is applied only by the director, is never dropped, and appears read-only after submission.

**Under the score**, after submission:

- **Group results**: every pilot in the group with name, the discipline values, raw score, and round score. Values update as scores come in, so mark the table **preliminary**. A row for a pilot with a pending review carries an indicator, and shows the originally entered scores until the review ends. A pilot with no score yet is shown as such.
- **Placement**: the pilot's place in the contest with the three pilots ahead and the three behind, as of the round viewed. Where a pilot has no score yet for the round, their position is **estimated**; label estimates clearly in text and icon, and say what the indicator means. A pending review on this or an earlier round is indicated.
- While the director is **hiding overall results**, the placement is shown as of the round when hiding started, with a note ("Standings are held at round 4"). Design that note.

Both tables must read on a phone without horizontal scrolling. Propose how: which columns are always visible, whether discipline values collapse into a per-pilot detail, and how the pilot's own row is marked. Show them with a group of six pilots in which one has no score and one has a pending review.

### Results

Route `/contests/{id}/results`. The latest results for the contest, almost always preliminary.

- **Individual overall results**: place, pilot, and group score (one score per pilot, so it stays easy to read). Mark the page preliminary. Ties share a place with a tie indicator ("3="). The participant's own row is marked. The participant's own place and score may use the brand's stencil accent and `numeric-lg` (one stencil number per screen), for example "3rd" with "You are 3rd after round 4."
- **Team standings**, when teams are enabled: place, team, and team score. Show them for every participant, including pilots whose team has no helper. Propose how the two sections share a phone screen (tabs, a segmented control, or sections), and say why.
- While the director is hiding overall results, both are held at the recorded round. Use the same note as above.
- When the contest results are public, a link to the contest on the public site for the complete results and flight details.

### States for every page

Design each, and make sure a failure **never loses what the person typed**:

- **Loading** (skeleton, not a spinner, so the layout does not jump) and **load failed with retry**.
- **Offline**: the person can still fill in a flight. A submission that is only saved on the device must look clearly different from one the server has accepted ("Saved on this device, waiting to send"), with the time, and must never read as accepted. Show it on the form and on the overview row. When the connection returns, show it sending and then accepted.
- **Rejected submission**: the person is told what happened and what to do. Show at least these reasons: scoring is closed, the round or group is locked, the score was already submitted (see above), the entry is out of order (an earlier round has no score), the draw changed, and the participant is retired. A rejected entry stays visible with the reason until the person dismisses it or retries.
- **Scoring closed**: the contest director has closed participant scoring. The pages still read normally, entry is off, and the reason is shown beside the disabled controls.
- **Contest completed**: read-only, with a link to public results when public.
- **Not permitted**: for example, a pilot opening a team page. Same message as an unavailable page.
- **Invalid link** (see the handler).

## Discipline fields

The form is built from the discipline's **score-entry schema**: field label, type, unit, precision, range, and dependencies. Treat the entry area as a set of typed fields so that a different discipline changes the fields and not the page. Show the F5J set. Then show **one variation** to prove it holds, for example F3J (time, landing, late landing, out of bounds; no height). Do not design every discipline.

## Room for follow-ups (do not design the actions)

Leave visible, labelled room for: the **F3K task** per round in the overview table, **notifications** (for example when a review is resolved), **account settings** reachable from the app bar, and a **language** choice. Show them as dimmed placeholders or omit them, but say where they go.

## Deliverables

1. **Foundations:** the app chrome (top bar, account state, connection indicator, how a person moves between pages) and the status vocabulary. The brand guide already defines In progress, Completed, Tie, Dropped, Re-flight, Penalty, Preliminary, and Not shown yet; reuse those exactly. Propose the missing ones in the same form (colour from the existing tokens, a Material Symbols icon, and a word): Up now, Up next, Just flown, Retired, Estimate, Pending review, Queued on device, Submitted, Rejected. Up now is the one place a chip may use `brand-deep`, so check it against the one-orange-fill rule on the team overview. Propose new tokens only if the existing ones cannot do the job, and say why.
2. **Landing, handler, and contests** at ~400px, light and dark where noted: the handler with a valid link and with an invalid link, the sign-in confirmation, the contests list with one contest, the empty state, and the "Is this you?" card.
3. **Team overview** at ~400px with the six-pilot example and the standings, and with the no-further-flight message.
4. **Pilot overview** with eight rounds, and in each of the closed, completed, and retired states. The retire confirmation and the copy-link control.
5. **F5J entry:** empty, partly filled with the time field parsing compact input (valid and rejected), the launch-height question, each toggle rule, the zero confirmation, the pre-submit summary, and the read-only submitted view with "entered by".
6. **Review and conflict:** the "someone else submitted first" view, the review request form, a pending review, and the hidden review button for an Official or locked score.
7. **Under the score:** the group results and placement tables at ~400px with the six-pilot example, including an estimate, a pending review, and the held-standings note.
8. **Results** at ~400px with and without team standings, and with the held-standings note.
9. **Shared states:** loading, load failed, offline and queued, queued then accepted, and each rejection reason.
10. **One discipline variation** (for example F3J) to prove the form holds.
11. A short rationale covering: how the app chrome works on a phone, how the two results tables fit a phone, the submit and conflict model, where you used progressive disclosure, how colour independence is achieved for each status, how you used the brand tokens and the one-orange-fill rule, and any component or token additions to the M3 theme.
12. Any questions or spec ambiguities you hit. List them; do not silently resolve them.

Light theme first. Every screen ships in both themes, so prove the dark theme on at least the team overview, the F5J entry form, and the results page.
