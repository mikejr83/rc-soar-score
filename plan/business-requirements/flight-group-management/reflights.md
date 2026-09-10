# RC Soar Score - Flight Group Management - Re-Flights

RC soaring disciplines have rules for the granting of re-flights. Extenuating circumstances may occur which entitle a pilot to another chance to record a score. The re-flight process is generally dictated by the discipline rules but contest directors may use their discretion to dictate how the process is achieved.

Contest disciplines can define a priority for how a pilot is assigned a new group for a re-flight. The application should present to the contest director the options per the contest discipline in order for the director to make the best decision. The application should not be the definitive method for determining a re-flight group as it is not aware of all possible situations which may result in one method being used.

A re-flight can occur the following ways:

* The pilot(s) awarded a re-flight is(are) placed within another group within the same round.
* A new group for the round is created with the pilot(s) requesting a re-flight. This group is flown after all other groups have flown for the round. The group's membership is determined by a random draw of pilots. The number of pilots drawn is determined by the discipline or by the contest director.
* The original flight group is re-flown, ie re-fly the entire group.

## Re-Flight Scoring

A pilot which was awarded a re-flight will have their raw score calculated per the rules of the contest discipline. The normalization of that score will be against the pilots in the re-flight group. That score becomes their round score.

In the cases where the group of pilots flying with the pilot(s) awarded a re-flight, those pilots not awarded the re-flight will keep the better of their two scores.

## Data Tracking

The original scores should be tracked as they are entered for pilots not awarded a re-flight. The contest director will indicate that a pilot is awarded a re-flight by selecting this option for the pilot in their flight group scoring page (see [`director-score-entry.md`](../director-score-entry.md) for details on the flight group scoring page).

## Re-Flight Types

### Move Pilot to Group

This is the preferred option for a pilot awarded a re-flight.

The contest director can use the same mechanism as described in [`move-pilot.md`](./move-pilot.md) to move a pilot to another flight group. In this situation, the pilot must be moved to another group within the same round. If this is not achievable due to the contest configuration the application should look to the contest discipline for what to do next. Even if this is achievable the contest director may select another method. When this is the case they should be alerted to a deviation from any official contest rules.

### Random Draw Re-flight

The application should randomly chose the pilots to fly with the pilot(s) awarded a re-flight. The contest director will be required to enter the group size. This initial value for the group size should be dictated by the contest discipline. The application can determine if the group size is not achievable due to the contest configuration and indicate that the maximum group size will be based off of the contest configuration.

The application will present the draw showing the pilots which will compete in the group. The contest director will announce the draw. This can be sent via notification to the participant's self-scoring interface. The participant should be able to decline participation. The contest director should see this indicated in the application. The contest director should be able to manually indicate that a pilot declines. The draw should continue. The director should then be able to finalize the group.

### Re-Fly Entire Group

The contest director will have the ability to request a re-flight of the entire group. The group is effectively "copied". It should be denoted by an incrementing "re-flight number". It is possible for the same group to have a situation where a re-flight is awarded during the re-flight.

The notification that a participant receives for a re-flight in this scenario is an indication that the re-flight will be occurring. This type of re-flight does not allow the opt-out by the pilot. The notification is a courtesy that the re-flight will occur.

## Notification of a Re-Flight

Notifications should be sent to those pilots of a re-flight if the application is functioning where it has online connectivity and is able to interact with the remote system.

Notification should be performed in the following scenarios:

* Random Draw Re-Flight
* Re-Fly Entire Group

## Display of Re-Flight

The self-scoring screens for participants will display if a re-flight has occurred for their round. The screen should show their overall scoring details as the contest discipline details for re-flights. This will typically be the best group score of both flights. The score details will be from their highest scoring flight. The participant should be able to review their original flight score if it was worse or the re-flight scores if it was worse.
