# Agent Guide for Soar Score

This is the authoritative repository-wide guide for the Soar Score codebase. It is supplemented by `AGENTS.md` files in individual applications and packages (for example, `apps/soar_score_server/AGENTS.md` and `packages/soar_score_core/AGENTS.md`).

When instructions conflict, this root file wins. Per-project files define local package boundaries, folder layout, naming conventions, and targeted test/build commands. They must not override repository-wide conventions, requirements references, or toolchain pins defined here.

## Project Overview

Soar Score is an RC sailplane soaring contest scoring and management suite. It is a Dart monorepo managed with Melos, containing Flutter and Dart applications and shared packages, plus a Next.js public website in `apps/soar_score_web` (ADR 0005).

**Technology stack:** Flutter, Dart, Melos, Node.js 24 and npm (public website only).

## Environment Setup

Development requires Melos and Flutter (which includes Dart). The public website additionally uses Node.js 24 and npm.

## Graphify – Codebase Intelligence

Graphify is the primary tool for architectural discovery and code relationship exploration in this repository. Use it as the default starting point for non-trivial work when understanding components, dependencies, data flow, or potential change impact.

Graphify complements source inspection; it does not replace reading code, tests, or requirements.

### When to use Graphify

Use Graphify for:

- Bugs that may cross files, packages, or application boundaries.
- Features that interact with existing functionality.
- Changes to shared packages, models, services, repositories, or APIs.
- Tracing data flow, callers, dependencies, and downstream effects.
- Exploring unfamiliar areas of the codebase.
- Reviewing pull requests and assessing regression risk.
- Finding related tests and understanding how they connect to implementation.

Graphify is not required for trivial isolated edits, documentation-only changes, or mechanical changes where architectural exploration adds no meaningful value.

### Exploration expectations

For non-trivial tasks:

1. Check whether a graph is available for the current repository checkout and whether it is sufficiently up to date for the task.
2. Start with targeted graph queries before broad source searches or reading many files.
3. Use Graphify's query, explain, and path capabilities as appropriate to discover relevant components, understand symbols and their relationships, and trace connections between components.
4. Look for callers, downstream dependencies, shared packages, data flow, and related tests, including relationships across application/package boundaries.
5. Verify important findings against the actual source code and tests.
6. Use the findings when planning the change; do not query the graph merely to satisfy a checklist.

Use the Graphify skill, command, or integration actually available in the agent's environment. Follow that integration's current usage instructions; do not assume a tool or capability is installed when it is not.

### Trust and limitations

- Treat graph relationships as navigational evidence, not proof of runtime behavior or business correctness.
- Distinguish explicitly extracted relationships from inferred relationships. Treat inferred relationships as leads to verify.
- A missing graph edge does not prove that no dependency exists.
- Graphify does not replace source-code inspection, tests, or the requirements under `./plan`.

### Graph freshness and maintenance

- Refresh or rebuild the graph when it is missing, stale, or materially incomplete for the task.
- After switching branches or worktrees, check that the graph represents the current checkout before relying on it.
- Prefer incremental updates when supported; do not perform a full rebuild for every task.
- After substantial structural changes, update the graph when needed so later tasks have a useful representation.
- Follow repository conventions for generated artifacts. Do not commit generated graph data unless the repository explicitly requires it.

If Graphify is unavailable, continue with normal repository exploration and state the limitation when it materially affects the investigation. Never claim to have queried or verified the graph when it was not used.

For non-trivial tasks, briefly communicate the relevant relationships found, the likely impact area, and any important graph limitations. Keep the report proportional to the task.

## Development Conventions

1. **Path dependencies:** Shared packages use path-based dependencies in `pubspec.yaml`.
2. **JSON serialization:** Use `json_annotation` and `json_serializable` for data models.
3. **State management:** Follow Flutter best practices appropriate to the app.
4. **API design:** Server endpoints use RESTful conventions on the shelf-based server.
5. **Requirements:** `./plan` is the source of truth for business, architecture, and UI requirements. Consult the relevant documents before changing behavior.
6. **Architecture references:** Use `docs/architecture/page-map.md` to locate pages and routes, `docs/architecture/contest-app-architecture.md` for contest-app implementation details, and `docs/architecture/scoring-lifecycle.md` for score lifecycle invariants.

## Code Style and Linting

- Each project uses its root `analysis_options.yaml`.
- Flutter apps include `package:flutter_lints/flutter.yaml`; Dart CLI/API projects include `package:lints/recommended.yaml`.
- Keep files focused on their domain. Avoid placing many unrelated classes in one file, and keep test files manageable.

## Testing and Quality

- Tests live in `test/` directories within each app and package.
- Flutter apps use `flutter_test`; Dart CLI/API projects use `package:test`.
- Run `melos test` for the monorepo or the targeted `dart test` / `flutter test` command for the affected project.
- Run `melos analyze` for Dart/Flutter static analysis.
- The public website (`apps/soar_score_web`) is not managed by Melos; use its own npm scripts as documented in its `AGENTS.md`.

### End-to-end tests

