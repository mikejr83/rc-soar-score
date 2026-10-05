# F5J (FAI Free-Flight) Discipline Example

F5J is an FAI precision duration discipline where pilots fly to reach a specified
working time, perform a precision landing, and incur launch height penalties.

## DisciplineProfile

```json
{
  "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
  "type": "F5J",
  "version": 1,
  "name": "FAI Free-Flight (F5J)",
  "description": "Precision duration discipline with working time, mandatory launch height penalties, and precision landing bonus. Score = flight points + landing bonus - height penalty.",
  "category": "duration",
  "default_landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
  "status": "published",
  "superseded_by": null,
  "created_by": "019a3c40-0000-7000-8000-000000000001",
  "created_at": "2026-09-15T00:00:00Z",
  "updated_by": null,
  "updated_at": null
}
```

## LandingTable

Two system tables. The first is the one the profile names as its default, where the scorer selects the points directly. The second is the common alternative, where the scorer selects a distance from the landing marker. Neither has an owner and neither is ever modified.

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "owner_account_id": null,
    "name": "F5J Standard Landing Table",
    "input_unit": "points",
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "owner_account_id": null,
    "name": "F5J Landing Distance Table",
    "input_unit": "meters",
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## LandingResult

Each entry maps the key the scorer selects to the points awarded. A score stores the entry `id`. Entries of the default table, then of the distance table.

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d01",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_50",
    "display_value": "50 pts",
    "point_value": 50,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d02",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_45",
    "display_value": "45 pts",
    "point_value": 45,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d03",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_40",
    "display_value": "40 pts",
    "point_value": 40,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d04",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_35",
    "display_value": "35 pts",
    "point_value": 35,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d05",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_30",
    "display_value": "30 pts",
    "point_value": 30,
    "ordinal_position": 5
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d06",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_25",
    "display_value": "25 pts",
    "point_value": 25,
    "ordinal_position": 6
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d07",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_20",
    "display_value": "20 pts",
    "point_value": 20,
    "ordinal_position": 7
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d08",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_15",
    "display_value": "15 pts",
    "point_value": 15,
    "ordinal_position": 8
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d09",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_10",
    "display_value": "10 pts",
    "point_value": 10,
    "ordinal_position": 9
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d0a",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_5",
    "display_value": "5 pts",
    "point_value": 5,
    "ordinal_position": 10
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2d0b",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02",
    "entry_key": "points_0",
    "display_value": "0 pts",
    "point_value": 0,
    "ordinal_position": 11
  }
]
```

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e01",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_1m",
    "display_value": "1m",
    "point_value": 50,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e02",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_2m",
    "display_value": "2m",
    "point_value": 45,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e03",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_3m",
    "display_value": "3m",
    "point_value": 40,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e04",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_4m",
    "display_value": "4m",
    "point_value": 35,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e05",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_5m",
    "display_value": "5m",
    "point_value": 30,
    "ordinal_position": 5
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e06",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_6m",
    "display_value": "6m",
    "point_value": 25,
    "ordinal_position": 6
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e07",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_7m",
    "display_value": "7m",
    "point_value": 20,
    "ordinal_position": 7
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e08",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_8m",
    "display_value": "8m",
    "point_value": 15,
    "ordinal_position": 8
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e09",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_9m",
    "display_value": "9m",
    "point_value": 10,
    "ordinal_position": 9
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e0a",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "within_10m",
    "display_value": "10m",
    "point_value": 5,
    "ordinal_position": 10
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2e0b",
    "landing_table_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2c00",
    "entry_key": "over_10m",
    "display_value": "Over 10m",
    "point_value": 0,
    "ordinal_position": 11
  }
]
```

