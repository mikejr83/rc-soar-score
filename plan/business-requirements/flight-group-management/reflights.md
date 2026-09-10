# RC Soar Score - Flight Group Management - Re-Flights

RC soaring disciplines have rules for the granting of re-flights. Extenuating circumstances may occur which entitle a pilot to another chance to record a score. The re-flight process is generally dictated by the discipline rules but contest directors may use their discretion to dictate how the process is achieved.

Contest disciplines can define a priority for how a pilot is assigned a new group for a re-flight. The application should present to the contest director the options per the contest discipline in order for the director to make the best decision. The application should not be the definitive method for determining a re-flight group as it is not aware of all possible situations which may result in one method being used.

A re-flight can occur the following ways:

* The pilot(s) awarded a re-flight is(are) placed within another group within the same round.
* A new group for the round is created with the pilot(s) requesting a re-flight. This group is flown after all other groups have flown for the round. The group's membership is determined by a random draw of pilots. The number of pilots drawn is determined by the discipline or by the contest director.
* The original flight group is re-flown, ie re-fly the entire group.

Each re-flight is a separate flight attempt linked to its source group and credited round. It must have a type, incrementing sequence number, status, reason, creating director, and audit history. A re-flight does not overwrite the original attempt.

The re-flight lifecycle is `Proposed`, `DrawPending`, `AwaitingResponses`, `ReadyToFly`, `Flown`, `Scored`, `Finalized`, or `Cancelled`. The contest director may cancel a re-flight before it is finalized, but cancellation must not remove historical scores or responses.

## Re-Flight Scoring

A pilot which was awarded a re-flight will have their raw score calculated per the rules of the contest discipline. The discipline profile defines the normalization population and how the re-flight attempt is selected for the pilot's official round score. The application must not assume that the higher score always wins.

In cases where pilots fly with a pilot awarded a re-flight, pilots not awarded the re-flight will keep the better of their two scores. "Better" means the discipline's official comparison value after normalization, penalties, and applicable re-flight rules; raw scores are retained for audit.

## Data Tracking

The original scores should be tracked as they are entered for pilots not awarded a re-flight. The contest director will indicate that a pilot is awarded a re-flight by selecting this option for the pilot in their flight group scoring page (see [`director-score-entry.md`](../director-score-entry.md) for details on the flight group scoring page).

Awarding a re-flight creates a new attempt and does not mutate the prior score. A re-flight may be created only while the affected score is not locked and the contest is not `Completed`, unless an authorized score-correction workflow explicitly permits it. The prior attempt, re-flight attempt, selected official result, and superseded result must remain distinguishable.

## Re-Flight Types

### Move Pilot to Group

This is the preferred option for a pilot awarded a re-flight.

The contest director can use the same mechanism as described in [`move-pilot.md`](./move-pilot.md) to move a pilot to another flight group. In this situation, the pilot must be moved to another group within the same round. If this is not achievable due to the contest configuration the application should look to the contest discipline for what to do next. Even if this is achievable the contest director may select another method. When this is the case they should be alerted to a deviation from any official contest rules.

### Random Draw Re-flight

The application should randomly choose the pilots to fly with the pilot(s) awarded a re-flight. The contest director will be required to enter the group size. This initial value for the group size should be dictated by the contest discipline. The application can determine if the group size is not achievable due to the contest configuration and indicate that the maximum group size will be based off of the contest configuration.

The discipline profile defines the eligible draw pool, exclusions, minimum and default group size, and team constraints. The draw must record the candidate pool, exclusions, selected pilots, randomization seed or equivalent reproducible input, and each participant's response. A draw is not final until the contest director finalizes it. If the requested size cannot be achieved, the application must show the achievable maximum and require the director to confirm the exception.

The application will present the draw showing the pilots which will compete in the group. The contest director will announce the draw. This can be sent via notification to the participant's self-scoring interface. The participant should be able to decline participation. The contest director should see this indicated in the application. The contest director should be able to manually indicate that a pilot declines. The draw should continue. The director should then be able to finalize the group.

Only pilots who are eligible under the discipline and contest configuration may be drawn. A declined pilot is excluded from the finalized group and remains in the audit history. The director may finalize while offline or without an acknowledgement; notifications are advisory and do not determine eligibility.

### Re-Fly Entire Group

The contest director will have the ability to request a re-flight of the entire group. The group is effectively "copied". It should be denoted by an incrementing "re-flight number". It is possible for the same group to have a situation where a re-flight is awarded during the re-flight.

The notification that a participant receives for a re-flight in this scenario is an indication that the re-flight will be occurring. This type of re-flight does not allow the opt-out by the pilot. The notification is a courtesy that the re-flight will occur.

The copied group retains its original membership and scores as historical data. The copied group receives the next re-flight number for that source group. A re-flight of a re-flight is linked to the immediately preceding attempt and receives the next number; it does not replace the prior attempt.

## Notification of a Re-Flight

Notifications should be sent to those pilots of a re-flight if the application is functioning where it has online connectivity and is able to interact with the remote system.

Notification should be performed in the following scenarios:

* Random Draw Re-Flight
* Re-Fly Entire Group

Notification delivery, acknowledgement, decline, and manual director overrides must be recorded. A move-to-group re-flight does not require a participant response, but the participant-facing result must identify the resulting attempt when online. Offline operation must not block creation, scoring, or finalization; pending notifications should be delivered when connectivity returns.

## Display of Re-Flight

The self-scoring screens for participants will display if a re-flight has occurred for their round. The screen should show their overall scoring details as the contest discipline details for re-flights. This will typically be the best group score of both flights. The score details will be from their highest scoring flight. The participant should be able to review their original flight score if it was worse or the re-flight scores if it was worse.

The participant view must distinguish the current official round result from each underlying attempt, show which attempt supplied the official result, and identify any pending or cancelled re-flight. It must use the discipline profile's selection rule rather than deriving the result from display order or a generic higher-score comparison.
