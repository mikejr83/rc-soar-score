# RC Soar Score Contest Scoring Rules - F5J

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document describes the FAI class designation of F5J, a thermal duration type discipline undertaken by pilots flying sailplanes with an electric motor launching system. This is the official profile for F5J when selecting it as a contest discipline. It is a variation on the shared duration-scoring model. Local deviations are allowed by the contest director but are treaded as overrides.

The FAI F5J task is similar to the FAI F3J task. It differs in that there are additional data points collected and used to calculate the pilots score.

The flight time is calculated by a timer started when the model leaves the pilot's hand with the motor running. The pilot may not launch before the working time starts. The pilot attempts to fly as long as possible during the working time and perform a precision landing before the working time expires. If the pilot lands before the working time expires the pilot receives any calculated landing points as a bonus. If the pilot has landed after the working time expires they forfeit the landing bonus but still may keep the score generated from their flight time minus launch penalty.

F5J has a provision for an over-flight window. The pilot may continue flying for up to 1 minute past the end of the window. If this occurs the pilot's recorded time stops when the working time ends. If the pilot lands within that 1 minute over-fly time and is within bounds, the pilot will receive their flight points as calculated minus any height penalty. If they are flying beyond that 1 minute over-fly time their score is forfeit and recorded as a 0. For scoring purposes in the application this scenario is not tracked. It is provided purely for clarity. The application does not record actual landing time or validate the one-minute overflight limit. The participant or official must select Late landing when applicable. A zero-score submission is used when the pilot exceeded the permitted overflight period.

This document serves as a primer for F5J scoring within the context of the RC Soar Score Contest application. Topics that go beyond recording scores are best left for the official FAI documentation for the F5J discipline.

## Scoring Options

F5J is a variation of how a duration type task is scored.

The following defaults are set in the scoring options section when this discipline is selected:

- Group Score - Normalized
- Total Score - Rounded to 1 decimal place

## Scoring Rules

The F5J discipline changes the wording for a typical duration task. The concept of target time is now "Working Time".

- Working Time - The length of the window for the pilots to fly. Defaults to 600 seconds (10 minutes).
- Points Per Second - How many raw points are awarded to the pilot based on their flight time. Defaults to 1.
- Landing Bonus - The selection of a landing bonus table. Should default to the system default for F5J contests or the last one used by the contest director for an F5J contest.
- Motor Restart - This is a selection of three options to determine how motor restarts affect the overall results.
  - Allowed - Restart is allowed. The pilot receives a 0 for the round. The round can be dropped. This is the default.
  - Non-Droppable 0 - Restart is allowed and can be identified on the scoring screen. The pilot receives a 0 for the round. The round's score cannot be dropped from the pilots final results.
  - Not Allowed - The contest will not consider motor restarts as they are forbidden. The option to select a motor restart is not shown on the scoring screen. The scoring application is not responsible for enforcing this. This is configuration for the scoring screens only.

This discipline introduces the concept of a launch height penalty. The height penalty has the following components:

- Reference Launch Height - The height where the penalty changes from minor to major.
- Minor penalty per meter - The number of points of penalty per meter of altitude. Defaults to 0.5.
- Major penalty per meter - The number of points of penalty per meter of altitude over the reference altitude. Defaults to 3.

### Out of Bounds Landing

For the purposes of score entering the following needs to be indicated for an out of bounds landing:

Greater 75m from the pilot's landing marker.

### Computational Rules

The following rules are used when calculating the score and are not configurable or presented to the contest director.

- An out of bounds landing receives a 0 score.
- A motor restart receives a 0 score. The score may carry for the pilot's final score depending on the configured scoring rules.
- A pilot may over fly the window time and land within one minute of the window closing. The time for the pilot will stop at the when the window ends. That will be their flight time. A late landing does not receive any landing bonus.
- The score for the pilot is calculated: time as points + landing bonus (if applicable) - height penalty.
- The minor height penalty value is used for recorded altitudes at or lower than the reference launch height.
- The major height penalty value is used for the number of meters in in the recorded altitude in excess of the reference launch height.

### Motor Restart

Any motor restart during a F5J contest results in the pilot receiving a zero. The scoring rules define a "Not Allowed" scenario. This configuration scenario is defined so that the UI elements will not present the option for entering a motor restart as a reason for the pilot taking a zero score.

The configuration also allows for the option "Non-Droppable 0". General contest configuration enables a contest director to set a point in the contest when the lowest round score is removed from the pilot's total score. When the discipline is F5J and this option is set, a 0 earned in a round in which a motor restart occurred cannot be the round which is selected to be dropped from the pilot's overall score. In that scenario the next lowest score which was not earned by a motor restart is selected.

