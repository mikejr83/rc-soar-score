# Identity, Participants and Access

Entity specifications: [Account](../../entities/account.md), [AccountIdentity](../../entities/account_identity.md), [AccountPublicProfile](../../entities/account_public_profile.md), [ParticipantProfile](../../entities/participant_profile.md), [ParticipantAccountLink](../../entities/participant_account_link.md), [ParticipantDirectoryEntry](../../entities/participant_directory_entry.md), [ContestParticipation](../../entities/contest_participation.md), [Invitation](../../entities/invitation.md).

## Account

```json
{
  "id": "019c0000-0000-7000-8000-000000000001",
  "first_name": "Dana",
  "last_name": "Whitfield",
  "email": "dana@example.org",
  "email_verified": true,
  "kind": "registered",
  "status": "active",
  "archived_at": null,
  "is_system_admin": false,
  "created_at": "2026-08-01T15:00:00Z",
  "updated_at": "2026-08-01T15:00:00Z"
}
```

## AccountIdentity

```json
{
  "id": "019c0000-0000-7000-8000-000000000004",
  "account_id": "019c0000-0000-7000-8000-000000000001",
  "issuer": "https://accounts.example.com",
  "subject": "104857293847561029384",
  "created_at": "2026-08-01T15:00:00Z"
}
```

## AccountPublicProfile

```json
{
  "id": "019c0000-0000-7000-8000-000000000005",
  "account_id": "019c0000-0000-7000-8000-000000000001",
  "display_name": "Dana Whitfield",
  "created_at": "2026-09-20T16:00:00Z"
}
```

## ParticipantProfile

A director's own copy of a participant's details. Only the owning director sees it.

```json
{
  "id": "019c0000-0000-7000-8000-000000000020",
  "owner_account_id": "019c0000-0000-7000-8000-000000000001",
  "first_name": "Sam",
  "last_name": "Ortega",
  "club": "Front Range Soaring Society",
  "fai_number": "USA-12345",
  "national_org_id": "AMA-987654",
  "city": "Boulder",
  "state": "CO",
  "country": "USA",
  "email": "sam@example.org",
  "created_at": "2026-09-01T18:00:00Z",
  "updated_at": "2026-09-01T18:00:00Z",
  "revision": 1
}
```

## ParticipantAccountLink

```json
{
  "id": "019c0000-0000-7000-8000-0000000000d0",
  "participant_profile_id": "019c0000-0000-7000-8000-000000000020",
  "account_id": "019c0000-0000-7000-8000-000000000002",
  "status": "Confirmed",
  "origin": "EmailMatch",
  "created_at": "2026-09-02T12:00:00Z",
  "confirmed_at": "2026-09-02T12:30:00Z",
  "ended_at": null,
  "revision": 2
}
```

## ParticipantDirectoryEntry

```json
{
  "id": "019c0000-0000-7000-8000-0000000000d1",
  "account_id": "019c0000-0000-7000-8000-000000000002",
  "first_name": "Sam",
  "last_name": "Ortega",
  "club": "Front Range Soaring Society",
  "fai_number": "USA-12345",
  "national_org_id": "AMA-987654",
  "city": "Boulder",
  "state": "CO",
  "country": "USA",
  "is_listed": true,
  "email_visible_to_directors": false,
  "created_at": "2026-09-02T12:00:00Z",
  "updated_at": "2026-09-02T12:00:00Z"
}
```

## ContestParticipation

```json
{
  "id": "019c0000-0000-7000-8000-000000000040",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "participant_profile_id": "019c0000-0000-7000-8000-000000000020",
  "classification": "Expert",
  "role_id": "019c0000-0000-7000-8000-000000000030",
  "role_name": "Pilot",
  "role_type": "Pilot",
  "participant_number": 1,
  "scoring_uuid": "3f6a1c52-8b7e-4d2a-9c41-0e5d7a9b8f13",
  "retired_at_round": null,
  "revision": 1
}
```

## Invitation

```json
{
  "id": "019c0000-0000-7000-8000-0000000000d2",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "type": "QRCode",
  "protected_credential": "pbkdf2-sha256$600000$c2FsdA$Zm9vYmFyYmF6cXV4",
  "invitation_revision": 1,
  "state": "Active",
  "audience": "Pilot",
  "issued_by": "019c0000-0000-7000-8000-000000000001",
  "issued_at": "2026-10-16T14:00:00Z",
  "expires_at": null,
  "first_used_at": "2026-10-17T15:02:11Z",
  "last_used_at": "2026-10-17T16:40:05Z",
  "revoked_at": null,
  "replaces_invitation_id": null,
  "redeemed_by_account_id": "019c0000-0000-7000-8000-000000000002",
  "delivery_outcomes": [
    {
      "channel": "print",
      "requested_at": "2026-10-16T14:00:00Z",
      "result": "printed"
    }
  ],
  "client_mutation_id": "01J9ZK3Q8V7N2M4R6T8W0Y1A3C"
}
```
