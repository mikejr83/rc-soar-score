# RC Soar Score Architecture - Scoring States

|Score state|Meaning|
|-----------|-------|
|Draft|Score form is active and not submitted|
|Submitted|Score is recorded and official unless changed|
|Review requested|Participant requests changes|
|Under review|Director or official is evaluating the request|
|Approved|Proposed changes become official|
|Rejected|Requested changes are denied; original remains official|
|Retired / zeroed|Pilot has withdrawn or future rounds are marked as zero|
|Locked|Score is no longer editable due to contest lock or completion|

## Scoring Opened

A contest having the published attribute can have a contest director open the contest to scoring. This is not required. The contest may be published and marked as public, but the contest will be scored only by the contest director or another official.

When the contest director opens scoring to participants the system will look at the participants and invite them to a special URL that enables them to enter their scores.

The system will use follow the process in [`self-scoring-invites.md`](./self-scoring-invites.md) to determine how to send the invites to participants.
