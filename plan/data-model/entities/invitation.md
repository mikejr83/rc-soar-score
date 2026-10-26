# Invitation

**Relationship to architecture-requirements:** plan/architecture-requirements/data/reviews-and-invitations.md, plan/architecture-requirements/self-scoring-invites.md  
**Purpose:** Controls participant access to a contest via Magic Link URLs or QR codes. A pilot invitation authorizes only that pilot; a non-flier invitation may select only pilots on the same contest team. An invitation link stays usable so the participant can return to their score overview; replacing or revoking it is what ends access.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ContestParticipation (also denormalized to Contest)  
**Child entities:** None

## Relationships

- Belongs to a Contest (`contest_id`, denormalized for sync scoping and authorization)
- Targets one ContestParticipation (`contest_participation_id`). The participation's `scoring_uuid` is the access identifier in the link
- A participation has a sequence of invitations, numbered by `invitation_revision`. At most one is `Active`; earlier ones are `Replaced` or `Revoked`
- May reference the invitation it replaces (`replaces_invitation_id`)
- Issued by an Account (`issued_by`)
- Redeemed by an Account (`redeemed_by_account_id`): the guest account created when an invitee without an account first redeems the invitation, or the invitee's own account
- Referenced by ScoreAttempt (`invitation_id`) as the access under which a score was submitted

## Fields/Properties

| Field                      | Type             | Required | Default  | Description                                                                                                                                  |
| -------------------------- | ---------------- | -------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7           | Yes      | -        | Primary key identifying the invitation                                                                                                       |
| `contest_id`               | UUIDv7           | Yes      | -        | FK Contest (denormalized; must match the participation's contest)                                                                            |
| `contest_participation_id` | UUIDv7           | Yes      | -        | FK ContestParticipation the invitation authorizes                                                                                            |
| `type`                     | Enum             | Yes      | MagicURL | How the link was first issued: `MagicURL` (emailed) or `QRCode` (printed). The link, credential and expiry are the same for both; a participant has one Active invitation, whatever the channel                                                                 |
| `protected_credential`     | String           | Yes      | -        | Protected representation of a high-entropy credential. The raw credential is never stored and never appears in logs or audit records         |
| `invitation_revision`      | Integer          | Yes      | 1        | Monotonically increasing per participation. Only the latest non-revoked revision authorizes access                                           |
| `state`                    | Enum             | Yes      | Active   | `Active`, `Replaced`, `Revoked`, or `Expired`                                                                                                |
| `audience`                 | Enum             | Yes      | Pilot    | Target audience, taken from the participation's role type: `Pilot` or `Helper`                                                               |
| `issued_by`                | UUIDv7           | Yes      | -        | FK Account of the director (or acting authority) who issued it                                                                               |
| `issued_at`                | timestamptz      | Yes      | -        | Time the invitation was issued                                                                                                               |
| `expires_at`               | timestamptz      | No       | null     | When access ends. Set to 24 hours after contest completion for every invitation, whatever its `type`; null until the contest completes           |
| `first_used_at`            | timestamptz      | No       | null     | When the link was first opened successfully                                                                                                  |
| `last_used_at`             | timestamptz      | No       | null     | When the link was last opened successfully. Informational; does not end access                                                               |
| `revoked_at`               | timestamptz      | No       | null     | When the director revoked the invitation (non-null if state is Revoked)                                                                      |
| `replaces_invitation_id`   | UUIDv7           | No       | null     | FK Invitation that this one replaced                                                                                                         |
| `redeemed_by_account_id`   | UUIDv7           | No       | null     | FK Account that first redeemed the invitation. A guest account is created when the invitee has none. Null until first redemption             |
| `delivery_outcomes`        | Array of Objects | No       | []       | Delivery requests and their outcomes (channel, requested time, result). Issuance and delivery are separate: delivery is not proof of receipt |
| `client_mutation_id`       | String           | Yes      | -        | Idempotency key. A retry with the same value must not create a second credential or duplicate delivery. Unique within the contest            |

## Invariants and Constraints

- (`contest_participation_id`, `invitation_revision`) is unique, and the revision of a new invitation is one higher than the participation's latest
- At most one `Active` invitation exists per participation (partial unique index on `contest_participation_id` where `state` is `Active`)
- Issuing a replacement sets the previous `Active` invitation to `Replaced` in the same transaction. An earlier link never regains access, even from a cached page, a retained session, or a delayed request
- Using a link does not consume it: `state` stays `Active` across uses, and the participant can return through the same link to their overview
- A pilot invitation authorizes only that pilot. A non-flier (helper) invitation targets the non-flier's own participation and may select and enter scores only for pilots on the same contest team. Helper invitations exist only when teams are enabled, and the helper is assigned to one team. The service enforces this and does not trust the client-selected pilot
- The credential is random and unguessable, and an emailed link and a QR code behave the same way. Resending sends the same link. Replacing or revoking an invitation is an optional director action, not part of normal use
- A linked account whose participant link is confirmed reaches the participation without the credential while its invitation is `Active`. Opening it from the account's contest list sets `redeemed_by_account_id` if it is empty. One guest account exists per invitation; a second device acts as the same guest
- A valid invitation is not permission by itself. Every read and mutation still checks lifecycle, scoring access, locks, retirement, assignment, and score state
- Issuance is allowed only while the contest is `Configuring`, `Ready`, or `Running`, and never for `Created`, `Completed`, or deletion states
- An invitation moves to `Expired` when `expires_at` passes. Every invitation, emailed or printed, expires 24 hours after contest completion (a read-only grace period for the overview and results). Nothing expires it earlier except replacing or revoking it; using it never does
- Revoking or replacing an invitation does not invalidate scores already accepted under it
- `client_mutation_id` is unique per contest, so issuance and revocation requests are safe to retry
- `redeemed_by_account_id` is set once, at first redemption, and later re-pointed only by claiming a guest account

## Lifecycle

```plaintext
Active -> Replaced
Active -> Revoked
Active -> Expired
```

- Created `Active` when the director issues an invitation for a participation
- Becomes `Replaced` when a newer invitation is issued for the same participation
- Becomes `Revoked` when the director revokes it, or `Expired` when `expires_at` passes
- Invitations are never deleted. They remain as the access history for the scores submitted under them
- A contest that is entirely offline cannot issue invitations. They are issued only after the contest and its matrix revision have been synchronized with the remote service

## Privacy and Scope

- `protected_credential` must be protected and never appears in logs, audit, or sync traffic
- Invitation state and timestamps are shared within the contest context
- Delivery outcomes are visible to contest administrators. They record delivery requests, not message contents
- Errors for an invalid, expired, revoked, or unauthorized credential must not reveal whether a contest, participant, or credential exists

## Audit and Synchronization

- Issuance, replacement, revocation, access, failed access attempts subject to rate limits, and delivery requests are each audited (`InvitationIssued`, `InvitationReplaced`, `InvitationRevoked`, `InvitationAccessed`, `InvitationAccessFailed`, `InvitationDeliveryRequested`) with the contest, participation, actor, source, time, and resulting invitation revision
- Credentials and message contents are never recorded in the audit trail
- State transitions are atomic
- Issuance and revocation are idempotent by `client_mutation_id`
