# RC Soar Score - Flight Group Management - Move Pilot

It may become necessary for a contest director to move a pilot from one flight group to another during a contest.

A move changes the pilot's assignment; it does not delete or rewrite a score that was already submitted. The application must retain the prior assignment and the reason, actor, time, and contest/matrix revision for the move.

The application will indicate the following when a move is attempted:

- If the source and target groups are not within the same round. A cross-round move requires explicit director confirmation.
- If the source or target group already has scores. The application must identify which scores are affected.
- If the group would have a team conflict - If the contest has teams enabled.

The application will not allow the move if:

- The pilot is already in the target group.
- The move would violate a contest rule that cannot be overridden by the contest director.

When a move is accepted, the source assignment remains in the audit history and the target assignment becomes the current assignment. Any affected derived group scores must be recalculated from their immutable raw score data. The application must not silently transfer or nullify a score between groups.

## Existing Scores

A pilot with an accepted score may be moved as an ordinary assignment change, but the application must require the contest director to choose how the existing score is handled:

- **Reset to non-entered:** The score is nullified for scoring purposes and the destination group receives a non-entered score placeholder. The original submitted score remains available in the audit history and is not deleted.
- **Transfer score:** The score is reassigned to the destination group as if the pilot had flown in that group. The score must retain its original submission data while its group assignment and derived values are recalculated using the destination group's eligible normalization population.

The selected handling must be recorded with the move, including the actor, reason, time, source and destination groups, and affected score revision. The director must be warned when transferring a score changes its normalization or credited result.

## Moving to a Different Round

A contest director may allow a pilot which missed a previous flight to "catch up" by flying in a different group within the same round or in a group within a future round. The application will need to track the original round in which this pilot will receive the score. The pilot's raw score will be normalized against their flight group but the score will be applied to the original round. Subsequent moving of a moved group will always point back to the original round.

For a cross-round move, the application must record both the scheduled flight round and the credited round. The credited round is the round that receives the pilot's official result; subsequent moves preserve that credited round. The score is calculated using the actual group in which the pilot flies, including that group's eligible normalization population, and is then applied to the credited round according to the discipline rules.
