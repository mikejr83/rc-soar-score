# Matrix, Assignments and Re-flights

Entity specifications: [MatrixRevision](../../entities/matrix_revision.md), [Round](../../entities/round.md), [RoundGroup](../../entities/round_group.md), [MatrixAssignment](../../entities/matrix_assignment.md), [ReFlight](../../entities/re_flight.md), [ReFlightParticipant](../../entities/re_flight_participant.md).

Five pilots fly in two groups per round: a group of three and a group of two. Team protection keeps teammates apart. Sam and Alex (Boulder Thermals) never fly together, and neither do Riley and Morgan (Longmont Lofters). Round 1 is finished and locked. Round 2 is in progress. After round 1, Sam's group flew with a spectator in the landing area, so the director awarded a re-flight of that whole group, flown as group 3 of round 2.

| Round | Group 1              | Group 2      | Group 3 (re-flight of round 1 group 1) |
| ----- | -------------------- | ------------ | -------------------------------------- |
| 1     | Sam, Riley, Taylor   | Alex, Morgan |                                        |
| 2     | Alex, Morgan, Taylor | Sam, Riley   | Sam, Riley, Taylor                     |

## MatrixRevision

Eight rounds are drawn. With four pilot pairs apart from the two protected teammates, the draw gives each of the 8 other pilot pairs 4 matchups.

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
    "groups_per_round": 2,
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
        "team_id": "019c0000-0000-7000-8000-000000000050"
      },
      {
        "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
        "team_id": "019c0000-0000-7000-8000-000000000056"
      },
      {
        "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
        "team_id": "019c0000-0000-7000-8000-000000000056"
      },
      {
        "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
        "team_id": null
      }
    ]
  },
  "fairness_summary": {
    "max_duplicate_matchups": 4,
    "matchup_histogram": {
      "0": 2,
      "4": 8
    },
    "unmet_opponent_count": 0,
    "lane_uniformity_index": null,
    "overall_fairness_score": 0.97
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
[
  {
    "id": "019c0000-0000-7000-8000-000000000081",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "ordinal": 1,
    "group_count": 2,
    "status": "Locked",
    "superseded_by_round_id": null,
    "revision": 2
  },
  {
    "id": "019c0000-0000-7000-8000-000000000082",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "ordinal": 2,
    "group_count": 2,
    "status": "Open",
    "superseded_by_round_id": null,
    "revision": 1
  }
]
```

## RoundGroup

Round 1 is locked. The re-flight group (group 3) was created when the re-flight group was finalized.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000201",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "round_id": "019c0000-0000-7000-8000-000000000081",
    "group_number": 1,
    "status": "Locked",
    "locked_by": "019c0000-0000-7000-8000-000000000001",
    "locked_at": "2026-10-17T15:30:00Z",
    "revision": 2
  },
  {
    "id": "019c0000-0000-7000-8000-000000000202",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "round_id": "019c0000-0000-7000-8000-000000000081",
    "group_number": 2,
    "status": "Locked",
    "locked_by": "019c0000-0000-7000-8000-000000000001",
    "locked_at": "2026-10-17T15:30:00Z",
    "revision": 2
  },
  {
    "id": "019c0000-0000-7000-8000-000000000203",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "round_id": "019c0000-0000-7000-8000-000000000082",
    "group_number": 1,
    "status": "Open",
    "locked_by": null,
    "locked_at": null,
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000204",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "round_id": "019c0000-0000-7000-8000-000000000082",
    "group_number": 2,
    "status": "Open",
    "locked_by": null,
    "locked_at": null,
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000205",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "round_id": "019c0000-0000-7000-8000-000000000082",
    "group_number": 3,
    "status": "Open",
    "locked_by": null,
    "locked_at": null,
    "revision": 1
  }
]
```

## MatrixAssignment

Original assignments for round 1, in group order:

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000101",
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
  },
  {
    "id": "019c0000-0000-7000-8000-000000000103",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
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
    "id": "019c0000-0000-7000-8000-000000000105",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
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
    "id": "019c0000-0000-7000-8000-000000000102",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000081",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "group": 2,
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
    "id": "019c0000-0000-7000-8000-000000000104",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000081",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "group": 2,
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

Original assignments for round 2:

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000111",
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
  },
  {
    "id": "019c0000-0000-7000-8000-000000000112",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
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
  },
  {
    "id": "019c0000-0000-7000-8000-000000000113",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
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
  },
  {
    "id": "019c0000-0000-7000-8000-000000000114",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
    "credited_round_id": "019c0000-0000-7000-8000-000000000082",
    "group": 2,
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
    "id": "019c0000-0000-7000-8000-000000000115",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
    "credited_round_id": "019c0000-0000-7000-8000-000000000082",
    "group": 2,
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

The re-flight assignments, created when the re-flight group was finalized. They are scheduled in round 2 and credited to round 1, as the second flight of each pilot's round 1:

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000121",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "group": 3,
    "lane": null,
    "flight_sequence": 2,
    "assignment_type": "Reflight",
    "source_assignment_id": "019c0000-0000-7000-8000-000000000101",
    "re_flight_id": "019c0000-0000-7000-8000-000000000901",
    "superseded_by_assignment_id": null,
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "reason": "Landing area obstructed by a spectator",
    "existing_score_handling": "None",
    "reset_score_revision": null,
    "created_at": "2026-10-17T15:50:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000122",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "group": 3,
    "lane": null,
    "flight_sequence": 2,
    "assignment_type": "Reflight",
    "source_assignment_id": "019c0000-0000-7000-8000-000000000103",
    "re_flight_id": "019c0000-0000-7000-8000-000000000901",
    "superseded_by_assignment_id": null,
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "reason": "Landing area obstructed by a spectator",
    "existing_score_handling": "None",
    "reset_score_revision": null,
    "created_at": "2026-10-17T15:50:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000123",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
    "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "group": 3,
    "lane": null,
    "flight_sequence": 2,
    "assignment_type": "Reflight",
    "source_assignment_id": "019c0000-0000-7000-8000-000000000105",
    "re_flight_id": "019c0000-0000-7000-8000-000000000901",
    "superseded_by_assignment_id": null,
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "reason": "Landing area obstructed by a spectator",
    "existing_score_handling": "None",
    "reset_score_revision": null,
    "created_at": "2026-10-17T15:50:00Z"
  }
]
```

## ReFlight

```json
{
  "id": "019c0000-0000-7000-8000-000000000901",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "credited_round_id": "019c0000-0000-7000-8000-000000000081",
  "source_round_id": "019c0000-0000-7000-8000-000000000081",
  "source_group": 1,
  "type": "ReflyEntireGroup",
  "sequence": 1,
  "previous_reflight_id": null,
  "status": "ReadyToFly",
  "reason": "Landing area obstructed by a spectator",
  "scheduled_round_id": "019c0000-0000-7000-8000-000000000082",
  "flown_group": 3,
  "deviation_acknowledged": false,
  "requested_group_size": null,
  "achievable_max_size": null,
  "size_exception_confirmed": false,
  "random_seed": null,
  "algorithm_version": null,
  "config_revision_id": "019c0000-0000-7000-8000-000000000070",
  "created_by": "019c0000-0000-7000-8000-000000000001",
  "created_at": "2026-10-17T15:40:00Z",
  "group_finalized_by": "019c0000-0000-7000-8000-000000000001",
  "group_finalized_at": "2026-10-17T15:50:00Z",
  "finalized_by": null,
  "finalized_at": null,
  "cancelled_by": null,
  "cancelled_at": null,
  "cancel_reason": null,
  "revision": 3
}
```

## ReFlightParticipant

Sam was awarded the re-flight. Riley and Taylor re-fly as members of the group. Taylor has not yet acknowledged the notification.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000911",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "re_flight_id": "019c0000-0000-7000-8000-000000000901",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "role": "Awarded",
    "excluded_reason": null,
    "draw_position": null,
    "response": "NotRequired",
    "responded_by": null,
    "responded_at": null,
    "notification_state": "Delivered",
    "notified_at": "2026-10-17T15:52:00Z",
    "acknowledged_at": "2026-10-17T15:53:30Z",
    "assignment_id": "019c0000-0000-7000-8000-000000000121",
    "revision": 2
  },
  {
    "id": "019c0000-0000-7000-8000-000000000912",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "re_flight_id": "019c0000-0000-7000-8000-000000000901",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "role": "GroupMember",
    "excluded_reason": null,
    "draw_position": null,
    "response": "NotRequired",
    "responded_by": null,
    "responded_at": null,
    "notification_state": "Delivered",
    "notified_at": "2026-10-17T15:52:00Z",
    "acknowledged_at": "2026-10-17T15:55:00Z",
    "assignment_id": "019c0000-0000-7000-8000-000000000122",
    "revision": 2
  },
  {
    "id": "019c0000-0000-7000-8000-000000000913",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "re_flight_id": "019c0000-0000-7000-8000-000000000901",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
    "role": "GroupMember",
    "excluded_reason": null,
    "draw_position": null,
    "response": "NotRequired",
    "responded_by": null,
    "responded_at": null,
    "notification_state": "Delivered",
    "notified_at": "2026-10-17T15:52:00Z",
    "acknowledged_at": null,
    "assignment_id": "019c0000-0000-7000-8000-000000000123",
    "revision": 2
  }
]
```
