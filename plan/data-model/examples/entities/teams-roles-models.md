# Teams, Roles and Models

Entity specifications: [Role](../../entities/role.md), [Team](../../entities/team.md), [TeamMembership](../../entities/team_membership.md), [ModelCatalog](../../entities/model_catalog.md), [ContestModelLink](../../entities/contest_model_link.md).

## Role

A system role has a null `owner_account_id`.

```json
{
  "id": "019c0000-0000-7000-8000-000000000030",
  "owner_account_id": null,
  "display_name": "Pilot",
  "type": "Pilot",
  "archived_at": null,
  "revision": 1
}
```

A director-defined role:

```json
{
  "id": "019c0000-0000-7000-8000-000000000031",
  "owner_account_id": "019c0000-0000-7000-8000-000000000001",
  "display_name": "Timekeeper",
  "type": "NonFlier",
  "archived_at": null,
  "revision": 1
}
```

## Team

```json
{
  "id": "019c0000-0000-7000-8000-000000000050",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "name": "Boulder Thermals",
  "revision": 1
}
```

## TeamMembership

```json
{
  "id": "019c0000-0000-7000-8000-000000000051",
  "team_id": "019c0000-0000-7000-8000-000000000050",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "revision": 1
}
```

## ModelCatalog

```json
{
  "id": "019c0000-0000-7000-8000-000000000060",
  "name": "Supra",
  "manufacturer": "Vladimir's Model",
  "revision": 1
}
```

## ContestModelLink

```json
{
  "id": "019c0000-0000-7000-8000-000000000061",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
  "model_catalog_id": "019c0000-0000-7000-8000-000000000060",
  "model_name": "Supra",
  "manufacturer": "Vladimir's Model",
  "model_id": "SUPRA-2024-001",
  "contest_specific_identifier": "M1",
  "revision": 1
}
```
