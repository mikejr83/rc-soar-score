# Ticket 001 — Toolchain and Version Baseline

- **Category:** Setup
- **Priority:** High
- **Status:** Done

## Context

`plan/implementation-plan.md` references Node and Flutter for implementation. Every other setup ticket (workspace, apps, packages, CI) depends on agreeing on the toolchain versions first.

Pinning convention (decided 2026-09-22): this ticket records version **lines** (major / maintenance track), not exact patch versions. Consumers of these pins (tickets 002, 011, 012) install the latest patch within the recorded line. If a recorded line goes stale, the escalation rule in `plan/tickets/mvp-implementation/README.md` applies: update this ticket first, then anything that references it.

This ticket is **ticket-level recording only**: it creates no `.nvmrc`, `package.json`, or CI config. Those repo artifacts are owned by tickets 002 and 011 and consume the lines recorded here.

## Recorded Pins (verified 2026-09-22)

| Tool | Pinned line | Verified against |
| ---- | ----------- | ---------------- |
| Node.js | 24 (current active LTS) | nodejs.org `latest-v24.x` listing (24.21.0 released 2026-09-08) |
| Flutter | 3.47.x (stable channel) | `flutter --version` → 3.47.4 stable (released 2026-09-10) |
| NX | 23 (current stable major) | npm `nx` dist-tags: latest 23.2.1, previous stable major 22 |
| Dart | Bundled with Flutter (no independent pin) | Dart 3.13.3 bundled with Flutter 3.47.4 |
| Playwright | 1.x | npm `playwright` latest 1.63.0 |

## Work Items

- [x] Identify and record the current stable version lines to pin (recorded in the table above, verified 2026-09-22).
- [x] Add a short "Toolchain pins" section to `plan/implementation-plan.md` listing the recorded lines and pointing at this ticket as the source of truth. Package/dependency version decisions stay with the scaffold tickets (002–012).
- [x] Update `AGENTS.md`'s CI/CD section (currently `Uses ubuntu-latest, Node LTS, Flutter 3.47.0`) to reference the lines recorded here instead of the stale patch-level reference.

Not owned by this ticket:

- Root `.nvmrc`, root `package.json` (`engines`, NX version), CI config → tickets 002 and 011.
- Root `.gitignore` (Dart, Flutter, NX, Node generated artifacts) → ticket 002.
- Playwright setup details → ticket 012, which consumes the 1.x line recorded here.

## Acceptance Criteria

- [x] Pinned version lines (Node, Flutter, NX, Dart, Playwright) are recorded in this ticket and are the single source of truth for tickets 002, 011, and 012.
- [x] `plan/implementation-plan.md` references the pinned toolchain lines.
- [x] `AGENTS.md`'s CI/CD section references the lines recorded here, not a stale patch-level version.
- [x] Tickets 002 and 011 consume these lines without re-deciding version granularity (line pins; latest patch of the line at consumption time).

## Dependencies

- None (first ticket in the series).

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
- `plan/tickets/mvp-implementation/README.md` (pin escalation rule)
