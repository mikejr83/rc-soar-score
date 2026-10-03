# Thermal Duration Discipline Example

Thermal Duration is a duration task where pilots fly a prescribed target time and
perform a precision landing. Group scoring defaults to "Normalized" (flight score
plus landing bonus normalized together).

## DisciplineProfile

```json
{
  "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
  "type": "ThermalDuration",
  "version": 1,
  "name": "Thermal Duration",
  "description": "Duration task with prescribed target time and precision landing. Flight score + landing bonus normalized to 1000. Default group scoring: Normalized.",
  "category": "duration",
  "default_landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
  "status": "published",
  "superseded_by": null,
  "created_by": "admin@example.com",
  "created_at": "2026-09-15T00:00:00Z",
  "updated_by": null,
  "updated_at": null
}
```

## LandingTable

The system table the profile names as its default. It has no owner and is never modified.

```json
{
  "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
  "owner_account_id": null,
  "name": "Thermal Standard Landing Table",
  "input_unit": "meters",
  "created_at": "2026-09-15T00:00:00Z"
}
```

## LandingResult

Each entry maps the key the scorer selects to the points awarded. A score stores the entry `id`.

```json
[
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c03",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "within_10m",
    "display_value": "Within 10 m",
    "point_value": 20,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c04",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "within_25m",
    "display_value": "Within 25 m",
    "point_value": 15,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c05",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "within_50m",
    "display_value": "Within 50 m",
    "point_value": 10,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c06",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "within_75m",
    "display_value": "Within 75 m",
    "point_value": 5,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c07",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "none",
    "display_value": "No bonus",
    "point_value": 0,
    "ordinal_position": 5
  }
]
```

## DisciplineConfigField

```json
[
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c08",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c09",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c0a",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c0b",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "field_key": "landing_table",
    "field_type": "landing",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points. The contest selects a landing table, which defaults to the profile\'s default (Thermal Standard Landing Table).",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c0c",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c0d",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded dynamically from the linked landing table (Thermal Standard Landing Table).",
    "required": false,
    "display_order": 2,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c0e",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "field_key": "out_of_bounds",
    "field_type": "bool",
    "name": "Out of Bounds",
    "description": "Pilot landed >75m from landing marker",
    "required": false,
    "default_value": false,
    "display_order": 3,
    "is_zero_reason": true,
    "zero_reason_code": "out_of_bounds",
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c0f",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "field_key": "overflight_gt_one_min",
    "field_type": "bool",
    "name": "Overflight > 1 Min",
    "description": "Pilot landed more than 1 minute past target time",
    "required": false,
    "default_value": false,
    "display_order": 4,
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c10",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c11",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "field_keys": ["out_of_bounds", "overflight_gt_one_min"],
    "constraint_type": "mutually_exclusive",
    "description": "Only one of out_of_bounds or overflight_gt_one_min can be selected",
    "message": "Select only one: Out of Bounds or Overflight > 1 Min",
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c12",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "formula_key": "overflight_penalty",
    "formula_type": "penalty",
    "description": "Calculate overflight penalty: if time exceeds target, penalty = (time - target) * PPS",
    "formula_text": "time_flown <= target_time ? 0 : (time_flown - target_time) * points_per_second",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c13",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c14",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "formula_key": "raw_score",
    "formula_type": "intermediate",
    "description": "Calculate raw score: flight score + landing bonus",
    "formula_text": "flight_score + landing_bonus",
    "inputs": {
      "flight_score": "calc:flight_score",
      "landing_bonus": "lookup:landing_table(landing)"
    },
    "outputs": { "raw_score": "calc:raw_score" },
    "depends_on": ["flight_score"],
    "is_primary": false,
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c15",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "formula_key": "normalization",
    "formula_type": "final",
    "is_primary": true,
    "description": "Normalize combined scores to 1000 (Thermal Normalized mode)",
    "formula_text": "raw_score / max_group_raw_score * 1000",
    "inputs": {
      "raw_score": "calc:raw_score",
      "max_group_raw_score": "group:raw_score_max"
    },
    "outputs": { "normalized": "final:normalized" },
    "depends_on": ["raw_score"],
    "display_order": 4,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineRule

```json
[
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c16",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c17",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
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
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```
