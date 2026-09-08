# RC Soar Score Architecture - Visibility States

## Public Site Visibility

A contest's data visibility has several states that it may transition through. This document is intended to define those states and how transitions between them occur.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|Public|The contest director has made the contest and its progress visible on the public site|The contest director marks the contest as public|Public → Private or Scoring Open|
|Private|The contest director hides the progress and scores from being visible on the public site.|The contest director marks it as private.|Private → Public or Scoring Open|

### Public

A contest that is synced to the remote site can be marked as public by the contest director. This now makes the contest available to be found in the public site.

### Private

A contest that is synced to the remote site can be marked as private by the contest director. This makes the contest hidden from the public site.

## Scoring Visibility

Scoring visibility refers to the ability for participants to enter scores on the web site. The site must be published in order for scoring visibility to be relevant, ie a contest that is in the "Local only" state for "Public Site Visibility" cannot have the state moved to open.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|Closed|Scores can only be entered by contest directors|Initial state|Closed → Locked or Open|
|Locked|The contest scores have been locked. Participants are see the scores as read-only and may not enter scores. The contest director may still modify scores through their administrative scoring screens.|The contest director indicates all scoring is to be suspended.|Locked → Closed or Open|
|Open|Scores can be entered by the contest directors or through the self-enter interface|Contest director marks scoring open|Open → Closed or Locked|

### Closed

The closed state for scoring indicates that the contest director is entering all score parameters. This is common in larger championship contests. The scores are written on paper by helpers and taken to an official. They are validated by the contest director and then manually entered into the application.

### Locked

The contest's scores are now read-only. This is commonly performed by contest directors that wish to not inadvertently modify scores when reviewing data.

### Open

Scoring is open to participants via their scoring interface.
