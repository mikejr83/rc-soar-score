# ALES (Altitude Limited Electronic Soaring) Discipline Example

ALES is a duration task where pilots fly a prescribed time and perform a precision
landing. Group scoring defaults to "Time" (flight time normalized, then landing
bonus added).

## DisciplineProfile

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "type": "ALES",
  "version": 1,
  "name": "Altitude Limited Electronic Soaring (ALES)",
  "description": "Duration task with prescribed target time and precision landing. Flight time normalized to 1000, then landing bonus added. Default group scoring: Time.",
  "category": "duration",
  "default_landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
  "default_options": { "group_score_mode": "Time" },
  "status": "published",
  "superseded_by": null,
  "created_by": "019a3c40-0000-7000-8000-000000000001",
  "created_at": "2026-09-15T00:00:00Z",
  "updated_by": null,
  "updated_at": null
}
```

## LandingTable

The system table the profile names as its default. It has no owner and is never modified.

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
  "owner_account_id": null,
  "name": "ALES Standard Landing Table",
  "input_unit": "points",
  "created_at": "2026-09-15T00:00:00Z"
}
```

## LandingResult

Each entry maps the key the scorer selects to the points awarded: the scorer selects the points directly, from 50 down to 0 in steps of 5, like the F5J Standard Landing Table. A landing more than 75 m from the marker is out of bounds and scores zero through the out-of-bounds indicator, not a table entry. A score stores the entry `id`.

```json
[
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e01",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_50",
    "display_value": "50 pts",
    "point_value": 50,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e02",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_45",
    "display_value": "45 pts",
    "point_value": 45,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e03",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_40",
    "display_value": "40 pts",
    "point_value": 40,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e04",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_35",
    "display_value": "35 pts",
    "point_value": 35,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e05",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_30",
    "display_value": "30 pts",
    "point_value": 30,
    "ordinal_position": 5
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e06",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_25",
    "display_value": "25 pts",
    "point_value": 25,
    "ordinal_position": 6
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e07",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_20",
    "display_value": "20 pts",
    "point_value": 20,
    "ordinal_position": 7
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e08",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_15",
    "display_value": "15 pts",
    "point_value": 15,
    "ordinal_position": 8
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e09",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_10",
    "display_value": "10 pts",
    "point_value": 10,
    "ordinal_position": 9
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e0a",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_5",
    "display_value": "5 pts",
    "point_value": 5,
    "ordinal_position": 10
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1e0b",
    "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "entry_key": "points_0",
    "display_value": "0 pts",
    "point_value": 0,
    "ordinal_position": 11
  }
]
```

## DisciplineConfigField