## DisciplineConfigField

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b08",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "working_time",
    "field_type": "int",
    "name": "Working Time",
    "description": "Duration the pilot must maintain flight, in seconds",
    "required": true,
    "default_value": 600,
    "validation": { "gt": 0, "lt": 3600 },
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b09",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "points_per_second",
    "field_type": "float",
    "name": "Points Per Second",
    "description": "Raw points awarded for each second of flight time",
    "required": true,
    "default_value": 1.0,
    "validation": { "gt": 0 },
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b0a",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "fractional_seconds",
    "field_type": "int",
    "name": "Fractional Secs",
    "description": "Number of decimal places to count (0-3)",
    "required": true,
    "default_value": 0,
    "validation": { "gte": 0, "lte": 3 },
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b0b",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "landing_table",
    "field_type": "landing",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points. The contest selects a landing table, which defaults to the profile's default (F5J Standard Landing Table).",
    "required": true,
    "display_order": 4,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b0c",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
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
    "display_order": 5,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b0d",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "reference_launch_height",
    "field_type": "int",
    "name": "Reference Launch Height (m)",
    "description": "Height where penalty transitions from minor to major",
    "required": true,
    "default_value": 200,
    "validation": { "gt": 0 },
    "display_order": 6,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b0e",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "minor_penalty_per_meter",
    "field_type": "float",
    "name": "Minor Penalty Per Meter",
    "description": "Penalty for altitudes at or below reference height",
    "required": true,
    "default_value": 0.5,
    "validation": { "gte": 0 },
    "display_order": 7,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b0f",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "major_penalty_per_meter",
    "field_type": "float",
    "name": "Major Penalty Per Meter",
    "description": "Penalty for altitudes above reference height",
    "required": true,
    "default_value": 3.0,
    "validation": { "gte": 0 },
    "display_order": 8,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineScoreField

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b10",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
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
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b11",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "launch_height",
    "field_type": "int",
    "name": "Launch Height (m)",
    "description": "Height achieved during free flight launch",
    "required": true,
    "display_order": 2,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b12",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded dynamically from the linked landing table (F5J Standard Landing Table).",
    "required": false,
    "display_order": 3,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b13",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "late_landing",
    "field_type": "bool",
    "name": "Late Landing",
    "description": "Pilot landed after working time expired but within 1 min",
    "required": false,
    "default_value": false,
    "display_order": 4,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b14",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "motor_restart",
    "field_type": "bool",
    "name": "Motor Restart",
    "description": "Pilot restarted motor during flight",
    "required": false,
    "default_value": false,
    "display_order": 5,
    "is_zero_reason": true,
    "zero_reason_code": "motor_restart",
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b15",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "out_of_bounds",
    "field_type": "bool",
    "name": "Out of Bounds",
    "description": "Pilot landed >75m from landing marker",
    "required": false,
    "default_value": false,
    "display_order": 6,
    "is_zero_reason": true,
    "zero_reason_code": "out_of_bounds",
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b16",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_key": "no_altitude_recorded",
    "field_type": "bool",
    "name": "No Altitude Recorded",
    "description": "Altitude device failed to record",
    "required": false,
    "default_value": false,
    "display_order": 7,
    "is_zero_reason": true,
    "zero_reason_code": "no_altitude_recorded",
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineValidation

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b20",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_keys": ["time_flown", "late_landing"],
    "constraint_type": "required_if",
    "description": "Late Landing must be marked when time flown exceeds working time",
    "applies_to": {
      "field": "time_flown",
      "op": "gt",
      "value": "working_time"
    },
    "message": "Late Landing can only be omitted when Time Flown is at or under Working Time",
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b21",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_keys": ["launch_height", "no_altitude_recorded"],
    "constraint_type": "required_if",
    "description": "A valid Launch Height is required when No Altitude Recorded is not selected",
    "applies_to": { "field": "launch_height", "op": "gt", "value": 0 },
    "message": "Launch Height must be greater than 0 unless No Altitude Recorded is selected",
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b22",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "field_keys": ["no_altitude_recorded", "motor_restart", "out_of_bounds"],
    "constraint_type": "mutually_exclusive",
    "description": "Only one of no_altitude_recorded, motor_restart, or out_of_bounds can be selected",
    "message": "Select only one: No Altitude, Motor Restart, or Out of Bounds",
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b24",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
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
    "is_primary": false,
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b25",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
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
    "is_primary": false,
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b26",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
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
    "is_primary": false,
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b27",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
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
    "display_order": 4,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineRule

```json
[
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b30",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "rule_key": "out_of_bounds",
    "rule_type": "zero",
    "condition": "out_of_bounds == true",
    "effect": "score = 0",
    "applies_to": ["out_of_bounds"],
    "depends_on": [],
    "display_name": "Out of bounds landing",
    "description": "The pilot landed more than 75m from their landing marker (oob).",
    "auto_score_zero": true,
    "affects_other_fields": ["time_flown", "landing"],
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b31",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "rule_key": "motor_restart",
    "rule_type": "zero",
    "condition": "motor_restart == true",
    "effect": "score = 0",
    "applies_to": ["motor_restart"],
    "depends_on": [],
    "display_name": "Motor restart",
    "description": "The pilot restarted their model during flight.",
    "auto_score_zero": true,
    "affects_other_fields": ["time_flown", "landing"],
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b32",
    "discipline_profile_id": "019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01",
    "rule_key": "no_altitude_recorded",
    "rule_type": "zero",
    "condition": "no_altitude_recorded == true",
    "effect": "score = 0",
    "applies_to": ["no_altitude_recorded"],
    "depends_on": [],
    "display_name": "No altitude recorded",
    "description": "The pilot's altitude recorder failed to record the flight altitude.",
    "auto_score_zero": true,
    "affects_other_fields": ["time_flown", "landing", "launch_height"],
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```
