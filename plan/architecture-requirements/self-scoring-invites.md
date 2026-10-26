# RC Soar Score Architecture - Self-Scoring Invitations

## Purpose and boundaries

Self-scoring invitations provide a participant with access to the participant score interface. The participant does not need an account. The contest director's application and the service remain the authorities for contest configuration, matrix assignments, score validity, official scores, and access policy.

Score entry, synchronization, review requests, retirement, and participant result views are defined in the related architecture documents [participant-score-entry.md](participant-score-entry.md), [participant-score-review.md](participant-score-review.md), and [participant-score-results.md](participant-score-results.md).

## Invitation and access

1. The contest director must explicitly initiate each self-scoring invitation. The system must not send invitations automatically because a contest enters a lifecycle or scoring-access state. In particular, opening participant scoring does not issue or send invitations, and invitations can be issued before it is opened (for example right after the matrix draw).
2. The director may issue invitations while the contest is `Configuring`, `Ready`, or `Running`. The service must reject issuance for `Created`, `Completed`, and deletion states.
3. An invitation must target a contest participant link and must use that link's non-sequential `Scoring UUID` as the contest-scoped access identifier. The identifier must not expose a participant's account identifier or email address.
4. The invitation URL must contain a high-entropy, unguessable credential: random, at least 128 bits, and not derived from any participant, contest, or account data. The only security goal is that one participant cannot guess another's link and enter scores for them. The service must store only a protected representation of a credential that can authorize access, and must not include the credential in logs, analytics, notification previews, or error messages.
5. Opening an invitation link must not require account creation or sign-in. The service must resolve the credential to exactly one contest, participant link, and permitted role before returning any contest data.
6. An invitation link is stable and reusable. It stays active until the contest is Completed and then for 24 hours (read-only), and nothing ends it earlier except replacement or revocation. It is not consumed by use, and an emailed link and a QR code behave the same way. Resending an invitation sends the same link. The participant returns to their overview through the same link for as long as the invitation is active.
7. The director may generate a replacement link for a participant, for example when a link was shared by mistake or sent to the wrong address. The earlier link then stops authorizing access, including from a cached page or a retained session. The director may also revoke an invitation. Neither action is required to run a contest, and neither invalidates scores already accepted from the link.
8. A participant who opens the link receives a guest identity and a session for it, as described in [accounts.md](data/accounts.md). The session identifies the participant link and contest and may be long-lived. The service must still check the invitation state, the contest lifecycle, and scoring access on every read and mutation, and must record the invitation as the access reference for each submission.
9. Issuing or replacing an invitation must not grant access to another contest, another participant, unassigned rounds, private participant contact data, director data, or administrative operations.
10. A participant's pilot link grants access only to that pilot's scores. A helper link is available only when teams are enabled. A helper is a non-flier assigned to exactly one team and may select and enter scores only for pilots on that team. The service must enforce this relationship rather than relying on the client-selected pilot. A pilot has only the pilot role; one person is not both pilot and helper on the same participant record.
11. The service must apply contest scoring access, lifecycle, administration-lock, round/group lock, retirement, and score-state rules on every read and mutation. A valid invitation is not by itself permission to submit.
12. A contest organized offline cannot generate QR codes, display self-scoring links, or allow participant self-scoring until the contest and its matrix revision have been synchronized with the remote service. As long as the contest remains 100% offline, participant self-scoring is disabled and the contest director (or local operators on the director's device) is responsible for all score entry.

## Access through a linked account

A participant with an account can reach the same participant link without opening the credential.

1. A participant link is reachable through an account only when the account is linked to the participant record behind it by a confirmed participant-account link (see [data/accounts.md](data/accounts.md)) and the participation has an active invitation. An unconfirmed email match must never grant access or list a contest.
2. The service lists those contests for the signed-in account. Opening one from the list counts as redeeming the invitation for the account, and the invitation is the access reference recorded on each submission.
3. A confirmed link belongs to the director's participant record, not to one contest. A new participation of the same record is reachable as soon as the director invites the participant, without another confirmation.
4. An account that redeems an invitation link and signs in must confirm that the participation is theirs before the link is created. Entries made earlier under the guest identity are attached to the account.
5. A guest identity is created once per participant link. A second device that opens the same link acts as the same guest, and the source device recorded on each submission tells the devices apart.
6. The authorization rules for the link apply unchanged to the account route: team scope, lifecycle, scoring access, locks, retirement, and score state.

## Invitation delivery and audit

1. The director must be able to request delivery of an invitation through the configured communication mechanism and must also be able to retrieve the invitation link for an out-of-band delivery method.
2. Delivery is a side effect of an issuance request, not proof that the participant received or opened the invitation. The service must expose issuance and delivery outcomes separately.
3. Issuance, replacement, revocation, access, failed access attempts subject to rate limits, and delivery requests must be auditable with the contest, participant link, actor, source, time, and resulting invitation revision. Credentials and message contents must not be recorded in the audit trail.
4. Invitation issuance and revocation requests must be safe to retry. A retry identified by the same request identifier must not create multiple active credentials or duplicate delivery effects.
5. The service must rate-limit credential guessing and delivery requests without revealing whether a contest, participant, or credential exists. Errors for an invalid, expired, revoked, or unauthorized credential must not provide an attacker with additional information.
6. A successful issuance or replacement response must provide the current invitation link, its invitation revision, and its expiry or revocation status so the director can resend the link when a participant closes the application or loses it.

## Related requirements

Participant score entry and synchronization are defined in [participant-score-entry.md](participant-score-entry.md). Participant score reviews and retirement are defined in [participant-score-review.md](participant-score-review.md). Participant-visible results are defined in [participant-score-results.md](participant-score-results.md). The helper team overview is defined in [participant-team-overview.md](participant-team-overview.md).
