# Contributing

## How work is tracked

All planned work is tracked in [GitHub issues](https://github.com/mikejr83/rc-soar-score/issues). The requirements stay in the repository under [`plan/`](plan/INDEX.md); the files under `plan/tickets/` are the historical record of earlier planning and decisions, so do not add new ticket files there.

- **Milestones** group the work in release order: M0 Foundations, M1 F5J online slice, M2 Disciplines, draw, accounts and publishing, M3 Self-scoring, M4 Offline and sync, M5 Release hardening.
- **Epics** are parent issues (`type:epic`) with sub-issues for the individual tickets.
- **Labels:** one `area:` (core, data, server, contest-app, self-score-app, public-site, sync, infra, docs), one `type:` (epic, feature, chore, decision, test), a `priority:` (p0 blocks the milestone, p1, p2) and a `size:` (S under a day, M a few days, L a week or more; split an L if you can). `needs-decision` and `blocked` mark tickets that cannot start. `good first issue` marks small, well-specified tickets.
- **Decisions** are `type:decision` issues. Record the outcome in a comment and update the affected requirement documents.

## Writing a ticket

Use the issue templates. A ticket states the context, the work items, the acceptance criteria and its dependencies by issue number. If a ticket would otherwise wait on a feature that does not exist yet, move that one item into a small follow-up issue and close the original when its own slice works.

## Working on a ticket

1. Read [`AGENTS.md`](AGENTS.md) and the per-project `AGENTS.md` for the packages you touch.
2. Branch from `master`, make the change, and add tests.
3. Run the checks described in [`docs/environment-setup.md`](docs/environment-setup.md): `melos analyze`, `melos test`, and `npx prettier --check` for any Markdown you changed.
4. Open a pull request that links the issue (`Closes #123` for the last PR of a ticket).
