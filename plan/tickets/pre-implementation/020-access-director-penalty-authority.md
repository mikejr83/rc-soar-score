# Ticket 020 — Access: Director Penalty and Disqualification Authority

- **Category:** Access / Permissions
- **Priority:** Low
- **Status:** Decided
- **Decision:** Only the contest director (or a local operator acting under the director's authority) issues a cumulative penalty, unilaterally and with a recorded reason, as an official-score revision that may follow a pilot's confirmation. Disqualification is **not** a feature of the first release: it has no outcome value, no contest-level overlay and no generic zero reason. A director who needs to void a flight records an official zero with a reason, using the zero reasons the discipline defines. (Option A, 2026-10-04.)

## Context

The authority to issue a director penalty or disqualification was not explicitly defined.

## Questions

1. ~~Can only the contest director issue a penalty or disqualification, or can a delegate director also do so?~~ **Resolved:** only the contest director, or a local operator acting under the director's authority on the director's installation. There is no separate delegate role. Helpers and participants cannot, and the service rejects a participant submission or review proposal that sets a cumulative penalty ([scores-and-results.md](../../architecture-requirements/data/scores-and-results.md)).
2. ~~Is there an approval workflow (e.g., a second official must confirm), or is it unilateral?~~ **Resolved:** unilateral. No approval workflow.
3. ~~Can a penalty be issued after a score is confirmed by the pilot?~~ **Resolved:** yes. A penalty is an official-score revision with a required reason, so the earlier value, the actor and the time stay in the audit trail ([official_score.md](../../data-model/entities/official_score.md)).
4. How is a penalty surfaced to the pilot — is there a notification, or is it only visible in the score breakdown? **Not decided.** The model records the penalty in the score breakdown and the audit trail and does not define a notification. It does not affect any field, so it is left to the participant-scoring UI work.

## Decisions

1. **Authority.** As in questions 1 to 3 above.
2. **Disqualification is out of scope for the first release (Option A).**
   - No disqualified outcome value is added. The outcome values stay as decided in ticket 012 (`NOT_ENTERED`, `ZERO`, `RETIRED`).
   - `ContestParticipation` gets no disqualification field. Retirement (`retired_at_round`) is unchanged.
   - No generic "disqualified" zero reason is added to the discipline model.
   - Results do not show a disqualification label. A voided flight shows as a zero with its recorded reason.
3. **Consequence for the data model.** None. This ticket adds no entity, column or enum value, so it does not block tickets 035 and 036.
4. **Revisit.** If disqualification is wanted later, the two candidate designs are a flight-level generic zero reason, which needs no table change, and a contest-level overlay on `ContestParticipation`, which adds a nullable column plus calculation, standings, team-score and publication rules. Either would arrive as an additive migration and, for offline installations, rely on the schema versioning in ticket 037.

## Status

- Decided. Question 4 (pilot notification) remains for the UI work and is not blocking.

## Sources

- `plan/business-requirements/managing-system.md`
- `plan/architecture-requirements/data/scores-and-results.md`
- `plan/data-model/entities/official_score.md`
- `plan/tickets/pre-implementation/012-data-score-status-enum.md`
- [data-model-triage.md](data-model-triage.md)
