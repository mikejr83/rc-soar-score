# Ticket 001 — Toolchain and Version Baseline

- **Category:** Setup
- **Priority:** High
- **Status:** Open

## Context

`plan/implementation-plan.md` references Dart and Flutter for implementation. Every other setup ticket (workspace, apps, packages, CI) depends on agreeing on the toolchain versions first.

This ticket is **ticket-level recording only**.

## Work Items

- [] Identify and record the current stable version lines to pin.
- [] Add a short "Toolchain pins" section to `plan/implementation-plan.md` listing the recorded lines and pointing at this ticket as the source of truth. Package/dependency version decisions stay with the scaffold tickets.
- [] Update `AGENTS.md`'s CI/CD section to reference the lines recorded here.

Not owned by this ticket:

- Set up of the workspace or projects.

## Acceptance Criteria

- [] Pinned version lines (Flutter/Dart and Melos — Node/NX are no longer used; ticket 002 was rejected) are recorded in this ticket and are the single source of truth for tickets 014, 011, and 013.
- [] `plan/implementation-plan.md` references the pinned toolchain lines.
- [] `AGENTS.md`'s CI/CD section references the lines recorded here, not a stale patch-level version.
- [] Tickets 014 and 011 consume these lines without re-deciding version granularity (line pins; latest patch of the line at consumption time).

## Dependencies

- None (first ticket in the series).

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
- `plan/tickets/mvp-implementation/README.md` (pin escalation rule)
