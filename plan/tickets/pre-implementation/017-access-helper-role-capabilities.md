# Ticket 017 — Access: Helper Role Capabilities

- **Category:** Access / Permissions
- **Priority:** High
- **Status:** Open

## Context

The helper role's capabilities are not explicitly defined in the business requirements. It is assumed helpers can enter scores, but the scope of what they can see and do is unclear.

## Questions

1. Can a helper enter scores for any group, or only their assigned group?
2. Can a helper see the overall standings, or only their group's scores?
3. Can a helper edit a score that has already been confirmed by the pilot?
4. Can a helper see the matrix (group assignments) for all rounds, or only the current round?
5. Can a helper request a re-flight, or is that a director-only action?

## Decisions Needed

- The full capability matrix for the helper role.
- Whether helpers have read access beyond their assigned group.

## Sources

- `plan/business-requirements/managing-system.md`
- `plan/ui/participant-scoring/`
