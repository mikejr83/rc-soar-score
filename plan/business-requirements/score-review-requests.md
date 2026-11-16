# RC Soar Score Business Requirements - Score Review Requests

The contest director may give participants the ability to request a score review. This is initiated by the participant from their self-scoring page.

This document will use the term "score" to mean the individual components that make up the final round score. When a participant requests a score review they are providing new details for the contest director to review and accept in order to update their score. This functionality is provide so that if a pilot enters data incorrectly they may submit new data. It is done as a request so that a contest director may review any updates before they take effect.

In this process the participant is the pilot or helper entering the score. The contest director will be reviewing these requests, with assistance from local operators on the same application installation when applicable. In places where the term "official" is used, it is synonymous with the contest director and does not identify a separate application user type.

## Process

1. The participant has entered a preliminary score in the self-scoring system (`Submitted` state).
2. The score is not locked (at the score, group, round, or contest level), and the contest director has not explicitly closed review for it. A score that the contest accepted automatically (see `contest-configuration.md`, Scores Become Official) can still be reviewed. A score the contest director marked official, corrected, or decided a review for cannot.
3. The participant has no other pending review request for that flight assignment/round.
4. The participant initiates a review by clicking "Request Review" in the self-scoring UI.
5. The participant is presented with the editable scoring form, prepopulated with their originally submitted values.
6. The participant adjusts the values (submit is enabled only if values change), optionally enters an explanation message, and submits the score review request.
7. The contest director is notified in the application (after a sync or via real-time connection) that a score review request is pending evaluation.
8. The contest director inspects the submitted preliminary score alongside the requested modifications and participant message.
9. The contest director evaluates the request:
   - **Approved**: The proposed modifications are accepted as the new official score revision (`Official` state) and trigger score recalculation.
   - **Rejected**: The proposed modifications are rejected, and the existing score is confirmed as official (`Official` state). An optional rejection reason may be recorded.
   - Once the director has decided the score through approval, rejection, marking it official, or direct administrative entry, participant review requests are closed for that score. Automatic acceptance does not close them.
   - If the director marks a score official while a request is open, the request is superseded and its proposal is not applied.
   - While a request is open, automatic acceptance holds that score. The other scores in the group or round are accepted as usual, and the results the held score affects stay preliminary.

## Auditing

Scores will be tracked in detail so that auditing of changes can be made without too much overhead on the system.

The originally entered score will be immutable. This holds if the contest director or participant entered the original score.

An official score will be tracked. This is always considered to be the latest and official scores.

The audit trail should then show:

- The originally entered score
- The user which entered the original score
- The current official score
- When the official score was updated. When the score is initially entered it will be the same as when the score is created. This value would change to reflect when a review updated and the system updated the score.
- All score review requests with score modification
- A status on the request showing if the review was approved or rejected.
