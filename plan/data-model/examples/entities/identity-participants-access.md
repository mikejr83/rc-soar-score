# Identity, Participants and Access

Entity specifications: [Account](../../entities/account.md), [AccountIdentity](../../entities/account_identity.md), [AccountPublicProfile](../../entities/account_public_profile.md), [ParticipantProfile](../../entities/participant_profile.md), [ParticipantAccountLink](../../entities/participant_account_link.md), [ParticipantDirectoryEntry](../../entities/participant_directory_entry.md), [ContestParticipation](../../entities/contest_participation.md), [Invitation](../../entities/invitation.md).

The contest has five pilots and one timekeeper. Only Sam has an account of their own, and Taylor, a visitor, joined through an emailed link and so has a guest account. The others have no account, which is normal: the director enters them by hand.

## Account

A registered director, a registered pilot, a guest, and a system administrator.

```json
[
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
  },
  {
    "id": "019c0000-0000-7000-8000-000000000002",
    "first_name": "Sam",
    "last_name": "Ortega",
    "email": "sam@example.org",
    "email_verified": true,
    "kind": "registered",
    "status": "active",
    "archived_at": null,
    "is_system_admin": false,
    "created_at": "2026-09-02T12:00:00Z",
    "updated_at": "2026-09-02T12:00:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000006",
    "first_name": "Taylor",
    "last_name": "Brooks",
    "email": null,
    "email_verified": false,
    "kind": "guest",
    "status": "active",
    "archived_at": null,
    "is_system_admin": false,
    "created_at": "2026-10-17T14:20:00Z",
    "updated_at": "2026-10-17T14:20:00Z"
  },
  {
    "id": "019c0000-0000-7000-8000-000000000003",
    "first_name": "Pat",
    "last_name": "Ruiz",
    "email": "pat@example.org",
    "email_verified": true,
    "kind": "registered",
    "status": "active",
    "archived_at": null,
    "is_system_admin": true,
    "created_at": "2026-07-01T12:00:00Z",
    "updated_at": "2026-07-01T12:00:00Z"
  }
]
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

Dana's own copy of each participant's details. Only the owning director sees them. Taylor has no club, FAI number, or email.

```json
[
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
  },
  {
    "id": "019c0000-0000-7000-8000-000000000021",
    "owner_account_id": "019c0000-0000-7000-8000-000000000001",
    "first_name": "Alex",
    "last_name": "Chen",
    "club": "Front Range Soaring Society",
    "fai_number": "USA-23456",
    "national_org_id": "AMA-876543",
    "city": "Denver",
    "state": "CO",
    "country": "USA",
    "email": "alex@example.org",
    "created_at": "2026-09-01T18:00:00Z",
    "updated_at": "2026-09-01T18:00:00Z",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000022",
    "owner_account_id": "019c0000-0000-7000-8000-000000000001",
    "first_name": "Jo",
    "last_name": "Park",
    "club": "Front Range Soaring Society",
    "fai_number": null,
    "national_org_id": "AMA-765432",
    "city": "Boulder",
    "state": "CO",
    "country": "USA",
    "email": "jo@example.org",
    "created_at": "2026-09-01T18:00:00Z",
    "updated_at": "2026-09-01T18:00:00Z",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000023",
    "owner_account_id": "019c0000-0000-7000-8000-000000000001",
    "first_name": "Riley",
    "last_name": "Nakamura",
    "club": "Longmont Lofters RC Club",
    "fai_number": "USA-34567",
    "national_org_id": "AMA-654321",
    "city": "Longmont",
    "state": "CO",
    "country": "USA",
    "email": "riley@example.org",
    "created_at": "2026-09-01T18:00:00Z",
    "updated_at": "2026-09-01T18:00:00Z",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000024",
    "owner_account_id": "019c0000-0000-7000-8000-000000000001",
    "first_name": "Morgan",
    "last_name": "Reyes",
    "club": "Longmont Lofters RC Club",
    "fai_number": "USA-45678",
    "national_org_id": "AMA-543210",
    "city": "Longmont",
    "state": "CO",
    "country": "USA",
    "email": "morgan@example.org",
    "created_at": "2026-09-01T18:00:00Z",
    "updated_at": "2026-09-01T18:00:00Z",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000025",
    "owner_account_id": "019c0000-0000-7000-8000-000000000001",
    "first_name": "Taylor",
    "last_name": "Brooks",
    "club": null,
    "fai_number": null,
    "national_org_id": null,
    "city": "Cheyenne",
    "state": "WY",
    "country": "USA",
    "email": null,
    "created_at": "2026-09-01T18:00:00Z",
    "updated_at": "2026-09-01T18:00:00Z",
    "revision": 1
  }
]
```

## ParticipantAccountLink

Sam's profile is linked to Sam's account because the verified email matched.

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

Five pilots and the timekeeper, numbered in one running sequence. Jo's role is the director-defined `NonFlier` role, so Jo has no flights.

```json
[
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
  },
  {
    "id": "019c0000-0000-7000-8000-000000000041",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "participant_profile_id": "019c0000-0000-7000-8000-000000000021",
    "classification": "Expert",
    "role_id": "019c0000-0000-7000-8000-000000000030",
    "role_name": "Pilot",
    "role_type": "Pilot",
    "participant_number": 2,
    "scoring_uuid": "b81d4e07-2c95-4a6f-8e13-5d90c7a2f4b6",
    "retired_at_round": null,
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000042",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "participant_profile_id": "019c0000-0000-7000-8000-000000000022",
    "classification": null,
    "role_id": "019c0000-0000-7000-8000-000000000031",
    "role_name": "Timekeeper",
    "role_type": "NonFlier",
    "participant_number": 3,
    "scoring_uuid": "6c2e9a15-7d43-4b88-a1f0-3e8b5c6d7a29",
    "retired_at_round": null,
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000043",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "participant_profile_id": "019c0000-0000-7000-8000-000000000023",
    "classification": "Sportsman",
    "role_id": "019c0000-0000-7000-8000-000000000030",
    "role_name": "Pilot",
    "role_type": "Pilot",
    "participant_number": 4,
    "scoring_uuid": "d4a07f3b-91e6-4c25-b7d8-0a1f9e2c6b54",
    "retired_at_round": null,
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000044",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "participant_profile_id": "019c0000-0000-7000-8000-000000000024",
    "classification": "Expert",
    "role_id": "019c0000-0000-7000-8000-000000000030",
    "role_name": "Pilot",
    "role_type": "Pilot",
    "participant_number": 5,
    "scoring_uuid": "2e9b5c80-4f1a-4d73-8c6e-7a3d0b1f9e48",
    "retired_at_round": null,
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000045",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "participant_profile_id": "019c0000-0000-7000-8000-000000000025",
    "classification": "Sportsman",
    "role_id": "019c0000-0000-7000-8000-000000000030",
    "role_name": "Pilot",
    "role_type": "Pilot",
    "participant_number": 6,
    "scoring_uuid": "a7f3c1d9-6b02-4e5a-9d84-1c0e8f2b7a36",
    "retired_at_round": null,
    "revision": 1
  }
]
```

## Invitation

Sam has a field QR token that lasts the whole contest. Taylor was sent a magic link that expires after 24 hours.

```json
[
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
    "first_used_at": "2026-10-17T14:02:11Z",
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
  },
  {
    "id": "019c0000-0000-7000-8000-0000000000d3",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
    "type": "MagicURL",
    "protected_credential": "pbkdf2-sha256$600000$cGVwcGVy$cXV4YmF6YmFyZm9v",
    "invitation_revision": 1,
    "state": "Active",
    "audience": "Pilot",
    "issued_by": "019c0000-0000-7000-8000-000000000001",
    "issued_at": "2026-10-17T14:10:00Z",
    "expires_at": "2026-10-18T14:10:00Z",
    "first_used_at": "2026-10-17T14:20:00Z",
    "last_used_at": "2026-10-17T15:14:00Z",
    "revoked_at": null,
    "replaces_invitation_id": null,
    "redeemed_by_account_id": "019c0000-0000-7000-8000-000000000006",
    "delivery_outcomes": [
      {
        "channel": "email",
        "requested_at": "2026-10-17T14:10:00Z",
        "result": "delivered"
      }
    ],
    "client_mutation_id": "01J9ZK3Q8V7N2M4R6T8W0Y1A3D"
  }
]
```
