# RC Soar Score Architecture - Contest State and Transitions

## Purpose

This document defines the state model for a contest. A contest has one execution lifecycle and several independent controls. Keeping these concerns separate prevents a publication change, scoring pause, or delete request from being mistaken for a change in the contest's execution state.

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

### Publication and visibility

Publication is an operation that creates or updates a separate public projection. It is not an execution lifecycle state and may occur while the contest is `Running` or `Completed`.

The publication status is:

| Value         | Meaning                                                             |
| ------------- | ------------------------------------------------------------------- |
| `Unpublished` | No public projection exists.                                        |
| `Published`   | A public projection exists and records the source private revision. |

The first publish defaults to `Private`. Visibility is independent of publication status:

| Value     | Meaning                                                                       |
| --------- | ----------------------------------------------------------------------------- |
| `Private` | Not searchable or publicly viewable.                                          |
| `Hidden`  | Not searchable or generally listed, but available to authorized participants. |
| `Public`  | Searchable and viewable without an account.                                   |

Visibility transitions are `Private <-> Hidden`, `Private <-> Public`, and `Hidden <-> Public`. A visibility change does not modify the private contest or its execution lifecycle. Publishing a later private revision replaces the public projection atomically; it does not create a new contest lifecycle state.

### Local archive

Local archiving is a storage/display flag for an offline or director-owned contest. It hides the contest from ordinary local selection without deleting data. It may be set or cleared at any lifecycle state and is not the same as a publicly published historical record.

### Deletion status

Deletion is an administrative workflow, not a normal execution state.

| Status          | Meaning                                                                                                                                                         |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `None`          | No deletion request exists.                                                                                                                                     |
| `PendingDelete` | A contest published at least once was delisted and awaits administrator approval. No scoring or ordinary editing is allowed.                                    |
| `Restored`      | An administrator denied the request. The contest and its prior publication and visibility state are restored, and the restoration is retained as audit history. |
| `Deleted`       | An administrator approved removal, or an unpublished local contest was deleted by its director. This is terminal.                                               |

Transitions:

```text
None -> PendingDelete -> Deleted
                    \-> Restored -> None
```

An unpublished, director-owned local contest may transition directly from `None` to `Deleted` after confirmation. A contest that has ever been published must never be physically deleted through ordinary synchronization. Its public projection is first delisted, then retained until administrator approval.

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
- `Running`: participation, teams, roles, draw mode, groups per round, discipline, and discipline scoring rules are fixed. Lane assignments may change only for groups without scores. Derived-score options may change and must trigger recalculation from immutable raw score data. A re-flight may be created as an explicit exception while the affected scores are not locked; it creates a new attempt and does not rewrite the matrix or prior scores.
- `Completed`: participant scoring is closed. No new rounds, participation, or matrix changes are allowed. Authorized score corrections preserve prior values and audit history.

## Transition invariants

1. Every accepted transition records the actor, authority, source installation, base revision, resulting revision, and time.
2. A stale or unauthorized transition is rejected without changing the contest.
3. A score submission cannot be accepted unless the lifecycle is `Ready` or `Running`, the target group and participant exist in the applicable matrix revision, and the contest is not administration-locked.
4. The first accepted score changes `Ready` to `Running` atomically with the score mutation.
5. Completion closes participant scoring and prevents future matrix or participation changes.
6. Public projections never become the source of truth. Publishing always identifies the private contest revision and preserves publication history.
7. Pending deletion prevents scoring and publication updates. Restoration returns the contest to its prior execution lifecycle and prior publication and visibility state; the deletion decision remains in audit history.
