# Ticket 004 — Configuration Override Scope

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** Open

## Context

`disciplines-and-configuration.md` says "an override is linked to the official profile and never mutates the shared profile." The granularity of an override is not specified.

## Questions

1. What is the granularity of a configuration override — per-contest, per-round, or per-discipline-setting?
2. Can a contest override just one setting (e.g., height-penalty rate) while inheriting all others from the shared profile?
3. How are conflicting overrides resolved if multiple apply (e.g., a contest-level and a round-level override for the same setting)?
4. Does an override create a new calculation revision even if it doesn't change any score values?

## Decisions Needed

- Override scope model (which levels, how they compose, how they are stored).
- Whether and how overrides trigger recalculation.

## Sources

- `plan/architecture-requirements/data/disciplines-and-configuration.md`
