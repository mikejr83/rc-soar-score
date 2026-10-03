# RC Soar Score Architecture - Contest State and Transitions

## Purpose

This document defines the state model for a contest. A contest has one execution lifecycle and several independent controls. Keeping these concerns separate prevents a publication change, results hiding, scoring pause, or delete request from being mistaken for a change in the contest's execution state.

The contest director's administration installation is the authority that performs state transitions. The service must validate every transition against the current contest revision. Synchronization may transport a transition, but it must not create a new transition implicitly.

## State dimensions

### Execution lifecycle

The execution lifecycle describes how far the contest has progressed.

| State         | Meaning                                                                                                  | Entry condition                                                                                       |
| ------------- | -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `Created`     | The contest has its minimum identity and location data, but no contest configuration has started.        | The director creates the contest.                                                                     |
| `Configuring` | The director is selecting the discipline and configuring participants, scoring, rules, and draw options. | The director selects a discipline or changes contest configuration.                                   |
| `Ready`       | A valid flight matrix exists and no score has been submitted.                                            | The director creates or updates a valid matrix.                                                       |
| `Running`     | At least one score has been submitted and the contest has not been completed.                            | The first official or participant score submission is accepted.                                       |
| `Completed`   | Contest execution has ended. The result is available for final validation and publication.               | The director completes the contest, or an automatic completion condition is accepted by the director. |

The lifecycle is monotonic:

```text
Created -> Configuring -> Ready -> Running -> Completed
```

There is no ordinary transition back to an earlier lifecycle state. If a completed contest requires a correction, the correction must preserve the completed lifecycle and use the score correction/audit workflow. If reopening is later required, it must be added as an explicit, authorized transition rather than inferred from an edit.

### Scoring access

Scoring access controls participant self-scoring and is independent of the execution lifecycle.

| Value    | Meaning                                                                                                                                       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `Closed` | Participants cannot submit scores. The director or an authorized local operator may enter scores when the lifecycle and lock rules permit it. |
| `Open`   | Participants and authorized helpers may submit scores when the lifecycle and lock rules permit it.                                            |

Valid transitions are `Closed <-> Open`. A running contest may be closed temporarily for breaks or validation and reopened without changing its lifecycle state. Completion forces participant scoring closed.

### Administration lock

Administration lock is independent of scoring access. It prevents modifications to contest configuration, participation, matrix assignments, and scores. A locked contest may still be viewed and published if the publication rules permit it.

| Value      | Meaning                                                   |
| ---------- | --------------------------------------------------------- |
| `Unlocked` | Authorized changes are allowed under the lifecycle rules. |
| `Locked`   | Mutations covered by the lock are rejected.               |

Valid transitions are `Unlocked -> Locked` and `Locked -> Unlocked`. Locking does not complete, pause, or archive a contest.

### Results hiding

Results hiding lets the director withhold the overall scores and placing, for example to preserve the final outcome until an awards ceremony. It is a contest control. It is independent of the execution lifecycle, scoring access, the administration lock, and publication.

| Value    | Meaning                                                                                                                   |
| -------- | ------------------------------------------------------------------------------------------------------------------------- |
| `Off`    | Overall scores and placing are shown normally.                                                                            |
| `Hidden` | Overall scores and placing are shown only as of a recorded round. Round scores and flight-group positions remain visible. |

When hiding is turned on, the service records the time and the round through which standings remain visible: the round in progress, or the last completed round if no round is in progress. Hiding ends when the director turns it off, when the contest becomes `Completed`, or 24 hours after it was turned on, whichever comes first. Turning it on again records a new round and time.

Hiding applies to participant result views and to the published copy. Scores continue to be entered, calculated, and published while results are hidden; hiding never changes stored data or the lifecycle. Hiding may be turned on while the contest is `Running`.

### Publication and visibility

Publication is an operation that creates or updates a separate public projection. It is not an execution lifecycle state and may occur while the contest is `Running` or `Completed`. Publication state and visibility belong to the published-contest record, not to the private contest. A contest that has never been published has no such record and is visible only to its director.

