# Ticket 021 — State Machine: Mid-Contest Draw Regeneration

- **Category:** Contest State Machine
- **Priority:** High
- **Status:** Open

## Context

If a pilot drops out after round 3, the remaining draw must be regenerated. The spec does not define how this interacts with existing matrix revisions and the draw engine.

## Questions

1. When a pilot drops out, is the draw regenerated only for future rounds, or must the entire matrix be re-optimized (which would change past rounds)?
2. If past rounds are unchanged, how does the draw engine handle the reduced pilot set for future rounds?
3. Can a new matrix revision be created that only covers rounds N+1 onward, while rounds 1–N retain their original revision?
4. How does the draw engine's history (pairwise meeting counts) account for the dropped pilot in future rounds?
5. What is the contest state during the re-draw — is the contest paused, or can it continue while the re-draw is computed?

## Decisions Needed

- Whether re-draws affect only future rounds or the entire matrix.
- The state transition for a mid-contest re-draw.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (incremental round generation)
- `plan/architecture-requirements/data/contest.md`
