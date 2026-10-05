# ADR 0002: Score entry layout for the contest administration app

- Status: accepted
- Date: 2026-10-05
- Decision issue: #82

## Context

Score entry is the most interaction-heavy screen (time, altitude, landing, late landing, motor restart, out of bounds). The plan already says official scoring targets tablet and larger screens and participant scoring is mobile-first. What was open was the phone story, breakpoints, page structure and input types.

## Decision

This decision covers official score entry in the contest administration app, used by a contest director or local operator.

- **Target devices:** tablet and desktop. Phone is a stretch goal; it must be usable but is not optimized.
- **Breakpoints:** the standard Material 3 window size classes (compact below 600dp, medium 600 to 839dp, expanded 840dp and up). There are no custom breakpoints. Following Material 3 is expected to make the screen reasonably usable on phones.
- **Structure:** a single page showing one complete group for one round as a grid, as described in `plan/ui/contest-administration/official-scoring.md`. There is no multi-step wizard. On compact widths the grid becomes a stacked card per pilot, with the same fields and actions.
- **Input types:**
  - Time uses a numeric keypad and the compact parse (`630` means 6:30, `630.4` means 6:30.4). The parsed value is displayed.
  - Launch height and other whole numbers use a numeric keypad with no decimal separator.
  - Landing is a segmented or chip choice from the selected landing table.
  - Late landing, motor restart, out of bounds and no altitude recorded are toggles. Existing zeroing and disabling rules in the discipline documents still apply.

Participant self-scoring is not changed by this decision. It stays mobile-first with large, high-contrast controls.

## Consequences

- The M1 F5J score entry screen is built tablet-first with Material 3 adaptive layout, and compact support comes from the same components.
- A phone-optimized director experience, if wanted later, is a separate decision.
