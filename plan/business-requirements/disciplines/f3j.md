# RC Soar Score Contest Scoring Rules - F3J

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document describes the FAI class designation of F3J, a thermal duration type discipline.

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
