# RC Soar Score Business Requirements - Contest Documents

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. Many larger contests or contests of high importance (championships) require paper documentation. Even with electronic means to enter scores, participants still like to have a paper copy of their flight groups. This document outlines the various documents which need to be available for the contest director to print.

## General Information About Documents

The application will need to print these documents for a contest director. A contest director may not require any of these documents, may want them all, or just certain ones. The application should present a list of documents along with a short description of what they provide. The contest director can then decide which to print.

These documents will need to reflect the current configuration of the contest.

Certain documents will have configuration that the contest director may select. The configuration is only important for the printing of the document. It isn't necessary to be retained. It's general purpose is to dictate what information is shown.

All contest documents will display basic contest information at some location. This is defined within each document. It is important that any document produced be able to be identifiable to a specific contest.

## Scoring Sheet

The scoring sheet document provides a contest director or another official a manner with which to record all the scoring details for a contest.

This document is broken down into sections. Each round is a major division. A header should denote the section by its round number. Each group within the round should be another division. It's header should contain the group number. Each group within each round should contain a grid for recording scores. The grids contain the columns necessary for an official to record scoring details.

The grid should contain the following columns:

* Lane number / Pilot Number / Ordinal Position - The first column will be a numeric number. What is displayed depends on the contest configuration. If the configuration has specified assigned lane numbers it should appear. Next, if pilot numbers have been specified, it should show. Otherwise the first column will be an integer starting from one and incrementing with each pilot present in the round.
* Pilot Name
* A column for all required scoring details.
* Penalty
* Re-flight Requested
* Original Round

The contest director may specify the following optional fields:

* Country - The participants country
* Class - The participant's class. Available only if classes are enabled for the contest.

The document should indicate the basic contest information at the top of each page. This information includes:

* The contest name
* The contest dates
* The contest venue

## Score Cards

Scoring cards can be provided to participants or officials for the tracking of flight details. Score cards are used to record a single pilots flights. They are broken into two different types of documents.

### Per-Round

Per-round score cards are used to record a single flight. The actual document consists of all pilots in the contest having a group of sections, each section representing their flight within a round. Each of the sections can be thought of as a "card".

When printed on a single sheet of paper these cards appear as outlined areas that may be cut out to make actual cards. The card presents the following information:

* Header
* Pilot Information
* Round and Group
* Scoring table
* Penalty
* Signature block

The header should contain the contest information:

* Name
* Dates
* Venu

The pilot information should include:

* Team - If enabled
* Pilot Name
* Pilot number - If enabled

The scoring table is used to collect the flight details based on the contest discipline. The table should have a row for each detail to be recorded. The first column is used as a title for the item to be recorded. The second column is for the recording of the primary scores. A final column is presented to allow for the recording of a re-flight score.

A place for entering a penalty should be provided for both the primary flight and the re-flight.

The card will have a final area for a signature block. This will include a signature location for the pilot and for a timer. A signature should be provided for each on a primary flight and if a re-flight was performed.

### Per-Pilot

This is the most common document to be printed by a contest director. It presents the pilot's information along with their portion of the flight matrix. It is presented as a simple grid.

The card will have the contest information:

* Name
* Date
* Venue

The pilot's name should appear as a large title line.

The card should display a QR code that will enable the pilot or their helper to scan it and be taken directly to their self-scoring page.

The grid for tracking scoring should appear with the following columns:

* Round
* Group
* Scoring Details
* Penalty
* Timer
