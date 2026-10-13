# AccountAlias

**Relationship to architecture-requirements:** plan/architecture-requirements/data/accounts.md  
**Purpose:** Remembers that a Local account id was claimed into a registered account. Late mutations, queued mutations and imported copies still carry the Local id as owner or actor, and the alias tells the backend which registered account they mean.  
**Identifier:** `id` (UUIDv7), which is the claimed Local account id itself  
**Parent entity:** Account  
**Child entities:** None

## Relationships

- Belongs to exactly one Account, the registered account that claimed the Local account
- An account may have several aliases, one for each installation of the same person

## Fields/Properties

| Field        | Type        | Required | Default | Description                                                           |
| ------------ | ----------- | -------- | ------- | --------------------------------------------------------------------- |
| `id`         | UUIDv7      | Yes      | -       | Primary key: the id the installation generated for its Local account  |
| `account_id` | UUIDv7      | Yes      | -       | FK Account: the registered account the Local account was claimed into |
| `claimed_at` | timestamptz | Yes      | now     | When the claim was recorded                                           |

## Invariants and Constraints

- `id` is never equal to `account_id`, and no account row exists for the Local id
- A claim never moves: claiming an id that is already an alias changes nothing, and a claim of an id held by another account is refused
- Claiming again for the same account is a no-op, not an error
- Only registered accounts can be the target of a claim
- Never synced to installations and never exposed to clients

## Lifecycle

Created when a signed-in user claims an installation's Local account. Never modified. Deleted only when the account is erased.

## Privacy and Scope

- Backend only
- The Local account id is already known to the installation that generated it; the alias adds nothing a client could not already hold

## Audit and Synchronization

- Creation is recorded in application logs
- Not synced
