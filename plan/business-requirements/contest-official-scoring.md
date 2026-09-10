# RC Soar Score Business Requirements

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. The application will provide the ability for contest directors or officials to enter scores for pilots.

This document covers administrative score entry. It differs from self-entered scoring because officials work on a complete group within a round and may correct scores under the contest director's authority.

## Administrative scoring

- The scoring view selects a round and group and shows every assigned pilot, including unentered placeholders.
- The grid shows the configured pilot/lane number, team, pilot name, discipline fields, raw score, group score, penalty, participant-submission indicator, and pending-review indicator.
- The official may enter or correct raw components only when lifecycle, administration lock, score lock, and matrix-assignment rules permit it. Every correction creates an auditable official revision.
- A score check reports missing entries and configurable out-of-range values without silently changing data.
- The official may mark accepted rows official and lock a group, round, or contest. A lock prevents participant changes and later corrections at that scope until an authorized unlock or correction workflow is applied.
- Time entry accepts the compact forms defined by the UI requirements, including locale-aware decimal separators.

Administrative entry is authoritative over a concurrent participant submission, but the participant submission remains retained as a historical or silent-review record. Derived values are recalculated by the scoring service from immutable raw components.
