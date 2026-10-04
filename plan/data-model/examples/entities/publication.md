# Publication

Entity specifications: [PublicationIdentity](../../entities/publication_identity.md), [PublicationProjection](../../entities/publication_projection.md), [PublicationParticipant](../../entities/publication_participant.md), [DelistRequest](../../entities/delist_request.md).

## PublicationIdentity

```json
{
  "id": "019c0000-0000-7000-8000-0000000000b0",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "owner_public_profile_id": "019c0000-0000-7000-8000-000000000005",
  "claim_status": "Claimed",
  "verification_email": null,
  "visibility": "Public",
  "published_at": "2026-10-17T16:55:00Z",
  "current_projection_id": "019c0000-0000-7000-8000-0000000000b1",
  "results_hidden_through_round": null,
  "results_hidden_at": null,
  "revision": 4
}
```

## PublicationProjection

The JSON sections are frozen copies. Pilots appear only as `pilot_key`.

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
    }
  ],
  "teams": [
    {
      "team_key": "t_3Nw9bD",
      "name": "Boulder Thermals",
      "pilot_keys": ["p_7Hq2xK"]
    }
  ],
  "matrix_info": {
    "rounds": [
      {
        "ordinal": 1,
        "groups": [{ "group": 1, "pilot_keys": ["p_7Hq2xK"] }]
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
    }
  ],
  "standings": {
    "pilots": [
      {
        "as_of_round": 1,
        "pilot_key": "p_7Hq2xK",
        "place": 1,
        "overall_score": 1040.0
      }
    ],
    "teams": [
      {
        "as_of_round": 1,
        "team_key": "t_3Nw9bD",
        "place": 1,
        "team_score": 1040.0
      }
    ]
  },
  "calculation_metadata": {
    "group_score_mode": "Time",
    "rounding_mode": "Round",
    "decimal_places": 1
  },
  "published_at": "2026-10-17T16:55:00Z",
  "published_by": "019c0000-0000-7000-8000-000000000001",
  "client_mutation_id": "01J9ZN7D4F6H8K0M2P4R6T8V0X"
}
```

## PublicationParticipant

```json
{
  "id": "019c0000-0000-7000-8000-0000000000b2",
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
  "created_at": "2026-10-17T16:55:00Z",
  "updated_at": "2026-10-17T16:55:00Z"
}
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
