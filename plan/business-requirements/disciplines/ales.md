# RC Soar Score - Discipline Scoring Rules - ALES

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document covers the scoring rules governing the ALES discipline.

ALES is an acronym for Altitude Limited Electronic Soaring.

## Scoring Options

ALES is a variation of how a duration type task is scored.

The largest change is that the "Group Score" selection should be set to "Time" as a default. Contest directors changing the "Group Score" after the discipline has been selected should be warned that their contest no longer meets the traditional definition of the ALES soaring discipline.

## Scoring Rules

The ALES discipline is a duration task. The pilot is attempting to fly a prescribed time and perform a precision landing. Thus the following must be configured by the contest director:

* Target Time - The duration of the flight the pilots will be attempting. Should be enterable as MM:ss or seconds.
* Fractional Seconds - How many tenths, hundredths of a second to count. Shown as a drop down indicating the number of decimal places, 0 - 3. Defaults to 0.
* Points Per Second - How many raw points are awarded to the pilot based on their flight time. Defaults to 1.
* Landing Bonus - The selection of a landing bonus table. Should default to the system default for ALES contests or the last one used by the contest director for an ALES contest.

### Computational Rules

The following rules are used when calculating the score and are not configurable or presented to the contest director.

* An out of bounds landing receives a 0 score.
* Over-flying of the target time - A point is awarded for each second of flight. If the pilot flies over the the target time they start accruing negative points. If the target time of 600 seconds, 10 minutes, is given and the pilot flies 602 seconds, at 1 point per second they would receive 598 points. This is 600 points for the target time plus negative 2 points for the 2 seconds flown over the target time.

### Out of Bounds Landing

For the purposes of score entering the following needs to be indicated for an out of bounds landing:

Greater 75m from the pilot's landing marker.

## Scoring Components

The following is data is requested to be entered for a score to be computed:

* Time flown
* Landing - Input based on the landing table selected.
* Motor Restart - An indicator that the pilot restarted their motor in flight and is receiving a 0 score for the flight.
* Out of bounds landing - An indicator that the pilot landed more than 75m from their landing marker.

The screen should allow the user to enter a time greater than a target time. Times greater than a minute past the target time should be met with a warning.

The screen should disable and 0 all fields if the pilot selects an out of bounds landing.

The screen should disable and 0 all fields if the pilot indicates a motor restart.

## Scoring Formula

A pilot's raw score is computed by the following formula:

The number of points per second as defined by the contest multiplied by the number of seconds the pilot has flown.

The landing score is added based on the "Group Score" configuration.

The total is the pilots raw score.
