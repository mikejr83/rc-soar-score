# Plan Index

The plans for RC Score Soar are split into Markdown files. These files contain information on the business requirements, architecture, user interface, implementation, and review of the solution. This document provides a high-level overview of those documents.

## Architecture Requirements

Documents in the sub-folder `architecture-requirements` define the application and service architecture.

- [`contest-state-and-transitions.md`](architecture-requirements/contest-state-and-transitions.md)
- [`data.md`](architecture-requirements/data.md) - Data-model entry point, invariants, and entity links.
- [`data/README.md`](architecture-requirements/data/README.md) - Canonical entity model, relationships, and open schema decisions.
- [`discipline-scoring.md`](architecture-requirements/discipline-scoring.md) - The shared scoring engine, discipline profiles, validation, and recalculation requirements.
- [`contest-publishing.md`](architecture-requirements/contest-publishing.md) - Requirements for publishing contest data and public projections.
- [`contest-visibility-state.md`](architecture-requirements/contest-visibility-state.md) - The visibility states for contests on the public site.
- [`offline-synchronization.md`](architecture-requirements/offline-synchronization.md)
- [`sync-protocol.md`](architecture-requirements/sync-protocol.md) - The wire protocol for synchronization: routes, request and response shapes, reason codes, versioning, paging, idempotency and call order.
- [`offline-usage.md`](architecture-requirements/offline-usage.md) - Requirements and goals for using the application offline.
- [`self-scoring-invites.md`](architecture-requirements/self-scoring-invites.md) - Requirements for issuing and enforcing participant self-scoring invitations.
- [`participant-score-entry.md`](architecture-requirements/participant-score-entry.md) - Requirements for participant score access, submission, and synchronization.
- [`participant-score-review.md`](architecture-requirements/participant-score-review.md) - Requirements for participant score reviews and retirement.
- [`participant-score-results.md`](architecture-requirements/participant-score-results.md) - Requirements for participant-visible group results and placement.
- [`participant-scoring-access.md`](architecture-requirements/participant-scoring-access.md) - The states that control participant scoring access.
- [`matrix-draw.md`](architecture-requirements/matrix-draw.md) - Flight matrix generation, simulated annealing optimization, team protection, and fairness metrics.
- [`score-review-and-validity-state.md`](architecture-requirements/score-review-and-validity-state.md) - Score validity and score review states.

## Business Specifications and Requirements

Documents in the sub-folder `business-requirements` define the operations and functions of the applications from a use case perspective. They describe how personas use the applications to perform the tasks necessary to achieve the intended functionality.

- [`accounts.md`](business-requirements/accounts.md) - Details how user accounts are used within the system.
- [`contest-configuration.md`](business-requirements/contest-configuration.md) - This contains the business requirements around configuring a soaring contest.
- [`contest-phases.md`](business-requirements/contest-phases.md) - A document containing the conceptual phases of a contest.
- [`contest-draw.md`](business-requirements/contest-draw.md) - The business requirements around organizing pilots into the groups within each round of the contest.
- [`contest-official-scoring.md`](business-requirements/contest-official-scoring.md) - The business requirements for official score entry and administration.
- [`contest-self-scoring.md`](business-requirements/contest-self-scoring.md) - The business requirements around how pilots or helpers enter scores during a contest and how they interact with the applications.
- [`contests.md`](business-requirements/contests.md) - A high-level overview of what a contest is and how they are run.
- [`managing-system.md`](business-requirements/managing-system.md) - The business requirements for managing the system data available to a contest director.
- [`score-review-requests.md`](business-requirements/score-review-requests.md) - The business requirements for requesting and managing score reviews.

### Contest Disciplines

The [`disciplines/README.md`](business-requirements/disciplines/README.md) document describes the shared discipline-scoring scope and links to the individual discipline rules.

- [`ales.md`](business-requirements/disciplines/ales.md) - ALES scoring rules.
- [`f3j.md`](business-requirements/disciplines/f3j.md) - F3J scoring rules.
- [`f3k.md`](business-requirements/disciplines/f3k.md) - F3K scoring rules.
- [`f3l.md`](business-requirements/disciplines/f3l.md) - F3L scoring rules.
- [`f5j.md`](business-requirements/disciplines/f5j.md) - F5J scoring rules.
- [`thermal.md`](business-requirements/disciplines/thermal.md) - Thermal duration scoring rules.

## User Interface

Documents in the `ui` sub-folder define the user experience and page-level requirements.

- [`contest-administration/README.md`](ui/contest-administration/README.md) - Contest director administration UI requirements.
- [`participant-scoring/README.md`](ui/participant-scoring/README.md) - Participant score-entry and review UI requirements.
- [`public-site/README.md`](ui/public-site/README.md) - Public contest site UI requirements.

## Data Model

Documents in the sub-folder `data-model` describe the 48-entity domain model that the code implements.

- [`data-model/README.md`](data-model/README.md) - Entity catalog, sync scope table and relationships.
- [`data-model/ERD.md`](data-model/ERD.md) - Every entity column and foreign key.
- [`data-model/enumerations.md`](data-model/enumerations.md) - The exact text of every enumeration value.
- [`data-model/contest-options.md`](data-model/contest-options.md) - Contest configuration options and defaults.
- [`data-model/examples/entities/README.md`](data-model/examples/entities/README.md) - One JSON example file per entity, used as a test base.
- [`tickets/mvp-implementation/035-implementation-plan.md`](tickets/mvp-implementation/035-implementation-plan.md) - How the domain models are built, one family per pull request.

## Application Plans

These documents describe the overall solution and the release scope.

- [`implementation-plan.md`](implementation-plan.md) - Repository, platform, technology, delivery plan and the release goal.
- [`application-plan.md`](application-plan.md) - Overall application scope, personas, and solution areas.

The overall flow of a contest from its description, to its creation and configuration, through to participants interaction are described over the two documents `contests.md` and `contest-phases.md`. The first document provides the basics of terminology usage and purpose and the second document walks through the conceptual phases of the contest.

## Work Tracking

Planned work is tracked in [GitHub issues](https://github.com/mikejr83/rc-soar-score/issues), grouped under milestones M0 to M5 and epic parent issues. The files under `tickets/` are the historical record of earlier planning and decisions; see [`../CONTRIBUTING.md`](../CONTRIBUTING.md).
