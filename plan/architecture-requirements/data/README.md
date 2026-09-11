# Data Model

This folder contains the canonical conceptual data model for RC Soar Score. The model is intentionally storage-neutral: an implementation may use relational tables, document collections, or a combination, but it must preserve the identifiers, relationships, revisions, state dimensions, and audit history described here.

## Reading order

1. [Accounts and ownership](accounts.md) establishes authenticated ownership and authority boundaries.
2. [Contest](contest.md) establishes configuration revisions, lifecycle, and independent control states.
3. [Participants and participation](participants.md) separates reusable identity from contest-specific participation.
4. [Teams, roles, and models](teams-roles-models.md) defines contest-specific participant organization and snapshots.
5. [Disciplines and configuration](disciplines-and-configuration.md) defines versioned scoring profiles and contest overrides.
6. [Matrix and assignments](matrix-and-assignments.md) defines rounds, groups, redraws, moves, and re-flights.
7. [Scores and results](scores-and-results.md) defines immutable submissions, official values, calculations, and rankings.
8. [Reviews and invitations](reviews-and-invitations.md) defines participant access and review workflows.
9. [Publication](publication.md) defines the public projection and its history.
10. [Synchronization and audit](synchronization-and-audit.md) defines offline mutations, conflicts, tombstones, and audit records.

## Global invariants

- Every entity has a stable opaque identifier. Identifiers are generated in a way that is safe offline and are never reused.
- Contest-owned records carry the contest identifier and a revision. A mutation carries its base revision and a unique client mutation identifier.
- Server time orders remote changes. Client time is retained only as audit information.
- Accepted mutations are idempotent. Stale, unauthorized, or inactive-installation mutations are rejected or surfaced as explicit conflicts; last-write-wins is not used for authoritative data.
- Raw participant input and official decisions are immutable revisions. Derived scores, rankings, and public projections are replaceable outputs with provenance.
- Drafts and queued local submissions are not accepted data: they do not affect lifecycle, completion, rankings, or publication.
- Storage location, synchronization state, publication, and visibility are separate concerns.
- Private participant data, invitation credentials, and director-only audit data never enter the public projection.

## Relationship summary

- An account owns zero or more contests. An anonymous publisher record may own a published projection but does not create an ordinary remote backup contest.
- A contest has many configuration revisions, matrix revisions, rounds, groups, participation links, score placeholders, and audit events.
- A participant profile can be reused across contests through contest participation links. The link stores contest-specific class, role, number, team, and model data.
- A matrix revision contains assignments. Each assignment identifies the scheduled and credited round, group, lane, and assignment history.
- A score placeholder belongs to one assignment and participant. It has immutable attempts and a current official selection; calculated results are versioned outputs.
- A review request proposes a new score revision without changing the original submission. An invitation authorizes a participant link and permitted team scope.
- A contest may have one stable published-contest identity and many atomic publication revisions. The private contest remains the source of truth.

## Open decisions before physical schema implementation

These are intentionally not hidden in entity descriptions because they require product or policy decisions:

- Physical database technology, identifier format, and uniqueness/index strategy.
- Whether shared participant profiles are globally addressable or only linked through an account-controlled directory.
- Whether retirement materializes future zero score records or uses a retirement overlay.
- Tie-breaking rules and the exact order of penalties, dropped rounds, re-flight selection, and team totals.
- Publication retention, anonymous publisher claiming, and invitation expiry duration.
- Synchronization cursor storage, conflict-resolution UI contract, and tombstone retention.
- Time-zone policy for contest dates, server timestamps, and inactivity completion detection.

The business and architecture requirements must resolve these decisions before migrations are treated as stable.
