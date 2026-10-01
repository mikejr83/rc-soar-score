# ModelCatalog

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md
**Purpose:** Reusable registry of aircraft models (name and manufacturer) that contestants reference. Director-owned or shared across contests so pilots can select from a maintained list.
**Identifier:** `id` (UUIDv7)
**Parent entity:** System or Contest (depending on scope)
**Child entities:** None

## Relationships
- Referenced by ContestModelLink when a contest-snapshot of the model is created
- Models may be shared across contests via their model_catalog_id

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUIDv7 | Yes | — | Primary key |
| name | String | Yes | — | Model name |
| manufacturer | String | No | — | Model manufacturer |
| revision | Integer | Yes | 0 | Revision counter for optimistic locking |

## Invariants and Constraints
- name and manufacturer pair must be unique (or name is unique if no manufacturer specified)
- Catalog entries are stable references; edits update the model definition but do not alter historical scores
- Historical scores reference the contest-snapshot (ContestModelLink), not the catalog entry directly

## Lifecycle
- Created when a new model is added to the registry
- Updated when model details change
- Entries persist as references for future contests

## Privacy and Scope
- Model catalog is shared across contests
- All model names and manufacturers are visible to users

## Audit and Synchronization
- Mutation through revision-based optimistic concurrency
- Catalog edits are additive updates; historical integrity is preserved via contest-model snapshots