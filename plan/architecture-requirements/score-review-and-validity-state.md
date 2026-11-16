# RC Soar Score Architecture - Scoring States

This document defines two different sets of states, the states for a score and the states used when making a score review request.

## Score States

A score is the data that is entered for a pilot in a specific group and round.

| State            | Meaning                                                                                                          | Entry condition                                                                                                                                                         | Exit / next transition                                                        |
| ---------------- | ---------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Draft            | Score form is active and not submitted                                                                           | Initial state                                                                                                                                                           | Draft → Submitted or Retired                                                  |
| Submitted        | Score is recorded as the current participant submission; its official status is determined by contest policy     | The participant enters the scoring details in the form and submits.                                                                                                     | Submitted -> Under review, Official, or Locked                                |
| Review requested | The review request is sent to the contest director                                                               | The request for review has been sent.                                                                                                                                   | Review requested → Under review                                               |
| Under review     | Director or official is evaluating the request                                                                   | The review request was received and has been viewed by the contest director.                                                                                            | Under review → Official                                                       |
| Official         | The current score revision is the contest director's accepted value. This does not erase earlier submissions.    | A contest director marks a score official, approves a review, rejects a review, or makes an authorized correction; or the contest accepts the submission automatically. | Official → Locked, or a new official revision through the correction workflow |
| Locked           | Score is no longer editable due to contest lock or completion                                                    | The contest director locking the contest, round, or group scores                                                                                                        | Previous state                                                                |
| Retired          | The participant has retired and this assignment is represented as a retirement/zero outcome under contest rules. | The participant's authorized retirement action is accepted.                                                                                                             | Terminal for participant entry; read access remains available                 |

### Draft

When the score is being entered it is in the draft state. Any UI would show the relevant inputs for the scoring details which are needed.

### Submitted

The user has entered the scoring details and they were submitted. Any input that generated warnings or confirmations were acknowledged. The screen has become readonly.

### Review Requested

The review has been submitted. The contest director receives a notification that there is a pending score review.

### Under Review

The contest director has viewed the review request. The contest director hasn't made a determination on if the changes are approved or denied. The score review flow is in progress.

### Official

A score becomes official when the following occurs:

- The contest director enters or marks the score as official.
- The score review flow completes with an approved outcome (applying the proposed revision as official).
- The score review flow completes with a rejected outcome (retaining the existing official score).
- The contest accepts the stored participant submission automatically, under the contest's **Scores become official** setting (see below).

An authorized director correction creates a new official revision and preserves the prior value.

#### How a score became official

Every official version records how it was selected. This is its **selection origin**:

| Origin            | Meaning                                                                                   | Official actor          |
| ----------------- | ----------------------------------------------------------------------------------------- | ----------------------- |
| `manual`          | The director entered the score, or marked the stored submission official.                 | The director            |
| `automatic`       | The contest accepted the stored submission because its configured scope was fully scored. | None (system authority) |
| `review_decision` | The director decided a review request (approved or rejected it).                          | The director            |

Official status alone never tells which of these happened, and never closes a participant's chance to ask for a review. Only an explicit director decision does (see **Review eligibility**).

#### Automatic acceptance

The director chooses when scores become official: **At end of round** (the default for a new contest), **At end of flight group**, or **Manually**. The choice is independent of when results are published to the public site.

- "End" means every required score in the scope has been submitted. It is not a scheduled time. A scope is complete when every required, live flight in it has a `Submitted`, `Under review` or `Official` score, using the contest's current assignments and its retirement and reflight rules. A missing score is never counted as a zero.
- When the scope becomes complete, the server makes the eligible submissions official without any director action. A valid submitted zero is accepted like any other value, with no extra acknowledgement.
- A score with an open review request is held. Only that score is held: the others in the scope are accepted. The results the held score affects stay preliminary. The server never supersedes a review and never applies its proposal on its own.
- The director may change the setting while the contest is running. Enabling it, or moving to a wider scope, accepts the scopes that are already complete. Switching to **Manually** stops future automatic acceptance and never undoes an official version.
- A contest with no stored setting behaves as **Manually**, so contests created before the setting existed do not change.
- Automatic acceptance happens on the server, after a participant submission, a director score write, a review decision, a retirement or assignment change, a change of the setting, or an accepted synchronization. It does not need an open director page. An interrupted evaluation is repeated without creating a second official version.
- Importing a contest never accepts scores. A contest exported from RC Soar Score keeps its score states and its setting exactly. A contest imported from another program arrives with its scores already official.

#### Review eligibility

A participant may submit a score review request against a score while review requests are enabled, the score is not locked at any level, and no explicit director decision has closed review for the current score. That includes a `Submitted` score and a score that was made official automatically.

Closing review for the current score takes an explicit director act on that score: the director marks the stored submission official, enters a correction, or decides a review. Marking an automatically accepted score official records the decision and closes review without creating a second, identical official version. A review request already open when the director does this is superseded, and its proposal is not applied.

There is no timed window. The pilot who submits the last score in a scope has the same chance to ask for a review as those who submitted earlier. A new official version of the score (for example a correction) starts a new current score.

### Locked

The contest director can lock scores. Locking scores prevents the scores from being modified. Score review requests cannot be submitted for locked scores. Locks can be enacted at the score, group, round, or contest level. Once scores for a group or round become official, the director may lock them so that they are not inadvertently modified or subject to further review requests.

## Score Review States

A participant can submit a score review request if the contest director has configured the contest to allow it, the score is not locked, and no explicit director decision has closed review for the current score. A score that the contest made official automatically is still eligible. The request must target the current score revision. See **Review eligibility** above.

| State              | Meaning                                                                    | Entry condition                                | Exit / next transition                |
| ------------------ | -------------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------- |
| Draft score review | Participant fills out new scoring details for review                       | Initial state                                  | Draft score review → Review submitted |
| Review submitted   | The review has been filled and has not been viewed                         | The submission of the review                   | Review Submitted → Under review       |
| Under review       | The review has been viewed by the contest director and is pending decision | The contest director views the review request. | Under review → Approved or rejected   |
| Approved           | The review is approved.                                                    | Contest director marks the review as approved. | terminal                              |
| Rejected           | The review is rejected.                                                    | Contest director marks the review as rejected. | terminal                              |

### Draft Score Review

The contest is configured to allow participants to submit score reviews. The participant has selected to request a score review. The UI populates itself from the last submitted data. The user makes any corrections and acknowledges any warnings or confirmations.

### Review Submitted

The participant has filled out the review form. They have acknowledged any warnings or confirmations. The review along with the proposed score details is stored and a notification is sent to the contest director to perform the review.

### Score Review Request Under Review

Once the contest director has received the notification and viewed the score review request the state becomes "Under Review". This is used as an indicator to the participant that their review has been received and that it is under consideration.

The contest director moves the review to the next state by either approving or rejecting the proposed changes.

### Approved

The review request was approved and the proposed scores become the current official revision for the flight. Earlier submissions remain in the audit history.

### Rejected

The review request was rejected. The proposed score changes are not applied. The current official score remains authoritative, and the rejection is an explicit director decision that closes review for it.
