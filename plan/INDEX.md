# Plan Index

The plans for RC Score Soar are split into markdown files. These files contain information on various topics related to architecture, business specifications, and implementation guidelines. This document provides high-level overview of those documents.

## Architecture Requirements

Documents in the sub-folder `architecture-requirements` define how application and service architecture.

* `data.md` - A list of entities and their properties.

## Business Specifications and Requirements

Document in the sub-folder `business-requirements` define the various operations and functions of the applications from a use case perspective. They involve personas utilizing the application to perform the various tasks and operations necessary to achieve the end functionality of the software.

* `contest-configuration.md` - This contains the business requirements around configuring a soaring contest.
* `contest-phases.md` - A document containing the conceptual phases of a contest.
* `contest-draw.md` - The business requirements around organizing pilots into the groups within each round of the contest.
* `contest-self-scoring.md` - The business requirements around how pilots or helpers enter scores during a contest and how they interact with the applications.
* `contests.md` - A high-level overview of what a contest is and how they are run.
* `managing-system.md` - The business requirements for managing the system data available to a contest director.

The overall flow of a contest from its description, to its creation and configuration, through to participants interaction are described over the two documents `contests.md` and `contest-phases.md`. The first document provides the basics of terminology usage and purpose and the second document walks through the conceptual phases of the contest.
