# Publication

Entity specifications: [PublicationIdentity](../../entities/publication_identity.md), [PublicationProjection](../../entities/publication_projection.md), [PublicationParticipant](../../entities/publication_participant.md), [DelistRequest](../../entities/delist_request.md).

The publication shows the contest after round 1, as published at the end of the round.

## PublicationIdentity

```json
{
  "id": "019c0000-0000-7000-8000-0000000000b0",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "owner_public_profile_id": "019c0000-0000-7000-8000-000000000005",
  "claim_status": "Claimed",
  "verification_email": null,
  "visibility": "Public",
  "published_at": "2026-10-17T16:00:00Z",
  "current_projection_id": "019c0000-0000-7000-8000-0000000000b1",
  "results_hidden_through_round": null,
  "results_hidden_at": null,
  "revision": 4
}
```

## PublicationProjection

The JSON sections are frozen copies. Pilots appear only as `pilot_key`, and identifying details live in PublicationParticipant.

```json
{
  "id": "019c0000-0000-7000-8000-0000000000b1",
  "publication_id": "019c0000-0000-7000-8000-0000000000b0",
  "projection_revision": 2,
  "contest_revision": 7,
  "config_revision": 2,
  "matrix_revision": 1,
  "discipline_type": "ALES",
  "discipline_rules_version": 1,
  "calculation_version": "1.0.0",
  "contest_identity": {
    "name": "Front Range ALES Open",
    "start_date_time": "2026-10-17T14:00:00Z",
    "end_date_time": "2026-10-18T22:00:00Z",
    "timezone": "America/Denver",
    "host": "Front Range Soaring Society",
    "city": "Boulder",
    "state": "CO",
    "country": "USA",
    "discipline_name": "ALES"
  },
  "participants": [
    {
      "pilot_key": "p_7Hq2xK",
      "classification": "Expert",
      "participant_number": 1,
      "team_key": "t_3Nw9bD"
    },
    {
      "pilot_key": "p_Bd4Wm9",
      "classification": "Expert",
      "participant_number": 2,
      "team_key": "t_3Nw9bD"
    },
    {
      "pilot_key": "p_Kc8Zt2",
      "classification": "Sportsman",
      "participant_number": 4,
      "team_key": "t_9Lq4vP"
    },
    {
      "pilot_key": "p_Fs5Ny3",
      "classification": "Expert",
      "participant_number": 5,
      "team_key": "t_9Lq4vP"
    },
    {
      "pilot_key": "p_Xe6Ra1",
      "classification": "Sportsman",
      "participant_number": 6,
      "team_key": null
    }
  ],
  "teams": [
    {
      "team_key": "t_3Nw9bD",
      "name": "Boulder Thermals",
      "pilot_keys": ["p_7Hq2xK", "p_Bd4Wm9"]
    },
    {
      "team_key": "t_9Lq4vP",
      "name": "Longmont Lofters",
      "pilot_keys": ["p_Kc8Zt2", "p_Fs5Ny3"]
    }
  ],
  "matrix_info": {
    "rounds": [
      {
        "ordinal": 1,
        "groups": [
          {
            "group": 1,
            "pilot_keys": ["p_7Hq2xK", "p_Kc8Zt2", "p_Xe6Ra1"]
          },
          {
            "group": 2,
            "pilot_keys": ["p_Bd4Wm9", "p_Fs5Ny3"]
          }
        ]
      },
      {
        "ordinal": 2,
        "groups": [
          {
            "group": 1,
            "pilot_keys": ["p_Bd4Wm9", "p_Fs5Ny3", "p_Xe6Ra1"]
          },
          {
            "group": 2,
            "pilot_keys": ["p_7Hq2xK", "p_Kc8Zt2"]
          },
          {
            "group": 3,
            "reflight": true,
            "pilot_keys": ["p_7Hq2xK", "p_Kc8Zt2", "p_Xe6Ra1"]
          }
        ]
      }
    ]
  },
  "scores": [
    {
      "pilot_key": "p_7Hq2xK",
      "round": 1,
      "group_score": 1040.0,
      "time_flown": 585,
      "landing_points": 40
    },
    {
      "pilot_key": "p_Kc8Zt2",
      "round": 1,
      "group_score": 1024.4,
      "time_flown": 570,
      "landing_points": 50
    },
    {
      "pilot_key": "p_Xe6Ra1",
      "round": 1,
      "group_score": 948.1,
      "time_flown": 540,
      "landing_points": 25
    },
    {
      "pilot_key": "p_Fs5Ny3",
      "round": 1,
      "group_score": 1045.0,
      "time_flown": 597,
      "landing_points": 45
    },
    {
      "pilot_key": "p_Bd4Wm9",
      "round": 1,
      "group_score": 0.0,
      "time_flown": 0,
      "landing_points": null,
      "zero_reason": "motor_restart"
    }
  ],
  "standings": {
    "pilots": [
      {
        "as_of_round": 1,
        "pilot_key": "p_Fs5Ny3",
        "place": 1,
        "overall_score": 1045.0
      },
      {
        "as_of_round": 1,
        "pilot_key": "p_7Hq2xK",
        "place": 2,
        "overall_score": 1040.0
      },
      {
        "as_of_round": 1,
        "pilot_key": "p_Kc8Zt2",
        "place": 3,
        "overall_score": 1024.4
      },
      {
        "as_of_round": 1,
        "pilot_key": "p_Xe6Ra1",
        "place": 4,
        "overall_score": 948.1
      },
      {
        "as_of_round": 1,
        "pilot_key": "p_Bd4Wm9",
        "place": 5,
        "overall_score": 0.0
      }
    ],
    "teams": [
      {
        "as_of_round": 1,
        "team_key": "t_9Lq4vP",
        "place": 1,
        "team_score": 2069.4
      },
      {
        "as_of_round": 1,
        "team_key": "t_3Nw9bD",
        "place": 2,
        "team_score": 1040.0
      }
    ]
  },
  "calculation_metadata": {
    "group_score_mode": "Time",
    "rounding_mode": "Round",
    "decimal_places": 1
  },
  "published_at": "2026-10-17T16:00:00Z",
  "published_by": "019c0000-0000-7000-8000-000000000001",
  "client_mutation_id": "01J9ZN7D4F6H8K0M2P4R6T8V0X"
}
```

