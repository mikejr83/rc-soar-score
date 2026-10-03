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

## Dates and Times

All dates stored in the data store should be stored in UTC.

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

## Physical schema and architectural decisions

The architectural and schema design decisions are resolved as follows:

- **Database technology, identifier format, and indexing**:
  - **Backend**: Relational database (hosting platform-agnostic standard SQL schema).
  - **Client / Web**: IndexedDB for local offline web and PWA client persistence.
  - **Identifier format**: UUIDv7 (128-bit time-ordered, collision-resistant UUIDs generated offline or online).
  - **Keying and uniqueness**: Surrogate UUIDv7 primary keys on all tables/stores with composite unique constraint indexes matching natural business keys (e.g., `(contest_id, round_number, group_number, lane_number)` and `(contest_id, client_mutation_id)` for idempotency).

- **Participant profile directory and sharing scope**:
  - Directors maintain their own private participant profiles, which are never shared with other directors.
  - Participant account holders can opt into a participant directory of basic details they offer to directors.
  - Contest Directors can search listed directory entries by Name, FAI/AMA/National Organization ID, and Email address, and copy one into a profile of their own.
  - Email addresses used for director auto-completion remain private and are strictly excluded from public projections.

- **Participant retirement representation**:
  - Modeled as a **retirement overlay** (`retired_at_round = N`; a pilot with no value has not retired) on the contest participation link.
  - The scoring engine dynamically evaluates unflown rounds $R \ge N$ as zero with a `Retired` status without preemptively materializing future dummy score records, preserving clean matrix redraws and schedule changes. Free-text retirement reasons are not tracked.

- **Tie-breaking rules and calculation pipeline**:
  - **Pipeline order**: Raw Flight Score $\rightarrow$ Normalized Group Score $\rightarrow$ Discard Dropped Rounds (excluding non-droppable zeros) $\rightarrow$ Cumulative Contest Penalties $\rightarrow$ Final Contest Total $\rightarrow$ Team Total.
  - **Discipline precedence**: Discipline-specific tie-breaking rules take precedence if defined.
  - **Default**: If no tie-breaker is defined by the discipline, ties remain unresolved (shared placement, e.g., `T-1`).
  - **Director-enabled tie-breaker option**: Contest Directors can optionally enable automated tie-breaking with the following precedence:
    1. Higher discarded (dropped) round score.
    2. Total raw flight points across all rounds.
  - **Team fallback tie-breaker**: If not specified by discipline rules:
    1. Lowest sum of place numbers among scoring team members.
    2. Best individual placing among team members.
    3. Shared team placement if still tied.

- **Publication retention, anonymous claiming, and invitation expiry**:
  - **Publication retention**: Published contest projections are retained indefinitely as a permanent public archive. Deleting a contest does not remove its publication. Removing a publication from public view requires a delist request decided by a system administrator.
  - **Anonymous contest claiming**: Contests published anonymously via a verified email can be claimed at any time in the future during the director's first-time login flow when creating/registering an account with that email.
  - **Invitation expiry**: Magic URL email invitations expire 24 hours after contest completion. Field QR code tokens provide access for the entire contest duration and do not expire mid-contest unless explicitly revoked.

- **Synchronization cursor storage, conflict resolution, and tombstone retention**:
  - **Sync cursor**: Monotonically increasing sequence stream per contest (`contest_mutation_seq`); clients track their last acknowledged sequence (`last_synced_seq`).
  - **Conflict resolution**: Official Director score submissions always take precedence over participant self-scores (participant submissions are preserved as immutable attempts in review/audit history). Concurrent Director conflicts or inactive installation mutations present a side-by-side conflict diff in the UI for explicit resolution. Derived values are always recalculated deterministically.
  - **Tombstones**: Soft-deletion tombstones are retained for **90 days** (or until contest archiving + 90 days) to prevent offline devices from resurrecting deleted records during delayed sync.
