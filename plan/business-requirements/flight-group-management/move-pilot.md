# RC Soar Score - Flight Group Management - Move Pilot

It may become necessary for a contest director to move a pilot from one flight group to another during a contest.

A move changes the pilot's assignment; it does not delete or rewrite a score that was already submitted. The application must retain the prior assignment and the reason, actor, time, and contest/matrix revision for the move.

The application will indicate the following when a move is attempted:

- If the source and target groups are not within the same round. A cross-round move requires explicit director confirmation.
- If the source or target group already has scores. The application must identify which scores are affected.
- If the group would have a team conflict - If the contest has teams enabled.

The application will not allow the move if:

- The pilot is already in the target group, unless the move is a reset of a score that was entered in the wrong place (see Existing Scores).
- The move would violate a contest rule that cannot be overridden by the contest director.

When a move is accepted, the source assignment remains in the audit history and the target assignment becomes the current assignment. Any affected derived group scores must be recalculated from their immutable raw score data. The application must not silently move or nullify a score between groups.

## Existing Scores

A pilot with an accepted score may be moved as an ordinary assignment change. Moving the pilot resets the score:

- **Reset to non-entered:** The score is nullified for scoring purposes and the destination receives a non-entered score placeholder, so the pilot can enter the score again. The original submitted score remains available in the audit history and is not deleted. A reset clears the score; it does not record a zero.

A score is never carried from one group to another, because its normalization depends on the group the pilot actually flew in. The selected handling is recorded with the move, including the actor, reason, time, source and destination groups, and the affected score revision.

Typical cases:

- **The pilot flew in an unassigned group and entered the score immediately.** The score landed on the pilot's assigned group, which is wrong. The contest director resets it, either by moving the pilot to the group they flew in or by resetting the score in place so the pilot flies their assigned group.
- **The pilot missed their group and flew in another.** Under a strict reading of most rules the pilot receives a zero. The contest director may instead move the pilot to the group they flew in. If the pilot had already entered a score, the move resets it so the pilot can enter it again.

A penalty that applies to that flight is the contest director's decision. It is entered as the Flight Penalty on the new flight, either by the pilot on the director's instruction or by the director. It is part of the round score. Only the contest director applies a Cumulative Penalty.

## Moving to a Different Round

A contest director may allow a pilot which missed a previous flight to "catch up" by flying in a different group within the same round or in a group within a future round. The application will need to track the original round in which this pilot will receive the score. The pilot's raw score will be normalized against their flight group but the score will be applied to the original round. Subsequent moving of a moved group will always point back to the original round.

For a cross-round move, the application must record both the scheduled flight round and the credited round. The credited round is the round that receives the pilot's official result; subsequent moves preserve that credited round. The score is calculated using the actual group in which the pilot flies, including that group's eligible normalization population, and is then applied to the credited round according to the discipline rules.
