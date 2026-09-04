# RC Soar Score Architecture - Visibility States

## Public Site Visibility

A contest's data visibility has several states that it may transition through. This document is intended to define those states and how transitions between them occur.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|Local only|Director is working offline; data is not published so it's only visible to them.|Initial State|Local → Public, Private|
|Public|The contest director has made the contest and its progress visible on the public site|The contest director has published the contest and marked it as public|Public → Private or Scoring Open|
|Private|The contest director has published the contest and marks the contest as private.|The contest is published and the contest director marks it as private.|Private → Public or Scoring Open|

### Local Only

When the contest director creates the contest it is created within their context. If the contest director is actively working in an online state their data is being directly synced to the remote data store. In that case the local only state is not a state as the contest should immediately start in private mode. This state is only applicable to the situation where the contest is created in an offline aspect and the contest director has not synced their data to the remote site.

### Public

A contest that is synced to the remote site can be marked as public by the contest director. This now makes the contest available to be found in the public site.

### Private

A contest that is synced to the remote site can be marked as private by the contest director. This makes the contest hidden from the public site.

## Scoring Visibility

Scoring visibility refers to the ability for participants to enter scores on the web site. The site must be published in order for scoring visibility to be relevant, ie a contest that is in the "Local only" state for "Public Site Visibility" cannot have the state moved to open.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|Closed|Scores can only be entered by contest directors|Initial state|Closed → Open|
|Open|Scores can be entered by the contest directors or through the self-enter interface|Contest director marks scoring open|Open → Closed|

<!-- 

|Published private|Contest exists in the remote system but is not publicly visible.|
|Published public|Contest is visible on the public site|
|Delisted|Contest is removed from public listings but retained for historical/admin use|
|Archived|Finalized historical record, no active scoring|

## Published

A contest director may chose to publish the contest at any point after the matrix has been created. The act of publishing the contest prepares the contest for public consumption and the ability for participants to add scoring data. A contest does not have to be published for the application to track its data.

A contest must be published to:

* Enable pilots or participants to enter scores online.
* For the contest to be marked as public and it to be found via searching on the public site.
* Users to see their past performance related to contests they may have participated in.

Publishing a contest does not immediately open scoring. It is the first step to enabling that functionality.

After publishing the contest director can open online scoring.

## Public Contest

A contest director may mark a contest as public or private. This is only applicable to published contests. A published contest that has been marked private enables the contest to be self-scored by pilots and participants but not visible on the public site. A published contest may be marked as public so that it can be found on the public web site and viewed but have scoring locked so that only officials may enter scores.

### Delisted

Once a contest has been published and is public it can be made private by the contest director. This is generally done to hide the overall results before an awards ceremony. This does not indicate that the contest is delisted.

Delisting occurs when the contest director wishes to retract a published contest. The contest director will find a contest that they have published previously and was **not** made public. They indicate that they wish to delist it. This disables the contest from any self-scoring functionality. This is intended to retract a contest that may have been published in error and prevent scores from being entered. -->