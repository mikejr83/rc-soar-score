# Plan Index

The plans for RC Score Soar are split into Markdown files. These files contain information on the business requirements, architecture, user interface, implementation, and review of the solution. This document provides a high-level overview of those documents.

## Architecture Requirements

Documents in the sub-folder `architecture-requirements` define the application and service architecture.

* [`contest-state-and-transitions.md`](architecture-requirements/contest-state-and-transitions.md)
* [`data.md`](architecture-requirements/data.md) - Data-model entry point, invariants, and entity links.
* [`data/README.md`](architecture-requirements/data/README.md) - Canonical entity model, relationships, and open schema decisions.
* [`discipline-scoring.md`](architecture-requirements/discipline-scoring.md) - The shared scoring engine, discipline profiles, validation, and recalculation requirements.
* [`contest-publishing.md`](architecture-requirements/contest-publishing.md) - Requirements for publishing contest data and public projections.
* [`contest-visibility-state.md`](architecture-requirements/contest-visibility-state.md) - The visibility states for contests on the public site.
* [`offline-synchronization.md`](architecture-requirements/offline-synchronization.md)
* [`offline-usage.md`](architecture-requirements/offline-usage.md) - Requirements and goals for using the application offline.
* [`self-scoring-invites.md`](architecture-requirements/self-scoring-invites.md) - Requirements for issuing and enforcing participant self-scoring invitations.
* [`participant-score-entry.md`](architecture-requirements/participant-score-entry.md) - Requirements for participant score access, submission, and synchronization.
* [`participant-score-review.md`](architecture-requirements/participant-score-review.md) - Requirements for participant score reviews and retirement.
* [`participant-score-results.md`](architecture-requirements/participant-score-results.md) - Requirements for participant-visible group results and placement.
* [`participant-scoring-access.md`](architecture-requirements/participant-scoring-access.md) - The states that control participant scoring access.
* [`score-review-and-validity-state.md`](architecture-requirements/score-review-and-validity-state.md) - Score validity and score review states.

## Business Specifications and Requirements

Documents in the sub-folder `business-requirements` define the operations and functions of the applications from a use case perspective. They describe how personas use the applications to perform the tasks necessary to achieve the intended functionality.

* [`accounts.md`](business-requirements/accounts.md) - Details how user accounts are used within the system.
* [`contest-configuration.md`](business-requirements/contest-configuration.md) - This contains the business requirements around configuring a soaring contest.
* [`contest-phases.md`](business-requirements/contest-phases.md) - A document containing the conceptual phases of a contest.
* [`contest-draw.md`](business-requirements/contest-draw.md) - The business requirements around organizing pilots into the groups within each round of the contest.
* [`contest-official-scoring.md`](business-requirements/contest-official-scoring.md) - The business requirements for official score entry and administration.
* [`contest-self-scoring.md`](business-requirements/contest-self-scoring.md) - The business requirements around how pilots or helpers enter scores during a contest and how they interact with the applications.
* [`contests.md`](business-requirements/contests.md) - A high-level overview of what a contest is and how they are run.
* [`managing-system.md`](business-requirements/managing-system.md) - The business requirements for managing the system data available to a contest director.
* [`score-review-requests.md`](business-requirements/score-review-requests.md) - The business requirements for requesting and managing score reviews.

### Contest Disciplines

The [`disciplines/README.md`](business-requirements/disciplines/README.md) document describes the shared discipline-scoring scope and links to the individual discipline rules.

* [`ales.md`](business-requirements/disciplines/ales.md) - ALES scoring rules.
* [`f3j.md`](business-requirements/disciplines/f3j.md) - F3J scoring rules.
* [`f3k.md`](business-requirements/disciplines/f3k.md) - F3K scoring rules.
* [`f3l.md`](business-requirements/disciplines/f3l.md) - F3L scoring rules.
* [`f5j.md`](business-requirements/disciplines/f5j.md) - F5J scoring rules.
* [`thermal.md`](business-requirements/disciplines/thermal.md) - Thermal duration scoring rules.

## User Interface

Documents in the `ui` sub-folder define the user experience and page-level requirements.

* [`overview.md`](ui/overview.md) - Shared UI and application-frame requirements.
* [`landing-page.md`](ui/landing-page.md) - Landing page requirements.
* [`main-page.md`](ui/main-page.md) - Main contest-management page requirements.
* [`contest-workspace.md`](ui/contest-workspace.md) - Contest configuration, matrix, and state actions.
* [`matrix.md`](ui/matrix.md) - Flight matrix inspection and redraw interactions.
* [`official-scoring.md`](ui/official-scoring.md) - Director and local-operator score entry.
* [`new-contest-wizard.md`](ui/new-contest-wizard.md) - New contest and initial configuration workflow.
* [`offline-ui.md`](ui/offline-ui.md) - Offline application-frame, connectivity, and synchronization UI.
* [`participant-data.md`](ui/participant-data.md) - Director-owned participant editing requirements.
* [`participant-scoring.md`](ui/participant-scoring.md) - Invitation-based participant score entry and review.
* [`public-contest.md`](ui/public-contest.md) - Public published-contest viewing and publication controls.
* [`reports.md`](ui/reports.md) - Contest standings, result, and export views.

## Application Plans

These documents describe the overall solution and the minimum viable product.

* [`implementation-plan.md`](../implementation-plan.md) - Repository, platform, technology, and delivery plan.
* [`application-plan.md`](application-plan.md) - Overall application scope, personas, and solution areas.
* [`mvp-application.md`](mvp-application.md) - Minimum viable product scope and page requirements.

The overall flow of a contest from its description, to its creation and configuration, through to participants interaction are described over the two documents `contests.md` and `contest-phases.md`. The first document provides the basics of terminology usage and purpose and the second document walks through the conceptual phases of the contest.
