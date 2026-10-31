# ContestRoundModel

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md  
**Purpose:** Records which of a pilot's models started a round. In F3B a pilot flies three tasks (Speed, Distance, Duration) as separate flights in one round, and the rules require the same model for all three, so the model that starts the round decides the model for every task of that round. Contest directors record it per pilot and per round. First-release disciplines never write this record  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ContestParticipation  
**Child entities:** None

## Relationships

- Belongs to a ContestParticipation (`contest_participation_id`) and a Round (`round_id`)
- References one ContestModelLink (`contest_model_link_id`) of the same participation

## Fields/Properties

| Field                      | Type    | Required | Default | Description                                                |
| -------------------------- | ------- | -------- | ------- | ---------------------------------------------------------- |
| `id`                       | UUIDv7  | Yes      | —       | Primary key                                                |
| `contest_id`               | UUIDv7  | Yes      | —       | Foreign key to Contest                                     |
| `contest_participation_id` | UUIDv7  | Yes      | —       | Foreign key to ContestParticipation                        |
| `round_id`                 | UUIDv7  | Yes      | —       | Foreign key to Round                                       |
| `contest_model_link_id`    | UUIDv7  | Yes      | —       | Foreign key to the ContestModelLink that started the round |
| `revision`                 | Integer | Yes      | 0       | Revision counter for optimistic locking                    |

## Invariants and Constraints

- (`contest_participation_id`, `round_id`) is unique: one starting model per pilot per round
- The model link must belong to the same participation
- The record is optional. A round with none is not an error; the application shows a notice at most
- When a participation has exactly one model link, the application may show it as the starting model without a stored record
- Whether a model change within a round forfeits scores is a discipline rule (F3B), not a property of this record
- Not used by F5J, F3J, Thermal Duration or ALES

## Lifecycle

- Created when the director records the starting model for a round, before or after the flights; changed or removed by the director with an audit entry

## Privacy and Scope

- Visible within the contest, like the model link

## Audit and Synchronization

- Mutation through revision-based optimistic concurrency
- Contest data: synchronizes through the contest stream
- Scope: this entity is documented ahead of the F3B discipline. No table, repository or API exists for it yet
