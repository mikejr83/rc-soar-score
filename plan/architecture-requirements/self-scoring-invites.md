# RC Soar Score Architecture - Self-Scoring Invitations

## Purpose and boundaries

Self-scoring invitations provide a participant with access to the participant score interface. The participant does not need an account. The contest director's application and the service remain the authorities for contest configuration, matrix assignments, score validity, official scores, and access policy.

Score entry, synchronization, review requests, retirement, and participant result views are defined in the related architecture documents [participant-score-entry.md](participant-score-entry.md), [participant-score-review.md](participant-score-review.md), and [participant-score-results.md](participant-score-results.md).

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

## Related requirements

Participant score entry and synchronization are defined in [participant-score-entry.md](participant-score-entry.md). Participant score reviews and retirement are defined in [participant-score-review.md](participant-score-review.md). Participant-visible results are defined in [participant-score-results.md](participant-score-results.md).
