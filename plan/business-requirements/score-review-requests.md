# RC Soar Score Business Requirements - Score Review Requests

The contest director may give participants the ability to request a score review. This is initiated by the participant from their self-scoring page.

This document will use the term "score" to mean the individual components that make up the final round score. When a participant requests a score review they are providing new details for the contest director to review and accept in order to update their score. This functionality is provide so that if a pilot enters data incorrectly they may submit new data. It is done as a request so that a contest director may review any updates before they take effect.

In this process the participant is the pilot or helper entering the score. The contest director or official will be reviewing these requests. In places where the term "official" is used the contest director can be used interchangeably.

## Process

1. The participant has entered a score in the system.
2. The participant has no other pending reviews for the round.
3. The participant indicates they need to submit a score review by clicking the button in the UI.
4. The participant is presented with the editable scoring form. The form is prepopulated with the values that are currently considered official.
5. The participant makes any adjustments needed.
6. The participant submits the score review request.
7. The contest director is notified in the application (after a sync or through some communication with the server) that a score review request is to be evaluated. The contest director may see the notification as they are moving between the group scoring pages.
8. The contest director is presented with the current official score and the requested score modifications as entered by the participant. If the participant left a message, it is shown as well.
9. The contest director may approve or reject the request. If the request is approved the modifications become the official score. If the contest director rejects the request a rejection message may be entered.

## Auditing

Scores will be tracked in detail so that auditing of changes can be made without too much overhead on the system.

The originally entered score will be immutable. This holds if the contest director or participant entered the original score.

An official score will be tracked. This is always considered to be the latest and official scores.

The audit trail should then show:

* The originally entered score
* The user which entered the original score
* The current official score
* When the official score was updated. When the score is initially entered it will be the same as when the score is created. This value would change to reflect when a review updated and the system updated the score.
* All score review requests with score modification
* A status on the request showing if the review was approved or rejected.
