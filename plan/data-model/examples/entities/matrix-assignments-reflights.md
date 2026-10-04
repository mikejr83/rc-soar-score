# Matrix, Assignments and Re-flights

Entity specifications: [MatrixRevision](../../entities/matrix_revision.md), [Round](../../entities/round.md), [RoundGroup](../../entities/round_group.md), [MatrixAssignment](../../entities/matrix_assignment.md), [ReFlight](../../entities/re_flight.md), [ReFlightParticipant](../../entities/re_flight_participant.md).

## MatrixRevision

```json
{
  "id": "019c0000-0000-7000-8000-000000000080",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "revision_number": 1,
  "previous_revision_id": null,
  "first_round": 1,
  "last_round": 8,
  "draw_mode": "StandardManOnMan",
  "random_seed": 2918374651,
  "algorithm_version": "1.0.0",
  "draw_config": {
    "schema_version": 1,
    "groups_per_round": 1,
    "team_protection": true,
    "lane_mode": "None",
    "configured_draw_mode": "StandardManOnMan"
  },
  "seeding_snapshot": {
    "pilots": [
      {
        "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
        "team_id": "019c0000-0000-7000-8000-000000000050"
      },
      {
        "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
        "team_id": null
      }
    ]
  },
  "fairness_summary": {
    "max_duplicate_matchups": 8,
    "matchup_histogram": { "8": 1 },
    "unmet_opponent_count": 0,
    "lane_uniformity_index": null,
    "overall_fairness_score": 1.0
  },
  "reason": "Initial draw",
  "created_by": "019c0000-0000-7000-8000-000000000001",
  "created_at": "2026-10-16T20:00:00Z",
  "finalized_by": "019c0000-0000-7000-8000-000000000001",
  "finalized_at": "2026-10-16T20:05:00Z"
}
```

## Round

```json
{
  "id": "019c0000-0000-7000-8000-000000000081",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
  "ordinal": 1,
  "group_count": 1,
  "status": "Open",
  "superseded_by_round_id": null,
  "revision": 1
}
```

## RoundGroup

```json
{
  "id": "019c0000-0000-7000-8000-000000000083",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "round_id": "019c0000-0000-7000-8000-000000000081",
  "group_number": 1,
  "status": "Locked",
  "locked_by": "019c0000-0000-7000-8000-000000000001",
  "locked_at": "2026-10-17T16:45:00Z",
  "revision": 2
}
```

## MatrixAssignment

An original assignment from the draw:

```json
{
  "id": "019c0000-0000-7000-8000-000000000084",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "scheduled_round_id": "019c0000-0000-7000-8000-000000000081",
  "credited_round_id": "019c0000-0000-7000-8000-000000000081",
  "group": 1,
  "lane": null,
  "flight_sequence": 1,
  "assignment_type": "Original",
  "source_assignment_id": null,
  "re_flight_id": null,
  "superseded_by_assignment_id": null,
  "actor_id": "019c0000-0000-7000-8000-000000000001",
  "reason": null,
  "existing_score_handling": "None",
  "reset_score_revision": null,
  "created_at": "2026-10-16T20:05:00Z"
}
```

Alex Chen's original assignments for round 1 and round 2, which carry the zero-score flights in [Scores, Results and Reviews](scores-results-reviews.md#zero-score-flights):

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000085",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000081",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "group": 1,
    "lane": null,
    "flight_sequence": 1,
    "assignment_type": "Original",
    "source_assignment_id": null,
    "re_flight_id": null,
    "superseded_by_assignment_id": null,
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "reason": null,
    "existing_score_handling": "None",
    "reset_score_revision": null,
    "created_at": "2026-10-16T20:05:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000086",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
    "credited_round_id": "019c0000-0000-7000-8000-000000000082",
    "group": 1,
    "lane": null,
    "flight_sequence": 1,
    "assignment_type": "Original",
    "source_assignment_id": null,
    "re_flight_id": null,
    "superseded_by_assignment_id": null,
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "reason": null,
    "existing_score_handling": "None",
    "reset_score_revision": null,
    "created_at": "2026-10-16T20:05:00Z"
  }
]
```

A re-flight assignment created when the re-flight group was finalized:

```json
{
  "id": "019c0000-0000-7000-8000-000000000087",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
  "credited_round_id": "019c0000-0000-7000-8000-000000000081",
  "group": 2,
  "lane": null,
  "flight_sequence": 2,
  "assignment_type": "Reflight",
  "source_assignment_id": "019c0000-0000-7000-8000-000000000084",
  "re_flight_id": "019c0000-0000-7000-8000-000000000090",
  "superseded_by_assignment_id": null,
  "actor_id": "019c0000-0000-7000-8000-000000000001",
  "reason": "Landing area obstructed by a spectator",
  "existing_score_handling": "None",
  "reset_score_revision": null,
  "created_at": "2026-10-17T17:20:00Z"
}
```

## ReFlight

```json
{
  "id": "019c0000-0000-7000-8000-000000000090",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "credited_round_id": "019c0000-0000-7000-8000-000000000081",
  "source_round_id": "019c0000-0000-7000-8000-000000000081",
  "source_group": 1,
  "type": "ReflyEntireGroup",
  "sequence": 1,
  "previous_reflight_id": null,
  "status": "Finalized",
  "reason": "Landing area obstructed by a spectator",
  "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
  "flown_group": 2,
  "deviation_acknowledged": false,
  "requested_group_size": null,
  "achievable_max_size": null,
  "size_exception_confirmed": false,
  "random_seed": null,
  "algorithm_version": null,
  "config_revision_id": "019c0000-0000-7000-8000-000000000070",
  "created_by": "019c0000-0000-7000-8000-000000000001",
  "created_at": "2026-10-17T16:50:00Z",
  "group_finalized_by": "019c0000-0000-7000-8000-000000000001",
  "group_finalized_at": "2026-10-17T17:10:00Z",
  "finalized_by": "019c0000-0000-7000-8000-000000000001",
  "finalized_at": "2026-10-17T17:20:00Z",
  "cancelled_by": null,
  "cancelled_at": null,
  "cancel_reason": null,
  "revision": 5
}
```

## ReFlightParticipant

```json
{
  "id": "019c0000-0000-7000-8000-000000000091",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "re_flight_id": "019c0000-0000-7000-8000-000000000090",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "role": "Awarded",
  "excluded_reason": null,
  "draw_position": null,
  "response": "NotRequired",
  "responded_by": null,
  "responded_at": null,
  "notification_state": "Delivered",
  "notified_at": "2026-10-17T17:05:00Z",
  "acknowledged_at": "2026-10-17T17:06:30Z",
  "assignment_id": "019c0000-0000-7000-8000-000000000087",
  "revision": 3
}
```
