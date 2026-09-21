# Ticket 011 — Participant Identity and Cross-Contest Matching

- **Category:** Data Model / Schema
- **Priority:** High
- **Status:** Open

## Context

`managing-system.md` states that a participant's email is used to determine whether a contest director's entry matches a participant already created in the remote system. But email is also described as "always private." The matching key and its interaction with privacy are underspecified.

## Questions

1. What is the exact matching key for cross-contest dedup — email alone, email + name, or a normalized identifier?
2. How does the system handle a mistyped email by the contest director? Is there a fuzzy-match or "possible match" prompt?
3. Is participant identity globally unique (one record reused across all contests) or per-contest registration that optionally links to a global person record?
4. How do local (offline) participants created before any sync reconcile with the remote identity — do they get a provisional local id that must be matched on first sync?
5. How does the server perform dedup without exposing email to the public site or other pilots — is there a server-side hash comparison?

## Decisions Needed

- The identity/matching model (global person vs. per-contest registration).
- The dedup mechanism and its privacy guarantees.

## Sources

- `plan/business-requirements/managing-system.md` (Participant Privacy and Data Syncing)
