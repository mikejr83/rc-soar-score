# RC Soar Score Architecture - Participant Scoring Access

Scoring access controls whether participants and authorized helpers can submit scores through the self-scoring interface. It is independent of the execution lifecycle and administration lock. A closed contest may still accept scores from the director or an authorized local operator when the lifecycle and lock rules permit it.

|State|Meaning|Entry condition|Exit / next transition|
|-----|-------|---------------|----------------------|
|`Closed`|Participants cannot submit scores. The director or an authorized local operator may enter scores when permitted.|Initial state, or the contest director closes scoring.|`Closed <-> Open`|
|`Open`|Participants and authorized helpers may submit scores when permitted; the director may also enter scores.|The contest director opens scoring.|`Open <-> Closed`|

## Closed

The closed state is useful when helpers record scores on paper and an official validates and enters them. It does not prevent director or authorized local-operator entry when the lifecycle and administration-lock rules permit it.

## Open

Scoring is open to participants and authorized helpers through their scoring interface. Completion forces participant scoring closed.
