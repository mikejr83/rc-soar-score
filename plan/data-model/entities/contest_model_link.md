# ContestModelLink

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md  
**Purpose:** A model that a participant has entered in a specific contest, snapshotted for the contest so later edits to the profile's model do not rewrite the contest's records. A participation can have any number of them (none, one, or several). It also carries the identifier the contest director applied to the model, such as a serial number for certification.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ContestParticipation  
**Child entities:** None

## Relationships

- Join between ModelCatalog (optional) and ContestParticipation
- Belongs to a ContestParticipation with the `Pilot` role type. Non-fliers have no model links
- Referenced by ContestRoundModel (`contest_model_link_id`) when the director records which model started a round (see below)
- Nothing else in the contest references a model link. In particular, flight records, scores and results do not

## Fields/Properties

| Field                         | Type    | Required | Default | Description                                                                                                                                                                                                       |
| ----------------------------- | ------- | -------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                          | UUIDv7  | Yes      | —       | Primary key                                                                                                                                                                                                       |
| `contest_id`                  | UUIDv7  | Yes      | —       | Foreign key to Contest                                                                                                                                                                                            |
| `contest_participation_id`    | UUIDv7  | Yes      | —       | Foreign key to ContestParticipation                                                                                                                                                                               |
| `model_catalog_id`            | UUIDv7  | No       | —       | Foreign key to ModelCatalog (optional)                                                                                                                                                                            |
| `model_name`                  | String  | Yes      | —       | Model name for this contest entry                                                                                                                                                                                 |
| `manufacturer`                | String  | No       | —       | Model manufacturer for this contest entry                                                                                                                                                                         |
| `model_id`                    | String  | No       | —       | The contestant-applied identifier: the marking, number or registration the pilot put on the model. Copied from the catalog entry when there is one, and editable on the contest entry                              |
| `contest_specific_identifier` | String  | No       | —       | The identifier the contest director applied to the model for this contest, for example a serial number or sticker used to show that the model was certified before the contest. Entered by the director, per contest |
| `revision`                    | Integer | Yes      | 0       | Revision counter for optimistic locking                                                                                                                                                                           |

## Invariants and Constraints

- A participation can have any number of model links. (`contest_participation_id`, `model_name`, `manufacturer`, `model_id`) identifies a model entry the director would otherwise enter twice; the application warns about an exact duplicate
- Only participations whose `role_type` is `Pilot` have model links
- If `model_catalog_id` is provided, the snapshot starts as a copy of the catalog definition. After that it is independent
- Missing model data is never an error. A model-enabled contest in which a pilot has no model link shows a notice. It never blocks creating the contest, drawing the matrix, adding a participant, opening scoring, entering scores or publishing
- No scoring or draw rule reads a model link in the first release. Disciplines that need a model for a round (F3B) use ContestRoundModel
- Editing the snapshot is allowed after flights are scored. The edit is an audited mutation and never recalculates any score

## Lifecycle

- Created when the director adds a model to a participant in the contest, at or after contest creation
- Removed when the director removes the model from the participant. A link that a ContestRoundModel references cannot be removed
- After contest end, the snapshot remains as part of historical records

## Privacy and Scope

- Model information is public within the contest
- The contest-specific identifier is shown wherever the contest shows the model

## Audit and Synchronization

- Mutation through revision-based optimistic concurrency
- Contest data: synchronizes through the contest stream
