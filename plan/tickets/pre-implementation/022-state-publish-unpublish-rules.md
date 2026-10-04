# Ticket 022 — State Machine: Publish/Unpublish Rules for Results

- **Category:** Contest State Machine
- **Priority:** Medium
- **Status:** Decided
- **Decision:** Unpublishing is not supported; republishing creates a new projection version; concealment uses results hiding and removal uses an administrator-decided delist request. (2026-10-04)

## Context

Whether a published round's results can be unpublished, and what happens to the public site if they are, is not defined.

## Questions

1. ~~Can a published round's results be unpublished?~~ **Resolved: no.** A published record is permanent public record. The director cannot remove it. Removal from public view is a delist request decided by a system administrator ([contest-publishing.md](../../architecture-requirements/contest-publishing.md), [publication.md](../../architecture-requirements/data/publication.md)). There is no round-level unpublish.
2. ~~If so, what does the public site show?~~ **Not applicable.** Without unpublish the public site always shows the latest published projection. Concealing the outcome is handled by results hiding, which withholds overall standings as of a round while round scores stay visible ([contest-state-and-transitions.md](../../architecture-requirements/contest-state-and-transitions.md)).
3. ~~Can a round be republished after being unpublished, and does it get a new revision number?~~ **Resolved:** a later publish updates the public record and creates a new versioned projection after the service validates the contest revision, state, visibility and privacy rules. A failed publish does not alter the private contest.
4. ~~Does unpublishing a round affect the cumulative standings of subsequent rounds?~~ **Not applicable.** Standings are derived and recomputed from raw scores; a projection is a snapshot of calculated results.
5. ~~Is unpublishing a director-only action?~~ **Resolved:** there is no director unpublish. A delist request is raised by the owner (or the account closure flow) and decided by a system administrator.

## Decisions

- Unpublishing is not supported. Republishing creates a new projection version. Concealment uses results hiding; removal uses a delist request.
- No schema impact.

## Sources

- `plan/ui/public-site/view-contest.md`
- `plan/architecture-requirements/data/scores-and-results.md`
