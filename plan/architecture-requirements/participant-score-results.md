# RC Soar Score Architecture - Participant Score Results

## Purpose and boundaries

This document defines the participant-visible group results and contest placement views available through the self-scoring interface. It does not define public publishing. Public projection updates remain governed by [contest-publishing.md](contest-publishing.md).

## Participant-safe result views

1. After a score is accepted, the service must provide the participant's group results and current placement required by the business workflow. These values must be calculated from the current authorized score revisions, including the `Cumulative Penalty` deduction at the contest calculation stage, and must be marked preliminary when the group or ranking is incomplete.
2. Participant-visible preliminary group results must update as authorized participant submissions are accepted, independently of the contest director's policy for copying eligible changes to the public projection. This participant update must not publish or alter the public projection.
3. Missing-score estimates, pending review indicators, and score states must be explicit in the response so the client does not present an estimate as an entered or official value.
4. While the director is hiding overall results, participant result views must show overall scores and placing only as of the recorded round, and must continue to show round scores and flight-group positions. Hiding ends by the rules in [contest-state-and-transitions.md](contest-state-and-transitions.md).
5. Participant result views must exclude email addresses, invitation credentials, director-only notes, private audit details, unauthorized team data, and unpublished data outside the participant's permitted contest scope.
6. When teams are enabled, the participant results view must include the team standings for every participant, not only helpers. Team standings follow the same rules as individual standings: they are calculated, marked preliminary while incomplete, and held at the recorded round while the director is hiding overall results.
7. A helper viewing a pilot's group results and placement must receive exactly what the pilot would receive. The service must derive the view from the pilot, not the helper.
8. The overall results view must show only the individual group scores needed for a phone layout and, when the contest results are public, the link to the contest on the public site.
