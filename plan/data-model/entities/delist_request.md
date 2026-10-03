# DelistRequest

**Relationship to architecture-requirements:** plan/architecture-requirements/data/publication.md, plan/architecture-requirements/data/accounts.md
**Purpose:** A request to remove a published result set from public view. Published results are public record that other groups rely on, so a publication cannot be removed by its owner directly. Every attempt to remove one, whether the owner asks outright or closes their account, becomes a request that a system administrator reviews and decides using their judgement.
**Identifier:** `id` (UUIDv7)
**Parent entity:** PublicationIdentity
**Child entities:** None

## Relationships

- Belongs to a PublicationIdentity (`publication_id`). It points at the publication, not the contest, because the contest behind a publication may already be deleted
- Requested by an Account (`requested_by`)
- Decided by an Account with the system administrator flag (`decided_by`)

## Fields/Properties

| Field            | Type        | Required    | Default               | Description                                                                                                         |
| ---------------- | ----------- | ----------- | --------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `id`             | UUIDv7      | Yes         | Generated on creation | Primary key                                                                                                         |
| `publication_id` | UUIDv7      | Yes         | -                     | FK PublicationIdentity the request applies to                                                                       |
| `requested_by`   | UUIDv7      | Yes         | -                     | FK Account that made the request. Re-pointed to the deleted-user account if the requester's account is erased       |
| `trigger`        | enum        | Yes         | -                     | `owner_request` (the owner asked to remove the publication) or `account_closure` (raised while closing the account) |
| `reason`         | String      | No          | -                     | The requester's explanation, visible to administrators                                                              |
| `requested_at`   | timestamptz | Yes         | now                   | When the request was made                                                                                           |
| `state`          | enum        | Yes         | pending               | `pending`, `approved`, `denied`, or `withdrawn`                                                                     |
| `decided_by`     | UUIDv7      | Conditional | -                     | FK Account; the system administrator who approved or denied. Required when `state` is `approved` or `denied`        |
| `decided_at`     | timestamptz | Conditional | -                     | When the decision was made. Required when `state` is `approved` or `denied`                                         |
| `decision_note`  | String      | Conditional | -                     | The administrator's rationale. Required when `state` is `approved` or `denied`                                      |

## Invariants and Constraints

- A request can only be made for a publication that is currently public
- At most one request per publication can be `pending` (partial unique index on `publication_id` where `state` is `pending`)
- Only the publication's owner, or the account-closure flow acting for the owner, can create a request. Participants do not delist publications; they use automatic redaction of their own details instead
- Only an account with `is_system_admin` can approve or deny. `decided_by` must be such an account
- `state` moves only from `pending` to `approved`, `denied`, or `withdrawn`. A decided or withdrawn request is immutable
- Only the requester can withdraw, and only while the request is `pending`
- `decided_by`, `decided_at`, and `decision_note` are all set together on approval or denial and are null otherwise
- A new request may be made after a denial. The earlier requests stay visible to the administrator
- Deleting a contest's working data does not require a request and does not affect the publication
- Approval removes the publication from public access (its visibility becomes delisted). Permanently purging its content is a separate administrator action and is not part of this entity
- Denial leaves the publication unchanged, including when the requester's account is later erased

## Lifecycle

```plaintext
pending -> approved | denied | withdrawn
```

- Created `pending` when the owner asks to remove a publication, or when an account closing with "remove my contest data" selected raises one for each publication it owns.
- An administrator reviews and decides. Approval delists the publication.
- A request is never deleted; it is retained as the record of the decision.
- An account closure does not wait for the decision. The requester's personal data is erased, `requested_by` is re-pointed to the deleted-user account, and the request stays open until an administrator decides.

## Privacy and Scope

- Backend only. Not synced to installations
- Visible to system administrators and to the requester while their account exists
- `reason` and `decision_note` are never exposed publicly

## Audit and Synchronization

- Creation, withdrawal, and every decision record an AuditEvent tied to the publication (`publication_id`), which survives deletion of the contest
- The decision is immutable once made
- Not synced
