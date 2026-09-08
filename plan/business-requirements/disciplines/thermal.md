# RC Soar Score - Discipline Scoring Rules - Thermal Duration

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document covers the scoring rules governing the Thermal Duration.

Thermal duration is similar to ALES in that it involves a pilot attempting to fly a prescribed time but the defaults for the scoring options and scoring rules differ.

## Scoring Options

Thermal Duration is a variation of how a duration type task is scored.

"Group Score" selection should be set to "Normalized" as a default. Contest directors changing the "Group Score" after the discipline has been selected should be warned that their contest no longer meets the traditional definition of the Thermal Duration soaring discipline.

## Scoring Rules

The Thermal Duration discipline is a duration task. The pilot is attempting to fly a prescribed time and perform a precision landing. Thus the following must be configured by the contest director:

* Target Time - The duration of the flight the pilots will be attempting. Should be enterable as MM:ss or seconds.
* Fractional Seconds - How many tenths, hundredths of a second to count. Shown as a drop down indicating the number of decimal places, 0 - 3. Defaults to 0.
* Points Per Second - How many raw points are awarded to the pilot based on their flight time. Defaults to 1.
* Landing Bonus - The selection of a landing bonus table. Should default to the system default for Thermal Duration discipline contests or the last one used by the contest director for a Thermal Duration contest.

### Computational Rules

The following rules are used when calculating the score and are not configurable or presented to the contest director.

* An out of bounds landing receives a 0 score.
* Over-flying of the target time - A point is awarded for each second of flight. If the pilot flies over the the target time they start accruing negative points. If the target time of 600 seconds, 10 minutes, is given and the pilot flies 602 seconds, at 1 point per second they would receive 598 points. This is 600 points for the target time plus negative 2 points for the 2 seconds flown over the target time. If fractional seconds are being use it works in the same manner. If the target time is 600 seconds and a pilot flies 1.2 seconds past the target time that pilot would lose 1.2 * points per second on their score.
* Over-flying of the target time by 1 minute - The scoring in ALES does not allow for flight times to exceed 1 minute beyond the target time. The application will not judge this based on a time entered by the participant. The scoring screen will show a selection for over-flying the target time.

### Out of Bounds Landing

For the purposes of score entering the following needs to be indicated for an out of bounds landing:

Greater 75m from the pilot's landing marker.

A 0 flight time and 0 landing is recorded when the participant selects that an out of bounds landing occurred.

## Scoring Components

The following is data is requested to be entered for a score to be computed:

* Time flown
* Landing - Input based on the landing table selected.
* Out of bounds landing - An indicator that the pilot landed more than 75m from their landing marker.
* Over-Flight of Greater Than One Minute - An indicator that the pilot's model had not landed after one minute had elapsed from the target time.

The screen should allow the user to enter a time greater than a target time. Times greater than a minute past the target time should be met with an error and to select the "Over-Flight of Greater Than One Minute" selection.

The screen should disable and 0 all fields if the pilot selects an out of bounds landing.

The screen should disable and 0 all fields if the pilot indicates an over-flight of greater than one minute.

### Validation

Time should never be a negative number.

The landing bonus is displayed to the user a selection option from the landing table configured for the contest. The purpose of this selection is to provide a UI construct to help a user enter a valid landing bonus. Some contest use distance from the landing marker as how the points are store vs. other contest directors having the displayed values be the actual points awarded.

The user pressing submit on the form with no fields filled out should receive a warning that they are entering a zero score for the round. If they acknowledge the zero score is kept.

Only one selection of out-of-bounds or over-flight of greater than one minute can be made. These all result in a 0 being recorded for the flight time and landing scores. The selection is used to indicate how the 0 point round occurred for the purposes of reporting.

### Zero Score Clarifications

If all pilots receive zero raw scores the points they are awarded are 0 for the round.

## Scoring Formula

A pilot's raw score is computed by the following formula:

If the pilot flies up to or under the target time, the pilot receives the number of points per second as defined by the contest multiplied by the number of seconds the pilot has flown. If the pilot exceeds the target time the pilot receives the number of points per second as defined by the contest multiplied by the target time minus the number of seconds the pilot flew past the target time multiplied by the number of points per second.

The number of points per second as defined by the contest multiplied by the number of seconds the pilot has flown.

The landing score is added based on the "Group Score" configuration.

The total is the pilots raw score.
