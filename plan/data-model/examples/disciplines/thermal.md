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
  "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
  "owner_account_id": null,
  "name": "Thermal Standard Landing Table",
  "input_unit": "points",
  "created_at": "2026-09-15T00:00:00Z"
}
```

## LandingResult

Each entry maps the key the scorer selects to the points awarded. The landing "tape" is 100 inches long and each inch is worth one point, so a landing within an inch of the marker is 100 points and a landing more than 100 inches away is 0. The scorer selects the points directly, from 100 down to 0. A landing more than 75 m from the marker is out of bounds and scores zero through the out-of-bounds indicator, not a table entry. A score stores the entry `id`.

```json
[
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d01",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_100",
    "display_value": "100 pts",
    "point_value": 100,
    "ordinal_position": 1
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d02",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_99",
    "display_value": "99 pts",
    "point_value": 99,
    "ordinal_position": 2
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d03",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_98",
    "display_value": "98 pts",
    "point_value": 98,
    "ordinal_position": 3
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d04",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_97",
    "display_value": "97 pts",
    "point_value": 97,
    "ordinal_position": 4
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d05",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_96",
    "display_value": "96 pts",
    "point_value": 96,
    "ordinal_position": 5
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d06",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_95",
    "display_value": "95 pts",
    "point_value": 95,
    "ordinal_position": 6
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d07",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_94",
    "display_value": "94 pts",
    "point_value": 94,
    "ordinal_position": 7
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d08",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_93",
    "display_value": "93 pts",
    "point_value": 93,
    "ordinal_position": 8
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d09",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_92",
    "display_value": "92 pts",
    "point_value": 92,
    "ordinal_position": 9
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d0a",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_91",
    "display_value": "91 pts",
    "point_value": 91,
    "ordinal_position": 10
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d0b",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_90",
    "display_value": "90 pts",
    "point_value": 90,
    "ordinal_position": 11
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d0c",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_89",
    "display_value": "89 pts",
    "point_value": 89,
    "ordinal_position": 12
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d0d",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_88",
    "display_value": "88 pts",
    "point_value": 88,
    "ordinal_position": 13
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d0e",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_87",
    "display_value": "87 pts",
    "point_value": 87,
    "ordinal_position": 14
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d0f",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_86",
    "display_value": "86 pts",
    "point_value": 86,
    "ordinal_position": 15
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d10",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_85",
    "display_value": "85 pts",
    "point_value": 85,
    "ordinal_position": 16
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d11",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_84",
    "display_value": "84 pts",
    "point_value": 84,
    "ordinal_position": 17
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d12",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_83",
    "display_value": "83 pts",
    "point_value": 83,
    "ordinal_position": 18
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d13",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_82",
    "display_value": "82 pts",
    "point_value": 82,
    "ordinal_position": 19
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d14",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_81",
    "display_value": "81 pts",
    "point_value": 81,
    "ordinal_position": 20
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d15",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_80",
    "display_value": "80 pts",
    "point_value": 80,
    "ordinal_position": 21
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d16",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_79",
    "display_value": "79 pts",
    "point_value": 79,
    "ordinal_position": 22
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d17",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_78",
    "display_value": "78 pts",
    "point_value": 78,
    "ordinal_position": 23
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d18",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_77",
    "display_value": "77 pts",
    "point_value": 77,
    "ordinal_position": 24
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d19",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_76",
    "display_value": "76 pts",
    "point_value": 76,
    "ordinal_position": 25
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d1a",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_75",
    "display_value": "75 pts",
    "point_value": 75,
    "ordinal_position": 26
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d1b",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_74",
    "display_value": "74 pts",
    "point_value": 74,
    "ordinal_position": 27
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d1c",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_73",
    "display_value": "73 pts",
    "point_value": 73,
    "ordinal_position": 28
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d1d",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_72",
    "display_value": "72 pts",
    "point_value": 72,
    "ordinal_position": 29
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d1e",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_71",
    "display_value": "71 pts",
    "point_value": 71,
    "ordinal_position": 30
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d1f",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_70",
    "display_value": "70 pts",
    "point_value": 70,
    "ordinal_position": 31
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d20",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_69",
    "display_value": "69 pts",
    "point_value": 69,
    "ordinal_position": 32
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d21",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_68",
    "display_value": "68 pts",
    "point_value": 68,
    "ordinal_position": 33
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d22",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_67",
    "display_value": "67 pts",
    "point_value": 67,
    "ordinal_position": 34
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d23",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_66",
    "display_value": "66 pts",
    "point_value": 66,
    "ordinal_position": 35
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d24",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_65",
    "display_value": "65 pts",
    "point_value": 65,
    "ordinal_position": 36
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d25",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_64",
    "display_value": "64 pts",
    "point_value": 64,
    "ordinal_position": 37
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d26",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_63",
    "display_value": "63 pts",
    "point_value": 63,
    "ordinal_position": 38
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d27",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_62",
    "display_value": "62 pts",
    "point_value": 62,
    "ordinal_position": 39
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d28",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_61",
    "display_value": "61 pts",
    "point_value": 61,
    "ordinal_position": 40
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d29",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_60",
    "display_value": "60 pts",
    "point_value": 60,
    "ordinal_position": 41
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d2a",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_59",
    "display_value": "59 pts",
    "point_value": 59,
    "ordinal_position": 42
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d2b",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_58",
    "display_value": "58 pts",
    "point_value": 58,
    "ordinal_position": 43
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d2c",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_57",
    "display_value": "57 pts",
    "point_value": 57,
    "ordinal_position": 44
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d2d",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_56",
    "display_value": "56 pts",
    "point_value": 56,
    "ordinal_position": 45
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d2e",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_55",
    "display_value": "55 pts",
    "point_value": 55,
    "ordinal_position": 46
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d2f",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_54",
    "display_value": "54 pts",
    "point_value": 54,
    "ordinal_position": 47
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d30",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_53",
    "display_value": "53 pts",
    "point_value": 53,
    "ordinal_position": 48
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d31",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_52",
    "display_value": "52 pts",
    "point_value": 52,
    "ordinal_position": 49
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d32",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_51",
    "display_value": "51 pts",
    "point_value": 51,
    "ordinal_position": 50
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d33",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_50",
    "display_value": "50 pts",
    "point_value": 50,
    "ordinal_position": 51
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d34",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_49",
    "display_value": "49 pts",
    "point_value": 49,
    "ordinal_position": 52
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d35",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_48",
    "display_value": "48 pts",
    "point_value": 48,
    "ordinal_position": 53
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d36",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_47",
    "display_value": "47 pts",
    "point_value": 47,
    "ordinal_position": 54
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d37",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_46",
    "display_value": "46 pts",
    "point_value": 46,
    "ordinal_position": 55
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d38",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_45",
    "display_value": "45 pts",
    "point_value": 45,
    "ordinal_position": 56
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d39",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_44",
    "display_value": "44 pts",
    "point_value": 44,
    "ordinal_position": 57
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d3a",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_43",
    "display_value": "43 pts",
    "point_value": 43,
    "ordinal_position": 58
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d3b",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_42",
    "display_value": "42 pts",
    "point_value": 42,
    "ordinal_position": 59
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d3c",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_41",
    "display_value": "41 pts",
    "point_value": 41,
    "ordinal_position": 60
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d3d",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_40",
    "display_value": "40 pts",
    "point_value": 40,
    "ordinal_position": 61
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d3e",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_39",
    "display_value": "39 pts",
    "point_value": 39,
    "ordinal_position": 62
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d3f",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_38",
    "display_value": "38 pts",
    "point_value": 38,
    "ordinal_position": 63
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d40",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_37",
    "display_value": "37 pts",
    "point_value": 37,
    "ordinal_position": 64
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d41",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_36",
    "display_value": "36 pts",
    "point_value": 36,
    "ordinal_position": 65
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d42",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_35",
    "display_value": "35 pts",
    "point_value": 35,
    "ordinal_position": 66
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d43",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_34",
    "display_value": "34 pts",
    "point_value": 34,
    "ordinal_position": 67
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d44",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_33",
    "display_value": "33 pts",
    "point_value": 33,
    "ordinal_position": 68
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d45",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_32",
    "display_value": "32 pts",
    "point_value": 32,
    "ordinal_position": 69
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d46",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_31",
    "display_value": "31 pts",
    "point_value": 31,
    "ordinal_position": 70
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d47",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_30",
    "display_value": "30 pts",
    "point_value": 30,
    "ordinal_position": 71
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d48",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_29",
    "display_value": "29 pts",
    "point_value": 29,
    "ordinal_position": 72
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d49",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_28",
    "display_value": "28 pts",
    "point_value": 28,
    "ordinal_position": 73
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d4a",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_27",
    "display_value": "27 pts",
    "point_value": 27,
    "ordinal_position": 74
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d4b",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_26",
    "display_value": "26 pts",
    "point_value": 26,
    "ordinal_position": 75
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d4c",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_25",
    "display_value": "25 pts",
    "point_value": 25,
    "ordinal_position": 76
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d4d",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_24",
    "display_value": "24 pts",
    "point_value": 24,
    "ordinal_position": 77
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d4e",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_23",
    "display_value": "23 pts",
    "point_value": 23,
    "ordinal_position": 78
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d4f",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_22",
    "display_value": "22 pts",
    "point_value": 22,
    "ordinal_position": 79
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d50",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_21",
    "display_value": "21 pts",
    "point_value": 21,
    "ordinal_position": 80
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d51",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_20",
    "display_value": "20 pts",
    "point_value": 20,
    "ordinal_position": 81
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d52",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_19",
    "display_value": "19 pts",
    "point_value": 19,
    "ordinal_position": 82
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d53",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_18",
    "display_value": "18 pts",
    "point_value": 18,
    "ordinal_position": 83
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d54",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_17",
    "display_value": "17 pts",
    "point_value": 17,
    "ordinal_position": 84
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d55",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_16",
    "display_value": "16 pts",
    "point_value": 16,
    "ordinal_position": 85
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d56",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_15",
    "display_value": "15 pts",
    "point_value": 15,
    "ordinal_position": 86
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d57",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_14",
    "display_value": "14 pts",
    "point_value": 14,
    "ordinal_position": 87
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d58",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_13",
    "display_value": "13 pts",
    "point_value": 13,
    "ordinal_position": 88
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d59",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_12",
    "display_value": "12 pts",
    "point_value": 12,
    "ordinal_position": 89
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d5a",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_11",
    "display_value": "11 pts",
    "point_value": 11,
    "ordinal_position": 90
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d5b",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_10",
    "display_value": "10 pts",
    "point_value": 10,
    "ordinal_position": 91
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d5c",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_9",
    "display_value": "9 pts",
    "point_value": 9,
    "ordinal_position": 92
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d5d",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_8",
    "display_value": "8 pts",
    "point_value": 8,
    "ordinal_position": 93
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d5e",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_7",
    "display_value": "7 pts",
    "point_value": 7,
    "ordinal_position": 94
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d5f",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_6",
    "display_value": "6 pts",
    "point_value": 6,
    "ordinal_position": 95
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d60",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_5",
    "display_value": "5 pts",
    "point_value": 5,
    "ordinal_position": 96
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d61",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_4",
    "display_value": "4 pts",
    "point_value": 4,
    "ordinal_position": 97
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d62",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_3",
    "display_value": "3 pts",
    "point_value": 3,
    "ordinal_position": 98
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d63",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_2",
    "display_value": "2 pts",
    "point_value": 2,
    "ordinal_position": 99
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d64",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_1",
    "display_value": "1 pts",
    "point_value": 1,
    "ordinal_position": 100
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3d65",
    "landing_table_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c02",
    "entry_key": "points_0",
    "display_value": "0 pts",
    "point_value": 0,
    "ordinal_position": 101
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
    "description": "Table mapping landing quality indicators to bonus points. The contest selects a landing table, which defaults to the profile's default (Thermal Standard Landing Table).",
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
  },
  {
    "id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c18",
    "discipline_profile_id": "019a3c4b-8f2a-7b1c-9d4e-6f5a3b2c3c01",
    "field_key": "flight_penalty",
    "field_type": "int",
    "name": "Flight Penalty",
    "description": "Points deducted from the flight, entered with the score by anyone who enters it. The director's cumulative penalty is applied separately on the official score.",
    "required": false,
    "default_value": 0,
    "validation": { "gte": 0 },
    "display_order": 5,
    "is_zero_reason": false,
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
    "description": "Calculate raw score: flight score + landing bonus - entered flight penalty",
    "formula_text": "flight_score + landing_bonus - flight_penalty",
    "inputs": {
      "flight_score": "calc:flight_score",
      "landing_bonus": "lookup:landing_table(landing)",
      "flight_penalty": "score:flight_penalty"
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
