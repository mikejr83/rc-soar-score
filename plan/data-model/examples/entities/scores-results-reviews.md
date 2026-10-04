# Scores, Results and Reviews

Entity specifications: [ScorePlaceholder](../../entities/score_placeholder.md), [ScoreAttempt](../../entities/score_attempt.md), [OfficialScore](../../entities/official_score.md), [FlightResult](../../entities/flight_result.md), [ParticipationStanding](../../entities/participation_standing.md), [TeamStanding](../../entities/team_standing.md), [ReviewRequest](../../entities/review_request.md).

The contest is scored in `Time` mode: each flight earns 1 point per second, the best flight in the group is normalized to 1000, and the landing bonus is added afterward. The landing bonus is read from the contest's landing table (50 points within 1 m, down to 5 points within 10 m), and a score stores the selected landing entry's id.

## Round 1 results

| Pilot  | Group | Time (s) | Landing    | Flight points | Group best | Normalized | Landing points | Group score |
| ------ | ----- | -------- | ---------- | ------------- | ---------- | ---------- | -------------- | ----------- |
| Sam    | 1     | 585      | within 3 m | 585           | 585        | 1000.0     | 40             | 1040.0      |
| Riley  | 1     | 570      | within 1 m | 570           | 585        | 974.4      | 50             | 1024.4      |
| Taylor | 1     | 540      | within 6 m | 540           | 585        | 923.1      | 25             | 948.1       |
| Morgan | 2     | 597      | within 2 m | 597           | 597        | 1000.0     | 45             | 1045.0      |
| Alex   | 2     | 0        | none       | 0             | 597        | 0.0        | 0              | 0.0         |

Alex restarted the motor, which scores zero. In round 2, Alex's group 1 flight is out of bounds, which also scores zero. The rest of round 2 has not been scored yet.

## ScorePlaceholder

One per flight. The first five are round 1. The next is Alex's round 2 flight, and the last is Morgan's round 2 flight, which has not been entered. The other round 2 placeholders and the three re-flight placeholders are also `NotEntered` and are left out.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000301",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "assignment_id": "019c0000-0000-7000-8000-000000000101",
    "state": "Official",
    "score_revision": 1,
    "locked_by": null,
    "locked_at": null,
    "revision": 3
  },
  {
    "id": "019c0000-0000-7000-8000-000000000303",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "assignment_id": "019c0000-0000-7000-8000-000000000103",
    "state": "Official",
    "score_revision": 1,
    "locked_by": null,
    "locked_at": null,
    "revision": 3
  },
  {
    "id": "019c0000-0000-7000-8000-000000000305",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
    "assignment_id": "019c0000-0000-7000-8000-000000000105",
    "state": "Official",
    "score_revision": 1,
    "locked_by": null,
    "locked_at": null,
    "revision": 3
  },
  {
    "id": "019c0000-0000-7000-8000-000000000304",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
    "assignment_id": "019c0000-0000-7000-8000-000000000104",
    "state": "Official",
    "score_revision": 1,
    "locked_by": null,
    "locked_at": null,
    "revision": 3
  },
  {
    "id": "019c0000-0000-7000-8000-000000000302",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "assignment_id": "019c0000-0000-7000-8000-000000000102",
    "state": "Official",
    "score_revision": 1,
    "locked_by": null,
    "locked_at": null,
    "revision": 3
  },
  {
    "id": "019c0000-0000-7000-8000-000000000311",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "assignment_id": "019c0000-0000-7000-8000-000000000111",
    "state": "Official",
    "score_revision": 1,
    "locked_by": null,
    "locked_at": null,
    "revision": 3
  },
  {
    "id": "019c0000-0000-7000-8000-000000000312",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
    "assignment_id": "019c0000-0000-7000-8000-000000000112",
    "state": "NotEntered",
    "score_revision": 0,
    "locked_by": null,
    "locked_at": null,
    "revision": 1
  }
]
```

## ScoreAttempt

A normal flight, a motor restart, and (last) an out of bounds landing. Sam, Riley, and Taylor are normal flights, Morgan too. Only one zero reason can be set, and a zero records the flight time as 0 and no landing.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000401",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000301",
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "raw_components": {
      "time_flown": 585,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d32",
      "flight_penalty": null
    },
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "authority": "Director",
    "invitation_id": null,
    "source_device": "field-laptop",
    "client_mutation_id": "01J9ZM5B2E4G6H8K0N2Q4S6U8W",
    "base_score_revision": 0
  },
  {
    "id": "019c0000-0000-7000-8000-000000000402",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000303",
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "raw_components": {
      "time_flown": 570,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d30",
      "flight_penalty": null
    },
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "authority": "Director",
    "invitation_id": null,
    "source_device": "field-laptop",
    "client_mutation_id": "01J9ZM5B2E4G6H8K0N2Q4S6U9X",
    "base_score_revision": 0
  },
  {
    "id": "019c0000-0000-7000-8000-000000000403",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000305",
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "raw_components": {
      "time_flown": 540,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d35",
      "flight_penalty": null
    },
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "authority": "Director",
    "invitation_id": null,
    "source_device": "field-laptop",
    "client_mutation_id": "01J9ZM5B2E4G6H8K0N2Q4S6UAY",
    "base_score_revision": 0
  },
  {
    "id": "019c0000-0000-7000-8000-000000000404",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000304",
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "raw_components": {
      "time_flown": 597,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d31",
      "flight_penalty": null
    },
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "authority": "Director",
    "invitation_id": null,
    "source_device": "field-laptop",
    "client_mutation_id": "01J9ZM5B2E4G6H8K0N2Q4S6UBZ",
    "base_score_revision": 0
  },
  {
    "id": "019c0000-0000-7000-8000-000000000405",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000302",
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "raw_components": {
      "time_flown": 0,
      "landing": null,
      "motor_restart": true,
      "out_of_bounds": false,
      "overflight_gt_one_min": false,
      "flight_penalty": null
    },
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "authority": "Director",
    "invitation_id": null,
    "source_device": "field-laptop",
    "client_mutation_id": "01J9ZM5B2E4G6H8K0N2Q4S6UC0",
    "base_score_revision": 0
  },
  {
    "id": "019c0000-0000-7000-8000-000000000406",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000311",
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "raw_components": {
      "time_flown": 0,
      "landing": null,
      "motor_restart": false,
      "out_of_bounds": true,
      "overflight_gt_one_min": false,
      "flight_penalty": null
    },
    "actor_id": "019c0000-0000-7000-8000-000000000001",
    "authority": "Director",
    "invitation_id": null,
    "source_device": "field-laptop",
    "client_mutation_id": "01J9ZM5B2E4G6H8K0N2Q4S6UD1",
    "base_score_revision": 0
  }
]
```

