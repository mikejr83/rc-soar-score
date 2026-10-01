# ALES (Altitude Limited Electronic Soaring) Discipline Example

ALES is a duration task where pilots fly a prescribed time and perform a precision
landing. Group scoring defaults to "Time" (flight time normalized, then landing
bonus added).

## DisciplineProfile

```json
{
  "id": "ales-profile-v1",
  "type": "ALES",
  "version": 1,
  "name": "Altitude Limited Electronic Soaring (ALES)",
  "description": "Duration task with prescribed target time and precision landing. Flight time normalized to 1000, then landing bonus added. Default group scoring: Time.",
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
    "id": "ales-cf-001",
    "discipline_profile_id": "ales-profile-v1",
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
    "id": "ales-cf-002",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_key": "points_per_second",
    "field_type": "float",
    "name": "Points Per Second",
    "description": "Raw points awarded for each second of flight time",
    "required": true,
    "default_value": 1.0,
    "validation": { "gt": 0 },
    "display_order": 2
  },
  {
    "id": "ales-cf-003",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_key": "landing_table",
    "field_type": "landing",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points. The system uses the linked LandingTable entity (ales-standard) to score landings.",
    "required": true,
    "default_value": "ales-standard",
    "options": [],
    "display_order": 3
  }
]
```

## DisciplineScoreField

```json
[
  {
    "id": "ales-sf-001",
    "discipline_profile_id": "ales-profile-v1",
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
    "id": "ales-sf-002",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded from the linked landing table (ales-standard).",
    "required": false,
    "options": [],
    "display_order": 2,
    "is_zero_reason": false
  },
  {
    "id": "ales-sf-003",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_key": "motor_restart",
    "field_type": "bool",
    "name": "Motor Restart",
    "description": "Pilot restarted motor during flight",
    "required": false,
    "default_value": false,
    "display_order": 3,
    "is_zero_reason": true,
    "zero_reason_code": "MOTOR_RESTART"
  },
  {
    "id": "ales-sf-004",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_key": "out_of_bounds",
    "field_type": "bool",
    "name": "Out of Bounds",
    "description": "Pilot landed >75m from landing marker",
    "required": false,
    "default_value": false,
    "display_order": 4,
    "is_zero_reason": true,
    "zero_reason_code": "OUT_OF_BOUNDS"
  },
  {
    "id": "ales-sf-005",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_key": "overflight_gt_one_min",
    "field_type": "bool",
    "name": "Overflight > 1 Min",
    "description": "Pilot landed more than 1 minute past target time",
    "required": false,
    "default_value": false,
    "display_order": 5,
    "is_zero_reason": true,
    "zero_reason_code": "OVERFLIGHT_GT_ONE_MIN"
  }
]
```

## DisciplineValidation

```json
[
  {
    "id": "ales-val-001",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_keys": ["time_flown"],
    "constraint_type": "greater_than_or_equal",
    "description": "Time flown must be 0 or more",
    "applies_to": { "field": "time_flown", "value": 0 },
    "message": "Time flown must be 0 or more",
    "display_order": 1
  },
  {
    "id": "ales-val-002",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "field_keys": ["motor_restart", "out_of_bounds", "overflight_gt_one_min"],
    "constraint_type": "mutually_exclusive_group",
    "description": "Only one of motor_restart, out_of_bounds, or overflight_gt_one_min can be selected",
    "message": "Select only one: Motor Restart, Out of Bounds, or Overflight > 1 Min",
    "display_order": 2
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "ales-form-001",
    "discipline_profile_id": "ales-profile-v1",
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
    "id": "ales-form-002",
    "discipline_profile_id": "ales-profile-v1",
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
    "id": "ales-form-003",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
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
    "display_order": 3
  }
]
```

## DisciplineRule

```json
[
  {
    "id": "ales-rule-001",
    "discipline_profile_id": "ales-profile-v1",
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
    "id": "ales-rule-002",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "rule_key": "motor_restart",
    "rule_type": "zero",
    "condition": "motor_restart == true",
    "effect": "score = 0; flight_score = 0; landing = 0; time_flown = 0",
    "applies_to": ["motor_restart"],
    "display_name": "Motor restart",
    "description": "The pilot restarted the motor during flight.",
    "display_order": 2
  },
  {
    "id": "ales-rule-003",
    "discipline_profile_id": "ales-profile-v1",
    "version": 1,
    "rule_key": "overflight_gt_one_min",
    "rule_type": "zero",
    "condition": "overflight_gt_one_min == true",
    "effect": "score = 0; flight_score = 0; landing = 0; time_flown = 0",
    "applies_to": ["overflight_gt_one_min"],
    "display_name": "Overflight > 1 minute",
    "description": "The pilot did not land within 1 minute past target time.",
    "display_order": 3
  }
]
```
