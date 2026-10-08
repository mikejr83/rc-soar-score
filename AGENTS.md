# Agent Guide for Soar Score

This document is the primary source of truth for the Soar Score codebase. It is supplemented by per-project `AGENTS.md` files located in each `apps/` and `packages/` directory (e.g., `apps/soar_score_server/AGENTS.md`, `packages/soar_score_core/AGENTS.md`). When a convention in this root file conflicts with a per-project file, **this root file wins**.

Per-project files should be read for:

- Package-specific boundary constraints (what must NOT be imported or depended on)
- Folder layout and naming conventions unique to that subproject
- Targeted test and build commands

Per-project files should NOT override:

- Shared code style or linting rules (use root `analysis_options.yaml`)
- Business requirement references (always consult `./plan`)
- Version or toolchain pins (see root CI section)

## Project Overview

Soar Score is an RC sailplane soaring contest scoring and management suite. It consists of multiple Flutter and Dart applications and shared packages, all managed by Melos in a Dart monorepo.

**Tech Stack:**

- Flutter
- Dart
- Melos

## Environment Setup

**Prerequisites:**

- Melos
- Flutter (includes Dart)

## Testing Conventions

- Tests are located in `test/` directories within each app and package
- Flutter apps use `flutter_test` package
- Dart CLI/API projects use `test` package
- Run with: `melos test` or directly with `dart test` / `flutter test`

## Code Style & Linting

- All projects use `analysis_options.yaml` at their root
- Flutter apps include `package:flutter_lints/flutter.yaml`
- Dart CLI projects include `package:lints/recommended.yaml`
- Run `melos analyze` to check

## CI/CD

- GitHub Actions workflow in `.github/workflows/ci.yml` (owned by ticket 011)
- Runs on push/PR to `master`
- Documentation-only changes skip the workflow entirely (`paths-ignore` covers `plan/**`, `docs/**`, `**/*.md`, `LICENSE`, `.prettierrc`, `.prettierignore`). A docs-only PR showing no checks is expected, not a CI problem.
- Steps: install deps → analyze → test → build

**Toolchain pins** (recorded in `plan/tickets/mvp-implementation/001-setup-toolchain-baseline.md`, which is the source of truth — CI must not drift from it):

- Flutter 3.47.x (stable channel)
- Dart: bundled with Flutter (3.13.x current, no independent pin)
- Melos 8.x

## Important Conventions

1. **Path dependencies**: All shared packages use path-based dependencies in `pubspec.yaml`
2. **JSON serialization**: Use `json_annotation` and `json_serializable` for data models
3. **State management**: Follow Flutter best practices for the specific app
4. **API design**: RESTful endpoints on shelf-based server

## Formatting

### Markdown

- All Markdown files must conform to the repo's Prettier config (`.prettierrc`). Do not hand-format against it.
- After creating or editing any `.md` file, run `npx prettier --write <file>` and keep the result.
- Before finishing a task, run `npx prettier --check "**/*.md"` and fix any failures.
- Never disable or edit Prettier config or `.prettierignore` to make a check pass.
- Use `-` for bullets, `1.` style for ordered lists, and `_emphasis_` / `**strong**`.
- One blank line between blocks; no trailing whitespace; file ends with a single newline.
- Tables must be column-aligned (Prettier will realign them; just run it).
- Do not hard-wrap prose unless `proseWrap` is set in the config.

## Work Tracking

Planned work is tracked in GitHub issues (milestones M0 to M5, epic parent issues with sub-issues, `area:`, `type:`, `priority:` and `size:` labels). Do not add ticket files under `plan/tickets/`; those are historical. `./plan` remains the source of truth for requirements. See `CONTRIBUTING.md`.

## Business and Architecture Requirements

Documentation is provided in the `./plan` folder. This contains business, architecture, and ui requirements. Consult this documentation when determining the best course of action for implementing business logic.

## Getting Help

- Review `analysis_options.yaml` for linting rules
- Consult Flutter documentation: https://docs.flutter.dev/
- Consult Dart documentation: https://dart.dev/
- Consult Melos documentation: https://melos.invertase.dev/commands

## Style guidelines

When creating files keep them targeted to the domain at hand. Do not place many classes in a single file. Test case files should be broken into manageable sizes.
