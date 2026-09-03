# RC Soar Score Architecture - Offline Synchronization

The ability for the contest director's application to function offline makes it necessary to account for how data entered by participants during a contest. It is necessary to define how to reconcile newly entered data between the online data and a contest director's offline copy.

The contest director working from an offline application is generally considered to have the master copy of the data. The contest director is the administrator of the score data so their modifications should take precedence. In practice the application should minimize how conflicts occur by keeping records of how data changes. A similar mentality can be used in the online case, the contest director can review any score entered and modify it as they see fit.

It is important to remember that a round score is made up of raw data. Configuration changes to the contest may require the score to be recomputed. However, the discipline cannot be changed once the draw has taken place. This makes the constituent parts of the score, the details, locked once the discipline is locked. Changes to configuration such as rounding/truncating, or decimal count will cause the score to be recomputed but the data to do this should already be available.

This document will use the term "score" to mean those components as defined by the discipline that make up a pilots score for the round.

## Synchronization Process

The contest director may connect to a network to sync data. The process is outlined below:

1. Retrieve all scoring data from the online site.
2. Where no score has been entered in the offline data, add new data.
3. Newly added data is marked as having been pulled from the remote site (through some sync code, timestamp, etc.)
4. Where a score exists, check to see if this data has been previously pulled from the remote.
5. If this data was last updated by the remote then the indication that it has been pulled from the remote is updated (the sync code, timestamp, etc is updated)
6. If this data was not last updated by the remote a check for the data state needs to be performed.