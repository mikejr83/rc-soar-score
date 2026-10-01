# F3J (FAI Thermal Duration) Discipline Example

F3J is an FAI thermal duration discipline where pilots fly the longest time within
a working time window and perform a precision landing. The score includes working
time points plus landing bonus minus overflight penalties.

## DisciplineProfile

```json
{
  "id": "f3j-profile-v1",
  "type": "F3J",
  "version": 1,
  "name": "FAI Thermal Duration (F3J)",
  "description": "Thermal duration discipline with working time window, precision landing bonus, and 30-point penalties for late landings. Score = flight points + landing bonus - penalties.",
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
    "id": "f3j-cf-001",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
    "field_key": "working_time",
    "field_type": "time",
    "name": "Working Time",
    "description": "Duration of the working time window. Format: MM:SS",
    "required": true,
    "default_value": "10:00",
    "validation": { "gt": 0, "lt": 3600 },
    "display_order": 1
  },
  {
    "id": "f3j-cf-002",
    "discipline_profile_id": "f3j-profile-v1",
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
    "id": "f3j-cf-003",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
    "field_key": "landing_table",
    "field_type": "landing",
    "name": "Landing Bonus Table",
    "description": "Table mapping landing quality indicators to bonus points. The system uses the linked LandingTable entity (f3j-standard) to score landings.",
    "required": true,
    "default_value": "f3j-standard",
    "options": [],
    "display_order": 3
  }
]
```

## DisciplineScoreField

```json
[
  {
    "id": "f3j-sf-001",
    "discipline_profile_id": "f3j-profile-v1",
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
    "id": "f3j-sf-002",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
    "field_key": "landing",
    "field_type": "landing",
    "name": "Landing",
    "description": "Landing position/quality indicator. Options are loaded from the linked landing table (f3j-standard).",
    "required": false,
    "options": [],
    "display_order": 2,
    "is_zero_reason": false
  },
  {
    "id": "f3j-sf-003",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
    "field_key": "late_landing",
    "field_type": "bool",
    "name": "Late Landing",
    "description": "Pilot landed after working time expired",
    "required": false,
    "default_value": false,
    "display_order": 3,
    "is_zero_reason": false
  },
  {
    "id": "f3j-sf-004",
    "discipline_profile_id": "f3j-profile-v1",
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
  }
]
```

## DisciplineValidation

```json
[
  {
    "id": "f3j-val-001",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
    "field_keys": ["time_flown"],
    "constraint_type": "less_than_or_equal",
    "description": "Time flown must be at or under working time",
    "applies_to": { "field": "time_flown", "compare_with": "working_time" },
    "message": "Time flown must be at or under working time",
    "display_order": 1
  },
  {
    "id": "f3j-val-002",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
    "field_keys": ["time_flown"],
    "constraint_type": "not_equal",
    "description": "Time flown must not equal working time exactly",
    "applies_to": { "field": "time_flown", "compare_with": "working_time" },
    "message": "Time flown cannot equal working time exactly",
    "display_order": 2
  }
]
```

## DisciplineFormula

```json
[
  {
    "id": "f3j-form-001",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
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
    "display_order": 1
  },
  {
    "id": "f3j-form-002",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
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
    "display_order": 2
  }
]
```

## DisciplineRule

```json
[
  {
    "id": "f3j-rule-001",
    "discipline_profile_id": "f3j-profile-v1",
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
    "id": "f3j-rule-002",
    "discipline_profile_id": "f3j-profile-v1",
    "version": 1,
    "rule_key": "late_landing_penalty",
    "rule_type": "penalty",
    "condition": "late_landing == true",
    "effect": "score = score - 30; landing = 0",
    "applies_to": ["late_landing"],
    "display_name": "Late landing penalty",
    "description": "Pilot landed after working time expired (30 point penalty, no landing bonus).",
    "display_order": 2
  }
]
```
