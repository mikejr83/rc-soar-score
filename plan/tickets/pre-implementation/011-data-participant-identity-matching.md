# Ticket 011 — Participant Identity and Cross-Contest Matching

- **Category:** Data Model / Schema
- **Priority:** High
- **Status:** Ready
- **Decision:** Tiered exact matching keys in two scopes: (1) intra-director — the director's own local and synced profiles are always deduped/linked by tiered keys (normalized email → FAI number → national organization ID, first present tier); (2) cross-director — matching only resolves to shared (account-opt-in) profiles, via a server-side exact lookup that returns a boolean plus allowed display fields only (email never returned). Name is never an automatic key, only a "possible match" suggestion. Identity model: reusable participant profile + per-contest participation link + optional many-to-many participant-account link; scores reference the participation link. Offline reconciliation: local profiles keep their client-generated ID; on first sync a match records a link/alias to the remote profile (director confirms, never silent). When both a director-owned and a shared profile match, the shared profile wins (director-owned record merged into it, one-time confirm; shared profile read-only to the director).
- **Cross-references (not blockers):** tickets 013/015 (sync conflict/atomicity mechanics for the profile-link mutations), `data/accounts.md` (account ↔ profile candidate links are a separate relationship), ticket 022 (public projection of matched shared profiles).

## Context

`managing-system.md` states that a participant's email is used to determine whether a contest director's entry matches a participant already created in the remote system. But email is also described as "always private." The architecture data docs (`data/participants.md`, `data/README.md`, `data/accounts.md`) define the reusable-profile / participation-link / account-link model, the privacy rules, and the shared directory, but the exact matching key, its scope, the offline reconciliation path, and the server-side matching mechanism were underspecified. All of these are now decided below.

## Questions

1. What is the exact matching key for cross-contest dedup — email alone, email + name, or a normalized identifier? — **Resolved: tiered exact keys (normalized email → FAI number → national organization ID); name is suggestion-only. See Decisions.**
2. How does the system handle a mistyped email by the contest director? Is there a fuzzy-match or "possible match" prompt? — **Resolved per `ui/contest-administration/participant-data.md`: before creating a record the director is shown any duplicate or possible match (email first, then normalized name similarity) and must choose the existing record or explicitly create a separate local record. Exact tiered keys only drive automatic links; no fuzzy match is ever applied automatically.**
3. Is participant identity globally unique (one record reused across all contests) or per-contest registration that optionally links to a global person record? — **Resolved: per the architecture data docs — a reusable participant profile (director-owned, local-only, or account-shared) plus a per-contest participation link; an optional many-to-many participant-account link. Scores reference the participation link, never only the profile.**
4. How do local (offline) participants created before any sync reconcile with the remote identity — do they get a provisional local id that must be matched on first sync? — **Resolved: no provisional id. Local profiles carry stable client-generated IDs; on first sync the server matches them via the tiered keys and, on a match, records a link/alias from the local ID to the remote profile. The director confirms; the merge is never silent.**
5. How does the server perform dedup without exposing email to the public site or other pilots — is there a server-side hash comparison? — **Resolved: server-side exact lookup by tiered keys. The client sends the normalized value it holds; the server compares against stored values and returns only a boolean match plus the shared profile's allowed display fields. Stored email/IDs are never included in responses; no fuzzy comparison is exposed.**

## Decisions Needed

- The identity/matching model (global person vs. per-contest registration).
- The dedup mechanism and its privacy guarantees.

Both resolved — see **Decisions** and **Acceptance criteria** below.

## Decisions

- **Identity model (Q3):** Reusable **participant profile** (director-owned, local-only, or account-shared) + per-contest **participation link** (authoritative contest snapshot: class, role, start number, team, scoring UUID, privacy/display overrides, status) + optional many-to-many **participant-account link** (survives email changes / account replacement). A profile has no class, role, team, number, or score; scores reference the participation link, not only the profile. This is the model in `data/participants.md`; no new global "person" table is introduced beyond profile + link.
- **Matching keys (Q1):** Automatic dedup uses **exact tiered keys**, first present tier wins:
  1. Normalized email (lowercase, trimmed).
  2. Else normalized FAI number.
  3. Else normalized national organization ID.

  Name is **never** an automatic key. Name similarity is used only for non-blocking "possible match" suggestions (Q2).

