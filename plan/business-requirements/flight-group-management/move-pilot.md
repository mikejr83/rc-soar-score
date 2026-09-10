# RC Soar Score - Flight Group Management - Move Pilot

It may become necessary for a contest director to move a pilot from one flight group to another during a contest.

The application will indicate the following when a move is attempted:

* If the group is not within the same round.
* If the group already has scores.
* If the group would have a team conflict - If the contest has teams enabled.

The application will not allow the move if:

* The pilot is already in the target group.

## Moving to a Different Round

A contest director may allow a pilot which missed a previous flight to "catch up" by flying in a different group within the same round or in a group within a future round. The application will need to track the original round in which this pilot will receive the score. The pilot's raw score will be normalized against their flight group but the score will be applied to the original round. Subsequent moving of a moved group will always point back to the original round.
