# RC Soar Score Contest Scoring Rules - F5J

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document describes the FAI class designation of F5J, a thermal duration type discipline undertaken by pilots flying sailplanes with an electric motor launching system.

The FAI F5J task is similar to the FAI F3J task. It differs in that there are additional data points collected and used to calculate the pilots score.

## Scoring Options

F5J is a variation of how a duration type task is scored.

The following defaults are set in the scoring options section when this discipline is selected:

* Group Score - Normalized
* Total Score - Rounded to 1 decimal place

## Scoring Rules

The F5J discipline changes the wording for a typical duration task. The concept of target time is now "Working Time".

* Working Time - The length of the window for the pilots to fly.
* Fractional seconds - How many tenths, hundredths of a second to count. Shown as a drop down indicating the number of decimal places, 0 - 3. Defaults to 0.
* Points Per Second - How many raw points are awarded to the pilot based on their flight time. Defaults to 1.
* Landing Bonus - The selection of a landing bonus table. Should default to the system default for F5J contests or the last one used by the contest director for an F5J contest.
* Motor Restart - This is a selection of three options to determine how motor restarts affect the overall results.
  * Allowed - Restart is allowed. The pilot receives a 0 for the round. The round can be dropped. This is the default.
  * Non-Droppable 0 - Restart is allowed and can be identified on the scoring screen. The pilot receives a 0 for the round. The round's score cannot be dropped from the pilots final results.
  * Not Allowed - The contest will not consider motor restarts as they are forbidden. The option to select a motor restart is not shown on the scoring screen.

This discipline introduces the concept of a launch height penalty. The height penalty has the following components:

* Reference Launch Height - The height where the penalty changes from minor to major.
* Minor penalty per meter - The number of points of penalty per meter of altitude. Defaults to 0.5.
* Major penalty per meter - The number of points of penalty per meter of altitude if the altitude exceeds the "Reference Launch Height"

### Out of Bounds Landing

For the purposes of score entering the following needs to be indicated for an out of bounds landing:

Greater 75m from the pilot's landing marker.

### Computational Rules

The following rules are used when calculating the score and are not configurable or presented to the contest director.

* An out of bounds landing receives a 0 score.
* A motor restart receives a 0 score. The score may carry for the pilot's final score depending on the configured scoring rules.
* A late landing does not receive any landing bonus.
* The score for the pilot is calculated: time as points + landing bonus (if applicable) - height penalty.
* The minor height penalty value is used for recorded altitudes at or lower than the reference launch height.
* The major height penalty value is used for recorded altitudes greater than the reference launch height.

## Scoring Components

The following is data is requested to be entered for a score to be computed:

* Time flown
* Launch height - in whole meters.
* Landing - Input based on the landing table selected.
* Late landing - The pilot did not land the model before the working time expired.
* Motor Restart - The pilot restarted their motor during flight. This is show based on the scoring rules configuration.
* Out of bounds landing - An indicator that the pilot landed more than 75m from their landing marker.

The screen should **not** allow the user to enter a time greater than a working time. Indicating a late landing should zero the landing bonus option and make it unavailable for selection.

The screen should disable and 0 all fields if the pilot selects an out of bounds landing.

The screen should disable and 0 all fields if the pilot indicates a motor restart.
