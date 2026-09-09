# RC Soar Score Architecture - Participant Score Review and Retirement

## Purpose and boundaries

This document defines participant-requested score reviews and participant retirement in the self-scoring workflow. Original score entry and synchronization are defined in [participant-score-entry.md](participant-score-entry.md). Invitation issuance and authorization are defined in [self-scoring-invites.md](self-scoring-invites.md).

## Review requests

1. A review request may be created only for an accepted participant score when review is enabled, the score is not locked or official under the configured policy, and no other review for that group score is pending.
2. A review request must preserve the current official score, the participant's proposed raw components, optional message, actor, base score revision, and request time. It must not mutate the original participant submission in place.
3. If the official score or its revision changes before a review is decided, the director must explicitly approve, reject, or supersede the request. The service must not apply a stale proposal automatically.

## Retirement

1. A participant retirement action must be an explicit, idempotent mutation authorized for that participant.
2. Once accepted, the participant's future and otherwise unsubmitted rounds must be represented as retired/zero according to contest rules, and new submissions and review requests must be rejected.
3. Existing scores and read access remain available after retirement.