## Scoring Components

The following is data is requested to be entered for a score to be computed:

- Time flown - Truncated to the second.
- Launch height - in whole meters.
- Landing - Input based on the landing table selected.
- Late landing - The pilot did not land the model before the working time expired (but did not fly over one minute past the window closing).
- Motor Restart - The pilot restarted their motor during flight. This is shown based on the scoring rules configuration.
- Out of bounds landing - An indicator that the pilot landed more than 75m from their landing marker.
- No Altitude Recorded - A participant may select this if the pilot's altitude recording device fails to record their F5J altitude. This case follows the same as a zero score situation. It is used for categorization of the zero score only.

The screen should **not** allow the user to enter a time greater than a working time. Indicating a late landing should zero the landing bonus option and make it unavailable for selection.

The screen should disable and 0 all fields if the pilot selects an out of bounds landing.

The screen should disable and 0 all fields if the pilot indicates a motor restart.

### Validation

Time should never be a negative number nor should it exceed the window time. A pilot may physically fly their model past the window but the recorded time cannot exceed the window time. A pilot overflying the window can only achieve a theoretical maximum time that is the specified working time minus the smallest representable time unit (as configured for the number of decimals store for the flight time). A pilot may not have started their flight when the working time started, thus if they are still flying when the working time ends they would be less than the theoretical maximum time and receive the time as recorded by their timer. In both cases the pilot would lose their landing bonus and the score would have the "Late landing" option selected.

The time entered cannot be the same as the working time. It is physically impossible for that situation to occur.

An altitude of 0 is not possible.

A launch height over 300 meters should be accompanied by an indication if the user entered a correct value.

The landing bonus is displayed to the user a selection option from the landing table configured for the contest. The purpose of this selection is to provide a UI construct to help a user enter a valid landing bonus. Some contest uses distance from the landing marker as how the points are store vs. other contest directors having the displayed values be the actual points awarded.

A user submitting a form with motor restart or out-of-bounds selected should acknowledge the pilot is receiving a zero score when motor restarts are prevented from being discarded.

A user may select both out of bounds landing and motor restart. This is applicable if the contest is not allowing a zero to be dropped when a motor restart occurs. The user should be notified of this situation when both are selected.

The user pressing submit on the form with no fields filled out should receive a warning that they are entering a zero score for the round. If they acknowledge the zero score is kept. This is sufficient to indicate that the pilot overflow the over-fly time of 1 minute.

The selection of the "No Altitude Record" should not allow any other values to be entered. The selections for late landing, motor restart, and out of bounds landing should be unselected and unavailable.

## Scoring Formula

A pilot's raw score is computed by the following formula:

The height penalty for the flight is calculated. If the altitude recorded is at or under the reference altitude the penalty is the minor penalty points per meter multiplied by the recorded altitude. If the altitude is over the reference then the penalty is the reference altitude multiplied by the minor penalty points per meter plus the difference between the recorded altitude and the reference altitude multiplied by the major penalty points per meter.

The base points for the pilot is found by using the number of points per second as defined by the contest multiplied by the number of seconds the pilot has flown.

The height penalty is subtracted from the base points.

Landing bonuses are taken from the landing bonus table based on the configuration of the contest at the time of score entry. The system is not concerned with the bonus table changing during a contest. The key/value pair presented in the UI is done in order to help the user provide a selection that tells the system what value is recorded for the landing bonus. Regardless of what the UI shows, the system should assume that the key/value lookup will indicate the value to be stored based on what the user selected.

The landing score is added based on the "Group Score" configuration only if the flight was not marked as having a late landing.

The total is the pilots raw score.

The lowest score a pilot can receive for their raw score is 0. This would be if the height penalty exceeded the points earned from their flight time (plus any landing bonus).

Pilots may receive the same calculated raw score. In this case their normalized score would be exactly the same.

Pilots which have no submitted score are considered a zero score. They will be indicated in the UI as to not confuse the users. As their scores are entered the normalized scores will be recalculated.

### Late Landing Behavior

A late landing is when the pilot flies over the working time but lands within bound and within the one minute overfly time. The pilot will keep their flight time. Their score will be calculated as normal, however, they forfeit their landing bonus points.

### Zero Score Clarifications

Score details entered that have any of the following conditions met:

- Motor Restart
- No altitude Recorded
- Out of bounds

Receive a 0 for the flight. No time, height, or landing is recorded for these situations.

There is only one situation where multiple zero selections can occur: Motor restart & Out of bounds - Both statuses are recorded. A notification that this will result in a 0 score that cannot be dropped is shown if the scoring rules have been configured such that motor restarts result in a non-dropped 0.

