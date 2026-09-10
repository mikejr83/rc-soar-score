# RC Soar Score Architecture - Data Model

This page is the entry point for the conceptual data requirements. It replaces the former mixed entity list with a stable contract for identifiers, ownership, revisions, state, privacy, synchronization, and derived values.

The model is storage-neutral. Local persistence, remote backup, and public publication are separate representations and lifecycle concerns; they are not three contest states. A local accountless contest may be published through the anonymous verification flow, but it does not become an ordinary remotely backed-up contest until claimed by an account.

## Entity documents

The detailed entities are maintained in the [`data`](data/README.md) folder:

- [`Contest`](data/contest.md)
- [`Accounts and ownership`](data/accounts.md)
- [`Participants and participation`](data/participants.md)
- [`Teams, roles, and models`](data/teams-roles-models.md)
- [`Disciplines and configuration`](data/disciplines-and-configuration.md)
- [`Matrix and assignments`](data/matrix-and-assignments.md)
- [`Scores and results`](data/scores-and-results.md)
- [`Reviews and invitations`](data/reviews-and-invitations.md)
- [`Publication`](data/publication.md)
- [`Synchronization and audit`](data/synchronization-and-audit.md)

The folder README defines the relationship summary, cross-cutting invariants, and open decisions that must be resolved before a physical schema is treated as stable.
