# Ticket 002 — NX Workspace at Repository Root

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

The repo currently contains only `plan/`, `research/`, `AGENTS.md`, and agent config folders. The monorepo uses an NX workspace with applications in `apps/` and shared packages in `packages/`. Target conventions (pub-get separation, `--no-pub` for Flutter commands, target dependencies) are defined in `AGENTS.md` and must be implemented here.

`AGENTS.md` is internally inconsistent about project naming (it says NX project names use `score-soar-*`, but its own table maps every directory to a `soar-score-*` project name). This ticket settles that convention.

## Work Items

- [ ] Create the NX workspace at the repository root: `nx.json`, root `package.json` (with the scripts referenced in `AGENTS.md`: `npm run build`, `npm run serve:api`, `npm run serve:contest`, `npm run serve:public`, `npm run test`, `npm run lint`), and any NX config files the current NX version requires.
- [ ] Decide and record the project-naming convention. Recommended: NX project names match directory names (`soar-score-api`, `soar-score-contest`, `soar-score-public`, `soar_score_api`, `soar_score_core`, `soar_score_data`, `soar_score_ui`). Correct the `AGENTS.md` text/table to match.
- [ ] Define the per-project target conventions that scaffold tickets will follow:
  - `pub-get` target, run as a dependency before `build`, `test`, and `analyze`.
  - Flutter (`flutter`) targets invoke `flutter ... --no-pub`; pure-Dart targets use `dart ... --no-pub` where supported.
  - `build`, `serve`, `test`, `analyze` targets per project type.
- [ ] Keep `plan/` and `research/` outside of the NX workspace (not referenced by any target).

## Acceptance Criteria

- [ ] `npx nx graph` (or equivalent) renders the workspace with the projects defined by this and the scaffold tickets.
- [ ] `npx nx run-many --target=pub-get --all` succeeds (once at least one project exists).
- [ ] Target dependency ordering matches `AGENTS.md`: pub-get before build/test/analyze.
- [ ] Flutter targets pass `--no-pub`.
- [ ] `AGENTS.md` naming inconsistency is resolved and consistent with `nx.json`/`project.json` files.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — NX version pin.

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
