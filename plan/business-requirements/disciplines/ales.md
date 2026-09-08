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
* Over-flying of the target time - A point is awarded for each second of flight. If the pilot flies over the the target time they start accruing negative points. If the target time of 600 seconds, 10 minutes, is given and the pilot flies 602 seconds, at 1 point per second they would receive 598 points. This is 600 points for the target time plus negative 2 points for the 2 seconds flown over the target time. If fractional seconds are being use it works in the same manner. If the target time is 600 seconds and a pilot flies 1.2 seconds past the target time that pilot would lose 1.2 * points per second on their score.
* Over-flying of the target time by 1 minute - The scoring in ALES does not allow for flight times to exceed 1 minute beyond the target time. The application will not judge this based on a time entered by the participant. The scoring screen will show a selection for over-flying the target time.

### Out of Bounds Landing

For the purposes of score entering the following needs to be indicated for an out of bounds landing:

Greater 75m from the pilot's landing marker.

A 0 flight time and 0 landing is recorded when the participant selects that an out of bounds landing occurred.

### Motor Restart

A motor restart is allowed in the ALES format. A motor restart results in the pilot receiving a zero score for the round; no landing bonus can be earned.

## Scoring Components

The following is data is requested to be entered for a score to be computed:

* Time flown
* Landing - Input based on the landing table selected.
* Motor Restart - An indicator that the pilot restarted their motor in flight and is receiving a 0 score for the flight.
* Out of bounds landing - An indicator that the pilot landed more than 75m from their landing marker.
* Over-Flight of Greater Than One Minute - An indicator that the pilot's model had not landed after one minute had elapsed from the target time.

The screen should allow the user to enter a time greater than a target time. Times greater than a minute past the target time should be met with an error and to select the "Over-Flight of Greater Than One Minute" selection.

The screen should disable and 0 all fields if the pilot selects an out of bounds landing.

The screen should disable and 0 all fields if the pilot indicates a motor restart.

The screen should disable and 0 all fields if the pilot indicates an over-flight of greater than one minute.

### Validation

Time should never be a negative number.

The landing bonus is displayed to the user a selection option from the landing table configured for the contest. The purpose of this selection is to provide a UI construct to help a user enter a valid landing bonus. Some contest use distance from the landing marker as how the points are store vs. other contest directors having the displayed values be the actual points awarded.

The user pressing submit on the form with no fields filled out should receive a warning that they are entering a zero score for the round. If they acknowledge the zero score is kept.

Only one selection of out-of-bounds, motor restart, or over-flight of greater than one minute can be made. These all result in a 0 score. These all result in a 0 being recorded for the flight time and landing scores. The selection is used to indicate how the 0 point round occurred for the purposes of reporting.

### Zero Score Clarifications

If all pilots receive zero raw scores the points they are awarded are 0 for the round.

## Scoring Formula

A pilot's raw score is computed by the following formula:

If the pilot flies up to or under the target time, the pilot receives the number of points per second as defined by the contest multiplied by the number of seconds the pilot has flown. If the pilot exceeds the target time the pilot receives the number of points per second as defined by the contest multiplied by the target time minus the number of seconds the pilot flew past the target time multiplied by the number of points per second.

The default "Group Scoring" configuration for ALES is "Time". This means that flight time is computed and normalized to 1000 for the group. The landing bonus is added to the normalized score. Contest directors may change this and select "Normalized". This is not common, but it is a setup that the application presents as a valid configuration. This is computed as the flight score plus the landing bonus and then normalized to 1000.

A pilot's raw score and thus their round score cannot be a negative number.

The total is the pilots raw score.

### Truncating and Rounding

Truncating of calculated values never takes place until the final group score is computed. Rounding follows the same requirement, it never takes place at an intermediate calculation step.

As truncating and rounding are configuration options which are only applicable to the final group score, this does not affect the raw score and only the final group score for pilots.

### Examples

The contest is configured for a target time of 480 seconds or 8 minutes, earning 1 point per second, and 0 decimals for time precision. The total score is set to rounded to 0 decimal places.

In the first example the traditional "Group Score" is configured to "Time".

Pilot A flies 477 seconds, 7 minutes and 57 seconds and performs a landing worth 30 points.

Pilot B flies 483 seconds, 8 minutes and 3 seconds and performs a landing worth 25 points.

Pilot C flies 470 seconds, 7 minutes and 50 seconds and performs a landing worth 50 points.

Pilot A's raw points are 477 because they flew for at or under the target time. Pilot B's raw points computed as 480 target time \* 1 points per second - (483 total seconds flown - 480 target time) \* 1 points per second => 480 - 3 = 477. Even though Pilot A flew 3 seconds under the target time and Pilot B flew 3 seconds over the target time, they both receive the same number of raw points.

Pilot C's raw score is computed as 470 because that pilot flew a time at or under the target time.

The round score is now computed by normalizing the raw points to 1000. This example is using "Group Score" set to "Time". This means landing bonus is added after normalization.

Pilot A and B are tied for the highest raw points, 477. They receive the normalized score of 1000 to start. Pilot A made a landing worth 30 points making their round score 1030. Pilot B made a landing worth 25 points making their round score 1025.

Pilot C's raw score is 98.5% of the 1000 point time score => 470 flight raw points \\ 477 raw flight points of best in group \* 1000 + 50 landing bonus = Rounded to 0 decimal places for 1035.

In the second example the "Group Score" is configured to "Normalized".

Assume that each of the pilots fly the same as in the first example.

Pilot A's raw points are 477 from their flight time points + 30 points earned from the landing bonus for a total of 507 points. Pilot B received 477 from their flight time + 25 points earned from the landing bonus for a total of 502 points. Pilot C has 470 points from flight time + 50 point landing bonus for a total of 520 points.

The highest score for the round is 520 points by Pilot C and is awarded the 1000 points per the "Normalized" setting of the "Group Score". Pilot A received 507 points which is 97.5% of Pilot C's score earning 975 points. Pilot B's score was 96.5% of Pilot C's score earning them a group score of 965.
