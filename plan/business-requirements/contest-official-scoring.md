# RC Soar Score Business Requirements

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. The application will provide the ability for contest directors or officials to enter scores for pilots.

This document covers administrative score entry. It differs from self-entered scoring because officials work on a complete group within a round and may correct scores under the contest director's authority.

## Administrative scoring

- The scoring view selects a round and group and shows every assigned pilot, including unentered placeholders.
- The grid shows the configured pilot/lane number, team, pilot name, discipline fields, raw score, group score, penalty, participant-submission indicator, and pending-review indicator.
- The official may enter or correct raw components only when lifecycle, administration lock, score lock, and matrix-assignment rules permit it. Every correction creates an auditable official revision.
- The contest director may enter or correct the Flight Penalty that goes with a flight's score, the same as any other raw component. It is part of the round score and is dropped with the round.
- The contest director may apply a Cumulative Penalty to a flight, entered as a whole number of points in the penalty column. Official discipline information may guide it, but it is the director's judgement. No penalty applied is different from a penalty that was applied and later removed (zeroed out). The penalty is deducted from the pilot's total at the end of the contest, is never dropped with its round, and still counts if the flight is re-flown. The director removes a penalty by zeroing it through an official correction. Results show the flight in which the penalty was given and sum the penalties in the total.
- A score check reports missing entries and configurable out-of-range values without silently changing data.
- The official may mark accepted rows official and lock a group, round, or contest. A lock prevents participant changes and later corrections at that scope until an authorized unlock or correction workflow is applied.
- Time entry accepts the compact forms defined by the UI requirements, including locale-aware decimal separators.

Administrative entry is authoritative over a concurrent participant submission, but the participant submission remains retained as a historical or silent-review record. Derived values are recalculated by the scoring service from immutable raw components.