## OfficialScore

A zero reason is kept in the components as `zero_reason`.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000501",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000301",
    "score_attempt_id": "019c0000-0000-7000-8000-000000000401",
    "score_revision": 1,
    "components": {
      "time_flown": 585,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d32",
      "flight_penalty": null,
      "cumulative_penalty": null
    },
    "set_at": "2026-10-17T15:10:00Z",
    "set_by": "019c0000-0000-7000-8000-000000000001",
    "reason": "Accepted director entry"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000502",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000303",
    "score_attempt_id": "019c0000-0000-7000-8000-000000000402",
    "score_revision": 1,
    "components": {
      "time_flown": 570,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d30",
      "flight_penalty": null,
      "cumulative_penalty": null
    },
    "set_at": "2026-10-17T15:11:00Z",
    "set_by": "019c0000-0000-7000-8000-000000000001",
    "reason": "Accepted director entry"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000503",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000305",
    "score_attempt_id": "019c0000-0000-7000-8000-000000000403",
    "score_revision": 1,
    "components": {
      "time_flown": 540,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d35",
      "flight_penalty": null,
      "cumulative_penalty": null
    },
    "set_at": "2026-10-17T15:12:00Z",
    "set_by": "019c0000-0000-7000-8000-000000000001",
    "reason": "Accepted director entry"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000504",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000304",
    "score_attempt_id": "019c0000-0000-7000-8000-000000000404",
    "score_revision": 1,
    "components": {
      "time_flown": 597,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d31",
      "flight_penalty": null,
      "cumulative_penalty": null
    },
    "set_at": "2026-10-17T15:20:00Z",
    "set_by": "019c0000-0000-7000-8000-000000000001",
    "reason": "Accepted director entry"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000505",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000302",
    "score_attempt_id": "019c0000-0000-7000-8000-000000000405",
    "score_revision": 1,
    "components": {
      "time_flown": 0,
      "landing": null,
      "flight_penalty": null,
      "cumulative_penalty": null,
      "zero_reason": "motor_restart"
    },
    "set_at": "2026-10-17T15:21:00Z",
    "set_by": "019c0000-0000-7000-8000-000000000001",
    "reason": "Accepted director entry"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000506",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000311",
    "score_attempt_id": "019c0000-0000-7000-8000-000000000406",
    "score_revision": 1,
    "components": {
      "time_flown": 0,
      "landing": null,
      "flight_penalty": null,
      "cumulative_penalty": null,
      "zero_reason": "out_of_bounds"
    },
    "set_at": "2026-10-17T17:05:00Z",
    "set_by": "019c0000-0000-7000-8000-000000000001",
    "reason": "Accepted director entry"
  }
]
```

## FlightResult

The out of bounds result is preliminary because round 2 group 1 is not yet complete.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000601",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000301",
    "official_score_id": "019c0000-0000-7000-8000-000000000501",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "outcome": "Scored",
    "raw_points": 625,
    "landing_points": 40,
    "flight_penalty_points": 0,
    "cumulative_penalty": null,
    "group_score": 1040.0,
    "is_selected": true,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:12:01Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000602",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000303",
    "official_score_id": "019c0000-0000-7000-8000-000000000502",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "outcome": "Scored",
    "raw_points": 620,
    "landing_points": 50,
    "flight_penalty_points": 0,
    "cumulative_penalty": null,
    "group_score": 1024.4,
    "is_selected": true,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:12:01Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000603",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000305",
    "official_score_id": "019c0000-0000-7000-8000-000000000503",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "outcome": "Scored",
    "raw_points": 565,
    "landing_points": 25,
    "flight_penalty_points": 0,
    "cumulative_penalty": null,
    "group_score": 948.1,
    "is_selected": true,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:12:01Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000604",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000304",
    "official_score_id": "019c0000-0000-7000-8000-000000000504",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "outcome": "Scored",
    "raw_points": 642,
    "landing_points": 45,
    "flight_penalty_points": 0,
    "cumulative_penalty": null,
    "group_score": 1045.0,
    "is_selected": true,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:21:01Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000605",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000302",
    "official_score_id": "019c0000-0000-7000-8000-000000000505",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "credited_round_id": "019c0000-0000-7000-8000-000000000081",
    "outcome": "Zero",
    "raw_points": 0,
    "landing_points": null,
    "flight_penalty_points": null,
    "cumulative_penalty": null,
    "group_score": 0.0,
    "is_selected": true,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:21:01Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000606",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000311",
    "official_score_id": "019c0000-0000-7000-8000-000000000506",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "credited_round_id": "019c0000-0000-7000-8000-000000000082",
    "outcome": "Zero",
    "raw_points": 0,
    "landing_points": null,
    "flight_penalty_points": null,
    "cumulative_penalty": null,
    "group_score": 0.0,
    "is_selected": true,
    "is_preliminary": true,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T17:05:01Z"
  }
]
```

