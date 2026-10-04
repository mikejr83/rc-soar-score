# Contest and Configuration

Entity specifications: [Contest](../../entities/contest.md), [ContestConfigurationRevision](../../entities/contest_configuration_revision.md), [ContestConfigurationPreset](../../entities/contest_configuration_preset.md). Every setting in `config` is defined in [contest-options.md](../../contest-options.md).

## Contest

```json
{
  "id": "019c0000-0000-7000-8000-000000000010",
  "name": "Front Range ALES Open",
  "start_date_time": "2026-10-17T14:00:00Z",
  "end_date_time": "2026-10-18T22:00:00Z",
  "timezone": "America/Denver",
  "host": "Front Range Soaring Society",
  "city": "Boulder",
  "state": "CO",
  "country": "USA",
  "owner_account_id": "019c0000-0000-7000-8000-000000000001",
  "lifecycle_state": "Running",
  "scoring_access": "Open",
  "admin_lock": "Unlocked",
  "results_hidden_through_round": null,
  "results_hidden_at": null,
  "local_archive": false,
  "created_at": "2026-09-01T18:00:00Z",
  "updated_at": "2026-10-17T15:10:00Z",
  "revision": 7
}
```

## ContestConfigurationRevision

```json
{
  "id": "019c0000-0000-7000-8000-000000000070",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "revision_number": 2,
  "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "source_preset_id": "019c0000-0000-7000-8000-000000000071",
  "config": {
    "core": {
      "teams_enabled": true,
      "team_pilot_count": 2,
      "team_protection": true,
      "roles_enabled": true,
      "draw_mode": "StandardManOnMan",
      "lane_mode": "None",
      "group_score_mode": "Time",
      "rounding_mode": "Round",
      "decimal_places": 1,
      "drop_after_rounds": [4],
      "tiebreaker_enabled": false,
      "classes_enabled": true,
      "models_enabled": true,
      "participant_numbers_enabled": true,
      "review_requests_enabled": true,
      "public_update_mode": "RoundCompletion"
    },
    "discipline": {
      "target_time": 600,
      "points_per_second": 1.0
    }
  },
  "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
  "created_by": "019c0000-0000-7000-8000-000000000001",
  "notes": "Turned on team protection before the draw",
  "created_at": "2026-10-10T19:30:00Z"
}
```

## ContestConfigurationPreset

```json
{
  "id": "019c0000-0000-7000-8000-000000000071",
  "owner_account_id": "019c0000-0000-7000-8000-000000000001",
  "discipline_profile_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d01",
  "name": "Club ALES, team format",
  "description": "Our usual two-day ALES contest with teams and one drop",
  "config": {
    "core": {
      "teams_enabled": true,
      "team_pilot_count": 2,
      "team_protection": false,
      "roles_enabled": true,
      "draw_mode": "StandardManOnMan",
      "lane_mode": "None",
      "group_score_mode": "Time",
      "rounding_mode": "Round",
      "decimal_places": 1,
      "drop_after_rounds": [4]
    },
    "discipline": {
      "target_time": 600,
      "points_per_second": 1.0
    }
  },
  "landing_table_id": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d02",
  "created_at": "2026-08-15T17:00:00Z",
  "updated_at": "2026-09-01T18:00:00Z",
  "revision": 2
}
```
