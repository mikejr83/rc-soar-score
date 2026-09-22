# Ticket 001 — Toolchain and Version Baseline

- **Category:** Setup
- **Priority:** High
- **Status:** Open

## Context

`plan/implementation-plan.md` references Dart and Flutter for implementation. Every other setup ticket (workspace, apps, packages, CI) depends on agreeing on the toolchain versions first.

Pinning convention (decided 2026-09-22): this ticket records version **lines** (major / maintenance track), not exact patch versions. Consumers of these pins (tickets 002, 011, 012) install the latest patch within the recorded line. If a recorded line goes stale, the escalation rule in `plan/tickets/mvp-implementation/README.md` applies: update this ticket first, then anything that references it.

This ticket is **ticket-level recording only**.

## Work Items

- [] Identify and record the current stable version lines to pin.
- [] Add a short "Toolchain pins" section to `plan/implementation-plan.md` listing the recorded lines and pointing at this ticket as the source of truth. Package/dependency version decisions stay with the scaffold tickets.
- [] Update `AGENTS.md`'s CI/CD section (currently `Uses ubuntu-latest, Node LTS, Flutter 3.47.0`) to reference the lines recorded here instead of the stale patch-level reference.

Not owned by this ticket:

- Set up of the workspace or projects.

## Acceptance Criteria

- [] Pinned version lines are recorded in this ticket and are the single source of truth for tickets 002, 011, and 012.
- [] `plan/implementation-plan.md` references the pinned toolchain lines.
- [] `AGENTS.md`'s CI/CD section references the lines recorded here, not a stale patch-level version.
- [] Tickets 002 and 011 consume these lines without re-deciding version granularity (line pins; latest patch of the line at consumption time).

## Dependencies

- None (first ticket in the series).

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
- `plan/tickets/mvp-implementation/README.md` (pin escalation rule)