```json
[
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d08",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "target_time",
    "field_type": "int",
    "name": "Target Time",
    "description": "Duration of the flight pilots will attempt, in seconds",
    "required": true,
    "default_value": 600,
    "validation": { "gt": 0, "lt": 3600 },
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d18",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "fractional_seconds",
    "field_type": "int",
    "name": "Fractional Secs",
    "description": "Number of decimal places to count (0-3)",
    "required": true,
    "default_value": 0,
    "validation": { "gte": 0, "lte": 3 },
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d09",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "points_per_second",
    "field_type": "float",
    "name": "Points Per Second",
    "description": "Raw points awarded for each second of flight time",
    "required": true,
    "default_value": 1.0,
    "validation": { "gt": 0 },
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d0a",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "landing_table",
    "field_type": "landing",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points. The contest selects a landing table, which defaults to the profile's default (ALES Standard Landing Table).",
    "required": true,
    "display_order": 4,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineScoreField

```json
[
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d0b",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "time_flown",
    "field_type": "time",
    "name": "Time Flown",
    "description": "Actual flight time (MM:SS format)",
    "required": true,
    "display_order": 1,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d0c",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded dynamically from the linked landing table (ALES Standard Landing Table).",
    "required": false,
    "display_order": 2,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d0d",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "motor_restart",
    "field_type": "bool",
    "name": "Motor Restart",
    "description": "Pilot restarted motor during flight",
    "required": false,
    "default_value": false,
    "display_order": 3,
    "is_zero_reason": true,
    "zero_reason_code": "motor_restart",
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d0e",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "out_of_bounds",
    "field_type": "bool",
    "name": "Out of Bounds",
    "description": "Pilot landed >75m from landing marker",
    "required": false,
    "default_value": false,
    "display_order": 4,
    "is_zero_reason": true,
    "zero_reason_code": "out_of_bounds",
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d0f",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_key": "overflight_gt_one_min",
    "field_type": "bool",
    "name": "Overflight > 1 Min",
    "description": "Pilot landed more than 1 minute past target time",
    "required": false,
    "default_value": false,
    "display_order": 5,
    "is_zero_reason": true,
    "zero_reason_code": "overflight_gt_one_min",
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineValidation

```json
[
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d10",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_keys": ["time_flown", "overflight_gt_one_min"],
    "constraint_type": "required_if",
    "description": "Overflight > 1 Min may only be marked when time flown exceeds target time by more than 60 seconds",
    "applies_to": {
      "field": "time_flown",
      "op": "gt",
      "value": "target_time + 60"
    },
    "message": "Overflight > 1 Min can only be selected when Time Flown exceeds Target Time by more than 1 minute",
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d11",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "field_keys": ["motor_restart", "out_of_bounds", "overflight_gt_one_min"],
    "constraint_type": "mutually_exclusive",
    "description": "Only one of motor_restart, out_of_bounds, or overflight_gt_one_min can be selected",
    "message": "Select only one: Motor Restart, Out of Bounds, or Overflight > 1 Min",
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d12",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "formula_key": "overflight_penalty",
    "formula_type": "penalty",
    "description": "Calculate overflight penalty: if time exceeds target, penalty = 2 * (time - target) * PPS, so flying over the target scores like flying the same time under it",
    "formula_text": "time_flown <= target_time ? 0 : 2 * (time_flown - target_time) * points_per_second",
    "inputs": {
      "time_flown": "score:time_flown",
      "target_time": "config:target_time",
      "points_per_second": "config:points_per_second"
    },
    "outputs": { "overflight_penalty": "calc:overflight_penalty" },
    "depends_on": [],
    "is_primary": false,
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d13",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "formula_key": "flight_score",
    "formula_type": "intermediate",
    "description": "Calculate flight score: max(0, time * PPS - overflight penalty)",
    "formula_text": "max(0, (time_flown * points_per_second) - overflight_penalty)",
    "inputs": {
      "time_flown": "score:time_flown",
      "points_per_second": "config:points_per_second",
      "overflight_penalty": "calc:overflight_penalty"
    },
    "outputs": { "flight_score": "calc:flight_score" },
    "depends_on": ["overflight_penalty"],
    "is_primary": false,
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d14",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "formula_key": "time_normalization",
    "formula_type": "final",
    "is_primary": true,
    "description": "Normalize flight scores to 1000, then add landing bonus (ALES Time mode)",
    "formula_text": "(flight_score / max_group_flight_score * 1000) + landing_bonus",
    "inputs": {
      "flight_score": "calc:flight_score",
      "max_group_flight_score": "group:flight_score_max",
      "landing_bonus": "lookup:landing_table(landing)"
    },
    "outputs": { "normalized": "final:normalized" },
    "depends_on": ["flight_score"],
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineRule

```json
[
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d15",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "rule_key": "out_of_bounds",
    "rule_type": "zero",
    "condition": "out_of_bounds == true",
    "effect": "score = 0",
    "applies_to": ["out_of_bounds"],
    "depends_on": [],
    "display_name": "Out of bounds landing",
    "description": "The pilot landed more than 75m from their landing marker.",
    "auto_score_zero": true,
    "affects_other_fields": ["time_flown", "landing"],
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d16",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "rule_key": "motor_restart",
    "rule_type": "zero",
    "condition": "motor_restart == true",
    "effect": "score = 0",
    "applies_to": ["motor_restart"],
    "depends_on": [],
    "display_name": "Motor restart",
    "description": "The pilot restarted the motor during flight.",
    "auto_score_zero": true,
    "affects_other_fields": ["time_flown", "landing"],
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d17",
    "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "rule_key": "overflight_gt_one_min",
    "rule_type": "zero",
    "condition": "overflight_gt_one_min == true",
    "effect": "score = 0",
    "applies_to": ["overflight_gt_one_min"],
    "depends_on": [],
    "display_name": "Overflight > 1 minute",
    "description": "The pilot did not land within 1 minute past target time.",
    "auto_score_zero": true,
    "affects_other_fields": ["time_flown", "landing"],
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```
