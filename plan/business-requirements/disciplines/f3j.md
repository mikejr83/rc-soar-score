# RC Soar Score Contest Scoring Rules - F3J

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document describes the FAI class designation of F3J, a thermal duration type discipline. This is the official profile for F3J when selecting it as a contest discipline. It is a variation on the shared duration-scoring model. Local deviations are allowed by the contest director but are treaded as overrides.

The FAI F3J task is similar to the Thermal Duration task. It differs in that pilots must attempt to fly the longest time within a working time without overflying it. The pilot attempts a precision landing to earn bonus points. This landing must occur within the working time to count. Overflying the working time results in a penalty.

## Scoring Options

F3J is a variation of how a duration type task is scored.

The following defaults are set in the scoring options section when this discipline is selected:

* Group Score - Normalized
* Total Score - Truncated to 1 decimal place

## Scoring Rules

The F3J discipline changes the wording for a typical duration task. The concept of target time is now "Working Time".

* Working Time - The length of the window for the pilots to fly.
* Fractional seconds - How many tenths, hundredths of a second to count. Shown as a drop down indicating the number of decimal places, 0 - 3. Defaults to 1.
* Points Per Second - How many raw points are awarded to the pilot based on their flight time. Defaults to 1.
* Landing Bonus - The selection of a landing bonus table. Should default to the system default for F3J contests or the last one used by the contest director for an F3J contest.

### Out of Bounds Landing

For the purposes of score entering the following needs to be indicated for an out of bounds landing:

Greater 75m from the pilot's landing marker.

### Computational Rules

The following rules are used when calculating the score and are not configurable or presented to the contest director.

* An out of bounds landing receives a 0 score.
* A late landing does not receive any landing bonus.
* A late landing incurs a 30 point penalty. This penalty stays with the round.

## Scoring Components

The following is data is requested to be entered for a score to be computed:

* Time flown
* Landing - Input based on the landing table selected.
* Late landing - The pilot did not land the model before the working time expired.
* Out of bounds landing - An indicator that the pilot landed more than 75m from their landing marker.

The screen should **not** allow the user to enter a time greater than a working time. Indicating a late landing should zero the landing bonus option and make it unavailable for selection.

## Scoring Formula

A pilot's raw score is computed by the following formula:

The number of points per second as defined by the contest multiplied by the number of seconds the pilot has flown.

The landing score is added based on the "Group Score" configuration.

The total is the pilots raw score.

## Re-Flights

The granting of re-flights are performed according the following order of priorities:

1. In the next available group within the round. If a group within the same round has an available spot (because the division of pilots was not evenly distributed between all groups) the contest director will assign them to that group. This can be determined by assessing if other groups within the round have recorded scores. The pilot cannot be placed into the same group with another team member if teams are in use.
2. A new group of a minimum of 4 pilots, or the largest group size if the largest group size is less than 6. The group of pilots is made up by competitors selected by random draw. Competitors from the same team are excluded. A randomly selected competitor may decline to fly. The draw is repeated until the group is filled. If a group cannot be filled because the randomly selected pilots decline the priority moves to the next.
3. The original group is re-flown at the end of the ongoing round.

In cases 2 and 3, for the competitors allocated the re-flight, the result of the re-flight is their score. For the other competitors, the better of their score in the ongoing round and the re-flight score will become their round score.
