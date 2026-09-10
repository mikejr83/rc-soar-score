# RC Soar Score — Plan Gap Analysis

Reviewed: `plan/**` and `implementation-plan.md`; this document is a historical baseline. The data-model and state findings below were rechecked on 2026-09-10.

## Resolved in the current documentation

- The former monolithic [`data.md`](../architecture-requirements/data.md) is now a schema entry point with entity documents under [`architecture-requirements/data`](../architecture-requirements/data/README.md).
- Accounts, contest ownership, independent contest state dimensions, participant snapshots, teams, roles, models, configuration revisions, matrix revisions, score attempts, official revisions, reviews, invitations, publication revisions, synchronization, tombstones, and audit events are now documented.
- `contest-official-scoring.md` now defines the administrative scoring contract instead of ending as a stub.
- The initial discipline list no longer claims F3L is implementable before its rules exist.
- Score submission and official score authority are separated; publication is no longer treated as a contest lifecycle state.

Ranked by "blocks implementation" first. Items in **A** and **D** are decisions the owner must make;
**B** and **C** are sections that need writing.

---

## A. Internal contradictions — pick one

**A1. Backend language: C# or Node?** *(blocks all architecture)*
`implementation-plan.md` says "C# service API layer". `mvp-application.md` §Basic API Layer says the
Electron-embedded local server should be NodeJS specifically so "a version or portion of the
application layer running as the remote API could be utilized for handling the requests from the
wrapped application locally." Those are mutually exclusive if the goal is code reuse.
→ **Q:** One API implementation shared between local and remote, or two? If C# remote, what runs
inside Electron, and is scoring logic then implemented twice?

**A2. "Locked" means three different things.**
  CD/officials **can** still enter scores.
**A2. Independent lock dimensions are now documented.** Administration lock, participant scoring
access, and per-score/group/round lock are separate concerns. Publication visibility has no `Locked`
state. Remaining work is to finalize lock precedence for the physical schema.
→ **Q:** Rename two of these. Is "locked" one flag or three independent ones?

**A3. State tables reference states that don't exist.**
- `contest-state-and-transitions.md` table: "Completed → **Published** or Archived" and
  "**Published** → Pending Delete" — but `contest-publishing.md` explicitly says publishing "does not
  describe a contest lifecycle state." Also **Locked** has a prose section but is absent from the table.
- `score-review-and-validity-state.md` table: "Draft → Submitted or **Retired**" (no Retired state
  defined); "Locked → **Previous state**" (undefined — which one, and how is it stored?).
- `contest-visibility-state.md` Public/Private table exit column says "Public → Private or
  **Scoring Open**" — mixing in a value from the other state machine. And §Scoring Visibility
  references a "**Local only**" public-visibility state that isn't in its own table.
→ **Ask:** one cross-reference table of every state name across the 4 state docs + `contest-phases.md`.

**A4. Can an account-less CD publish?**
`data.md` intro: "A contest director that does not have an account will not have data stored in the
remote system for back up. **They will be able to publish public contests.**"
`contest-publishing.md`: "A contest that is created offline **will not be sent to the remote site**
for storage **unless the contest director has a user account**."
→ **Q:** Which? (Publishing implies remote storage, so the first reads like an error.)

**A5. Participant ownership: per-CD or global?**
`managing-system.md` §Managing Participants: participants are stored "linked to the contest director",
edits "remain the contest directors", never shared. `data.md` §Participant: one global \*:\* collection,
and §Participant User Link says account creation searches for "a participant that exists with the same
email" and links to it.
→ **Q:** If three CDs each have a local record for the same pilot and that pilot registers, which
record does the account link to? What happens to the other two?

**A6. Live scores vs. required validation.**
`contest-configuration.md` sets score display default to "Require validation before score calculation".
`contest-self-scoring.md` §Round and Contest Placement Viewing: the group table "will update as
participants enter the data", and placement is extrapolated live.
→ **Q:** Under the default, does the pilot see nothing until the CD validates? Or does the pilot-facing
view ignore the display mode?

**A7. Configuration lock points differ by document.**
- Post-draw lock list (`contest-state-and-transitions.md` §Draw): Use teams, Use roles, Draw mode, Groups per round.
- Running lock list (same doc): Use teams, Use roles, discipline scoring rules.
  Draw mode and Groups per round silently drop off; scoring rules appear only at Running.
- Discipline lock: state doc locks it "after the contest director acknowledges" the selection;
  `offline-synchronization.md` says it's locked "once the draw has taken place."
→ **Q:** Is the lock list cumulative (Running ⊇ Ready)? When exactly does discipline lock?

**A8. Pilot start numbers vs. post-draw additions.**
`contest-configuration.md`: the number "is assigned when the first draw occurs. It cannot be changed
afterwards." `contest-draw.md` allows adding a pilot after a draw (randomly slotted in).
→ **Q:** What number does a post-draw pilot get? Next available, or does everyone renumber?

**A9. Completion timeout is unowned.**
`contest-phases.md`: "No score has been entered in 48 hours." `contest-state-and-transitions.md`:
"after some time period (generally there is not more than a one day gap for weather days)."
→ **Q:** What's the number, and **who evaluates it**? An offline app that hasn't synced in two days
would auto-complete a contest the server still sees as running (and vice versa).

---

## B. Documents on the critical path that stop mid-thought

**B1. `offline-synchronization.md` ends mid-sentence at step 6.** The conflict-resolution rule — the
entire point of the document — is missing. Unanswered:
- CD redraws the matrix or adds a round offline while pilots have already scored online against the old matrix.
- Review requests submitted server-side while the CD is offline; the CD meanwhile edits that same score directly.
- Record identity across devices — are IDs UUIDs generated client-side, or server-assigned?
- Is sync per-contest or global? Can two devices hold the same contest?

