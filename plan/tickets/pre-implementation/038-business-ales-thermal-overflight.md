# Ticket 038 — Business: ALES/Thermal Target-Time Over-Flight

- **Category:** Business Rules
- **Priority:** Medium
- **Status:** Open

## Context

`discipline-scoring.md` states that ALES and Thermal tests must cover "target-time over-flight, the one-minute over-flight boundary." The exact behavior is not specified in the business requirements.

## Questions

1. In ALES/Thermal, what happens when a pilot overflies the target time — is the time capped at the target (like F5J's working time), or is there a penalty?
2. What is the one-minute over-flight boundary — can the pilot land up to 1 minute after the target time expires?
3. If the pilot lands within the one-minute boundary, is the time capped at the target or at the actual landing time?
4. Does the landing bonus apply if the pilot lands within the one-minute boundary?
5. How does the over-flight rule differ between ALES and Thermal?

## Decisions Needed

- The over-flight rule for ALES and Thermal.
- The one-minute boundary behavior and its effect on landing bonus.

## Sources

- `plan/architecture-requirements/discipline-scoring.md` (test requirements, ALES/Thermal)
- `plan/business-requirements/disciplines/` (ALES, Thermal)
