# AccountIdentity

**Relationship to architecture-requirements:** plan/architecture-requirements/data/accounts.md  
**Purpose:** Associates an account with a login at an identity provider. It keeps the provider's identifiers out of the Account itself, so the provider can change, an account can have more than one login method, and the identifiers never reach a client.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Account  
**Child entities:** None

## Relationships

- Belongs to exactly one Account
- An account may have several identities (for example two providers)

## Fields/Properties

| Field        | Type        | Required | Default               | Description                                                                      |
| ------------ | ----------- | -------- | --------------------- | -------------------------------------------------------------------------------- |
| `id`         | UUIDv7      | Yes      | Generated on creation | Primary key                                                                      |
| `account_id` | UUIDv7      | Yes      | -                     | FK Account                                                                       |
| `issuer`     | String      | Yes      | -                     | Identifier of the identity provider that issued the subject (the token's issuer) |
| `subject`    | String      | Yes      | -                     | Stable subject identifier assigned by the issuer                                 |
| `created_at` | timestamptz | Yes      | now                   | When the identity was attached to the account                                    |

## Invariants and Constraints

- (`issuer`, `subject`) is unique: a subject is only meaningful together with its issuer
- A token is accepted only when its issuer and subject match a stored identity; the matched identity determines the account
- Creating a registered account and its first identity happens in one transaction
- Only registered accounts have identities
- Never synced to installations and never exposed to clients

## Lifecycle

Created at registration or when a user attaches another login to their account. Deleted when the identity is removed or the account is erased. Never modified.

## Privacy and Scope

- Backend only
- Identifiers are authentication keys, not references that clients may see or use

## Audit and Synchronization

- Creation and deletion are recorded in application logs
- Not synced
