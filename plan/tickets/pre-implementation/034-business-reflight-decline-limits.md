# Ticket 034 — Business: Re-Flight Decline Limits

- **Category:** Business Rules
- **Priority:** Medium
- **Status:** Decided
- **Decision:** Declines are unlimited; the draw ends when the group fills or the pool is exhausted, which cancels the re-flight and keeps the original score. (2026-10-04)

## Context

Re-flight priority 2 allows a randomly selected competitor to decline. The F5J spec says "the draw is repeated until the group is filled" and "if a group cannot be filled, the priority moves to the next." The maximum number of declines before giving up is not defined.

## Questions

1. ~~What is the maximum number of declines before the re-flight group is abandoned?~~ **Resolved: no fixed number.** The draw repeats until the group is filled; if the pool is exhausted and the group cannot be filled, the re-flight is cancelled and the director moves on to the next method ([re_flight.md](../../data-model/entities/re_flight.md)).
2. ~~If all remaining pilots decline, is the re-flight cancelled, or is the original score kept?~~ **Resolved:** the re-flight is cancelled. A re-flight never overwrites the original attempt, and cancelling never removes historical scores or responses.
3. ~~Can the same pilot be selected multiple times in the random draw if they decline?~~ **Resolved: no.** A drawn pilot who declines becomes `Excluded` with reason `Declined`, and the declined row stays in the history ([re_flight_participant.md](../../data-model/entities/re_flight_participant.md)).
4. ~~Is there a time limit for a pilot to accept or decline?~~ **Resolved: none in the first release.** Offers, responses and notifications are optional, and the director can finalize the group without an acknowledgement, including while offline. A director can record a decline or acceptance on the pilot's behalf.
5. ~~How does the decline history affect subsequent re-flights?~~ **Resolved: it does not.** A decline is recorded on that re-flight's participant row and audited. Eligibility for any later draw is decided only by the discipline and contest configuration.

## Decisions

- Declines are unlimited and end only when the group fills or the pool is exhausted, which cancels the re-flight. Declines are recorded on `ReFlightParticipant` and audited.
- No schema impact.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Re-Flights, priority 2)
- `plan/business-requirements/disciplines/f3j.md` (Re-Flights)
