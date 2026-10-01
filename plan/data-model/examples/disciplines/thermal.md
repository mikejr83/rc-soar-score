# Thermal Duration Discipline Example

Thermal Duration is a duration task where pilots fly a prescribed target time and
perform a precision landing. Group scoring defaults to "Normalized" (flight score
plus landing bonus normalized together).

## DisciplineProfile

```json
{
  "id": "thermal-profile-v1",
  "type": "THERMAL",
  "version": 1,
  "name": "Thermal Duration",
  "description": "Duration task with prescribed target time and precision landing. Flight score + landing bonus normalized to 1000. Default group scoring: Normalized.",
  "category": "duration",
  "status": "published",
  "created_by": "admin@example.com",
  "created_at": "2026-09-15T00:00:00Z",
  "updated_by": null,
  "updated_at": null
}
```

## DisciplineConfigField

```json
[
  {
    "id": "thermal-cf-001",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "target_time",
    "field_type": "time",
    "name": "Target Time",
    "description": "Duration of the flight pilots will attempt. Format: MM:SS",
    "required": true,
    "default_value": "10:00",
    "validation": { "gt": 0, "lt": 3600 },
    "display_order": 1
  },
  {
    "id": "thermal-cf-002",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "fractional_seconds",
    "field_type": "int",
    "name": "Fractional Secs",
    "description": "Number of decimal places to count (0-3)",
    "required": true,
    "default_value": 0,
    "validation": { "gte": 0, "lte": 3 },
    "display_order": 2
  },
  {
    "id": "thermal-cf-003",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "points_per_second",
    "field_type": "float",
    "name": "Points Per Second",
    "description": "Raw points awarded for each second of flight time",
    "required": true,
    "default_value": 1.0,
    "validation": { "gt": 0 },
    "display_order": 3
  },
  {
    "id": "thermal-cf-004",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "landing_table",
    "field_type": "enum",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points",
    "required": true,
    "options": [
      { "value": "thermal-standard", "label": "Standard Thermal Table" }
    ],
    "display_order": 4
  }
]
```

## DisciplineScoreField

```json
[
  {
    "id": "thermal-sf-001",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "time_flown",
    "field_type": "time",
    "name": "Time Flown",
    "description": "Actual flight time (MM:SS format)",
    "required": true,
    "display_order": 1,
    "is_zero_reason": false
  },
  {
    "id": "thermal-sf-002",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded from the linked landing table (thermal-standard).",
    "required": false,
    "options": [],
    "display_order": 2,
    "is_zero_reason": false
  },
  {
    "id": "thermal-sf-003",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "out_of_bounds",
    "field_type": "bool",
    "name": "Out of Bounds",
    "description": "Pilot landed >75m from landing marker",
    "required": false,
    "default_value": false,
    "display_order": 3,
    "is_zero_reason": true,
    "zero_reason_code": "OUT_OF_BOUNDS"
  },
  {
    "id": "thermal-sf-004",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_key": "overflight_gt_one_min",
    "field_type": "bool",
    "name": "Overflight > 1 Min",
    "description": "Pilot landed more than 1 minute past target time",
    "required": false,
    "default_value": false,
    "display_order": 4,
    "is_zero_reason": true,
    "zero_reason_code": "OVERFLIGHT_GT_ONE_MIN"
  }
]
```

## DisciplineValidation

```json
[
  {
    "id": "thermal-val-001",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_keys": ["time_flown"],
    "constraint_type": "greater_than_or_equal",
    "description": "Time flown must be 0 or more",
    "applies_to": { "field": "time_flown", "value": 0 },
    "message": "Time flown must be 0 or more",
    "display_order": 1
  },
  {
    "id": "thermal-val-002",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "field_keys": ["out_of_bounds", "overflight_gt_one_min"],
    "constraint_type": "mutually_exclusive_group",
    "description": "Only one of out_of_bounds or overflight_gt_one_min can be selected",
    "message": "Select only one: Out of Bounds or Overflight > 1 Min",
    "display_order": 2
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "thermal-form-001",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
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
    "display_order": 1
  },
  {
    "id": "thermal-form-002",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
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
    "display_order": 2
  },
  {
    "id": "thermal-form-003",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
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
    "display_order": 3
  },
  {
    "id": "thermal-form-004",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
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
    "display_order": 4
  }
]
```

## DisciplineRule

```json
[
  {
    "id": "thermal-rule-001",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "rule_key": "out_of_bounds",
    "rule_type": "zero",
    "condition": "out_of_bounds == true",
    "effect": "score = 0; flight_score = 0; landing = 0; time_flown = 0",
    "applies_to": ["out_of_bounds"],
    "display_name": "Out of bounds landing",
    "description": "The pilot landed more than 75m from their landing marker.",
    "display_order": 1
  },
  {
    "id": "thermal-rule-002",
    "discipline_profile_id": "thermal-profile-v1",
    "version": 1,
    "rule_key": "overflight_gt_one_min",
    "rule_type": "zero",
    "condition": "overflight_gt_one_min == true",
    "effect": "score = 0; flight_score = 0; landing = 0; time_flown = 0",
    "applies_to": ["overflight_gt_one_min"],
    "display_name": "Overflight > 1 minute",
    "description": "The pilot did not land within 1 minute past target time.",
    "display_order": 2
  }
]
```
