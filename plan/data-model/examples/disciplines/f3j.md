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
  "default_options": { "rounding_mode": "Truncate" },
  "status": "published",
  "superseded_by": null,
  "created_by": "019a3c40-0000-7000-8000-000000000001",
  "created_at": "2026-09-15T00:00:00Z",
  "updated_by": null,
  "updated_at": null
}
```

## LandingTable

Two system tables. The first is the one the profile names as its default, where the scorer selects the points directly. The second is the common alternative, copied from the official F3J rules, where the scorer selects the distance from the landing spot. Neither has an owner and neither is ever modified.

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "owner_account_id": null,
    "name": "F3J Standard Landing Table",
    "input_unit": "points",
    "created_at": "2026-09-15T00:00:00Z"
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "owner_account_id": null,
    "name": "F3J Landing Distance Table",
    "input_unit": "meters",
    "created_at": "2026-09-15T00:00:00Z"
  }
]
```

## LandingResult

Each entry maps the key the scorer selects to the points awarded. A score stores the entry `id`.

The standard table's entries are the points the official table awards, from 100 down to 0:

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b01",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_100",
    "display_value": "100 pts",
    "point_value": 100,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b02",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_99",
    "display_value": "99 pts",
    "point_value": 99,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b03",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_98",
    "display_value": "98 pts",
    "point_value": 98,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b04",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_97",
    "display_value": "97 pts",
    "point_value": 97,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b05",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_96",
    "display_value": "96 pts",
    "point_value": 96,
    "ordinal_position": 5
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b06",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_95",
    "display_value": "95 pts",
    "point_value": 95,
    "ordinal_position": 6
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b07",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_94",
    "display_value": "94 pts",
    "point_value": 94,
    "ordinal_position": 7
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b08",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_93",
    "display_value": "93 pts",
    "point_value": 93,
    "ordinal_position": 8
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b09",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_92",
    "display_value": "92 pts",
    "point_value": 92,
    "ordinal_position": 9
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b0a",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_91",
    "display_value": "91 pts",
    "point_value": 91,
    "ordinal_position": 10
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b0b",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_90",
    "display_value": "90 pts",
    "point_value": 90,
    "ordinal_position": 11
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b0c",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_85",
    "display_value": "85 pts",
    "point_value": 85,
    "ordinal_position": 12
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b0d",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_80",
    "display_value": "80 pts",
    "point_value": 80,
    "ordinal_position": 13
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b0e",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_75",
    "display_value": "75 pts",
    "point_value": 75,
    "ordinal_position": 14
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b0f",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_70",
    "display_value": "70 pts",
    "point_value": 70,
    "ordinal_position": 15
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b10",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_65",
    "display_value": "65 pts",
    "point_value": 65,
    "ordinal_position": 16
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b11",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_60",
    "display_value": "60 pts",
    "point_value": 60,
    "ordinal_position": 17
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b12",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_55",
    "display_value": "55 pts",
    "point_value": 55,
    "ordinal_position": 18
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b13",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_50",
    "display_value": "50 pts",
    "point_value": 50,
    "ordinal_position": 19
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b14",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_45",
    "display_value": "45 pts",
    "point_value": 45,
    "ordinal_position": 20
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b15",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_40",
    "display_value": "40 pts",
    "point_value": 40,
    "ordinal_position": 21
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b16",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_35",
    "display_value": "35 pts",
    "point_value": 35,
    "ordinal_position": 22
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b17",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_30",
    "display_value": "30 pts",
    "point_value": 30,
    "ordinal_position": 23
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1b18",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a02",
    "entry_key": "points_0",
    "display_value": "0 pts",
    "point_value": 0,
    "ordinal_position": 24
  }
]
```

The distance table's entries are the official table, where each entry is the distance from the spot up to which the points are awarded: 0.2 m up to 2 m in steps of 0.2 m is 100 down to 91, 3 m is 90, then 4 m to 15 m in steps of 1 m is 85 down to 30 in fives. Farther than 15 m is 0.

```json
[
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d01",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_0_2m",
    "display_value": "0.2m",
    "point_value": 100,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d02",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_0_4m",
    "display_value": "0.4m",
    "point_value": 99,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d03",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_0_6m",
    "display_value": "0.6m",
    "point_value": 98,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d04",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_0_8m",
    "display_value": "0.8m",
    "point_value": 97,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d05",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_1m",
    "display_value": "1m",
    "point_value": 96,
    "ordinal_position": 5
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d06",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_1_2m",
    "display_value": "1.2m",
    "point_value": 95,
    "ordinal_position": 6
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d07",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_1_4m",
    "display_value": "1.4m",
    "point_value": 94,
    "ordinal_position": 7
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d08",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_1_6m",
    "display_value": "1.6m",
    "point_value": 93,
    "ordinal_position": 8
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d09",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_1_8m",
    "display_value": "1.8m",
    "point_value": 92,
    "ordinal_position": 9
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d0a",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_2m",
    "display_value": "2m",
    "point_value": 91,
    "ordinal_position": 10
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d0b",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_3m",
    "display_value": "3m",
    "point_value": 90,
    "ordinal_position": 11
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d0c",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_4m",
    "display_value": "4m",
    "point_value": 85,
    "ordinal_position": 12
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d0d",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_5m",
    "display_value": "5m",
    "point_value": 80,
    "ordinal_position": 13
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d0e",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_6m",
    "display_value": "6m",
    "point_value": 75,
    "ordinal_position": 14
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d0f",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_7m",
    "display_value": "7m",
    "point_value": 70,
    "ordinal_position": 15
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d10",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_8m",
    "display_value": "8m",
    "point_value": 65,
    "ordinal_position": 16
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d11",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_9m",
    "display_value": "9m",
    "point_value": 60,
    "ordinal_position": 17
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d12",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_10m",
    "display_value": "10m",
    "point_value": 55,
    "ordinal_position": 18
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d13",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_11m",
    "display_value": "11m",
    "point_value": 50,
    "ordinal_position": 19
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d14",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_12m",
    "display_value": "12m",
    "point_value": 45,
    "ordinal_position": 20
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d15",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_13m",
    "display_value": "13m",
    "point_value": 40,
    "ordinal_position": 21
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d16",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_14m",
    "display_value": "14m",
    "point_value": 35,
    "ordinal_position": 22
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d17",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "within_15m",
    "display_value": "15m",
    "point_value": 30,
    "ordinal_position": 23
  },
  {
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1d18",
    "landing_table_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1c00",
    "entry_key": "over_15m",
    "display_value": "Over 15m",
    "point_value": 0,
    "ordinal_position": 24
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
    "id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a0f",
    "discipline_profile_id": "019a3c4f-8f2a-7b1c-9d4e-6f5a3b2c1a01",
    "field_key": "fractional_seconds",
    "field_type": "int",
    "name": "Fractional Secs",
    "description": "Number of decimal places to count (0-3)",
    "required": true,
    "default_value": 1,
    "validation": { "gte": 0, "lte": 3 },
    "display_order": 2,
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
    "display_order": 3,
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
    "display_order": 4,
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