## PublicationParticipant

One row per pilot.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000b20",
    "publication_id": "019c0000-0000-7000-8000-0000000000b0",
    "pilot_key": "p_7Hq2xK",
    "source_participation_id": "019c0000-0000-7000-8000-000000000040",
    "details": {
      "name": "Sam Ortega",
      "club": "Front Range Soaring Society",
      "country": "USA"
    },
    "public_profile_id": null,
    "redacted_at": null,
    "created_at": "2026-10-17T16:00:00Z",
    "updated_at": "2026-10-17T16:00:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000b21",
    "publication_id": "019c0000-0000-7000-8000-0000000000b0",
    "pilot_key": "p_Bd4Wm9",
    "source_participation_id": "019c0000-0000-7000-8000-000000000041",
    "details": {
      "name": "Alex Chen",
      "club": "Front Range Soaring Society",
      "country": "USA"
    },
    "public_profile_id": null,
    "redacted_at": null,
    "created_at": "2026-10-17T16:00:00Z",
    "updated_at": "2026-10-17T16:00:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000b22",
    "publication_id": "019c0000-0000-7000-8000-0000000000b0",
    "pilot_key": "p_Kc8Zt2",
    "source_participation_id": "019c0000-0000-7000-8000-000000000043",
    "details": {
      "name": "Riley Nakamura",
      "club": "Longmont Lofters RC Club",
      "country": "USA"
    },
    "public_profile_id": null,
    "redacted_at": null,
    "created_at": "2026-10-17T16:00:00Z",
    "updated_at": "2026-10-17T16:00:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000b23",
    "publication_id": "019c0000-0000-7000-8000-0000000000b0",
    "pilot_key": "p_Fs5Ny3",
    "source_participation_id": "019c0000-0000-7000-8000-000000000044",
    "details": {
      "name": "Morgan Reyes",
      "club": "Longmont Lofters RC Club",
      "country": "USA"
    },
    "public_profile_id": null,
    "redacted_at": null,
    "created_at": "2026-10-17T16:00:00Z",
    "updated_at": "2026-10-17T16:00:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000b24",
    "publication_id": "019c0000-0000-7000-8000-0000000000b0",
    "pilot_key": "p_Xe6Ra1",
    "source_participation_id": "019c0000-0000-7000-8000-000000000045",
    "details": {
      "name": "Taylor Brooks",
      "club": null,
      "country": "USA"
    },
    "public_profile_id": null,
    "redacted_at": null,
    "created_at": "2026-10-17T16:00:00Z",
    "updated_at": "2026-10-17T16:00:00Z"
  }
]
```

## DelistRequest

```json
{
  "id": "019c0000-0000-7000-8000-0000000000b4",
  "publication_id": "019c0000-0000-7000-8000-0000000000b0",
  "requested_by": "019c0000-0000-7000-8000-000000000001",
  "trigger": "owner_request",
  "reason": "Published under the wrong contest name",
  "requested_at": "2026-10-19T14:00:00Z",
  "state": "approved",
  "decided_by": "019c0000-0000-7000-8000-000000000003",
  "decided_at": "2026-10-19T18:30:00Z",
  "decision_note": "Confirmed with the owner"
}
```