- Contest-app E2E tests live in `apps/soar_score_contest/integration_test/` and run locally through `scripts/e2e-contest.ps1` or `scripts/e2e-contest.sh`. The `-d web` / `-Device web` option runs them in headless Chrome against a token-free test server. CI does not run these tests; `melos test` covers `test/` only.
- Keep contest-app E2E coverage current. After changing contest-app pages, routes, widget keys, visible labels, flows, or demo data, run the E2E suite and update the affected journeys in the same PR. Extend the matching phase of `contest_lifecycle_journey_test.dart` for lifecycle changes. Add a standalone `*_test.dart` only for a feature outside the lifecycle, and explain why in the PR. See `apps/soar_score_contest/AGENTS.md` for the allowed standalone files.
- Self-scoring E2E tests live in `apps/soar_score_self_score/integration_test/` and run through `scripts/e2e-score.sh` or `scripts/e2e-score.ps1`. Changes to its pages, flows, or widget labels must extend the matching journey phase in the same PR. See `apps/soar_score_self_score/AGENTS.md`.

## Business and Architecture Requirements

- `./plan` contains the business, architecture, and UI requirements. Consult the relevant documents when determining intended behavior.
- Persistent schema changes require a new schema version and a data-preserving, transactional migration.
- Keep versioned SQLite and PostgreSQL schema snapshots and test upgrades, rollback, and compatibility as described in `packages/soar_score_data/AGENTS.md`.
- Never require deleting a user's database to upgrade.
- When changing score submission, officialization, promotion, recalculation, or synchronization, follow `docs/architecture/scoring-lifecycle.md` and the applicable requirements under `./plan`.

## CI/CD and Toolchain

The GitHub Actions workflow is `.github/workflows/ci.yml` (owned by ticket 011). It runs on push/PR to `master` and performs dependency installation, analysis, tests, and builds.

The public website (`apps/soar_score_web`) has a separate `public-site` job that runs `npm ci`, lint, test, and build. Melos does not manage this app.

Documentation-only changes skip CI. The workflow's `paths-ignore` includes `plan/**`, `docs/**`, `**/*.md`, `LICENSE`, `.prettierrc`, `.prettierignore`, `.gitignore`, `.mcp.json`, `.agents/**`, `.kilo/**`, `.vscode/**`, `.github/CODEOWNERS`, and `.github/ISSUE_TEMPLATE/**`. A docs-only PR showing no checks is expected.

**Toolchain pins** are recorded in `plan/tickets/mvp-implementation/001-setup-toolchain-baseline.md`, which is the source of truth. CI must not drift from it:

- Flutter 3.50.x (stable channel)
- Dart bundled with Flutter (3.14.x current; no independent pin)
- Melos 8.x
- Node.js 24 and npm for the public website

## Work Tracking

Planned work is tracked in GitHub issues (milestones M0 to M5, epic parent issues with sub-issues, and `area:`, `type:`, `priority:`, and `size:` labels). Do not add ticket files under `plan/tickets/`; those are historical. `./plan` remains the source of truth for requirements. See `CONTRIBUTING.md`.

## Commit Messages

Use the [Conventional Commits](https://www.conventionalcommits.org) specification:

```text
<type>(<optional scope>): <short summary>

[optional body: explain what and why]

[optional footer(s): BREAKING CHANGE: ..., Closes #123]
```

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Scope is optional. Use the affected app or package directory name, for example `feat(contest-app):`, `fix(server):`, or `refactor(soar_score_core):`.
- Use the imperative mood in present tense (`add`, `fix`, `remove`), keep the summary under 72 characters, and omit the trailing period.
- The optional body explains what and why, not how.
- Optional footers reference issues (`Closes #123`, `Ref: #456`) and breaking changes.

## Markdown Formatting

- All Markdown must conform to the repository's Prettier configuration (`.prettierrc`). Do not hand-format against it.
- After creating or editing any `.md` file, run `npx prettier --write <file>` and keep the result.
- Before finishing a task, run `npx prettier --check "**/*.md"` and fix failures.
- Never disable or edit Prettier configuration or `.prettierignore` to make a check pass.
- Use `-` for bullets, `1.` for ordered lists, and `_emphasis_` / `**strong**`.
- Use one blank line between blocks, no trailing whitespace, and one final newline. Tables must be column-aligned by Prettier. Do not hard-wrap prose unless the config's `proseWrap` setting requires it.

## Demo Data

The demo database (`packages/soar_score_data/lib/seeding/demo/`) must continue to demonstrate every feature for which it has data.

A PR that adds or changes a model, repository, or service usable by the demo must update the demo seeder, or add the repository to the exemptions in `packages/soar_score_data/test/seeding/demo_coverage_test.dart` with a reason and the issue that will bring it into the demo. That test fails for a repository that is neither seeded nor exempt. Open items are tracked in #305.

## Architecture Documentation Maintenance

Keep the architecture references current:

- Update `docs/architecture/page-map.md` when a page or route is added, renamed, or moved.
- Update `docs/architecture/contest-app-architecture.md` when contest-app implementation structure or documented behavior changes materially.
- Update `docs/architecture/scoring-lifecycle.md` when score lifecycle rules or invariants change.
