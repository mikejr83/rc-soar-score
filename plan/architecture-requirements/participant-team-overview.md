# RC Soar Score Architecture - Participant Team Overview

## Purpose and boundaries

The team overview is the first page a helper sees. It lets a helper find the pilots on their team, see which of them is flying soon, and compare team standings. It is available only when teams are enabled for the contest. It does not define public publishing or the director's workspace. The business behaviour is defined in [contest-self-scoring.md](../business-requirements/contest-self-scoring.md).

## Team overview response

1. The service must return the team overview only for a helper link or a linked account acting as a helper, and only when teams are enabled. A pilot link, or a contest without teams, must receive the same recovery response as an unavailable view.
2. The response must contain the helper's team, and for each pilot on that team: the pilot's display name, pilot number when enabled, the round, group, and lane (when assigned) of the pilot's next entry target, whether the pilot is retired, and the pilot's Up now or Up next indicator.
3. The response must contain the overall standing of every team in the contest, with the helper's team identified. Team standings are calculated values derived from the eligible pilot totals according to the contest's configured rules. They must be marked preliminary when the contest is incomplete.
4. While the director is hiding overall results, team standings must be shown as of the recorded round and must not change until hiding ends, in the same way as individual standings (see [participant-score-results.md](participant-score-results.md)).
5. The response must exclude email addresses, invitation credentials, director-only notes, and private audit details. It must contain only the helper's own team pilots in the pilot list. Other teams appear only in the standings.

## Up now and Up next

The service computes the indicators so that every helper on the team sees the same result.

1. **Latest scored group.** The latest group with an accepted score is taken from the latest round, by round number, that has an accepted score. A correction to an earlier round does not move it. This is the same rule the director's workspace uses to find the current round and group. A group "has a score" when at least one accepted score exists for it.
2. **Walk forward.** Starting with the group after the latest scored group, in matrix order, continue into the next round when that round is drawn. Seeded rounds are drawn one round at a time, so a later round may not exist yet.
3. **Up now.** The team's pilots in the first group, found by the walk, that contains a team pilot are **Up now** if that group is the one directly after the latest scored group.
4. **Up next.** When the first group found is not the one directly after, its team pilots are **Up next** and no pilot is Up now. When there are Up now pilots, the team pilots in the next later group that contains a team pilot are **Up next**.
5. **Skipped pilots.** Retired pilots, and pilots with no remaining unscored assignment, are not given either indicator.
6. **Nothing yet.** Before any group has a score, the latest scored group is empty and the walk starts with the first group of the first round.
7. **No next group.** When the walk reaches the end of the drawn rounds without finding a team pilot, the response states that no further flight is drawn. The client must not guess.
8. **Just flown.** A team pilot in the latest scored group who has no score yet is returned with a "just flown" marker, so the client can prompt the helper to enter the score.
9. **Wording.** The indicators trail the real order of flying because they depend on entered scores. The response carries the values; the client labels them as based on entered scores.

Re-flight groups are not considered by this rule.

## Examples

Group 3 of round 4 has one accepted score. Rob flew in group 3 and has no score; he is marked just flown. Joe is in group 4, which is directly after, so he is Up now. Amy is not in group 5. She is in the first group of round 5, which is drawn, so she is Up next.

If the first drawn team group is group 6, the response has no Up now pilots and the pilots in group 6 are Up next.
