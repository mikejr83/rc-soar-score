# RC Soar Score Architecture - Participant Score Results

## Purpose and boundaries

This document defines the participant-visible group results and contest placement views available through the self-scoring interface. It does not define public publishing. Public projection updates remain governed by [contest-publishing.md](contest-publishing.md).

## Participant-safe result views

1. After a score is accepted, the service must provide the participant's group results and current placement required by the business workflow. These values must be calculated from the current authorized score revisions, including the `Cumulative Penalty` deduction at the contest calculation stage, and must be marked preliminary when the group or ranking is incomplete.
2. Participant-visible preliminary group results must update as authorized participant submissions are accepted, independently of the contest director's policy for copying eligible changes to the public projection. This participant update must not publish or alter the public projection.
3. Missing-score estimates, pending review indicators, and score states must be explicit in the response so the client does not present an estimate as an entered or official value.
4. Participant result views must exclude email addresses, invitation credentials, director-only notes, private audit details, unauthorized team data, and unpublished data outside the participant's permitted contest scope.