If "Motor Restart" is selected then the "No altitude recorded" option is not selectable. If "No altitude recorded" is selected then "Motor restart" and "Out of bounds" are not selectable.

These zero condition flags are stored for reporting later in the contest and in the case of motor restart it is considered when discarding the lowest score when the scoring rules disallow motor restarts being discarded.

If every pilot receives a zero as a raw score due to:

- Out of bounds
- No altitude recorded
- Motor restart

All pilots will receive a 0 for their normalized group score.

### Truncating and Rounding

Truncating of calculated values never takes place until the final group score is computed. Rounding follows the same requirement, it never takes place at an intermediate calculation step.

As truncating and rounding are configuration options which are only applicable to the final group score, this does not affect the raw score and only the final group score for pilots.

### Examples

The window configuration is set to 600 seconds or 10 minutes, earning 1 point per second, 0 decimals for time precision, with a reference altitude of 200m, a minor penalty of 0.5 points per meter and a major penalty of 3 points per meter.

F5J is flown where the "Group Score" is "normalized" meaning the flight score and landing bonus are added together for the pilot's raw score and the normalized to 1000 being the pilot who had the highest score for the group. The total score is "rounded" to 1 decimal place. The following examples use that assumption.

The pilot A flies 9:30, nine minutes and 30 seconds. The pilot launched to an altitude of 13m. The landing was 45 points.

Pilot B flies 9:55, nine minutes and 55 seconds. They launched to an altitude of 46m. Their landing was 50 points.

Pilot C flies 7:45, seven minutes and 45 seconds. They launched to an altitude of 204m. Their landing was 30 points.

Pilot A's flight score = 570 seconds of flight time \* 1 point per sec - 13m \* 0.5 points per meter = 563.5 flight points

Pilot A's raw score = 563.5 flight points + 45 landing points for a total = 608.5

Pilot B's flight score = 595 seconds of flight time \* 1 point per sec - 46m \* 0.5 points per meter = 572 flight points.

Pilot B's raw score = 572 flight points + 50 landing points = 622.

Pilot C's height penalty = 200m reference altitude \* 0.5 points per meter + (204m recorded altitude - 200m reference altitude) \* 3 points per meter = 112

Pilot C's flight score = 465 seconds of flight time \* 1 point per second - 112 height penalty = 353 flight points

Pilot C's raw score = 353 flight points + 30 landing points = 383.

Normalization is performed by `pilots raw score` / `highest raw score in the group` \* 1000

| Pilot | Raw Score | Group Score |
| ----- | --------- | ----------- |
| A     | 608.5     | 978.3       |
| B     | 622       | 1000\*      |
| C     | 383       | 615.8       |

\* Pilot B received the highest score and is awarded the 1000 points for the round. All other pilot's raw scores are normalized to their score.

#### Late Landing Examples

A pilot releases their model at the opening of the window and the timer starts. They do not land before the working time ends. Using the configured 0 decimals for precision indicates that the second is the most precise unit of time recorded. This would make the maximum achievable flight time 599 seconds. The pilot lands before one minute of overly has occurred. The score would be entered as 9 minutes 59 seconds, late landing selected. No bonus landing points would be selectable or applied.

A pilot does not release their model at the opening of the window. Instead they wait 30 seconds. They start flying and their timer starts. They fly past the working time limit. The time stops at the end of the working time. Using the configured 0 decimals for precision indicates that the second is the most precise unit of time recorded. This would make the maximum achieve flight time of 599 seconds. The pilot did not start immediately so their time is recorded from when their timer started to when the working time ended, 570 seconds. This is less than the theoretical max of 599. 9 minutes and 30 seconds are recorded for their flight time and late landing is selected. NO bonus landing points would be selectable or applied.

## Re-Flights

The granting of re-flights are performed according the following order of priorities:

1. In an incomplete group. If a group within the same round has an available spot (because the division of pilots was not evenly distributed between all groups) the contest director will assign them to that group. This can be determined by assessing if other groups within the round have recorded scores.
2. A new group of a minimum of 6 pilots, or the largest group size if the largest group size is less than 6. The group of pilots is made up by competitors selected by random draw. Competitors from the same team are excluded. A randomly selected competitor may decline to fly. The draw is repeated until the group is filled. If a group cannot be filled because the randomly selected pilots decline the priority moves to the next.
3. The original group is re-flown at the end of the ongoing round.

In cases 2 and 3, for the competitors allocated the re-flight, the result of the re-flight is their score. For the other competitors, the better of their score in the ongoing round and the re-flight score will become their round score.
