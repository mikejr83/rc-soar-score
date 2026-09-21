# Ticket 013 — Agentic Coding Rules (Per-Project AGENTS.md)

- **Category:** Agentic Coding
- **Priority:** Medium
- **Status:** Open

## Context

The repo root `AGENTS.md` is the single source of truth and is already solid (scripts, conventions, test layout). As the monorepo grows into three apps and four packages, agents (and junior developers) benefit from short, domain-specific rule files co-located with each app/package: conventions that are local to that code (folder layout, what belongs in that package, lint/analysis settings, test conventions). Per the decision in this ticket's planning, we keep root `AGENTS.md` as the primary source of truth and add focused per-package `AGENTS.md` files that defer to it.

## Work Items

- [ ] Refine root `AGENTS.md`:
  - Fix the project-naming inconsistency (text says `score-soar-*`, table says `soar-score-*`) per the decision recorded in ticket 002.
  - Add a short section pointing to per-project `AGENTS.md` files and stating that when they conflict, the root file wins.
- [ ] Add per-project `AGENTS.md` files (short: scope, folder layout, key conventions, what must NOT be imported/depended on, example commands). One each for:
  - `apps/soar-score-api/AGENTS.md` — shelf handler structure, middleware order, DTO placement in `soar_score_api`, authn via Auth0 JWT (ref ticket 010), in-process handler tests only.
  - `apps/soar-score-contest/AGENTS.md` — offline-aware design note (UI must not assume connectivity; refer to `plan/architecture-requirements/offline-usage.md`), theme lives in the app, no direct database access (must go through `soar_score_data`), routing construct shared with public app.
  - `apps/soar-score-public/AGENTS.md` — two-area split (site pages vs. results), report-dense layouts may depart from strict Material 3 (ref implementation-plan), read-only of contest data.
  - `packages/soar_score_core/AGENTS.md` — pure Dart, no Flutter, no I/O, owns scoring engine + domain model types; all business rules trace to `plan/business-requirements/`.
  - `packages/soar_score_data/AGENTS.md` — repositories per entity (one file each), SQLite mechanism choice from ticket 007, HTTP client uses `soar_score_api` only, no business logic.
  - `packages/soar_score_api/AGENTS.md` — DTOs use `json_annotation`, no Flutter, token handling injected (ref ticket 010), errors typed in `errors/`.
  - `packages/soar_score_ui/AGENTS.md` — reusable components only (no state, no data access), theme tokens, must work in both app themes.
- [ ] Add each new `AGENTS.md` to this ticket's checklist as completed.

## Acceptance Criteria

- [ ] Root `AGENTS.md` naming inconsistency is resolved.
- [ ] Seven per-project `AGENTS.md` files exist, each under ~40 lines, each deferring to root for shared conventions.
- [ ] Each per-project file names exactly one thing that package must not do (e.g. core: no Flutter; data: no business logic) so agents can't violate the boundaries.

## Dependencies

- [002-scaffold-nx-workspace.md](002-scaffold-nx-workspace.md) — naming decision.
- [003](003-scaffold-dart-api-app.md) through [009](009-scaffold-ui-package.md) — folders must exist.
- [010-setup-auth0-identity.md](010-setup-auth0-identity.md) — auth conventions for the API app file.

## Sources

- `AGENTS.md` (existing, at repo root)
- `plan/implementation-plan.md`