| Publication state | Meaning                                                    |
| ----------------- | ---------------------------------------------------------- |
| Unpublished       | No published record exists.                                |
| Published         | A published record exists and records the source revision. |

The published record has a visibility that the director controls:

| Value      | Meaning                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------- |
| `Unlisted` | Not searchable or generally listed, but available through its link and to its participants. |
| `Public`   | Searchable and viewable without an account.                                                 |

The first publish defaults to `Unlisted`. Visibility transitions are `Unlisted <-> Public`. A visibility change does not modify the private contest or its execution lifecycle. Publishing a later private revision replaces the public projection atomically; it does not create a new contest lifecycle state.

A published record can also be `Delisted`. This is not a director choice: it results only from a system administrator approving a delist request, and the director cannot reverse it.

### Local archive

Local archiving is a storage/display flag for an offline or director-owned contest. It hides the contest from ordinary local selection without deleting data. It may be set or cleared at any lifecycle state and is not the same as a publicly published historical record. It is local to the installation and is not synchronized.

### Contest deletion

Deletion is an administrative action, not an execution state, and a contest has no deletion status. A director may delete a contest after a warning and confirmation. Deletion removes the director's working data for the contest, and synchronized installations are told through a tombstone.

A contest that was published is deletable too. Its published record is not removed: the record keeps its projection and loses only its link to the contest, and it can no longer be updated. The director is warned of this before confirming. Removing a published record from public view is a separate delist request that a system administrator decides, described in [contest-publishing.md](contest-publishing.md).

## Lifecycle transition rules

| From          | To            | Required condition                                                                                                          |
| ------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `Created`     | `Configuring` | A discipline is selected or another configuration mutation is accepted.                                                     |
| `Configuring` | `Ready`       | Required configuration is valid and a valid flight matrix has been created.                                                 |
| `Ready`       | `Configuring` | A configuration or matrix change invalidates the current matrix and no score exists. The prior matrix revision is retained. |
| `Ready`       | `Running`     | The first score submission is accepted.                                                                                     |
| `Configuring` | `Running`     | Not allowed; a valid matrix is required before scoring.                                                                     |
| `Running`     | `Completed`   | The director completes the contest, or an accepted completion condition is met.                                             |

The automatic completion signals are advisory until accepted by the director: all non-retired pilots have a score or explicit zero for all flown groups, or no score has been entered for the configured inactivity period (currently 48 hours in the business requirements). A future matrix round may remain unflown when the director completes the contest.

## Mutability by lifecycle state

- `Created`: only minimum contest identity and location data are available.
- `Configuring`: discipline, participants, scoring options, rules, draw options, and matrix may be changed. Changes that affect an existing matrix require a redraw or explicit matrix revision.
- `Ready`: scores may be entered, and configuration may still be changed only while it does not violate matrix and lock rules. A matrix change creates a new matrix revision.
- `Running`: teams, roles, draw mode, groups per round, discipline, and discipline scoring rules are fixed. Participants may still be added. A pilot added once scores exist is placed by late-add assignments in groups that have not flown and have space, and is not added if no such group exists. Lane assignments may change only for groups without scores. Derived-score options may change and must trigger recalculation from immutable raw score data. A re-flight may be created as an explicit exception while the affected scores are not locked; it creates a new attempt and does not rewrite the matrix or prior scores.
- `Completed`: participant scoring is closed. No new rounds, participation, or matrix changes are allowed. Authorized score corrections preserve prior values and audit history.

## Transition invariants

1. Every accepted transition records the actor, authority, source installation, base revision, resulting revision, and time.
2. A stale or unauthorized transition is rejected without changing the contest.
3. A score submission cannot be accepted unless the lifecycle is `Ready` or `Running`, the target group and participant exist in the applicable matrix revision, and the contest is not administration-locked.
4. The first accepted score changes `Ready` to `Running` atomically with the score mutation.
5. Completion closes participant scoring and prevents future matrix or participation changes.
6. Public projections never become the source of truth. Publishing always identifies the private contest revision and preserves publication history.
7. Deleting a contest removes the director's working data and never removes its published record, other than clearing the record's link to the contest. Hiding results never changes stored scores or the lifecycle.
