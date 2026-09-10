# Matrix and Assignments

## Matrix and draw

A matrix belongs to a contest and has revisions. A matrix revision records the draw configuration, participating pilot links, rounds, groups, lanes, random seed or reproducibility data, fairness result, creator, reason, and finalization state. A new draw never overwrites an earlier revision.

A round belongs to a matrix revision and has an ordinal round number. A group belongs to a round and has an ordinal group number. A group contains assignments for pilot participation links.

## Assignment history

An assignment records participant link, scheduled round, credited round, group, lane, assignment revision, assignment type (`Original`, `Moved`, or `Reflight`), source assignment, actor, reason, and timestamps. Scores reference the assignment and matrix revision that produced them.

Scheduled and credited rounds are separate so a later re-flight or move can receive credit for the original round without rewriting history.

## Re-flights

A re-flight record belongs to a contest and credited round. It records type, sequence, lifecycle status, reason, discipline/rules/calculation versions, creating and finalizing actors, awarded pilots, draw candidates and exclusions, selected pilots, participant responses, notifications, and the director's final decision. The discipline profile defines group-size, normalization, and result-selection rules; these are not generic contest fields.

## Invariants

- A score placeholder exists for every pilot assignment, even before a value is entered.
- A scored assignment cannot be silently moved or reinterpreted.
- Future unscored rounds may be added or revised only under the contest lifecycle and explicit matrix revision rules.
- Seeded draw mode may create later matrix revisions incrementally after prerequisite rounds are complete.
