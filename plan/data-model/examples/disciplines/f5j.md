# F5J (FAI Free-Flight) Discipline Example

F5J is an FAI precision duration discipline where pilots fly to reach a specified
working time, perform a precision landing, and incur launch height penalties.

## DisciplineProfile

```json
{
  "id": "f5j-profile-v1",
  "type": "F5J",
  "version": 1,
  "name": "FAI Free-Flight (F5J)",
  "description": "Precision duration discipline with working time, mandatory launch height penalties, and precision landing bonus. Score = flight points + landing bonus - height penalty.",
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
    "id": "f5j-cf-001",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "working_time",
    "field_type": "time",
    "name": "Working Time",
    "description": "Duration the pilot must maintain flight. Format: MM:SS",
    "required": true,
    "default_value": "15:00",
    "validation": { "gt": 0, "lt": 3600 },
    "display_order": 1
  },
  {
    "id": "f5j-cf-002",
    "discipline_profile_id": "f5j-profile-v1",
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
    "id": "f5j-cf-003",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "fractional_seconds",
    "field_type": "int",
    "name": "Fractional Secs",
    "description": "Number of decimal places to count (0-3)",
    "required": true,
    "default_value": 0,
    "validation": { "gte": 0, "lte": 3 },
    "display_order": 3
  },
  {
    "id": "f5j-cf-004",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "landing_table",
    "field_type": "landing",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points. The system uses the linked LandingTable entity (f5j-standard) to score landings",
    "required": true,
    "default_value": "f5j-standard",
    "options": [],
    "display_order": 4
  },
  {
    "id": "f5j-cf-005",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "motor_restart_mode",
    "field_type": "enum",
    "name": "Motor Restart Mode",
    "description": "How motor restarts are handled",
    "required": true,
    "default_value": "allowed",
    "options": [
      { "value": "allowed", "label": "Allowed (0, droppable)" },
      { "value": "non_droppable", "label": "Allowed (0, non-droppable)" },
      { "value": "not_allowed", "label": "Not Allowed" }
    ],
    "display_order": 5
  },
  {
    "id": "f5j-cf-006",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "reference_launch_height",
    "field_type": "int",
    "name": "Reference Launch Height (m)",
    "description": "Height where penalty transitions from minor to major",
    "required": true,
    "default_value": 200,
    "validation": { "gt": 0 },
    "display_order": 6
  },
  {
    "id": "f5j-cf-007",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "minor_penalty_per_meter",
    "field_type": "float",
    "name": "Minor Penalty Per Meter",
    "description": "Penalty for altitudes at or below reference height",
    "required": true,
    "default_value": 0.5,
    "validation": { "gte": 0 },
    "display_order": 7
  },
  {
    "id": "f5j-cf-008",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "major_penalty_per_meter",
    "field_type": "float",
    "name": "Major Penalty Per Meter",
    "description": "Penalty for altitudes above reference height",
    "required": true,
    "default_value": 3.0,
    "validation": { "gte": 0 },
    "display_order": 8
  }
]
```

## DisciplineScoreField

```json
[
  {
    "id": "f5j-sf-001",
    "discipline_profile_id": "f5j-profile-v1",
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
    "id": "f5j-sf-002",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "launch_height",
    "field_type": "int",
    "name": "Launch Height (m)",
    "description": "Height achieved during free flight launch",
    "required": true,
    "display_order": 2,
    "is_zero_reason": false
  },
  {
    "id": "f5j-sf-003",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded from the linked landing table (f5j-standard).",
    "required": false,
    "options": [],
    "display_order": 3,
    "is_zero_reason": false
  },
  {
    "id": "f5j-sf-004",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "late_landing",
    "field_type": "bool",
    "name": "Late Landing",
    "description": "Pilot landed after working time expired but within 1 min",
    "required": false,
    "default_value": false,
    "display_order": 4,
    "is_zero_reason": false
  },
  {
    "id": "f5j-sf-005",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "motor_restart",
    "field_type": "bool",
    "name": "Motor Restart",
    "description": "Pilot restarted motor during flight",
    "required": false,
    "default_value": false,
    "display_order": 5,
    "is_zero_reason": true,
    "zero_reason_code": "MOTOR_RESTART"
  },
  {
    "id": "f5j-sf-006",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "out_of_bounds",
    "field_type": "bool",
    "name": "Out of Bounds",
    "description": "Pilot landed >75m from landing marker",
    "required": false,
    "default_value": false,
    "display_order": 6,
    "is_zero_reason": true,
    "zero_reason_code": "OUT_OF_BOUNDS"
  },
  {
    "id": "f5j-sf-007",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_key": "no_altitude_recorded",
    "field_type": "bool",
    "name": "No Altitude Recorded",
    "description": "Altitude device failed to record",
    "required": false,
    "default_value": false,
    "display_order": 7,
    "is_zero_reason": true,
    "zero_reason_code": "NO_ALTITUDE_RECORDED"
  }
]
```

