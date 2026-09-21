# Ticket 017 — Access: Helper Role Capabilities

- **Category:** Access / Permissions
- **Priority:** High
- **Status:** ready
- **Depends on:** ticket 001 (team membership cardinality), ticket 018 (pilot vs helper conflict).
- **Decision:** Helper mobile self-scoring access is team-scoped (a non-flier helper link can select and enter raw score components only for pilots on their assigned team, or assigned pilot list if teams are not enabled); helpers have standard participant read visibility (matrix assignments, group results, placements, and team standings within permitted privacy rules); administrative actions (granting re-flights, applying penalties, redrawing rounds, official score overrides) are strictly director-only.

## Context

Helpers (non-fliers, timers, callers, team managers) participate in soaring contests to assist pilots. The exact capability boundary between a helper's mobile self-scoring interface and director administration must be unambiguous for UI and API authorization guards.

## Questions

1. **~~Can a helper enter scores for any group, or only their assigned group?~~** — **Resolved: Team-scoped (Decision 1).** When teams are enabled, a helper link can enter scores only for pilots belonging to the helper's team. If teams are disabled, helper links can be assigned to a specific pilot or list.
2. **~~Can a helper see the overall standings, or only their group's scores?~~** — **Resolved: Standard participant visibility (Decision 2).** Helpers see preliminary group results, matrix assignments, and overall standings identical to pilot participants.
3. **~~Can a helper edit a score that has already been confirmed by the pilot?~~** — **Resolved: Read-only once submitted (Decision 3).** Once any valid score is submitted (by pilot or helper), the score becomes read-only and requires a formal Score Review Request to modify (per ticket 018).
4. **~~Can a helper see the matrix (group assignments) for all rounds, or only the current round?~~** — **Resolved: All drawn rounds (Decision 2).** Matrix assignments for all drawn rounds are visible to helpers to assist with flight preparation and timing.
5. **~~Can a helper request a re-flight, or is that a director-only action?~~** — **Resolved: Director-only (Decision 4).** Re-flight issuance, penalties, and draw adjustments are strictly director actions. A helper may only submit a Score Review Request if enabled.

## Decisions Needed

- (All resolved — see Decisions.)

## Decisions

- **Team-Scoped Score Entry (Decision 1):** A helper's mobile invitation link resolves to their participant non-flier record and team association. The helper UI provides a pilot selector filtered exclusively to pilots on the helper's team (or assigned pilot list). Submissions targeting unauthorized pilots are rejected by the API. (2026-09-21)
- **Standard Participant Visibility (Decision 2):** Helpers have read-only access to matrix assignments across all drawn rounds, preliminary group results, and cumulative standings, subject to standard participant privacy rules (private emails and credentials stripped). (2026-09-21)
- **Score Read-Only Lock & Dispute Flow (Decision 3):** Submitting a score (whether by helper or pilot) transitions the assignment to `Submitted`. Once submitted, the interface becomes read-only for both helper and pilot. Subsequent adjustments must go through the standard `Score Review Request` flow. (2026-09-21)
- **Administrative Guard (Decision 4):** Helpers have zero offline administrative authority. They cannot issue penalties, grant re-flights, lock/unlock rounds, publish snapshots, or perform draw operations. Local operators assisting the director on the primary administration device act directly under the director's authenticated session, not as independent helper accounts. (2026-09-21)

## Acceptance Criteria

- [ ] Helper mobile invitation links restrict score-entry selection exclusively to pilots on the helper's assigned team (or assigned pilot list).
- [ ] API rejects score submission attempts by a helper if the targeted pilot is outside the helper's authorized team scope.
- [ ] Helpers can view round matrix assignments, group scoreboards, and standings matching the pilot participant view.
- [ ] Once a score is accepted from either the pilot or helper, the score form displays in a read-only state for both users.
- [ ] Helpers cannot access contest administration controls (re-flight draw, manual draw adjustments, director penalties, contest state transitions).

## Sources

- `plan/architecture-requirements/self-scoring-invites.md`
- `plan/architecture-requirements/participant-score-entry.md`
- `plan/architecture-requirements/data/teams-roles-models.md`
- `plan/ui/participant-scoring/participant-scoring.md`
- `plan/tickets/pre-implementation/018-access-pilot-helper-score-conflict.md`