## ParticipationStanding

Overall standings as of round 1, with no rounds dropped yet.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000701",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
    "as_of_round": 1,
    "place": 1,
    "is_tied": false,
    "raw_total": 1045.0,
    "dropped_rounds": [],
    "penalty_total": 0,
    "overall_score": 1045.0,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:22:02Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000702",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "as_of_round": 1,
    "place": 2,
    "is_tied": false,
    "raw_total": 1040.0,
    "dropped_rounds": [],
    "penalty_total": 0,
    "overall_score": 1040.0,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:22:02Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000703",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "as_of_round": 1,
    "place": 3,
    "is_tied": false,
    "raw_total": 1024.4,
    "dropped_rounds": [],
    "penalty_total": 0,
    "overall_score": 1024.4,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:22:02Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000704",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
    "as_of_round": 1,
    "place": 4,
    "is_tied": false,
    "raw_total": 948.1,
    "dropped_rounds": [],
    "penalty_total": 0,
    "overall_score": 948.1,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:22:02Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000705",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "as_of_round": 1,
    "place": 5,
    "is_tied": false,
    "raw_total": 0.0,
    "dropped_rounds": [],
    "penalty_total": 0,
    "overall_score": 0.0,
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:22:02Z"
  }
]
```

## TeamStanding

Each team counts the scores of its best two pilots (`team_pilot_count` is 2).

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000711",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "team_id": "019c0000-0000-7000-8000-000000000056",
    "as_of_round": 1,
    "place": 1,
    "is_tied": false,
    "team_score": 2069.4,
    "counted_participations": [
      "019c0000-0000-7000-8000-000000000044",
      "019c0000-0000-7000-8000-000000000043"
    ],
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:22:03Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000712",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "team_id": "019c0000-0000-7000-8000-000000000050",
    "as_of_round": 1,
    "place": 2,
    "is_tied": false,
    "team_score": 1040.0,
    "counted_participations": [
      "019c0000-0000-7000-8000-000000000040",
      "019c0000-0000-7000-8000-000000000041"
    ],
    "is_preliminary": false,
    "config_revision_id": "019c0000-0000-7000-8000-000000000070",
    "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
    "calculation_version": "1.0.0",
    "computed_at": "2026-10-17T15:22:03Z"
  }
]
```

## ReviewRequest

Taylor's request to change the flight time was rejected, so the score stays official.

```json
{
  "id": "019c0000-0000-7000-8000-000000000801",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-000000000305",
  "proposed_components": {
    "time_flown": 550,
    "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d35"
  },
  "participant_message": "My own timer shows 9:10, not 9:00.",
  "requester_id": "019c0000-0000-7000-8000-000000000006",
  "base_score_revision": 1,
  "requested_at": "2026-10-17T15:14:00Z",
  "state": "Rejected",
  "decision_actor_id": "019c0000-0000-7000-8000-000000000001",
  "decision_time": "2026-10-17T15:25:00Z",
  "decision_message": "The official timer's reading stands.",
  "resulting_attempt_id": null,
  "revision": 3
}
```
