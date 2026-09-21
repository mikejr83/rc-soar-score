# Ticket 036 — Business: Out-of-Bounds Landing Distance Measurement

- **Category:** Business Rules
- **Priority:** Low
- **Status:** Open

## Context

The F5J spec defines an out-of-bounds landing as "greater than 75 m from the pilot's landing marker." The measurement method and configurability are not specified.

## Questions

1. Is the 75 m measured from the landing marker (a specific point) or from the center of the landing zone?
2. Is it a straight-line (as-the-crow-flies) distance or along a defined path?
3. Is the 75 m distance configurable per contest, or a fixed rule?
4. How is the distance determined in practice — by the timer, the pilot, or a measurement tool?
5. Is the out-of-bounds determination made before or after score entry (i.e., can it be changed after the score is entered)?

## Decisions Needed

- The measurement method for out-of-bounds landings.
- Whether the distance threshold is configurable.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Out of Bounds Landing)
