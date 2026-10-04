# Teams, Roles and Models

Entity specifications: [Role](../../entities/role.md), [Team](../../entities/team.md), [TeamMembership](../../entities/team_membership.md), [ModelCatalog](../../entities/model_catalog.md), [ContestModelLink](../../entities/contest_model_link.md).

There are two teams of two pilots. Taylor flies without a team. Team protection is on, so teammates never fly in the same group.

## Role

A system role has a null `owner_account_id`. The second role is defined by the director.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000030",
    "owner_account_id": null,
    "display_name": "Pilot",
    "type": "Pilot",
    "archived_at": null,
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000031",
    "owner_account_id": "019c0000-0000-7000-8000-000000000001",
    "display_name": "Timekeeper",
    "type": "NonFlier",
    "archived_at": null,
    "revision": 1
  }
]
```

## Team

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000050",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "name": "Boulder Thermals",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000056",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "name": "Longmont Lofters",
    "revision": 1
  }
]
```

## TeamMembership

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000051",
    "team_id": "019c0000-0000-7000-8000-000000000050",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000053",
    "team_id": "019c0000-0000-7000-8000-000000000050",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000054",
    "team_id": "019c0000-0000-7000-8000-000000000056",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000055",
    "team_id": "019c0000-0000-7000-8000-000000000056",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "revision": 1
  }
]
```

## ModelCatalog

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000060",
    "name": "Supra",
    "manufacturer": "Vladimir's Model",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000062",
    "name": "Estrella",
    "manufacturer": "Sky Dancer Models",
    "revision": 1
  }
]
```

## ContestModelLink

Taylor's home-built model is not in the catalog, so `model_catalog_id` is null.

```json
[
  {
    "id": "019c0000-0000-7000-8000-000000000061",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000040",
    "model_catalog_id": "019c0000-0000-7000-8000-000000000060",
    "model_name": "Supra",
    "manufacturer": "Vladimir's Model",
    "model_id": "SUPRA-2024-001",
    "contest_specific_identifier": "S1",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000063",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000041",
    "model_catalog_id": "019c0000-0000-7000-8000-000000000060",
    "model_name": "Supra",
    "manufacturer": "Vladimir's Model",
    "model_id": "SUPRA-2025-014",
    "contest_specific_identifier": "A1",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000064",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000043",
    "model_catalog_id": "019c0000-0000-7000-8000-000000000060",
    "model_name": "Supra",
    "manufacturer": "Vladimir's Model",
    "model_id": "SUPRA-2023-077",
    "contest_specific_identifier": "R1",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000065",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000044",
    "model_catalog_id": "019c0000-0000-7000-8000-000000000062",
    "model_name": "Estrella",
    "manufacturer": "Sky Dancer Models",
    "model_id": "EST-2025-003",
    "contest_specific_identifier": "M1",
    "revision": 1
  },
  {
    "id": "019c0000-0000-7000-8000-000000000066",
    "contest_id": "019c0000-0000-7000-8000-000000000010",
    "contest_participation_id": "019c0000-0000-7000-8000-000000000045",
    "model_catalog_id": null,
    "model_name": "Home-built 3.4 m",
    "manufacturer": null,
    "model_id": "TB-001",
    "contest_specific_identifier": "T1",
    "revision": 1
  }
]
```
