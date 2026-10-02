# Invitation

**Relationship to architecture-requirements:** plan/architecture-requirements/data/reviews-and-invitations.md, plan/architecture-requirements/participating-contestants-and-teams/contest.md  
**Purpose:** Controls participant access to a contest via Magic Link URLs or QR codes. Pilot invitations authorize only that pilot; non-flier invitations may be used to select only pilots on the same contest team.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Contest  
**Child entities:** None

## Relationships

- Belongs to a Contest (foreign key `contestId`)
- References a Participation record via `linkId_part` (foreign key)
- One-to-one: Each pilot may have one valid pilot-type invitation; multiple crew-type invitations per pilot
- Invitation is single-use and expires when used, expired, or revoked

## Fields/Properties

| Field                      | Type             | Required | Default  | Description                                                     |
| -------------------------- | ---------------- | -------- | -------- | --------------------------------------------------------------- |
| `id`                       | UUIDv7           | Yes      | -        | Primary key identifying the invitation                          |
| `contest_id`               | UUIDv7           | Yes      | -        | Foreign key to the Contest                                      |
| `contest_participation_id` | UUIDv7           | Yes      | -        | Foreign key to the Participation record                         |
| `type`                     | Enum             | Yes      | MagicURL | Type of invitation: `MagicURL`, `QRCode`                        |
| `protected_credential`     | String           | Yes      | -        | Encrypted credential; raw credential never stored in logs/audit |
| `invitation_revision`      | Integer          | Yes      | 0        | Revision counter for optimistic locking                         |
| `state`                    | Enum             | Yes      | Sent     | Current state: `Sent`, `Used`, `Expired`, `Revoked`             |
| `audience`                 | Enum             | Yes      | Pilot    | Target audience: `Pilot`, `Helper`                              |
| `issued_at`                | Timestamp        | Yes      | -        | Time invitation was issued                                      |
| `used_at`                  | Timestamp        | No       | null     | Time invitation was used (non-null if state is Used)            |
| `expired_at`               | Timestamp        | No       | null     | Time invitation expired (non-null if state is Expired)          |
| `revoked_at`               | Timestamp        | No       | null     | Time invitation was revoked (non-null if state is Revoked)      |
| `delivery_outcomes`        | Array of Objects | No       | []       | Records of delivery attempts and outcomes                       |
| `rate_limit_attempts`      | Integer          | Yes      | 0        | Count of remaining allowed uses for non-pilot QR codes          |

## Invariants and Constraints

- Pilot invitation authorizes only that specific pilot; non-flier may select only pilots on same contest team
- Magic URL email invitations expire 24 hours after contest completion
- Field QR tokens do not expire during an active contest (per ticket 021)
- Invitation is single-use; once used it transitions to `Used`
- Invitation transitions to `Expired` when expiration time passes or contest is complete and 24 hours have passed
- Invitation transitions to `Revoked` when manually revoked
- `rate_limit_attempts` must be > 0 for non-pilot QR codes

## Lifecycle

```plaintext
Sent -> Used
Sent -> Expired
Sent -> Revoked
```

## Privacy and Scope

- `protected_credential` must be encrypted and never appear in logs, audit, or sync traffic without the decryption key
- Invitation state and timestamps are shared within the contest context
- Delivery outcomes and rate limit attempts are visible to contest administrators

## Audit and Synchronization

- Invitation creation is audited as `InvitationIssued`
- Invitation use is audited as `InvitationUsed`
- Invitation revocation is audited as part of invitation lifecycle
- Delivery failures are recorded in `delivery_outcomes`
- Mutation uses `invitation_revision` for optimistic locking
- Invitation state transitions are atomic