- **Scopes:** Dedup runs at exactly two scopes:
  - **Intra-director:** always. The director's own local and synced profiles are matched by tiered keys; this powers the "frequent participants" list and the copy-pilots-from-previous-contest wizard flow.
  - **Cross-director:** only against the **shared directory** (profiles owned by participant accounts that opted into sharing). A director-owned profile of another director is never visible or matchable. All directors can link to the same shared profile.
- **Mistyped email / possible matches (Q2):** When creating or editing a profile, the UI shows (a) exact tiered-key duplicates and (b) possible matches by normalized name (plus an "email looks similar" hint when close). The director must choose an existing record or explicitly create a separate local record. Automatic linking happens only on exact tiered-key equality.
- **Offline reconciliation (Q4):** Local profiles keep their client-generated stable ID (sync already preserves IDs and never silently overwrites). On first sync the server runs the tiered-key match against the intra-director and shared scopes. On a match it records a **link/alias** from the local profile ID to the canonical remote/shared profile; the director is prompted to confirm. No silent merge of shared-profile data.
- **Shared profile precedence:** When the same director's entry matches both their own director-owned profile and an opt-in shared profile, the **shared profile wins**: the director-owned record is marked merged into the shared profile (one-time confirm), and per `managing-system.md` the shared profile's participant data is read-only from the director's point of view (the participant controls email visibility).
- **Privacy mechanism (Q5):** Cross-director matching is a **server-side exact lookup**: the client sends the normalized email/FAI/ID it holds; the server compares to stored values and returns only a boolean match plus the shared profile's allowed display fields (name, country, etc.). Stored emails/IDs are never included in responses, never logged, and are excluded from public projections; no fuzzy comparison is exposed over the API.
- **Account linking is separate:** Matching an account to a profile (per `data/accounts.md`) remains a candidate link subject to ownership/privacy rules — a distinct relationship from the profile-level dedup above. Account creation never merges or rewrites historical participation.

## Acceptance criteria

- A participant profile is stored separately from its per-contest participation link; scores, assignments, invitations, and contest model links reference the participation link, and no contest-scoped identity data (class, role, number, team, score) lives on the profile.
- Automatic profile matching uses exact tiered keys in the order email → FAI number → national organization ID, with the first present tier winning; name is never an automatic key.
- Matching applies (a) always within a director's own profiles and (b) across directors only against shared (account-opt-in) profiles; director-owned profiles of other directors are never returned or linked.
- Creating/editing a profile shows exact duplicates and possible name matches before save, and requires an explicit director choice between reusing an existing record and creating a new local record; automatic links occur only on exact tiered-key equality.
- Locally created profiles retain their client-generated ID through first sync; a first-sync match produces a director-confirmed link/alias record from the local ID to the canonical remote/shared profile, with no silent merge of shared-profile data.
- When both a director-owned and a shared profile match, the shared profile becomes canonical: the director-owned record is merged into it (one-time confirm) and the director's subsequent edits to that profile's participant data are rejected as read-only.
- The server's matching API returns only a boolean match plus allowed display fields; stored emails and ID values are never returned, logged, or published, and public projections never include email.
- Account-to-profile linking remains a separate candidate-link flow and never auto-merges or rewrites historical contest participation.

## Sources

- `plan/business-requirements/managing-system.md` (Participant Privacy and Data Syncing)
- `plan/architecture-requirements/data/participants.md` (participant profile, participation link, participant-account link, privacy)
- `plan/architecture-requirements/data/accounts.md` (account ↔ profile candidate links; no auto-merge on account creation)
- `plan/architecture-requirements/data/README.md` (shared profile directory; director search by Name, FAI/AMA/National ID, Email; email private)
- `plan/architecture-requirements/data/synchronization-and-audit.md` (stable IDs, no silent overwrite, preserved IDs on import)
- `plan/ui/contest-administration/participant-data.md` (duplicate / possible-match prompt before create)
