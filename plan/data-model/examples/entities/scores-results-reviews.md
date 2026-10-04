# Scores, Results and Reviews

Entity specifications: [ScorePlaceholder](../../entities/score_placeholder.md), [ScoreAttempt](../../entities/score_attempt.md), [OfficialScore](../../entities/official_score.md), [FlightResult](../../entities/flight_result.md), [ParticipationStanding](../../entities/participation_standing.md), [TeamStanding](../../entities/team_standing.md), [ReviewRequest](../../entities/review_request.md).

The flight is Sam's round 1 flight: 585 seconds against a 600 second target, landing within 3 m (40 points). Sam has the group's best flight score, so the normalized time score is 585 / 585 \* 1000 + 40 = 1040.

## ScorePlaceholder

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a0",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "assignment_id": "019c0000-0000-7000-8000-000000000084",
  "state": "Official",
  "score_revision": 1,
  "locked_by": null,
  "locked_at": null,
  "revision": 3
}
```

## ScoreAttempt

The landing value is the selected LandingResult id.

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a1",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000a0",
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
}
```

## OfficialScore

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a2",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000a0",
  "score_attempt_id": "019c0000-0000-7000-8000-0000000000a1",
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
}
```

## FlightResult

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a4",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000a0",
  "official_score_id": "019c0000-0000-7000-8000-0000000000a2",
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
  "computed_at": "2026-10-17T15:10:01Z"
}
```

## ParticipationStanding

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a5",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "as_of_round": 1,
  "place": 1,
  "is_tied": false,
  "raw_total": 1040.0,
  "dropped_rounds": [],
  "penalty_total": 0,
  "overall_score": 1040.0,
  "is_preliminary": false,
  "config_revision_id": "019c0000-0000-7000-8000-000000000070",
  "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
  "calculation_version": "1.0.0",
  "computed_at": "2026-10-17T16:50:00Z"
}
```

## TeamStanding

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a6",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "team_id": "019c0000-0000-7000-8000-000000000050",
  "as_of_round": 1,
  "place": 1,
  "is_tied": false,
  "team_score": 1040.0,
  "counted_participations": ["019c0000-0000-7000-8000-000000000040"],
  "is_preliminary": false,
  "config_revision_id": "019c0000-0000-7000-8000-000000000070",
  "matrix_revision_id": "019c0000-0000-7000-8000-000000000080",
  "calculation_version": "1.0.0",
  "computed_at": "2026-10-17T16:50:00Z"
}
```

## ReviewRequest

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a3",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000a0",
  "proposed_components": {
    "time_flown": 590,
    "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d32"
  },
  "participant_message": "My timer shows 9:50, not 9:45.",
  "requester_id": "019c0000-0000-7000-8000-000000000002",
  "base_score_revision": 1,
  "requested_at": "2026-10-17T15:30:00Z",
  "state": "Submitted",
  "decision_actor_id": null,
  "decision_time": null,
  "decision_message": null,
  "resulting_attempt_id": null,
  "revision": 1
}
```

## Zero-score flights

In ALES, a motor restart or an out of bounds landing (more than 75 m from the landing marker) scores zero. Only one zero reason can be selected, and the flight time and landing are recorded as 0 and no landing. The flags stay in the raw attempt, the official score keeps the zero reason in its components, and the flight result has outcome `Zero` with no landing points.

### Motor restart

Alex Chen restarted the motor in round 1. The flight scores 0 and no landing bonus can be earned.

#### ScorePlaceholder

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a7",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
  "assignment_id": "019c0000-0000-7000-8000-000000000085",
  "state": "Official",
  "score_revision": 1,
  "locked_by": null,
  "locked_at": null,
  "revision": 3
}
```

#### ScoreAttempt

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a8",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000a7",
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
  "client_mutation_id": "01J9ZPMR4F6H8K0M2P4R6T8V0X",
  "base_score_revision": 0
}
```

#### OfficialScore

```json
{
  "id": "019c0000-0000-7000-8000-0000000000a9",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000a7",
  "score_attempt_id": "019c0000-0000-7000-8000-0000000000a8",
  "score_revision": 1,
  "components": {
    "time_flown": 0,
    "landing": null,
    "flight_penalty": null,
    "cumulative_penalty": null,
    "zero_reason": "motor_restart"
  },
  "set_at": "2026-10-17T15:15:00Z",
  "set_by": "019c0000-0000-7000-8000-000000000001",
  "reason": "Accepted director entry"
}
```

#### FlightResult

```json
{
  "id": "019c0000-0000-7000-8000-0000000000aa",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000a7",
  "official_score_id": "019c0000-0000-7000-8000-0000000000a9",
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
  "computed_at": "2026-10-17T15:1501Z"
}
```

### Out of bounds landing

Alex Chen landed more than 75 m from the marker in round 2. The flight scores 0.

#### ScorePlaceholder

```json
{
  "id": "019c0000-0000-7000-8000-0000000000ab",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
  "assignment_id": "019c0000-0000-7000-8000-000000000086",
  "state": "Official",
  "score_revision": 1,
  "locked_by": null,
  "locked_at": null,
  "revision": 3
}
```

#### ScoreAttempt

```json
{
  "id": "019c0000-0000-7000-8000-0000000000ac",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000ab",
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
  "client_mutation_id": "01J9ZPOB4F6H8K0M2P4R6T8V0X",
  "base_score_revision": 0
}
```

#### OfficialScore

```json
{
  "id": "019c0000-0000-7000-8000-0000000000ad",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000ab",
  "score_attempt_id": "019c0000-0000-7000-8000-0000000000ac",
  "score_revision": 1,
  "components": {
    "time_flown": 0,
    "landing": null,
    "flight_penalty": null,
    "cumulative_penalty": null,
    "zero_reason": "out_of_bounds"
  },
  "set_at": "2026-10-18T15:20:00Z",
  "set_by": "019c0000-0000-7000-8000-000000000001",
  "reason": "Accepted director entry"
}
```

#### FlightResult

```json
{
  "id": "019c0000-0000-7000-8000-0000000000ae",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "score_placeholder_id": "019c0000-0000-7000-8000-0000000000ab",
  "official_score_id": "019c0000-0000-7000-8000-0000000000ad",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
  "credited_round_id": "019c0000-0000-7000-8000-000000000082",
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
  "computed_at": "2026-10-18T15:2001Z"
}
```
