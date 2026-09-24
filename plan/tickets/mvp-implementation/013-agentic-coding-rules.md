# Ticket 013 — Agentic Coding Rules (Per-Project AGENTS.md)

- **Category:** Agentic Coding
- **Priority:** Medium
- **Status:** In-Review

## Context

The repo root `AGENTS.md` is the single source of truth and is already solid (scripts, conventions, test layout). As the monorepo grows into three apps and four packages, agents (and junior developers) benefit from short, domain-specific rule files co-located with each app/package: conventions that are local to that code (folder layout, what belongs in that package, lint/analysis settings, test conventions). Per the decision in this ticket's planning, we keep root `AGENTS.md` as the primary source of truth and add focused per-package `AGENTS.md` files that defer to it.

## Work Items

- [x] Add a short section to root `AGENTS.md` pointing to per-project `AGENTS.md` files and stating that when they conflict, the root file wins. (The old project-naming inconsistency was resolved by removing the naming sections from `AGENTS.md`; the convention lives in `plan/implementation-plan.md` — no root `AGENTS.md` naming fix is required.)
- [x] Add per-project `AGENTS.md` files (short: scope, folder layout, key conventions, what must NOT be imported/depended on, example commands). One each for:
  - `apps/soar_score_server/AGENTS.md` — thin executable; shelf handler structure; authn via Auth0 JWT (ref ticket 010); in-process handler tests only (see Follow-ups: DTO placement).
  - `apps/soar_score_contest/AGENTS.md` — offline-aware design; theme lives in the app; no direct database access; routing construct shared with public app.
  - `apps/soar_score_public/AGENTS.md` — two-area split; report-dense layouts may depart from strict Material 3; read-only of contest data.
  - `packages/soar_score_core/AGENTS.md` — pure Dart, no Flutter, no I/O; owns scoring engine + domain; business rules trace to `plan/business-requirements/`.
  - `packages/soar_score_data_sqlite/AGENTS.md` — repositories per entity; drift/sqlite3 mechanism (ref ticket 007); no business logic; in-process tests.
  - `packages/soar_score_data_postgres/AGENTS.md` — repositories per entity; drift/drift_postgres mechanism (ref ticket 016); server-side only.
  - `packages/soar_score_api/AGENTS.md` — DTOs use `json_annotation`; no Flutter; token handling injected (ref ticket 010); errors typed in `errors/`.
  - `packages/soar_score_api_handlers/AGENTS.md` — shelf route table; no transport or DB; pure Dart routing logic; in-process tests.
  - `packages/soar_score_ui/AGENTS.md` — reusable components only (no state, no data access); theme tokens; must work in both app themes.
  - (Note: ticket listed `soar_score_data` as a single package; it has since split into `soar_score_data_sqlite` and `soar_score_data_postgres`, plus `soar_score_api_handlers` exists — all now covered.)
- [x] Add each new `AGENTS.md` to this ticket's checklist as completed.

## Acceptance Criteria

- [x] Root `AGENTS.md` has a section pointing to the per-project files and the root-wins rule.
- [x] Nine per-project `AGENTS.md` files exist (3 apps + 6 packages), each under 40 lines, each deferring to root for shared conventions.
- [x] Each per-project file names at least one boundary constraint (e.g. core: no Flutter/I/O; data packages: no business logic; api_handlers: no transport/database; server: no business logic; ui: no state management/data access).

## Dependencies

- [003](003-scaffold-dart-api-app.md) through [009](009-scaffold-ui-package.md) — folders must exist.
- `plan/implementation-plan.md` — project naming convention for the per-project files.
- [010-setup-auth0-identity.md](010-setup-auth0-identity.md) — auth conventions for the API app file.

## Sources

- `AGENTS.md` (existing, at repo root)
- `plan/implementation-plan.md`

---

## History

### Completed — 2026-09-24

**Status Change:** Open → In-Review

**Decisions:**
- Created 9 AGENTS.md files (not 7 as originally in scope) to match the evolved codebase (soar_score_data split into sqlite/postgres packages; soar_score_api_handlers extracted). Each is under 40 lines with an explicit boundary.

**Files Changed:**
- `AGENTS.md` — added "Per-Project Agent Guides" section with root-wins rule
- `apps/soar_score_server/AGENTS.md` — new
- `apps/soar_score_contest/AGENTS.md` — new
- `apps/soar_score_public/AGENTS.md` — new
- `packages/soar_score_core/AGENTS.md` — new
- `packages/soar_score_api/AGENTS.md` — new
- `packages/soar_score_api_handlers/AGENTS.md` — new
- `packages/soar_score_data_sqlite/AGENTS.md` — new
- `packages/soar_score_data_postgres/AGENTS.md` — new
- `packages/soar_score_ui/AGENTS.md` — new

**Verification:**
- `scripts/verify.ps1`: PASSED (bootstrap, format, analyze, test, build all passed)
