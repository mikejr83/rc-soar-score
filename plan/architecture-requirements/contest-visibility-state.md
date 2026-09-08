# RC Soar Score Architecture - Visibility States

## Public Site Visibility

A contest must be published by a contest director before it can be visible in the public site. Once the contest is published it still can be given a visibility state.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|Public|The contest director has made the contest and its progress visible on the public site|The contest director marks the contest as public|Public → Hidden or Private|
|Hidden|The contest is hidden from searching and general public consumption.|The contest director marks the contest as hidden.|Hidden -> Public or Private|
|Private|The contest director hides the progress and scores from being visible on the public site.|The contest director marks it as private.|Private → Hidden or Public|

### Public

A contest that is published can be marked as public by the contest director. This now makes the contest available to be found in the public site through searching.

### Hidden

A contest that is published can be marked as hidden by the contest director. This makes the contest only visible to the participants.

### Private

A contest that is published can be marked as private by the contest director. This makes the contest hidden from the public site completely.

## Participant Scoring Visibility

The participant scoring visibility refers to the ability for participants to enter scores on the web site. This state does not reflect in the contest directors ability to enter scores.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|Closed|Scores can only be entered by contest directors|Initial state|Closed → Locked or Open|
|Open|Scores can be entered by the contest directors or through the self-enter interface|Contest director marks scoring open|Open → Closed or Locked|

### Closed

The closed state for scoring indicates that the contest director is entering all score parameters. This is common in larger championship contests. The scores are written on paper by helpers and taken to an official. They are validated by the contest director and then manually entered into the application.

### Open

Scoring is open to participants via their scoring interface.
