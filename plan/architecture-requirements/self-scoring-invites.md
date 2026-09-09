# RC Soar Score Architecture - Participant Self-Scoring

## Purpose and boundaries

Participant self-scoring allows a pilot, or an authorized non-flier on the pilot's team, to submit the discipline-specific raw scoring details for a group score from a mobile device. The participant does not need an account. The contest director's application and the service remain the authorities for contest configuration, matrix assignments, score validity, official scores, and access policy.

This interface accepts participant inputs and exposes only the contest and participant data needed for the self-scoring workflow. It does not publish results, replace director scoring, or make a participant an official user. A participant submission is an immutable candidate input even when a later official decision gives precedence to another value.

## Invitation and access

1. The contest director must explicitly initiate each self-scoring invitation. The system must not send invitations automatically because a contest enters a lifecycle or scoring-access state.
2. The director may issue invitations while the contest is `Configuring`, `Ready`, or `Running`. The service must reject issuance for `Created`, `Completed`, and deletion states.
3. An invitation must target a contest participant link and must use that link's non-sequential `Scoring UUID` as the contest-scoped access identifier. The identifier must not expose a participant's account identifier or email address.
4. The invitation URL must contain a high-entropy, unguessable credential. The service must store only a protected representation of a credential that can authorize access, and must not include the credential in logs, analytics, notification previews, or error messages.
5. Opening an invitation link must not require account creation or sign-in. The service must resolve the credential to exactly one contest, participant link, and permitted role before returning any contest data.
6. Each issued invitation link must have a monotonically increasing invitation revision for its participant link. Only the most recently issued, non-revoked invitation link may open the participant's score interface or authorize a score read or mutation.
7. Issuing a replacement invitation link must invalidate every earlier link for that participant immediately. An earlier link must not regain access because a client has cached the page, retained a session, or submits a delayed request.
8. The service must support director-controlled invitation revocation and replacement. A revoked or replaced credential must stop authorizing access without invalidating scores already accepted from it.
9. Issuing or replacing an invitation must not grant access to another contest, another participant, unassigned rounds, private participant contact data, director data, or administrative operations.
10. A participant's pilot link grants access only to that pilot's scores. A non-flier link may select and enter scores only for pilots on the same team when teams are enabled. The service must enforce this relationship rather than relying on the client-selected pilot.
11. The service must apply contest scoring access, lifecycle, administration-lock, round/group lock, retirement, and score-state rules on every read and mutation. A valid invitation is not by itself permission to submit.

## Invitation delivery and audit

1. The director must be able to request delivery of an invitation through the configured communication mechanism and must also be able to retrieve the invitation link for an out-of-band delivery method.
2. Delivery is a side effect of an issuance request, not proof that the participant received or opened the invitation. The service must expose issuance and delivery outcomes separately.
3. Issuance, replacement, revocation, access, failed access attempts subject to rate limits, and delivery requests must be auditable with the contest, participant link, actor, source, time, and resulting invitation revision. Credentials and message contents must not be recorded in the audit trail.
4. Invitation issuance and revocation requests must be safe to retry. A retry identified by the same request identifier must not create multiple active credentials or duplicate delivery effects.
5. The service must rate-limit credential guessing and delivery requests without revealing whether a contest, participant, or credential exists. Errors for an invalid, expired, revoked, or unauthorized credential must not provide an attacker with additional information.
6. A successful issuance or replacement response must provide the current invitation link, its invitation revision, and its expiry or revocation status so the director can resend the latest link when a participant closes the application or loses the link.

## Participant score access

1. An authorized participant response must identify the contest, participant display information, permitted team members when applicable, and the participant's assigned rounds, groups, lanes, and discipline task data. It must not include unrelated participants' private data.
2. The service must return the first eligible round without a submitted score as the participant's next entry target. The client may display later rounds, but the service must not accept an out-of-order score when the contest rules require sequential entry.
3. A score view must distinguish at least `not entered`, `draft`, `submitted`, `review requested`, `under review`, `official`, `locked`, `zero`, and `retired` outcomes where those states apply. Derived scores and rankings must be identified as calculated values, not participant-entered values.
4. A participant may create or update a local draft before submission. Drafts must not affect contest lifecycle, rankings, group results, completion checks, or director notifications until accepted as a submission. Draft storage must be scoped to the participant's authorized contest access.
5. Once a participant score submission is accepted, the participant-facing score becomes read-only. Further changes must use the configured score review workflow, and a participant must not overwrite the original submission in place.
6. The service must return the current scoring schema and discipline-rules version with the entry surface. The client must not be able to add, omit, rename, or reinterpret scoring fields by sending an arbitrary payload.
7. The participant must be able to return to the score overview after closing or leaving the application by reopening the most recent invitation link. The link must resolve to the current overview and preserve access to previously submitted scores, pending reviews, and eligible future rounds without requiring a new invitation.
8. The participant interface must provide a visible way to copy or share the current invitation link, subject to the credential protections, so the participant can retain a route back to the score overview. A participant may use the browser's bookmark or history as an additional recovery path, but the system must not depend on either being available.
9. If the invitation link is no longer the most recent or has been revoked, the participant must receive a recovery response that does not expose contest or participant details and directs them to obtain the latest invitation link from the contest director. The old link must not display cached scores or accept mutations.

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

## Review requests and retirement

1. A review request may be created only for an accepted participant score when review is enabled, the score is not locked or official under the configured policy, and no other review for that group score is pending.
2. A review request must preserve the current official score, the participant's proposed raw components, optional message, actor, base score revision, and request time. It must not mutate the original participant submission in place.
3. If the official score or its revision changes before a review is decided, the director must explicitly approve, reject, or supersede the request. The service must not apply a stale proposal automatically.
4. A participant retirement action must be an explicit, idempotent mutation authorized for that participant. Once accepted, the participant's future and otherwise unsubmitted rounds must be represented as retired/zero according to contest rules, and new submissions and review requests must be rejected. Existing scores and read access remain available.

## Synchronization and recovery

1. Participant submission mutations must use the common synchronization contract: stable identifiers, base revisions, unique mutation identifiers, actor and authority, source device, server ordering, acknowledgements, and durable retry state.
2. A disconnected participant client may retain drafts and unsent submissions locally, but it must clearly distinguish a locally queued submission from a server-accepted score. It must not display a queued score as official or use it to claim contest completion.
3. The service must preserve rejected submissions, conflicts, score revisions, review requests, retirement actions, and audit history for the lifetime of the contest. Recovery and synchronization must not discard a participant submission merely because an official value has precedence.
4. Participant synchronization responses must be limited to changes the invitation holder is authorized to see. Director synchronization may receive the complete audit and conflict records under the director's authority.

## Participant-safe result views

1. After a score is accepted, the service must provide the participant's group results and current placement required by the business workflow. These values must be calculated from the current authorized score revisions and must be marked preliminary when the group or ranking is incomplete.
2. Participant-visible preliminary group results must update as authorized participant submissions are accepted, independently of the contest director's policy for copying eligible changes to the public projection. This participant update must not publish or alter the public projection.
3. Missing-score estimates, pending review indicators, and score states must be explicit in the response so the client does not present an estimate as an entered or official value.
4. Participant result views must exclude email addresses, invitation credentials, director-only notes, private audit details, unauthorized team data, and unpublished data outside the participant's permitted contest scope.
