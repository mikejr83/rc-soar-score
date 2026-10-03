# Matrix and Assignments

## Matrix and draw

A matrix belongs to a contest and has revisions. A matrix revision records the draw configuration, participating pilot links, rounds, groups, lanes, random seed or reproducibility data, fairness result, creator, reason, and finalization state. A new draw never overwrites an earlier revision.

A round belongs to a matrix revision and has an ordinal round number. A group belongs to a round and has an ordinal group number. A group contains assignments for pilot participation links.

## Assignment history

An assignment records participant link, scheduled round, credited round, group, lane, assignment revision, assignment type (`Original`, `Moved`, `Reflight`, or `LateAdd`), source assignment, actor, reason, and timestamps. Scores reference the assignment and matrix revision that produced them.

Scheduled and credited rounds are separate so a later re-flight or move can receive credit for the original round without rewriting history.

## Late additions

A pilot may arrive after the draw. Once a score exists the draw is locked, so the pilot is added with `LateAdd` assignments in groups that have not yet flown, in the current or later rounds. A `LateAdd` may be credited to a round the pilot missed, so a pilot can make up missed rounds by flying more than once, in different groups, at the contest director's discretion. The score is normalized against the group actually flown and credited to the missed round. A round for which the pilot has no assignment counts as not entered.

A group accepts a late addition only while it holds fewer pilots than the largest group size of the round's original draw. If no group in the remaining rounds has space, the pilot is not added and the director is told. The application may offer to redraw the later unscored rounds, but a redraw is always the director's decision, because printed matrix cards for those rounds must be reprinted. Cards for rounds that are not redrawn remain valid.

## Re-flights

A re-flight record belongs to a contest and credited round. It records type, sequence, lifecycle status, reason, discipline/rules/calculation versions, creating and finalizing actors, awarded pilots, draw candidates and exclusions, selected pilots, participant responses, notifications, and the director's final decision. The discipline profile defines group-size, normalization, and result-selection rules; these are not generic contest fields.

## Invariants

- A score placeholder exists for every pilot assignment, even before a value is entered.
- A scored assignment cannot be silently moved or reinterpreted.
- Future unscored rounds may be added or revised only under the contest lifecycle and explicit matrix revision rules.
- Seeded draw mode may create later matrix revisions incrementally after prerequisite rounds are complete.
