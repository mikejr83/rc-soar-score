# RC Soar Score Architecture - Participant Score Review and Retirement

## Purpose and boundaries

This document defines participant-requested score reviews and participant retirement in the self-scoring workflow. Original score entry and synchronization are defined in [participant-score-entry.md](participant-score-entry.md). Invitation issuance and authorization are defined in [self-scoring-invites.md](self-scoring-invites.md).

## Review requests

1. A review request may be created only when review requests are enabled for the contest, the score is not locked (at the score, group, round, or contest level), no explicit director decision has closed review for the current score, and no other review request for that flight assignment is currently pending. The score may be preliminary (`Submitted`) or official by automatic acceptance.
2. A review request is prohibited on a `Locked` score, and on a score whose review the director has explicitly closed by marking it official, correcting it, or deciding a review. Official status alone does not close review: a score the contest accepted automatically stays reviewable until it is locked or explicitly decided. There is no timed window. Once review is closed or the score is locked, corrections can only be made by the contest director or authorized official through administrative score correction.
3. A review request must preserve the current submitted score, the participant's proposed raw components (which may include a `Flight Penalty` but not a `Cumulative Penalty`), optional explanation message, actor, base score revision, and request time. It must not mutate the original participant submission in place.
4. If an official edits or marks the score official while a review request is pending, the review request is superseded and the decision closes review for the current score. The service must not apply a stale proposal automatically. Automatic acceptance never supersedes a review request and never applies its proposal: a score with an open review request is held, and the results it affects stay preliminary.
   4a. A review request opened on an automatically accepted score keeps the current official version in place until the director decides. The pilot's view shows the score as official and under review, not as missing, and never shows the proposal as a score.
5. Both the pilot and a helper on the pilot's team may create a review request. Only one review request may be pending for a flight assignment, so a second request from the other person is rejected and the client shows the pending request. The request records the actor who created it.

## Retirement

1. A participant retirement action must be an explicit, idempotent mutation authorized for that participant. A pilot may retire themselves, and a helper may retire a pilot on the helper's team. The service must record the actor who retired the pilot. The director may reinstate a retired pilot.
2. Once accepted, the participant's future and otherwise unsubmitted rounds must be represented as retired/zero according to contest rules, and new submissions and review requests must be rejected.
3. Existing scores and read access remain available after retirement.
