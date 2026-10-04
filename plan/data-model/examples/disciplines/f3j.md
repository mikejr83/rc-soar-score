# F3J (FAI Thermal Duration) Discipline Example

F3J is an FAI thermal duration discipline where pilots fly the longest time within
a working time window and perform a precision landing. The score includes working
time points plus landing bonus minus overflight penalties.

## DisciplineProfile

```json
{
  "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
  "type": "F3J",
  "version": 1,
  "name": "FAI Thermal Duration (F3J)",
  "description": "Thermal duration discipline with working time window, precision landing bonus, and 30-point penalties for late landings. Score = flight points + landing bonus - penalties.",
  "category": "duration",
  "default_landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
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
  "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
  "owner_account_id": null,
  "name": "F3J Standard Landing Table",
  "input_unit": "meters",
  "created_at": "2026-09-15T00:00:00Z"
}
```

## LandingResult

Each entry maps the key the scorer selects to the points awarded. A score stores the entry `id`.

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a03",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "within_10m",
    "display_value": "Within 10 m",
    "point_value": 20,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a04",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "within_25m",
    "display_value": "Within 25 m",
    "point_value": 15,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a05",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "within_50m",
    "display_value": "Within 50 m",
    "point_value": 10,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a06",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "within_75m",
    "display_value": "Within 75 m",
    "point_value": 5,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a07",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
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
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a08",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "field_key": "working_time",
    "field_type": "int",
    "name": "Working Time",
    "description": "Duration of the working time window, in seconds",
    "required": true,
    "default_value": 600,
    "validation": { "gt": 0, "lt": 3600 },
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a09",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
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
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a0a",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "field_key": "landing_table",
    "field_type": "landing",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points. The contest selects a landing table, which defaults to the profile's default (F3J Standard Landing Table).",
    "required": true,
    "display_order": 3,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineScoreField

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a0b",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
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
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a0c",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded dynamically from the linked landing table (F3J Standard Landing Table).",
    "required": false,
    "display_order": 2,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a0d",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "field_key": "late_landing",
    "field_type": "bool",
    "name": "Late Landing",
    "description": "Pilot landed after working time expired",
    "required": false,
    "default_value": false,
    "display_order": 3,
    "is_zero_reason": false,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a0e",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
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
  }
]
```

## DisciplineValidation

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a10",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
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
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a12",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "formula_key": "flight_score",
    "formula_type": "intermediate",
    "description": "Calculate flight score: time * PPS",
    "formula_text": "points_per_second * time_seconds",
    "inputs": {
      "points_per_second": "config:points_per_second",
      "time_seconds": "score:time_flown"
    },
    "outputs": { "flight_score": "calc:flight_score" },
    "depends_on": [],
    "is_primary": false,
    "display_order": 1,
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a13",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "formula_key": "raw_score",
    "formula_type": "final",
    "is_primary": true,
    "description": "Calculate raw score: flight score + landing bonus (if not late)",
    "formula_text": "flight_score + (late_landing ? 0 : landing_bonus)",
    "inputs": {
      "flight_score": "calc:flight_score",
      "late_landing": "score:late_landing",
      "landing_bonus": "lookup:landing_table(landing)"
    },
    "outputs": { "raw_score": "final:raw_score" },
    "depends_on": ["flight_score"],
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## DisciplineRule

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a15",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
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
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a16",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "rule_key": "late_landing_penalty",
    "rule_type": "penalty",
    "condition": "late_landing == true",
    "effect": "score = score - 30; landing_bonus = 0",
    "applies_to": ["late_landing"],
    "depends_on": [],
    "display_name": "Late landing penalty",
    "description": "Pilot landed after working time expired (30 point penalty, no landing bonus).",
    "auto_score_zero": false,
    "affects_other_fields": ["landing"],
    "display_order": 2,
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```
