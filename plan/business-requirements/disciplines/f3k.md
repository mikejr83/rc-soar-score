# RC Soar Score Contest Scoring Rules - F3K

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. This document describes the FAI class designation of F3K, the Radio Control Hand Launch Gliders discipline.

F3K is a multi-task, duration-oriented discipline where pilots hand-launch their gliders and attempt to achieve specific flight time objectives. A competition consists of multiple rounds, each round using a different task type. The tasks vary in how they score flights, ranging from single-flights to ladder-style time progression challenges.

The model specifications are:

- Maximum span: 1.5 meters
- Maximum weight: 750 grams
- Maximum wing loading: 150 grams per square decimeter

## Task Types

F3K competitions use various task types. Each task has a working time period during which pilots may launch multiple attempts (unless otherwise specified). The pilot's helper must announce targets to the timekeeper immediately after each launch.

### Task A (Last flight)

During the working time (typically 10 minutes), the competitor has an unlimited number of attempts. Only the longest flight time counts as the score.

- **Objective:** Only the last flight of the competitor is scored.
- **Scoring:** Flight time is measured in seconds, with a maximum of 300 seconds.

### Task B (Next to last and last flight)

The  competitor has an unlimited number of flights, but only the next to last and the last flight will be scored. The scores are summed. Working time is 10 minutes.

- **Objective:** The next-to-last and last flights are scored.
- **Scoring:** The sum of the flight times of the two flights is measured in seconds, with a maximum of 480 seconds (240 seconds per flight).

### Task C (All up, Last Down)

The competitor makes three flights. The scores are summed. Working time is 10 minutes.

- **Objective:** Competitors launch simultaneously, and the flight times of all attempts are added together.
- **Scoring:** The sum of all flight times is measured in seconds, with a maximum of 180 seconds per attempt.

### Task D (Two Flights)

Each competitor has two (2) flights. The scores are summed. Working time is 10 minutes.

- **Objective:** Two flights are scored, and their flight times are added together.
- **Scoring:** The sum of the flight times of the two flights is measured in seconds, with a maximum of 600 seconds (300 seconds per flight).

### Task E (Poker - variable target time)

Each competitor has an unlimited number of flights to achieve or exceed up to three (3) target times. If the target is reached or exceeded, then the target time is credited and the competitor can announce the next target time, which may be lower, equal, or higher. If the target time is not reached, the announced target flight time cannot be changed. The target(s) (1 - 3) with achieved target times are scored. The achieved target times are added together. Working time is 10 minutes.

- **Objective:** Competitors announce target times and aim to achieve or exceed them.
- **Scoring:** Achieved target times are scored.

### Task F (Three of Six)

The competitor may launch his model glider a maximum of 6 times. Only the three longest flights (each up to a maximum of 180 seconds) are summed for the score. Working time is 10 minutes.

- **Objective:** Competitors launch up to six times, and the three longest flights are scored.
- **Scoring:** The sum of the three longest flight times is measured in seconds, with a maximum of 540 seconds (180 seconds per flight).

### Task G (Five Longest Flights)

The competitor has an unlimited number of flights. The best five flights are summed, with each flight capped at a maximum of 120 seconds. Working time is 10 minutes.

- **Objective:** The five longest flights are scored.
- **Scoring:** The sum of the five longest flight times is measured in seconds, with a maximum of 600 seconds (120 seconds per flight).

### Task H (Four Target Flights)

The competitor must achieve four flights of different target durations: 60, 120, 180, and 240 seconds, in any order. The pilot's four longest flights are matched to these targets (longest to 240s, next to 180s, etc.). Only flight time up to the target time is scored. Working time is 10 minutes.

- **Objective:** Competitors must achieve four specific target times.
- **Scoring:** The sum of the achieved target times is measured in seconds, with a maximum of 600 seconds (240 seconds for the longest target).

### Task I (Three Longest Flights)

The competitor has an unlimited number of flights. The best three flights are summed, with each flight capped at a maximum of 200 seconds. Working time is 10 minutes.

- **Objective:** The three longest flights are scored.
- **Scoring:** The sum of the three longest flight times is measured in seconds, with a maximum of 600 seconds (200 seconds per flight).

### Task J (Three Last Flights)

The competitor has an unlimited number of flights, but only the last three flights are scored. Maximum time per flight is 180 seconds. Working time is 10 minutes.

- **Objective:** The three last flights are scored.
- **Scoring:** The sum of the flight times of the three last flights is measured in seconds, with a maximum of 540 seconds (180 seconds per flight).

### Task K (Big Ladder - Increasing Time)

The competitor must make exactly five flights targeting increasing times: 60s, 90s, 120s, 150s, and 180s. Each flight must be flown in order. The actual time flown (up to the target time) is added together for the score. Working time is 10 minutes.

- **Objective:** Competitors must achieve five target times (60, 90, 120, 150, 180 seconds).
- **Scoring:** The sum of the achieved target times is measured in seconds, with a maximum of 600 seconds.

### Task L (One Flight)

The competitor launches the glider only once. The flight time is scored. Maximum flight time is 419 or 599 seconds. Working time is 7 or 10 minutes.

- **Objective:** Only one flight is scored.
- **Scoring:** Flight time is measured in seconds, with a maximum of 419 or 599 seconds depending on the 7 or 10 minute window.

### Task M (Fly-off Increasing Time by 2 Minutes ("Huge Ladder"))

The competitor makes three flights targeting increasing times: 180s, 300s, and 420s. Actual times (up to target) are summed for the score. Working time is 15 minutes.

- **Objective:** Competitors must achieve three target times (180, 300, 420 seconds).
- **Scoring:** The sum of the achieved target times is measured in seconds, with a maximum of 900 seconds.

### Task N (Best Flight - Extended)

The competitor has an unlimited number of flights. Only the best flight counts, with a maximum of 599 seconds (9 minutes 59 seconds). Working time is 10 minutes.

- **Objective:** Only the best flight is scored.
- **Scoring:** Flight time is measured in seconds, with a maximum of 599 seconds.

## Competition Structure

An F3K competition typically consists of 6 rounds, each with a different task type. If more than 5 rounds are flown, the lowest score is discarded. A fly-off may be flown to determine the final ranking.

## Scoring and Normalization

Scores are normalized within each flight group. The pilot with the highest raw score in each group receives 1000 points, and other pilots' scores are scaled proportionally relative to that top score.

## Re-Flights

A competitor is entitled to a re-flight if:

1. Their model collides with another model in flight or during launch
2. Their launch is interfered with by another competitor's model or launch line
3. Their flight is hindered by an event beyond their control
4. The flight could not be judged by the timekeeper

To claim a re-flight, the competitor must land their model as soon as possible after the interference.

## Zero Score Conditions

- Launching outside the working time.
- Landing outside the defined landing area.
- Contact with a person or object within the safety area.
