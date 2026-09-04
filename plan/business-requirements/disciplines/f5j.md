# RC Soar Score Contest Scoring Rules - F5J

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document describes the FAI class designation of F5J, a thermal duration type discipline undertaken by pilots flying sailplanes with an electric motor launching system.

The FAI F5J task is similar to the FAI F3J task. It differs in that there are additional data points collected and used to calculate the pilots score.

## Scoring Options

F5J is a variation of how a duration type task is scored. F5J has a provision for an over-flight window. The pilot may continue flying for up to 1 minute past the end of the window. If this occurs the pilot's recorded time stops when the window ends. If the pilot lands within that 1 minute over-fly time, the pilot will receive their flight points as calculated minus any height penalty. If they are flying beyond that 1 minute over-fly time their score is 0.

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
* Major penalty per meter - The number of points of penalty per meter of altitude over the reference altitude. Defaults to 3.

### Out of Bounds Landing

For the purposes of score entering the following needs to be indicated for an out of bounds landing:

Greater 75m from the pilot's landing marker.

### Computational Rules

The following rules are used when calculating the score and are not configurable or presented to the contest director.

* An out of bounds landing receives a 0 score.
* A motor restart receives a 0 score. The score may carry for the pilot's final score depending on the configured scoring rules.
* A pilot may over fly the window time and land within one minute of the window closing. The time for the pilot will stop at the when the window ends. That will be their flight time. A late landing does not receive any landing bonus.
* The score for the pilot is calculated: time as points + landing bonus (if applicable) - height penalty.
* The minor height penalty value is used for recorded altitudes at or lower than the reference launch height.
* The major height penalty value is used for the number of meters in in the recorded altitude in excess of the reference launch height.

### Motor Restart

Any motor restart during a F5J contest results in the pilot receiving a zero. The scoring rules define a "Not Allowed" scenario. This configuration scenario is defined so that the UI elements will not present the option for entering a motor restart as a reason for the pilot taking a zero score.

The configuration also allows for the option "Non-Droppable 0". General contest configuration enables a contest director to set a point in the contest when the lowest round score is removed from the pilot's total score. When the discipline is F5J and this option is set, a 0 earned in a round in which a motor restart occurred cannot be the round which is selected to be dropped from the pilot's overall score. In that scenario the next lowest score which was not earned by a motor restart is selected.

## Scoring Components

The following is data is requested to be entered for a score to be computed:

* Time flown
* Launch height - in whole meters.
* Landing - Input based on the landing table selected.
* Late landing - The pilot did not land the model before the working time expired (but did not fly over one minute past the window closing).
* Motor Restart - The pilot restarted their motor during flight. This is show based on the scoring rules configuration.
* Out of bounds landing - An indicator that the pilot landed more than 75m from their landing marker.
* No Altitude Recorded - A participant may select this if the pilot's altitude recording device fails to record their F5J altitude. This case follows the same as a zero score situation. It is used for categorization of the zero score only.

The screen should **not** allow the user to enter a time greater than a working time. Indicating a late landing should zero the landing bonus option and make it unavailable for selection.

The screen should disable and 0 all fields if the pilot selects an out of bounds landing.

The screen should disable and 0 all fields if the pilot indicates a motor restart.

### Validation

Time should never be a negative number nor should it exceed the window time.

A launch height over 300 meters should be accompanied by an indication if the user entered a correct value.

Landing bonuses taken from the landing bonus table based on the configuration of the contest. The user selects the displayed value and the key for that displayed value is what is stored as the landing bonus.

A user submitting a form with motor restart or out-of-bounds selected should acknowledge the pilot is receiving a zero score.

The user pressing submit on the form with no fields filled out should receive a warning that they are entering a zero score for the round. If they acknowledge the zero score is kept. This is sufficient to indicate that the pilot overflow the over-fly time of 1 minute.

A user may select both out of bounds landing and motor restart. This is applicable if the contest is not allowing a zero to be dropped when a motor restart occurs. The user should be notified of this situation when both are selected.

The selection of the "No Altitude Record" should not allow any other values to be entered. The selections for late landing, motor restart, and out of bounds landing should be unselected and unavailable.

## Scoring Formula

A pilot's raw score is computed by the following formula:

The hight penalty for the flight is calculated. If the altitude recorded is at or under the reference altitude the penalty is the minor penalty points per meter multiplied by the recorded altitude. If the altitude is over the reference then the penalty is the reference altitude multiplied by the minor penalty points per meter plus the difference between the recorded altitude and the reference altitude multiplied by the major penalty points per meter.

The base points for the pilot is found by using the number of points per second as defined by the contest multiplied by the number of seconds the pilot has flown.

The hight penalty is subtracted from the base points.

The landing score is added based on the "Group Score" configuration.

The total is the pilots raw score.

### Examples

The window configuration is set to 600 seconds or 10 minutes, earning 1 point per second, with a reference altitude of 200m, a minor penalty of 0.5 points per meter and a major penalty of 3 points per meter.

F5J is flown where the "Group Score" is "normalized" meaning the flight score and landing bonus are added together for the pilot's raw score and the normalized to 1000 being the pilot who had the highest score for the group. The total score is "rounded" to 1 decimal place. The following examples use that assumption.

The pilot A flies 9:30, nine minutes and 30 seconds. The pilot launched to an altitude of 13m. The landing was 45 points.

Pilot B flies 9:55, nine minutes and 55 seconds. They launched to an altitude of 46m. Their landing was 50 points.

Pilot C files 7:45, seven minutes and 45 seconds. They launched to an altitude of 204m. Their landing was 30 points.

Pilot A's flight score = 570 seconds of flight time \* 1 point per sec - 13m \* 0.5 points per meter = 563.5 flight points

Pilot A's raw score = 563.5 flight points + 45 landing points for a total = 608.5

Pilot B's flight score = 595 seconds of flight time \* 1 point per sec - 46m \* 0.5 points per meter = 572 flight points.

Pilot B's raw score = 572 flight points + 50 landing points = 622.

Pilot C's hight penalty = 200m reference altitude \* 0.5 points per meter + (204m recorded altitude - 200m reference altitude) \* 3 points per meter = 112

Pilot C's flight score = 465 seconds of flight time \* 1 point per second - 112 height penalty = 353 flight points

Pilot C's raw score = 353 flight points + 30 landing points = 383.

Normalization is performed by `pilots raw score` / `highest raw score in the group` * 1000

|Pilot|Raw Score|Group Score|
|-----|---------|-----------|
|A|608.5|978.3|
|B|622|1000\*|
|C|383|615.8|

\* Pilot B received the highest score and is awarded the 1000 points for the round. All other pilot's raw scores are normalized to their score.
