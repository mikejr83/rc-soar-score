# ModelCatalog

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md  
**Purpose:** A contest director's own reusable registry of aircraft models (name and manufacturer), so the director can pick from a maintained list when recording a pilot's model. Each entry belongs to one director and is never shared with other directors in the first release. Sharing across directors is a possible future policy.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Account (the owning director)  
**Child entities:** None

## Relationships

- Belongs to the director's Account (`owner_account_id`)
- Referenced by ContestModelLink (`model_catalog_id`) when a contest snapshot of the model is created. The reference is optional, because a link can be created from free text

## Fields/Properties

| Field              | Type    | Required | Default | Description                                                  |
| ------------------ | ------- | -------- | ------- | ------------------------------------------------------------ |
| `id`               | UUIDv7  | Yes      | —       | Primary key                                                  |
| `owner_account_id` | UUIDv7  | Yes      | —       | FK Account of the director who owns and maintains this entry |
| `name`             | String  | Yes      | —       | Model name                                                   |
| `manufacturer`     | String  | No       | —       | Model manufacturer                                           |
| `revision`         | Integer | Yes      | 0       | Revision counter for optimistic locking                      |

## Invariants and Constraints

- (`owner_account_id`, `name`, `manufacturer`) is unique. Where no manufacturer is given, (`owner_account_id`, `name`) is unique among that owner's entries without a manufacturer. Two directors may each keep an entry with the same name and manufacturer
- Catalog entries are stable references; edits update the model definition but do not alter historical scores
- Historical scores reference the contest snapshot (ContestModelLink), not the catalog entry directly
- Only the owning director (or a local operator acting under the director's authority) creates, edits or deletes an entry

## Lifecycle

- Created when a director adds a model to their registry
- Updated when model details change
- Entries persist as references for the director's future contests

## Privacy and Scope

- A catalog entry is private to its owning director. It is never shown to other directors, to participants, or on the public site. The model name and manufacturer shown on a contest come from the contest snapshot (ContestModelLink), which follows the contest's own visibility rules
- Director data: it synchronizes through the director's own sequence stream, scoped by `owner_account_id`

## Audit and Synchronization

- Mutation through revision-based optimistic concurrency
- Catalog edits are additive updates; historical integrity is preserved via contest model snapshots
- Deleting an entry creates a tombstone in the director stream. ContestModelLink snapshots are unaffected
