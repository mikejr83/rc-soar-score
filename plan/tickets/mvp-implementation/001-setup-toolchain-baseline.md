# Ticket 001 — Toolchain and Version Baseline

- **Category:** Setup
- **Priority:** High
- **Status:** Done

## Context

`plan/implementation-plan.md` references Dart and Flutter for implementation. Every other setup ticket (workspace, apps, packages, CI) depends on agreeing on the toolchain versions first.

This ticket is **ticket-level recording only**: it records the toolchain version lines; it creates no workspace, CI, or project artifacts.

Pinning convention: pins are version **lines** (major / maintenance track), not patch versions. Consumers of these pins (tickets 014, 011, 013) install the latest patch within the recorded line at consumption time. If a recorded line goes stale, the escalation rule in `plan/tickets/mvp-implementation/README.md` applies: update this ticket first, then anything that references it.

## Recorded Pins (verified 2026-09-22)

| Tool | Pinned line | Verified against |
| ---- | ----------- | ---------------- |
| Flutter | 3.47.x (stable channel) | `flutter --version` → 3.47.4 stable, released 2026-09-10 |
| Dart | Bundled with Flutter (no independent pin) | Dart 3.13.3 bundled with Flutter 3.47.4 |
| Melos | 8.x | pub.dev `melos` latest 8.9.0, published 2026-09-22; requires Dart ≥ 3.9, satisfied |

Node.js and NX are no longer part of the toolchain (ticket 002 rejected); the Playwright line was dropped with ticket 012 (rejected).

## Work Items

- [x] Identify and record the current stable version lines to pin (recorded in the table above).
- [x] Add a short "Toolchain pins" section to `plan/implementation-plan.md` listing the recorded lines and pointing at this ticket as the source of truth. Package/dependency version decisions stay with the scaffold tickets.
- [x] Update `AGENTS.md`'s CI/CD section to reference the lines recorded here.

Not owned by this ticket:

- Set up of the workspace or projects.

## Acceptance Criteria

- [x] Pinned version lines (Flutter/Dart and Melos — Node/NX are no longer used; ticket 002 was rejected) are recorded in this ticket and are the single source of truth for tickets 014, 011, and 013.
- [x] `plan/implementation-plan.md` references the pinned toolchain lines.
- [x] `AGENTS.md`'s CI/CD section references the lines recorded here, not a stale patch-level version.
- [ ] Tickets 014 and 011 consume these lines without re-deciding version granularity (line pins; latest patch of the line at consumption time) — not verifiable yet: tickets 014 and 011 are still `Open`; this criterion is satisfied at their consumption time.

## Files changed

- `plan/tickets/mvp-implementation/001-setup-toolchain-baseline.md` — recorded pins, pinning convention, work items and acceptance criteria checked.
- `plan/implementation-plan.md` — "Toolchain pins" table extended with the Melos 8.x line.
- `AGENTS.md` — CI/CD section updated to reference the recorded lines (ticket 001 as source of truth).

## Follow-ups

- Melos 8 removed the standalone `melos.yaml` (config now lives in the root `pubspec.yaml` under `workspace:`/`melos:` keys). Ticket 014's work items were written for a pre-8 `melos.yaml`; reconcile when executing 014.
- The folder README index row for this ticket still reads "Done" (left over from the earlier NX→Melos migration); align it with the status recorded here when the index is next updated.

## Dependencies

- None (first ticket in the series).

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
- `plan/tickets/mvp-implementation/README.md` (pin escalation rule)
