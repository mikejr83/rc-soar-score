# Contest

A contest is the private source-of-truth aggregate for one radio-controlled soaring event.

## Identity and ownership

- `contestId`, name, start and end date/time, time zone, host/venue, city, state/province, and country.
- `ownerAccountId` for an account-backed contest, or an explicit anonymous/local ownership mode.
- Creation and last-modified metadata.

A contest director without an account may administer a local contest and may publish through the anonymous verification flow. Anonymous publication does not create an ordinary remote backup record.

## Time zone policy

The contest should store the time zone it was created in.

## Configuration and control state

Contest configuration is revisioned. A revision references the discipline profile and overrides, participant options, team options, draw options, scoring options, rules, and publication update policy. A change that affects a matrix or calculation creates a new revision and follows lifecycle mutability rules.

Store these independent controls; do not combine them into one status field:

- Execution lifecycle: `Created`, `Configuring`, `Ready`, `Running`, `Completed`.
- Participant scoring access: `Closed` or `Open`.
- Administration lock: `Unlocked` or `Locked`.
- Results hiding: off, or hidden with the round through which standings are shown and the time hiding began.
- Local archive flag, local to the installation and not synchronized.

Publication state, visibility, and delisting belong to the published-contest record described in [publication.md](publication.md), not to the contest. A contest that has never been published has no such record and is visible only to its director. A contest has no deletion status: deleting it removes the director's working data and leaves any published record in place.

Every accepted state transition records actor, authority, source installation, base revision, resulting revision, and server/client timestamps. Completion closes participant scoring and prevents new participation or matrix changes; authorized score corrections remain possible as new revisions.

## Configuration fields

The model must accommodate discipline, classes, roles, teams, pilot numbers, models, draw mode, groups per round, lane mode, team protection, preliminary seeded rounds, group-score mode, rounding/truncation and precision, dropped-round policy, review policy, and public update policy. Discipline-specific values belong in the versioned configuration document described in [disciplines-and-configuration.md](disciplines-and-configuration.md).

## Invariants

- The first accepted score atomically changes `Ready` to `Running`.
- A stale or unauthorized transition changes nothing.
- Publishing, synchronization, archiving, and visibility do not change execution lifecycle.
- Deleting a published contest removes only the director's working data. Its published record remains and loses only its link to the contest.