**B2. Invitation requirements are now defined.** [`self-scoring-invites.md`](../architecture-requirements/self-scoring-invites.md) defines opaque credentials, revisioning, replacement, revocation, delivery, team scope, and audit. Remaining decisions are expiry duration and session invalidation semantics.

**B3. Official scoring is now documented.** The business document captures the group/round grid, validation, locks, corrections, and authority rules; the MVP document remains the UI detail source.

**B4. `f3l.md` and `f3k.md` are title-only.** F3L is listed under "Initial supported disciplines" in
`contest-configuration.md` and under "simple duration" in the disciplines README — but has no scoring
rules at all, so it can't be built. F3K is explicitly out of scope, yet `contest-self-scoring.md`
specifies an F3K task-type column on the pilot overview table.

---

## C. Missing entirely

**C1. Seeded man-on-man doesn't fit the state model.** `contest-configuration.md` §Draw Options:
seeded mode "uses a new draw after every round" placing similar-scoring pilots together. But every
other doc assumes one full matrix created before Ready, and `contest-self-scoring.md` shows the pilot
a table of *all* rounds with their group assignment up front — impossible if round N+1 isn't drawn yet.
→ Needs: when the re-draw runs, what a pilot sees for future rounds, how it interacts with team
protection and with the "add rounds" flow.

**C2. `data.md` is missing roughly half the entities the BRs require.** No entity for:
Team; Landing Bonus table + entries; Role / Participant Type; per-discipline scoring rules
(target/working time, points per second, decimals, height-penalty params, motor-restart mode);
Score audit trail (`score-review-requests.md` requires original score, entering user, official score,
official-updated timestamp — none are fields); lane assignment; sync metadata (the thing
`offline-synchronization.md` steps 3–5 depend on).
The Contest entity also lacks: lifecycle state, public/private, scoring-open state, score display mode,
rounding vs. truncate + decimal count, dropped-round-after-round-N, team-score pilot count.
Also: "Published Contest" is described as a **clone** of the contest, which conflicts with the public
site showing live in-progress results.

**C3. Scoring edge cases with no defined answer.**
- Normalization divide-by-zero: every pilot in a group scores 0 (weather, mass out-of-bounds). What's the group score?
- Group of one pilot always normalizes to 1000.
- "Time" group score on ALES/Thermal: defined as "the pilot with the best time score receives 1000."
  But those are *target-time* tasks where best = closest to target, and overflying yields **negative**
  raw points. Normalizing a negative number against a positive best is undefined. ALES defaults to Time mode.
- Dropped round: is it one drop total once round N is reached, or one drop per N rounds? Interaction
  order with penalties, with "Penalty Not Discarded", and with team scoring is unspecified.
- ALES has motor restart as a zero condition but, unlike F5J, no droppable/non-droppable configuration.
- F3J's 30-point late-landing penalty vs. the generic Penalty field — same mechanism or separate?
- **Tie-breaking is never mentioned.** Contest placement, team placement, class winners all need it.
- **Reflights are never mentioned.** Standard in FAI events (equipment failure, mid-air, timing error).
  Any CD will ask. Not in the state model, data model, or matrix.
- **CD-applied penalties have no business requirement.** `mvp-application.md` has a Penalty grid column
  and `data.md` has Penalty + Penalty Not Discarded fields, but no doc says when/how a CD applies one.

**C4. The Official persona has no auth or account model.** `contests.md` defines Official as "a proxy
for the contest director" who enters scores administratively — but `accounts.md` covers only CDs,
participants, and public viewers. No delegation, no shared login, no invite. Related: no IdP is chosen
(`ui/landing-page.md` just says "IdP site"), and there's no story for how the offline app obtains,
stores, or refreshes a token when it's mostly disconnected.

**C5. Three referenced deliverables have no document.**
- The **public site** — named as a top-level app in `application-plan.md`, `mvp-application.md`,
  `implementation-plan.md`, and driven by the entire visibility state machine. Zero requirements.
- **Reports** — a nav target on the contest config page; pilot classes exist *only* for reporting;
  team scores are for reports. No report is specified.
- **Export** — listed as a core CD need in `managing-system.md`. No format, no scope.
- Also `managing-system.md` mentions a "fly-off" copy scenario once, with no rules for what a fly-off is.

**C6. Cross-cutting, unaddressed:** time zones (contest dates, the 48-hour rule, offline clocks);
concurrency (two officials editing the same group; a pilot submitting while the CD edits the same score);
data retention/PII for participant data held per-CD and synced remotely; capacity assumptions
(pilots/rounds — drives whether the draw algorithm can be brute-force).

---

## D. The biggest single question

**D1. Does MVP include self-scoring at all?**
`mvp-application.md` states the MVP is the offline desktop app with no accounts and no authn/authz.
But `contest-visibility-state.md` states scoring visibility can't be opened unless the contest is
published to the remote site — which needs an account. So in MVP, participants can't self-score, which
removes: the mobile self-scoring UI, review requests, the Review Requested grid column, the "Score
Submitted from Participant" column, and most of the sync doc.
→ **Q:** Is MVP contest-director-entry only? If yes, `mvp-application.md` should say so explicitly and
the self-scoring/review docs move to phase 2. If no, MVP needs accounts and the API after all.

---

*Hygiene:* `plan/INDEX.md` lists 10 of the 24 plan docs — missing the entire `disciplines/` and `ui/`
folders, plus `contest-publishing.md`, `contest-visibility-state.md`, `score-review-and-validity-state.md`,
`score-review-requests.md`, `contest-official-scoring.md`, `self-scoring-invites.md`, `mvp-application.md`,
`application-plan.md`. Also `implementation-plan.md` sits at repo root while everything else is in `plan/`.
