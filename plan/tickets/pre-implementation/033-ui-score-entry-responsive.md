# Ticket 033 — UI: Responsive Layout for Score Entry

- **Category:** UI / UX
- **Priority:** Medium
- **Status:** Decided
- **Decision:** Official score entry targets tablet and desktop, with phone as a stretch goal. It uses standard Material 3 window size classes, a single page with a stacked-card fallback on compact widths, and numeric keypads for time and whole numbers. See [ADR 0002](../../../docs/adr/0002-score-entry-layout.md) and issue #82.

## Context

Score entry is the most interaction-heavy page (time, altitude, landing, late-landing, motor-restart, out-of-bounds). The target device and responsive layout are not specified.

## Questions

1. What is the target device for score entry — tablet, phone, or both?
2. On phone, does the form stack vertically, or is a compact/stepped layout used?
3. Are there specific breakpoints (e.g., below 480px) where the layout changes?
4. Is the score entry form a single page or a multi-step wizard?
5. Are there device-specific input types (e.g., numeric keyboard for time and altitude)?

## Decisions Needed

- Target devices and responsive breakpoints for score entry.
- The form layout (single page vs. multi-step).

## Sources

- `plan/ui/participant-scoring/`
