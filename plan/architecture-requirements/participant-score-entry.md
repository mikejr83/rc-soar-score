# RC Soar Score Architecture - Participant Score Entry

## Purpose and boundaries

Participant score entry allows a pilot, or an authorized non-flier on the pilot's team, to submit discipline-specific raw scoring details for a group score from a mobile device. The participant does not need an account. The contest director's application and the service remain the authorities for contest configuration, matrix assignments, score validity, official scores, and access policy.

Invitation issuance and authorization are defined in [self-scoring-invites.md](self-scoring-invites.md). Review requests and retirement are defined in [participant-score-review.md](participant-score-review.md). Participant result views are defined in [participant-score-results.md](participant-score-results.md).

## Participant score access

1. An authorized participant response must identify the contest, participant display information, permitted team members when applicable, and the participant's assigned rounds, groups, lanes, and discipline task data. It must not include unrelated participants' private data.
2. The service must return the first eligible round without a submitted score as the participant's next entry target. The client may display later rounds, but the service must not accept an out-of-order score when the contest rules require sequential entry.
3. A score view must distinguish at least `not entered`, `draft`, `submitted`, `review requested`, `under review`, `official`, `locked`, `zero`, and `retired` outcomes where those states apply. Derived scores and rankings must be identified as calculated values, not participant-entered values.
4. A participant may create or update a local draft before submission. Drafts must not affect contest lifecycle, rankings, group results, completion checks, or director notifications until accepted as a submission. Draft storage must be scoped to the participant's authorized contest access.
5. Once a participant score submission is accepted, the participant-facing score becomes read-only. Further changes must use the configured score review workflow, and a participant must not overwrite the original submission in place.
6. The service must return the current scoring schema and discipline-rules version with the entry surface. The schema contains the discipline's score fields. It does not contain the `Cumulative Penalty`, which only the contest director applies. Participants see it read-only once it is applied.
7. The client must not be able to add, omit, rename, or reinterpret scoring fields by sending an arbitrary payload. The service must reject a submission that carries a `Cumulative Penalty`, omits a required field, supplies a value of the wrong type, or supplies a value outside the configured valid range.
8. The participant must be able to return to the score overview after closing or leaving the application by reopening the most recent invitation link. The link must resolve to the current overview and preserve access to previously submitted scores, pending reviews, and eligible future rounds without requiring a new invitation.
9. The participant interface must provide a visible way to copy or share the current invitation link, subject to the credential protections, so the participant can retain a route back to the score overview. A participant may use the browser's bookmark or history as an additional recovery path, but the system must not depend on either being available.
10. If the invitation link is no longer the most recent or has been revoked, the participant must receive a recovery response that does not expose contest or participant details and directs them to obtain the latest invitation link from the contest director. The old link must not display cached scores or accept mutations.

## Score submission

1. A submission must identify the contest, participant link, matrix revision, round, group score, and the client mutation identifier. The server must derive the authorized pilot and assignment from the invitation and current contest data rather than trusting equivalent client fields.
2. The service must validate the submission against the current discipline rules, configured ranges and precision, participant assignment, group and round, matrix revision, contest lifecycle, scoring access, administration lock, and applicable score lock before accepting it.
3. The service must reject a submission that is stale, duplicated with different data, assigned to another participant, outside the participant's team authority, for a missing assignment, or for a score that is already submitted or locked. The rejection must explain the actionable condition without exposing unauthorized data.
4. A successful submission must atomically store the immutable original raw components, actor and authority, invitation/access reference, source device, client mutation identifier, matrix and calculation metadata, server time, and resulting score state. It must also atomically create the group-score placeholder's submitted value and any derived values that can be calculated.
5. The first accepted participant submission must atomically transition the contest from `Ready` to `Running`. A failed or rejected submission must not change the contest lifecycle.
6. The service must make submission idempotent. Repeating the same client mutation after a timeout must return the original acceptance and revision without creating a second score or second notification.
7. Concurrent submissions for the same group score must be resolved by the service using the score revision and authority rules. The service must never use client timestamps or last-write-wins to silently replace an accepted participant submission.
8. A participant submission received while the director is offline must be retained by synchronization. It must not silently replace an offline official value; when the values conflict, the participant submission must remain available as a pending or silent review record for the director.
9. The accepted response must include the resulting score state, revision, calculated values, validation messages, and the next permitted operation. It must not require the client to infer acceptance from a changed screen.

## Synchronization and recovery

1. Participant submission mutations must use the common synchronization contract: stable identifiers, base revisions, unique mutation identifiers, actor and authority, source device, server ordering, acknowledgements, and durable retry state.
2. A disconnected participant client may retain drafts and unsent submissions locally, but it must clearly distinguish a locally queued submission from a server-accepted score. It must not display a queued score as official or use it to claim contest completion.
3. The service must preserve rejected submissions, conflicts, score revisions, review requests, retirement actions, and audit history for the lifetime of the contest. Recovery and synchronization must not discard a participant submission merely because an official value has precedence.
4. Participant synchronization responses must be limited to changes the invitation holder is authorized to see. Director synchronization may receive the complete audit and conflict records under the director's authority.
