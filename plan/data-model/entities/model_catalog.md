# ModelCatalog

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md  
**Purpose:** An aircraft model that belongs to a participant profile, so the same model can be used across several of the director's contests. A person can have any number of models. Each entry belongs to one profile and so to one director, and is never shared with other directors in the first release. (The entity keeps its original name, ModelCatalog; the catalog is now the list of a person's models.)  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ParticipantProfile (with the owning director's Account for synchronization scope)  
**Child entities:** None

## Relationships

- Belongs to a ParticipantProfile (`participant_profile_id`) and, for synchronization scope, to the profile's owning director Account (`owner_account_id`)
- Referenced by ContestModelLink (`model_catalog_id`) when a contest snapshot of the model is created. The reference is optional, because a contest link can be created from free text

## Fields/Properties

| Field                    | Type    | Required | Default | Description                                                                                                                                       |
| ------------------------ | ------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                     | UUIDv7  | Yes      | —       | Primary key                                                                                                                                       |
| `owner_account_id`       | UUIDv7  | Yes      | —       | FK Account of the director who owns the profile. Used only for synchronization scope; it always equals the profile's owner                        |
| `participant_profile_id` | UUIDv7  | Yes      | —       | FK ParticipantProfile of the person who flies this model                                                                                          |
| `name`                   | String  | Yes      | —       | Model name                                                                                                                                        |
| `manufacturer`           | String  | No       | —       | Model manufacturer                                                                                                                                |
| `model_id`               | String  | No       | —       | The contestant-applied identifier: the marking, number or registration the pilot has put on the model. Not required, and never used for scoring   |
| `revision`               | Integer | Yes      | 0       | Revision counter for optimistic locking                                                                                                           |

## Invariants and Constraints

- (`participant_profile_id`, `name`, `manufacturer`) is unique. Where no manufacturer is given, (`participant_profile_id`, `name`) is unique among that profile's entries without a manufacturer
- A profile can have any number of models, including none
- A model belongs to the profile's person only. Non-fliers have no models in a contest (see ContestModelLink)
- Catalog entries are stable references; edits update the model definition but do not alter historical contest snapshots
- Only the owning director (or a local operator acting under the director's authority) creates, edits or deletes an entry
- A model that a contest link references is archived by the director in the UI rather than deleted. If it is deleted, the contest links keep their snapshot and their `model_catalog_id` is no longer resolvable

## Lifecycle

- Created when a director adds a model to a profile, either on the profile or from a contest participant row
- Updated when model details change
- Persists with the profile for the director's future contests. A profile with no participations can be deleted with its models; deleting the profile creates tombstones for its models

## Privacy and Scope

- A model entry is private to its owning director. It is never shown to other directors, to participants, or on the public site. The model name and manufacturer shown on a contest come from the contest snapshot (ContestModelLink), which follows the contest's own visibility rules
- Director data: it synchronizes through the director's own sequence stream, scoped by `owner_account_id`

## Audit and Synchronization

- Mutation through revision-based optimistic concurrency
- Edits are additive updates; historical integrity is preserved through contest model snapshots
- Deleting an entry creates a tombstone in the director stream. ContestModelLink snapshots are unaffected