## DisciplineValidation

```json
[
  {
    "id": "f5j-val-001",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_keys": ["time_flown"],
    "constraint_type": "less_than",
    "description": "Time flown must be less than working time",
    "applies_to": { "field": "time_flown", "compare_with": "working_time" },
    "message": "Time flown must be less than working time",
    "display_order": 1
  },
  {
    "id": "f5j-val-002",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_keys": ["launch_height"],
    "constraint_type": "greater_than",
    "description": "Launch height must be greater than 0",
    "applies_to": { "field": "launch_height", "value": 0 },
    "message": "Launch height must be greater than 0",
    "display_order": 2
  },
  {
    "id": "f5j-val-003",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_keys": ["time_flown"],
    "constraint_type": "greater_than_or_equal",
    "description": "Time flown must be 0 or more",
    "applies_to": { "field": "time_flown", "value": 0 },
    "message": "Time flown must be 0 or more",
    "display_order": 3
  },
  {
    "id": "f5j-val-004",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "field_keys": ["no_altitude_recorded", "motor_restart", "out_of_bounds"],
    "constraint_type": "mutually_exclusive_group",
    "description": "Only one of no_altitude_recorded, motor_restart, or out_of_bounds can be selected",
    "message": "Select only one: No Altitude, Motor Restart, or Out of Bounds",
    "display_order": 4
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "f5j-form-001",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "formula_key": "height_penalty",
    "formula_type": "penalty",
    "description": "Calculate the launch height penalty using reference launch height and minor/major penalty rates",
    "formula_text": "altitude <= reference_height ? altitude * minor_penalty : (reference_height * minor_penalty) + ((altitude - reference_height) * major_penalty)",
    "inputs": {
      "altitude": "score:launch_height",
      "reference_height": "config:reference_launch_height",
      "minor_penalty": "config:minor_penalty_per_meter",
      "major_penalty": "config:major_penalty_per_meter"
    },
    "outputs": { "height_penalty": "calc:height_penalty" },
    "depends_on": [],
    "display_order": 1
  },
  {
    "id": "f5j-form-002",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "formula_key": "flight_score",
    "formula_type": "intermediate",
    "description": "Calculate flight score: time flown * points per second - height penalty",
    "formula_text": "points_per_second * time_seconds - height_penalty",
    "inputs": {
      "points_per_second": "config:points_per_second",
      "time_seconds": "score:time_flown",
      "height_penalty": "calc:height_penalty"
    },
    "outputs": { "flight_score": "calc:flight_score" },
    "depends_on": ["height_penalty"],
    "display_order": 2
  },
  {
    "id": "f5j-form-003",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "formula_key": "raw_score",
    "formula_type": "intermediate",
    "description": "Calculate raw score: flight score + landing bonus (if not late landing)",
    "formula_text": "flight_score + (late_landing ? 0 : landing_bonus)",
    "inputs": {
      "flight_score": "calc:flight_score",
      "late_landing": "score:late_landing",
      "landing_bonus": "lookup:landing_table(landing)"
    },
    "outputs": { "raw_score": "calc:raw_score" },
    "depends_on": ["flight_score"],
    "display_order": 3
  },
  {
    "id": "f5j-form-004",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "formula_key": "time_normalization",
    "formula_type": "final",
    "is_primary": true,
    "description": "Normalize the scores to a max of 1000 points for the best flight in the group",
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
    "id": "f5j-rule-001",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "rule_key": "out_of_bounds",
    "rule_type": "zero",
    "condition": "out_of_bounds == true",
    "effect": "score = 0; raw_score = 0; flight_score = 0; height_penalty = 0; landing = 0",
    "applies_to": ["out_of_bounds"],
    "display_name": "Out of bounds landing",
    "description": "The pilot landed more than 75m from their landing marker (oob).",
    "display_order": 1
  },
  {
    "id": "f5j-rule-002",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "rule_key": "motor_restart",
    "rule_type": "zero",
    "condition": "motor_restart == true",
    "effect": "score = 0; raw_score = 0; flight_score = 0; height_penalty = 0; landing = 0",
    "applies_to": ["motor_restart"],
    "display_name": "Motor restart",
    "description": "The pilot restarted their model during flight.",
    "display_order": 2
  },
  {
    "id": "f5j-rule-003",
    "discipline_profile_id": "f5j-profile-v1",
    "version": 1,
    "rule_key": "no_altitude_recorded",
    "rule_type": "zero",
    "condition": "no_altitude_recorded == true",
    "effect": "score = 0; raw_score = 0; flight_score = 0; height_penalty = 0; landing = 0",
    "applies_to": ["no_altitude_recorded"],
    "display_name": "No altitude recorded",
    "description": "The pilot's altitude recorder failed to record the flight altitude.",
    "display_order": 3
  }
]
```
