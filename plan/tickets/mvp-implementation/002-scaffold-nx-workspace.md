# Ticket 002 — NX Workspace at Repository Root — REJECTED

- **Category:** Scaffold
- **Priority:** High
- **Status:** Rejected (replaced by [014-setup-melos-workspace.md](014-setup-melos-workspace.md))

## Context

> **REJECTED / INVALID — superseded.** This ticket is no longer actionable. `plan/implementation-plan.md` no longer uses NX and Node.js: the repository is a Dart/Flutter monorepo managed by **Melos** with native Dart/Flutter tooling. Workspace setup is tracked by **ticket 014** (Melos workspace at repository root), which also supersedes this ticket's naming-convention decision and `.gitignore` ownership.

The original text below is kept only for history. Do not act on it.

## Context (original)

`plan/implementation-plan.md` defined this repository as an NX monorepo: applications live in `apps/`, shared packages in `packages/` (created when appropriate), and `plan/` remains the stable source of truth for design. `plan/application-plan.md` defines the application set: a contest management app (Flutter, laptop/tablet, must run disconnected), a public viewing site (Flutter web), and a Dart/shelf API layer. The MVP ticket series in this folder scaffolds seven projects: `soar_score_server`, `soar_score_contest`, `soar_score_public` (apps) and `soar_score_core`, `soar_score_data`, `soar_score_api`, `soar_score_ui` (packages).

The repo currently contains only `plan/`, `research/`, `AGENTS.md`, and agent config folders. Per the toolchain baseline (ticket 001), the workspace must use the NX 23 line and Node 24. Per-project target conventions (pub-get separation, `--no-pub` for Flutter) are defined in `AGENTS.md` and must be implemented here.

**Project naming (settled by this ticket; moved to ticket 014):** All Dart project names are snake_case and match their directory names — apps under `apps/` and packages under `packages/` — per the Dart package naming standard. Future projects (e.g. the self-scoring web app, the offline desktop shell described in `plan/application-plan.md`) follow the same pattern.

## Work Items (original — superseded)

- [ ] Create the NX workspace at the repository root using the standard nx workspace creation tools. The files: `nx.json`, root `package.json` (with `nx` pinned to the 23 line, `engines` Node 24, and the scripts referenced in `AGENTS.md`: `npm run build`, `npm run test`, `npm run lint`), root `.nvmrc` (Node 24), and any other NX config files the current NX version requires. Root `package.json`/`.nvmrc` ownership per ticket 001.
- [ ] Use nx tooling for adding any projects.
- [ ] Define the per-project target conventions that scaffold tickets will follow:
  - `pub-get` target, run as a dependency before `build`, `test`, and `analyze`.
  - Flutter (`flutter`) targets invoke `flutter ... --no-pub`; pure-Dart targets use `dart ... --no-pub` where supported.
  - `build`, `serve`, `test`, `analyze` targets per project type.
- [ ] Keep `plan/` and `research/` outside of the NX workspace (not referenced by any target).
- [ ] Create the root `.gitignore` covering Dart/Flutter generated artifacts (`.dart_tool/`, `build/`, `.packages`), NX (`.nx/cache/`), Node (`node_modules/`), and coverage output. (Owned here per ticket 001's decision; ticket 010's `.env` entry piggybacks on this file.)

## Acceptance Criteria (original — superseded)

- [ ] `npx nx graph` (or equivalent) renders the workspace with the projects defined by this and the scaffold tickets (003–009).
- [ ] `npx nx run-many --target=pub-get --all` succeeds (once at least one project exists).
- [ ] Target dependency ordering matches `AGENTS.md`: pub-get before build/test/analyze.
- [ ] Flutter targets pass `--no-pub`.
- [ ] Every project created by tickets 003–009 uses its directory name as its NX project name, per the convention recorded in this ticket.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — ~~NX 23 and Node 24 pins.~~ (NX/Node no longer used.)

## Sources

- `plan/implementation-plan.md`
- `plan/application-plan.md`
- `AGENTS.md`
