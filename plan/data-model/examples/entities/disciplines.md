# Disciplines and Landing Tables

Entity specifications: [DisciplineProfile](../../entities/discipline_profile.md), [DisciplineConfigField](../../entities/discipline_configfield.md), [DisciplineScoreField](../../entities/discipline_scorefield.md), [DisciplineValidation](../../entities/discipline_validation.md), [DisciplineFormula](../../entities/discipline_formula.md), [DisciplineRule](../../entities/discipline_rule.md), [LandingTable](../../entities/landing_table.md), [LandingResult](../../entities/landing_result.md).

One row of each is shown, taken from the ALES profile. The complete sets for ALES, F3J, F5J, and Thermal Duration are in [examples/disciplines](../disciplines/).

## DisciplineProfile

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "type": "ALES",
  "version": 1,
  "name": "Altitude Limited Electronic Soaring (ALES)",
  "description": "Duration task with prescribed target time and precision landing.",
  "category": "duration",
  "default_landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
  "default_options": { "group_score_mode": "Time" },
  "status": "published",
  "superseded_by": null,
  "created_by": "019c0000-0000-7000-8000-000000000003",
  "created_at": "2026-09-15T00:00:00Z",
  "updated_by": null,
  "updated_at": null
}
```

## DisciplineConfigField

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d08",
  "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "field_key": "target_time",
  "field_type": "int",
  "name": "Target Time",
  "description": "Duration of the flight pilots will attempt, in seconds",
  "unit": "seconds",
  "required": true,
  "default_value": 600,
  "options": null,
  "validation": { "gt": 0, "lt": 3600 },
  "display_order": 1,
  "created_at": "2026-09-15T00:00:00Z"
}
```

## DisciplineScoreField

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d0b",
  "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "field_key": "time_flown",
  "field_type": "time",
  "name": "Time Flown",
  "description": "Actual flight time",
  "field_kind": "input",
  "unit": "seconds",
  "precision": 0,
  "required": true,
  "default_value": null,
  "options": null,
  "validation": { "gte": 0 },
  "display_order": 1,
  "is_zero_reason": false,
  "zero_reason_code": null,
  "created_at": "2026-09-15T00:00:00Z"
}
```

## DisciplineValidation

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d11",
  "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "field_keys": ["motor_restart", "out_of_bounds", "overflight_gt_one_min"],
  "constraint_type": "mutually_exclusive",
  "description": "Only one of the zero reasons can be selected",
  "applies_to": null,
  "message": "Select only one: Motor Restart, Out of Bounds, or Overflight > 1 Min",
  "display_order": 2,
  "created_at": "2026-09-15T00:00:00Z"
}
```

## DisciplineFormula

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d13",
  "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "formula_key": "flight_score",
  "formula_type": "intermediate",
  "description": "Flight score: max(0, time * PPS - overflight penalty)",
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
}
```

## DisciplineRule

```json
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
}
```

## LandingTable

A system table has a null `owner_account_id`.

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
  "owner_account_id": null,
  "name": "ALES Standard Landing Table",
  "input_unit": "meters",
  "created_at": "2026-09-15T00:00:00Z"
}
```

## LandingResult

A score stores this entry's `id`, which fixes the key, the points, and the table.

```json
{
  "id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d04",
  "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
  "entry_key": "within_25m",
  "display_value": "Within 25 m",
  "point_value": 15,
  "ordinal_position": 2
}
```
