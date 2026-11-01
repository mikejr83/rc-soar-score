# GliderScore to Soar Score mapping

The field-by-field mapping that turns a raw GliderScore snapshot (the
`gs-import/v1` result of
[backend-plan.md](backend-plan.md)) into a reviewable Soar Score import draft
covering **every comp in the `.mdb` in one call** as full contests
(contest + configuration, participants, matrix, scores, landings).

This document is the mapping design only. It deliberately stops at the
**reviewable draft**: persistence into the repositories, the wizard UI, and
per-comp selection are follow-up work owned with the import wizard. The draft
is not yet a mechanical persistence contract: the Persistence Compatibility
section records entity-invariant
conflicts and source ambiguities that must be resolved or explicitly supported
by an import-specific historical representation before persistence is built.

## 1. What the mapper consumes

`GliderScoreImportService.importFile`
(`packages/soar_score_core/lib/services/glider_score_import_service.dart`)
returns a `GliderScoreImportResult` (`gs-import/v1`): a list of named tables,
each a list of raw `Map<String, Object?>` rows, in file order. Nulls are
**absent keys** (the helper omits them). The mapper is a pure function over
that snapshot:

```
GliderScoreImportResult  ->  ImportDraft   (this design)
ImportDraft              ->  repositories  (follow-up, not this design)
```

The reference databases used for research are `S:\Shared\GliderScoreData.mdb`
(37 comps, 158 pilots, 6,522 score rows) and a second file analysed on
2026-10-23 (DBVersion 6.78; 38 comps, 158 pilots, 651 comp-pilots, 6,584 score
rows, 26 tables; no `State`, `Email`, `FAI_ID`, `OtherRegistration` columns in
`Pilots`). GliderScore versions differ in columns, so the mapper treats every
non-key column as optional. Its 26 tables are all accounted for in this
document: either mapped (§5) or explicitly not mapped (§6). Findings from the
second file are in `findings.md`.

## 2. Overall shape

- One `.mdb` = many comps = **many Soar Score contests**. The draft carries
  one `ContestDraft` per `Comps` row, in `CompNo` order.
- The two global tables `Pilots` and the lookup tables `CountryCodes`,
  `Roles`, `LndgNames`/`LndgPoints` are shared across comps: a pilot who
  flies in several comps becomes **one** `ParticipantProfile` with one
  `ContestParticipation` per comp.
- Everything the mapper mints follows the Soar Score id rules: **every new id
  is a freshly generated UUIDv7**. Nothing is imported by numeric id; source
  keys are kept only in a provenance map (§3).
- The draft is reviewable: it includes a `warnings` list so the wizard can
  show exactly what was guessed, dropped, or left to the director.

### Proposed draft structure

```
ImportDraft
  sourceDbFile, schema ("gs-mapping/v1"), importedAtUtc
  contests: ContestDraft[]            // one per Comps row
    sourceCompNo, sourceClass
    contest (fields to create)
    config (fields for the first ContestConfigurationRevision)
    landingTables: LandingTableDraft[]
    participants: ParticipationDraft[]
    teams: TeamDraft[]
    matrix: MatrixDraft[]             // one per (CompNo, TaskNo)
      rounds: RoundDraft[]
        groups: GroupDraft[]          // RoundGroup, for locking
      reFlights: ReFlightDraft[]
      assignments: AssignmentDraft[]
      scores: ScoreDraft[]            // attempt + official score per flight
  profiles: ProfileDraft[]            // deduplicated across comps
  roles: RoleDraft[]                  // non-system roles the import needs
  idMap: EntityIdMap                   // typed source keys -> minted UUIDv7s (§3)
  warnings: MappingWarning[]          // code, comp, message, fields involved
```

## 3. Id scheme

All Soar Score entities are identified by UUIDv7, which does not encode order
or provenance. The import therefore mints ids and keeps the source keys in a
side map so that (a) cross-references can be resolved deterministically and
(b) a later re-import or the follow-up persistence step can reason about
"same source row, new id".

Keys used (all stable within the file). The implementation must qualify each
key by source table and target entity: a single source key may identify more
than one Soar entity, and a bare string key is not sufficient to avoid
collisions. For example, the flight source key resolves separately to a
`MatrixAssignment` id, `ScorePlaceholder` id, `ScoreAttempt` id, and
`OfficialScore` id. A suitable logical shape is
`(targetEntity, sourceTable, compoundSourceKey) -> UUIDv7`.

| Source key (compound)                                                | Minted for                                                                                  |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `PilotNo`                                                            | ParticipantProfile (one per pilot referenced by an in-scope comp)                           |
| `CompNo`                                                             | Contest                                                                                     |
| `CompNo + PilotNo`                                                   | ContestParticipation                                                                        |
| `CompNo + Team`                                                      | Team (when `Team > 0`)                                                                      |
| `CompNo + TaskNo`                                                    | Source task snapshot; its MatrixRevision projection is subject to Persistence Compatibility |
| `CompNo + TaskNo + RoundNo`                                          | Round                                                                                       |
| `CompNo + TaskNo + RoundNo + GroupNo`                                | RoundGroup                                                                                  |
| `CompNo + TaskNo + RoundNo + GroupNo` with `ReFlightNo > 0`          | ReFlight (one per re-flight group number)                                                   |
| `CompNo + TaskNo + RoundNo + GroupNo + PilotNo + ReFlightNo + SeqNo` | Flight source key; separate ids per target entity                                           |
| `(comp, task, round, group, pilot)` for the selected flight          | FlightResult is not minted (computed; GS selection may be unknown)                          |
| `LndgNo`                                                             | LandingTable (+ one LandingResult per `LndgPoints` row)                                     |
| `Role` (code)                                                        | Role (reused or system role)                                                                |

Minting order is fixed by the draft structure (profiles, contests, roles,
teams, participations, landing tables, then matrix and scores) so the id map
is built before it is referenced.

## 4. Class to discipline mapping

`Comps.GSCompClass` selects the `DisciplineProfile` (`type`) of the contest.
The Soar Score discipline types in force are ALES, ThermalDuration, F3J, F5J,
F3L, F3K.

| `GSCompClass` | Discipline `type`        | Config table       | Notes                                                                                                                    |
| ------------- | ------------------------ | ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| `F3J`         | F3J                      | `Dur`              | `Dur` values stored on the config revision (§7 Q7, resolved)                                                             |
| `F5J`         | F5J                      | `Dur`              | `Dur` values stored on the config revision (§7 Q7, resolved); `F5JMotorReStarted` kept in raw components per flight      |
| `F3B`         | — (no table data needed) | `Dis`              | Distance competition; F3B data not needed by the current app; comp listed in warnings, not created                       |
| `DurGeneral`  | ThermalDuration          | `Dur`              | Generic duration event                                                                                                   |
| `DurALES`     | ALES                     | `Dur`              | Mapped to ALES (resolved, §7 Q2)                                                                                         |
| `F3K`         | — (no table data needed) | `F3K`              | F3K data not needed by the current app (profile representable but not implemented); comp listed in warnings, not created |
| `F3L`         | — (no table data needed) | (none, uses `Dur`) | F3L data not needed by the current app (profile representable but not implemented); comp listed in warnings, not created |
| `F5B`         | — (no equivalent)        | `F5B`              | Out of scope; comp listed in warnings, not created                                                                       |
| `Spd`         | — (no equivalent)        | `Spd`              | Speed competition; out of scope                                                                                          |
| `Elec`        | — (no equivalent)        | (none)             | Out of scope                                                                                                             |
| `F5L`         | — (no equivalent)        | `Dur`              | New in the analysed file (one comp, no scored rows); no Soar profile; comp listed in warnings, not created               |

Reference-DB split (analysed file): 38 comps = 30 mappable (23 F5J, 3 F3J,
3 DurGeneral, 1 DurALES), 8 not imported (2 F3B, 1 F3K, 1 F3L, 1 F5B, 1 F5L,
1 Spd, 1 Elec). The wizard shows supported comps as importable only when
structural compatibility checks pass. Comps with unresolved representation
conflicts are blocked with a reason; unsupported classes are skipped with a
reason.

The contests pin the **system** profile for that discipline type — no
new profile versions are created. The imported values are stored on the
first `ContestConfigurationRevision`, so any difference from the profile's
defaults is recorded as the contest's configuration; the review step
cross-checks them against the profile's fields at import time (§7 Q7,
resolved).

## 5. Entity-by-entity mapping

### 5.1 `Comps` -> `Contest`

| GliderScore (`Comps`)                                                                                                         | Soar Score (`Contest`)      | Rule / note                                                                                                                                                   |
| ----------------------------------------------------------------------------------------------------------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CompID`                                                                                                                      | —                           | GS internal GUID-like key; Soar ids are minted UUIDv7s; provenance only                                                                                       |
| `CompNo`                                                                                                                      | id (minted)                 | id map key                                                                                                                                                    |
| `CompName`                                                                                                                    | `name`                      | Verbatim                                                                                                                                                      |
| `CompVenue`                                                                                                                   | `host`                      | Single string; city/state/country stay null (GliderScore has no finer split)                                                                                  |
| `CompDate` (naive ISO)                                                                                                        | `start_date_time`           | Naive date, 00:00. Converted to UTC with the **current system's timezone** (§7 Q1, resolved). `end_date_time` has no source: set equal to start date          |
| `GSCompClass`                                                                                                                 | -> `DisciplineProfile.type` | §4; selects the profile for the config revision                                                                                                               |
| `CompSeriesNo`                                                                                                                | —                           | No series concept in Soar Score; provenance only (warning if present, see §5.5.7)                                                                             |
| `PrelimCompNo`                                                                                                                | —                           | Points at another comp acting as qualifiers. Soar Score does not support preliminary-comps functionality in its initial release; not mapped (§7 Q3, resolved) |
| `WasLastUploadPublic`, `IsPublic`, `UseRegistration`, `UseRegistrationIdx`, `BadgeSpecs`, `printCountry`, `printRegistration` | —                           | Publication/registration/badge concerns; Soar publication is a separate identity. Not mapped                                                                  |
| `DropScoreOption`, `AssignHelpers`                                                                                            | —                           | Operational scoring/helper settings; no Soar counterpart. Not mapped                                                                                          |
| `AudioProfileDT`, `AudioProfileAP`, `AudioProfileBT`                                                                          | —                           | Timer audio profiles; the current app does not consider timer audio. Not mapped (see §6)                                                                      |

Contest state: an imported contest is historical, but most comps are not
finished (in the reference file 21 of 30 mappable comps have unscored rows,
only 8 are fully scored). The draft proposes `lifecycle_state: Completed` only
for a comp with no unscored non-retired rows, through the import-specific
pathway required by the persistence-compatibility section; other comps import
in the state the lifecycle allows for "rounds remain". It also proposes
`scoring_access: Closed`, `admin_lock: Unlocked`, `owner_account_id` = the
installing director (or null for the offline local account), and no results
hiding.

### 5.2 Config tables -> first `ContestConfigurationRevision`

The first config revision of an imported contest pins the discipline profile
(§4) and stores **the full resolved settings**. The GliderScore values below
are imported as the resolved settings; anything not listed here stays at the
platform/profile default and the draft records that it stayed default.
`groups per round` is **not** a config option in Soar Score (it lives on the
rounds/matrix revision, built in §5.5.2), and the landing table link is a
column on the revision (`landing_table_id`), not JSON.

#### Core options (from `Comps` and the class config table)

| GliderScore                        | Core option key               | Rule / note                                                                                                                                       |
| ---------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Comps.GroupScoreOption`           | `group_score_mode`            | `1` -> `Normalized`, `2` -> `Time` (resolved, §7 Q4); reference DB has only `1` (35) and `2` (2)                                                  |
| `Comps.RoundOrTruncate`            | `rounding_mode`               | `0` -> `Round`, `1` -> `Truncate`                                                                                                                 |
| `Comps.GroupScoreDecimals`         | `decimal_places`              | 0..2 in GS, valid for Soar (0..3)                                                                                                                 |
| `Comps.Drop1AtRound..Drop5AtRound` | `drop_after_rounds`           | `99` means "no drop". Soar allows **at most two** drops; GS allows five. Take the lowest two, warn if any are discarded (§7 Q5, resolved)         |
| `Comps.UseTeams`                   | `teams_enabled`               | `1`/`0`                                                                                                                                           |
| `Comps.NbrForTeamScore`            | `team_pilot_count`            | Only when `teams_enabled`; GS value is the number of pilot scores counted                                                                         |
| `Comps.UseTeamProtection`          | `team_protection`             | Only when `teams_enabled`                                                                                                                         |
| `Comps.UseRoles`                   | `roles_enabled`               | GS reference row is always `0`, yet `Roles` values exist on some files; option follows the flag, warning if roles are present but the flag is off |
| `Comps.DrawMode`                   | `draw_mode`                   | GS `0` -> `StandardManOnMan` (only code seen; resolved, §7 Q6)                                                                                    |
| `Comps.UseClasses`                 | `classes_enabled`             | Drives whether `classification` is populated on participations                                                                                    |
| `Comps.UseModels`                  | `models_enabled`              | Drives whether model data is imported                                                                                                             |
| `Comps.UsePilotNumbering`          | `participant_numbers_enabled` | Drives numbering (§5.4)                                                                                                                           |
| `Comps.ScoresLocked`               | —                             | Locking is live state, not a setting. Not mapped (warning if set)                                                                                 |
| `Comps.Enforce20KHz`               | —                             | **Discarded** — a configuration Soar Score does not track (resolved, §7 Q7); provenance warning only                                              |
| `Comps.F3QDrop6to10`               | —                             | F3Q-only drop list; comp is out of scope, ignored                                                                                                 |
| (none)                             | remaining core options        | Platform defaults; `public_update_mode`, `review_requests_enabled` etc. untouched                                                                 |

#### Discipline fields (per class config table)

Rows in `Dur`, `Dis`, `F3K`, `F5B`, `Spd` carry the per-contest discipline
settings. Only in-scope classes (`Dur`/`Dis` rows) are mapped here;
`F3K`, `F5B`, and `Spd` configs go with their non-imported comps (table
data not needed by the current app). The import pins the **system**
profile for the contest's discipline type — no new profile versions are
created — and stores the per-contest values on the first `ContestConfigurationRevision`
(§7 Q7, resolved). Keys below are the system profile's field keys.

| GliderScore (`Dur` / `Dis`)                                                | Soar Score discipline field key (proposed)                                                      | Class(es) | Notes                                                                                                                                                                                                                                                                                                              |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `durTargetTime`                                                            | `target_time` (secs) for ALES/Thermal; `working_time` for F5J/F3J                               | all `Dur` | Working/target time in seconds; the system profile's key differs per discipline type                                                                                                                                                                                                                               |
| `DurPointsPerSecond`                                                       | `points_per_second`                                                                             | all `Dur` |                                                                                                                                                                                                                                                                                                                    |
| `durDecimalsForTiming`                                                     | `fractional_seconds` (system profile field, 0-3)                                                | all `Dur` | The profile's decimal field. No conflict with core `GroupScoreDecimals` (`decimal_places`): distinct fields, each imports its own source (§7 Q8, resolved)                                                                                                                                                         |
| `durLndg`                                                                  | `landing_table` (system profile field of type `landing`) / revision's `landing_table_id` column | all `Dur` | `LndgNo=0` -> the profile's default; otherwise `LndgNo` identifies the comp's GS table, and the revision's `landing_table_id` is set by the §5.5.6 match: the system default when it fully matches, else another shipped table (warning), else the reconstructed `LndgPoints` table                                |
| `durFlightPenalty`                                                         | `raw_components.dur_flight_penalty` (provenance)                                                | all `Dur` | A GS per-comp penalty-regime code, uniform per class (3 for every F5J, 1 for every F3J, 2 for Elec, 0 elsewhere); not a numeric penalty magnitude and not a Soar option. No impact on imported scores; F5J per-flight penalties come from `Scores.Penalty` and the reference-height fields below (§7 Q9, resolved) |
| `durNumberOfTimekeepers`                                                   | —                                                                                               | all `Dur` | Live operational detail, no Soar field; warning only                                                                                                                                                                                                                                                               |
| `durGroupsPerRound` / `disGroupsPerRound`                                  | — (round's `group_count`)                                                                       | all       | Built into each round in §5.5.2, not into the revision                                                                                                                                                                                                                                                             |
| `durNbrOfLanes`                                                            | `lane_mode` / `lane_count`                                                                      | all `Dur` | `0` -> `lane_mode: None`; `> 0` -> `Random` with `lane_count` = the value. The reference DB contains 29 zero-lane rows, two rows with 2 lanes, and three rows with 6 lanes; lanes must be preserved rather than assumed absent.                                                                                    |
| `durRefHeight`, `durPenaltyUpToRefHeight`, `durPenaltyOverRefHeight`       | `reference_launch_height`, `minor_penalty_per_meter`, `major_penalty_per_meter`                 | F5J       | System F5J profile field keys (resolved, §7 Q7); values as-is, stored on the config revision                                                                                                                                                                                                                       |
| `F5JMotorRestartOption`                                                    | contest config `motor_restart_mode`                                                             | F5J       | 0 = Not Allowed (`not_allowed`), 1 = Allowed, zero cannot be dropped (`non_droppable`), 2 = Allowed, zero can be dropped (`allowed`); NULL in the oldest comps (setting did not exist; a restart flag never zeroed the flight, so keep the recorded scores)                                                        |
| `durAllowBackToBack`, `durPilotsMin`, `disAllowBackToBack`, `disPilotsMin` | —                                                                                               | all       | GS operational draw details (comma-coded). No Soar option; kept as provenance, warning                                                                                                                                                                                                                             |
| `durPilotsMax` / `disPilotsMax` / `f3kPilotsMax` / ...                     | —                                                                                               | all       | Group size is **derived** in Soar (from N and G); not stored. Ignored                                                                                                                                                                                                                                              |
| `durDrawLocked` / `disDrawLocked` / ...                                    | —                                                                                               | all       | Live draw lock; not a setting. Not mapped (warning if set)                                                                                                                                                                                                                                                         |
| `disPilotsMin` etc.                                                        | —                                                                                               | `Dis`     | As above                                                                                                                                                                                                                                                                                                           |

`F3KTaskByRound` (per-round F3K task strings such as `X`) and any `F5K*` /
`F3K` per-round tables are discipline task definitions with no Soar Score
equivalent in the current model; they are provenance only for the flagged
comps (§6).

### 5.3 `Pilots` -> `ParticipantProfile`

`Pilots` is a **global** roster in the `.mdb`; the same `PilotNo` appears in
every comp the pilot flew. The import creates one profile per distinct
`PilotNo` referenced by a participation in an in-scope comp and reuses it
across those participations. Pilots found only in skipped comps or unused by
all in-scope comps are not imported by default (see Persistence Compatibility).

| GliderScore (`Pilots`)        | Soar Score (`ParticipantProfile`) | Rule / note                                                                                                                                                                                                                                                                         |
| ----------------------------- | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PilotNo`                     | id (minted)                       | Key in id map                                                                                                                                                                                                                                                                       |
| `FirstName`                   | `first_name`                      | Verbatim                                                                                                                                                                                                                                                                            |
| `LastName`                    | `last_name`                       | Verbatim                                                                                                                                                                                                                                                                            |
| `Country` (GS 3-letter code)  | `country`                         | GS value is already a country code; `CountryCodes` (206 rows) used to validate it, unresolved code kept as-is with warning. Confirm and normalize to Soar's country-code format (demo uses 2-letter codes) rather than carrying a potentially incompatible 3-letter value unchanged |
| `FAINumber`                   | `fai_number`                      | Empty or `0` -> null                                                                                                                                                                                                                                                                |
| `State`                       | `state`                           | Verbatim (39 of 158 reference rows have a value)                                                                                                                                                                                                                                    |
| `Email`                       | `email`                           | Verbatim (21 of 158 reference rows have a value)                                                                                                                                                                                                                                    |
| `FAI_ID`, `OtherRegistration` | —                                 | Absent in newer or older GS versions (the analysed 6.78 file has no `State`, `Email`, `FAI_ID` or `OtherRegistration`); treat every non-key column as optional. When present: no dedicated Soar field, provenance only                                                              |
| `UsualClass`                  | —                                 | Class is contest-specific; goes to `ContestParticipation.classification` when `classes_enabled` (§5.4)                                                                                                                                                                              |
| `Filter`                      | —                                 | GS filtering flag; not mapped                                                                                                                                                                                                                                                       |

`owner_account_id` is the importing director (or installation Local account
for offline imports); profile ownership must be assigned consistently with
that account and the supported local-to-registered account lifecycle. If the
installation has no account identity available, persistence must stop rather
than mint an invalid owner reference.
`club`, `national_org_id`, `city` have no source and stay null.
Re-importing a database where profiles already exist is a
follow-up concern (matching/deduping, §8), not part of the draft contract.

### 5.4 `CompPilots` -> `ContestParticipation` + `Role` + `Team`/`TeamMembership` + `ContestModelLink`

| GliderScore (`CompPilots`) | Soar Score                               | Rule / note                                                                                                                                                                                                                                                                                          |
| -------------------------- | ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CompNo` + `PilotNo`       | `ContestParticipation.id` (minted)       | One participation per (comp, pilot)                                                                                                                                                                                                                                                                  |
| `CompNo`                   | `contest_id`                             | From id map                                                                                                                                                                                                                                                                                          |
| `PilotNo`                  | `participant_profile_id`                 | From id map (shared profile)                                                                                                                                                                                                                                                                         |
| `Role`                     | `role_id` / `role_name` / `role_type`    | Mapped through `Roles` table: `Plt` -> system Pilot, `Hlp` -> system Helper, `TM` -> system Team Manager, `CD` -> NonFlier role created if absent, composite codes (`TM/Plt`, `CD/Plt`) unmappable (one role per participation) -> the pilot keeps `Pilot`, warning (§5.5.7)                         |
| `IsPilot`                  | guard                                    | `1` -> `role_type: Pilot`; `0` would mean a non-flier (not present in reference DB)                                                                                                                                                                                                                  |
| `Retired`                  | `retired_at_round`                       | `1` -> the round after the pilot's last `Updated = True` flight (1 if none); retired pilots' later rows exist as unscored placeholders and are not imported as assignments. Show the inferred round for confirmation (§7 Q10).                                                                       |
| `StartNo`                  | `participant_number`                     | Only imported when `participant_numbers_enabled` is on; `0` -> allocate from the running sequence in (StartNo, PilotNo) order so numbers stay distinct (§5.4)                                                                                                                                        |
| `PilotClass`               | `classification`                         | Only when `classes_enabled` and the participation is a pilot                                                                                                                                                                                                                                         |
| `Team`                     | `team_id` + `TeamMembership`             | `0` -> no team. `> 0` -> a Team per (CompNo, Team). **No team names exist in GS** (there is no Teams table): names are generated ("Team 1", "Team 2", ...) with a warning; names are editable after import in the contest UI                                                                         |
| `OmitFromTeamScore`        | —                                        | No per-pilot exclusion in Soar team scoring; not mapped, warning when set                                                                                                                                                                                                                            |
| `DrawFreq`                 | —                                        | GS draw-frequency bookkeeping; not a Soar field. Not mapped                                                                                                                                                                                                                                          |
| `Model`                    | `ContestModelLink.model_name`            | One link per participation (invariant: one per participation). Created when present; `ModelData` -> `model_id` when it is not `-1`/empty (resolved, §7 Q11: reference file has all `-1`). `model_catalog_id` stays null: GS has no per-director catalog; `ModelNames` in the reference file is empty |
| `ModelData`                | `ContestModelLink.model_id` / provenance | `-1` / empty -> null; otherwise kept as external id string                                                                                                                                                                                                                                           |

Participations of non-pilots (helpers, the CD) are created with the mapped
role and `role_type: NonFlier`; they have no assignments or scores, matching
the data model.

#### Roles table

| `Roles.Role`       | Soar Score role                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------- |
| `Plt`              | System role `Pilot`                                                                         |
| `Hlp`              | System role `Helper`                                                                        |
| `TM`               | System role `Team Manager`                                                                  |
| `CD`               | NonFlier; import creates a director-owned "Competition Director" role when the comp uses it |
| `TM/Plt`, `CD/Plt` | **Unmappable** (see row above)                                                              |

Roles are created once per import and shared across the imported comps of
the same file; `RoleDraft` rows carry `display_name` and type for review.

### 5.5 `Scores` and the flight structure -> matrix, scores

This is the heart of the import. **GliderScore keeps the draw inside `Scores`:**
a row exists for every drawn flight, with `Updated = False` and no data until it
is scored. Whole future rounds, retired pilots' later rounds and pilots who did
not fly are all present as unscored rows (reference file: 863 unscored F5J
rows). So the matrix is the full draw, not a lower bound reconstructed from
scored flights. What GS does not hold:

- Lane numbers: every imported assignment has `lane: null`; `lane_mode` still
  comes from `durNbrOfLanes` (comps 15 and 16 use 6 lanes, comp 20 uses 2) and
  lanes cannot be reconstructed from the source, so the count is preserved in
  configuration/provenance and the matrix is not claimed lane-equivalent.
- The draw seed and algorithm: placeholder seed, flagged in warnings.

#### 5.5.1 `TaskNo` -> `MatrixRevision`

`TaskNo` is not a global id: in the reference file 35 of 37 comps use a
`TaskNo` different from their `CompNo`, most simply use 1, and only comp 3
(F3B, skipped) has several tasks. Multiple tasks in one comp would mean
successive draws. Mapping:

- One `MatrixDraft` per distinct `(CompNo, TaskNo)` with score rows.
- Task order is provisional source order, sorted by the smallest `RoundNo`
  seen for that task and then by `TaskNo`. This is a draft ordering only:
  the Persistence Compatibility section must determine whether the ordered
  tasks can be projected to valid extension/tail-redraw revisions.
- `first_round`/`last_round` per draft come from the min/max `RoundNo` of
  that task's rows.
- The draft records each source task's ordinals and overlap with earlier tasks
  and shows a per-task note. Product decision Q12-B1 governs duplicate
  task-number handling, but overlapping task ranges are not automatically
  valid `MatrixRevision` extensions or tail redraws. Apply the compatibility
  checks below; where no valid revision sequence exists, block persistence of
  the affected comp rather than simply superseding overlapping rows.
- `draw_mode`: `StandardManOnMan` (the only observable mode); `random_seed`
  and `algorithm_version` have no source: the draft uses a deterministic
  placeholder seed (e.g. `0`) and the current engine version, flagged in
  `warnings` — an imported matrix is history, not a reproducible draw.
- `seeding_snapshot`: empty (no order source); `team_protection` copied from
  `Comps.UseTeamProtection`.

#### 5.5.2 `RoundNo` -> `Round`

| GliderScore (`Scores`)                                                             | Soar Score (`Round`) | Rule                                                                                                                                                                                                                |
| ---------------------------------------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RoundNo`                                                                          | `ordinal`            | Verbatim, per (comp, task)                                                                                                                                                                                          |
| `disGroupsPerRound` / `durGroupsPerRound` / `f3kGroupsPerRound` (per class config) | `group_count`        | The config value for that comp; where observed groups exceed it, the maximum observed wins with a warning. Still create every regular RoundGroup from 1 through `group_count`, including groups with no score rows. |
| `Comps.ScoresLocked`                                                               | `status`             | Imported rounds are all `Open` (final); lock state is not history                                                                                                                                                   |

`matrix_revision_id` and `contest_id` come from the drafts above. Groups and
assignments come from the observed rows, scored or not (§5.5.3).

#### 5.5.3 `GroupNo` -> `RoundGroup`

Create one `RoundGroup` per observed group number in the round. The configured
`*GroupsPerRound` can be stale (the reference file has comps that configure
fewer groups than the draw has), so the observed draw wins. All groups have
`status: Open`; unscored flights inside them are pending placeholders (§5.5.4).

#### 5.5.4 `Scores` rows -> `MatrixAssignment` + `ScorePlaceholder` + `ScoreAttempt` + `OfficialScore`

Each `Scores` row is one flight. Its position in the matrix is keyed by
`(CompNo, TaskNo, RoundNo, GroupNo, PilotNo)`, and the row's own fields
distinguish the flight:

| GliderScore (`Scores`)                                | Soar Score                                              | Rule / note                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ----------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| —                                                     | `MatrixAssignment` (minted)                             | One per (comp, task, round, group, pilot, re-flight) flight; built even for pilots who have other rows so all flown flights of a pilot are present                                                                                                                                                                                                                                                                                                                                                                                               |
| `PilotNo`                                             | `contest_participation_id`                              | From id map                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `RoundNo`, `GroupNo`                                  | `scheduled_round_id`, `group`                           | Scheduled = where it flew. For the original flight `credited_round_id` = `scheduled_round_id`                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `OriginalRoundNo`                                     | `credited_round_id`                                     | Differs from `RoundNo` exactly when GS recorded a moved flight. Product decision Q13 keeps the flight in its actual flight round and credits `OriginalRoundNo`; this conflicts with the current `Original` invariant and is draft-only until Persistence Compatibility defines a valid persisted representation. Do not synthesize a source assignment or silently coerce the row.                                                                                                                                                               |
| `ReFlightNo`                                          | re-flight handling                                      | `0` -> regular flight (`ReflightNo=1`, `2`, ... become `Reflight` assignments under a ReFlight, §5.5.5)                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `SeqNo`                                               | — (provenance)                                          | The pilot's slot in the group (1..n, identical across a pilot's re-flight rows, a few repeats); not an attempt counter, and not `flight_sequence`.                                                                                                                                                                                                                                                                                                                                                                                               |
| `DrawFreq`                                            | —                                                       | Provenance only                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `Helper`                                              | `ScoreAttempt.actor_id` hint                            | GS helper id (the scorer). No matching Soar account exists: the attempt is filed under the importing director with authority `Director`, and the helper id is kept in `raw_components` as provenance (§7 Q14)                                                                                                                                                                                                                                                                                                                                    |
| `Updated`                                             | placeholder vs scored                                   | `False` = drawn, not yet scored (no data in the row); `True` = scored. Not a re-entry marker. See §5.5.                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `Landing`                                             | landing selection                                       | `0`/absent -> no landing. Otherwise the value may be a distance in metres **or entered points**, depending on the selected GS table: distance tables (for example `F3J Enter Dist`, `F5J Enter Distance`) use metres, while `Enter Points` tables use points. Determine the encoding from `Dur.durLndg`/`LndgNames` and compare awarded points before resolving. Resolve only against a semantically matching contest table (§5.5.6) to the selected `LandingResult.id`; ambiguous encoding/match requires review and blocks exact-score claims. |
| `Time1Mins` (+ `Time1Secs`, `Time2Mins`, `Time2Secs`) | `time_flown` (`raw_components.duration_sec`)            | `Time1Mins` holds the flight time packed as `M:SS` (minutes*100 + seconds, e.g. 958 is 9:58; with timing decimals the value carries a fraction, e.g. 952.4). The other three fields are 0 outside F3B, F3K and F5B. Decode with `(v ~/ 100) * 60 + (v % 100)`; keep the raw value in `raw_components`.                                                                                                                                                                                                                                           |
| `Laps`                                                | `raw_components.laps`                                   | Lap count (lap-based disciplines); not part of Soar core components, kept in the raw JSON                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `FlightScoreDeduction`                                | `launch_height` (F5J)                                   | F5J launch height in metres; the height penalty is computed by Soar. See §7 Q16 (corrected). For other classes the meaning differs and belongs to the discipline mapping.                                                                                                                                                                                                                                                                                                                                                                        |
| `Penalty`                                             | `OfficialScore.components.flight_penalty`               | Non-zero values are small round penalties (reference: 100 and 300 points) -> mapped as the per-flight `flight_penalty` integer                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `RawScore`                                            | (validation target)                                     | GS's computed flight score. **Not stored** by the import (Soar derived values live in FlightResult, which the calculator recomputes). Kept in `raw_components` and used to validate the recomputed result (§7.1)                                                                                                                                                                                                                                                                                                                                 |
| `NormalisedScore`                                     | (validation target)                                     | As above, for the group score; comparison requires an independently established GS-counted flight (Which GS Flight Counts)                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `F5JMotorReStarted`                                   | `motor_restart` flag + `raw_components.motor_restarted` | Soar's calculator ignores the other components when the flag is set, so the components can be stored beside it. Applies only when the comp's `Dur.F5JMotorRestartOption` is 1 or 2; NULL (oldest comps) means the flag never zeroed the flight: keep it as provenance only. Option maps 0 to `not_allowed`, 1 to `non_droppable`, 2 to `allowed` (droppable) on the contest config (§5.2).                                                                                                                                                       |
| `LandingOver75m`, `ScoresChecked`                     | —                                                       | GS bookkeeping; provenance only                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |

Per flight, the import creates **four** linked records (all ids minted per the
§3 key):

1. `MatrixAssignment` — scheduled/credited round, group, sequence, type
   `Original` (or `Reflight`, §5.5.5), `lane: null`, `actor_id` = importing
   director, reason "imported from GliderScore `.mdb`". An `Original` with
   different scheduled and credited rounds is not valid under the current
   entity invariant; such a row is draft-only pending Persistence Compatibility.
2. `ScorePlaceholder`, `ScoreAttempt`, and `OfficialScore` must be created via
   the supported score acceptance/officialization path (or an explicitly
   specified import path that preserves its invariants). The concrete revision
   sequence is specified in Persistence Compatibility; do not assume `score_revision: 1` for both
   placeholder and OfficialScore.
3. `ScoreAttempt` — one attempt, authority `Director`, actor the importing
   director, `raw_components` holding the GS fields above verbatim (original
   units), `config_revision_id`/`matrix_revision_id` pointing at the
   imported revision (informational per the entity docs),
   `client_mutation_id` = a deterministic, source-qualified flight key (e.g.
   `gs:comp=3,task=2,round=2,group=6,rf=1,pilot=13,seq=1`) so a retry of
   the same persistence operation can dedupe. This is not re-import
   idempotency: fresh drafts mint fresh IDs, and matching an already-imported
   contest/profile is out of scope (§8).
4. `OfficialScore` — revision set by the supported import/officialization
   pathway (not assumed to be revision 1), with `components` normalized into Soar units:
   `duration_sec`, `landing` (the selected LandingResult id or absent),
   `flight_penalty` (from `Penalty`), plus the raw GS values under a
   `glidersource` key for provenance. `reason`: "imported from
   GliderScore `.mdb` (RawScore=N)". `set_at` = the import instant (no better
   source; §7 Q18, resolved), `set_by` = importing director.
   Rows with `Updated = False` produce a `MatrixAssignment` and a pending
   `ScorePlaceholder` only (no attempt, no official score); items 2 to 4 apply to
   `Updated = True` rows.

`FlightResult` is **not** part of the draft: it is derived data the Soar
calculator recomputes from the attempt/official components, the imported
configuration, and the discipline. The wizard (follow-up) runs the calculator
over the draft and reports mismatches against GS `RawScore` /
`NormalisedScore` per flight as review information rather than blocking
errors — the imported configuration is an approximation of GS's own rules
engine, so exact equality is not required (Validation Report).

Row duplicates: the reference file has no duplicate
`(comp, task, round, group, pilot, re-flight)` keys, but the mapper must be
total over the input: if a key repeats, the **last** row in file order wins and a
warning is emitted (`Updated` is the scored/unscored marker, not a re-entry
marker).

#### 5.5.5 Re-flights

GliderScore records a re-flight as **additional rows with `ReFlightNo > 0`
in the same round and group** (the group re-flies, partially or wholly).
Evidence from the reference DB: comp 3 task 2 round 2 group 6 has both a
complete `ReFlightNo=0` set and a complete `ReFlightNo=1` set for all four
pilots (whole-group re-flight); other groups have only some pilots with
`ReFlightNo=1` (individual re-flights).
**Decided and observed (reference file).** All F5J re-flights in the file (comp
21 round 8 group 2, comp 22 round 2 group 2) are whole-group, `ReFlightNo = 1`,
same `GroupNo`, same pilots, same `SeqNo`. A pilot who did not re-fly has an
identical carried-over row. Roles are decided: a pilot with no score in the
original flight is `Awarded`, everyone else in the group is `GroupMember`
(Mike, 2026-10-23); the re-flight set normalises separately from the original.
The draft semantics below stay for files that have subset re-flights.

Mapping rules (draft semantics; persistence constraints follow):

- One `ReFlightDraft` per distinct `(CompNo, TaskNo, RoundNo, GroupNo,
ReFlightNo)` with rows; `sequence` = the re-flight number. Source rows
  establish who flew again, but do not by themselves establish the Soar
  `ReFlightParticipant.role` (`Awarded` versus `GroupMember`) or all lifecycle
  events. Do not infer these roles solely from `ReFlightNo`. The proposed
  type is decided per group:
  - **whole group re-flew** (every pilot of the regular group has a row with
    that `ReFlightNo`) -> `ReflyEntireGroup`;
  - **subset re-flew** -> preserve product decision Q12-A1 to describe this
    as `MoveToGroup` to the same group, with a warning. This is draft-level
    description only: current `MoveToGroup` requires an open spot and does not
    establish participant roles or prove the source group had capacity. The
    persistence step must validate these constraints; it must not force an
    invalid re-flight into the current entity. Unresolved roles block
    score-equivalent persistence for the affected re-flight.
- `credited_round_id` = `source_round_id` = `scheduled_round_id` = the round
  (GS credits in place). GS records the re-flight under the same `GroupNo`;
  current Soar rules require `ReflyEntireGroup` and `RandomDraw` groups to be
  numbered after regular groups, while `MoveToGroup` uses an existing group
  with capacity. Same-group source placement is therefore not automatically
  valid in Soar. Preserve the source group in raw provenance and mark the row
  draft-only until a supported representation is defined; do not create
  out-of-range groups by guess.
- Draft `ReFlightParticipant` rows only when roles can be justified:
  `Awarded` for the pilot entitled to the extra chance, `GroupMember` for
  other pilots re-flying as part of a whole group. Both use response
  `NotRequired`; each flying participant references its minted `Reflight`
  assignment. If GS does not identify the awarded set, mark the role
  unresolved in the draft and block persistence of that re-flight rather than
  defaulting every pilot to `Awarded`.
- The proposed `MatrixAssignment` rows: type `Reflight`,
  `re_flight_id` set, `source_assignment_id` = the pilot's `Original`
  assignment in the same credited round, `flight_sequence` = the next
  free sequence for that pilot (`SeqNo` is the pilot's group slot, not a
  sequence), `credited_round_id` = original round.
- Soar's which-flight-counts rule (discipline result selection) reads the
  re-flight roles and picks the official result; the draft does **not** pick.
  Preserve all observed flight scores. The calculator may compute Soar's
  selected flight at review time, but GS's counted flight is unknown unless
  independently established (Which GS Flight Counts); do not label any stored
  `NormalisedScore` as the counted-flight target by assumption.
- All decision fields (`random_seed`, `reason`, status history,
  `deviation_acknowledged`, acknowledgement columns) have no source:
  `status: Finalized`, `reason: "imported from GliderScore"`, decision
  timestamps = import time.

#### 5.5.6 `LndgNames` + `LndgPoints` -> `LandingTable` + `LandingResult`

**Reconstruction.** Every table named by `LndgNames` with `LndgNo > 0` is
reconstructed as a `LandingTable` (the name from `LndgNames.Name`), each
`LndgPoints` row as a `LandingResult`:

| GliderScore | Soar Score (`LandingResult`) | Rule                                                                  |
| ----------- | ---------------------------- | --------------------------------------------------------------------- |
| `LndgNo`    | `landing_table_id`           | From table id map                                                     |
| `Distance`  | `entry_key`                  | String form of the distance (e.g. `"7.4"`) — keys are strings in Soar |
| `Distance`  | `display_value`              | `"<distance> m"`                                                      |
| `Points`    | `point_value`                | Verbatim (int in all reference rows)                                  |
| (row order) | `ordinal_position`           | Sorted ascending by distance, 1-based                                 |

**Soar entry keys.** Soar's system tables use keys such as `points_50`,
`within_7m` and `over_10m`, not the distance string. Matching therefore goes
GS value to points (by the table's input unit) to the Soar entry. In the
reference file every landing value of every mappable comp resolves in its own
table (0 unresolved), 22 of 23 F5J comps use GS table 9 ("F5J Enter Points")
which equals Soar's F5J Standard Landing Table, comp 10 uses table 5 (distance)
which equals the F5J Distance Table, F3J comps use tables 2 and 3 (the F3J
distance and standard tables), and two DurGeneral comps (tables 2 and 6) have no
Thermal system equivalent and need the reconstructed table.

`input_unit` is `meters` only for reconstructed distance-entry tables. For GS
tables whose name indicates entered points (`Enter Points`, `Pts`), the
reconstructed table must use `input_unit: points` and the `Distance` column is
treated as the entered key, not a physical distance. This is data-backed: the
reference DB uses `durLndg=2` (`F3J Enter Dist`) for comps 1/2 and `durLndg=3`
(`F3J Enter Points`) for comps 4/11/20; the corresponding source values are
fractional/metre-like (comp 1) and 30..100 point values (comp 4).
`owner_account_id` = the importing director (these are imports, not system
tables). `LndgNo=0` ("None") is not a table.

**Table selection (semantic match required).** The contest's own table is not
imported by default. Each comp's landing values are matched against the
candidate tables the discipline offers, and the match decides what the
contest actually used:

- **Candidates:** the discipline's system default landing table, its other
  shipped tables (F5J: the distance table, F3J: the official distance
  table; ALES/Thermal: none), and the comp's own reconstructed `LndgPoints`
  table.
- **A candidate matches** iff every distinct non-zero `Scores.Landing`
  value of the comp resolves to exactly one entry and awards the same points
  as the corresponding source `LndgPoints.Points`, and no two different
  landing values resolve to the same entry. Matching keys alone is not enough.
  Where source data does not establish whether the value represents a distance
  or entered points, or candidates with the same key award different points,
  mark the match ambiguous and require review. Beyond the last breakpoint,
  shipped distance-table catch-all entries (`over_10m`/`over_15m`,
  `point_value` 0) match only when source scoring confirms the zero result.
- **Decision order:** system default first, then the other shipped tables
  (a non-standard table is a warning, not an error), then the comp's own
  table. The matching table is pinned as the revision's `landing_table_id`
  and every score row resolves against it.
- **Partial match fallback:** if no candidate matches fully and there is no
  semantic ambiguity, pin the best
  matching candidate (the default on a total miss) and resolve the
  non-matching rows to no landing (0) with a per-row warning. The Q17 delta
  report surfaces any divergence in `RawScore`/`NormalisedScore`.
- **Units** require an explicit decision from the selected GS table. A table
  name such as `Enter Points` is meaningful evidence, not provenance-only
  text: it establishes point-entry semantics when corroborated by the value
  range and source scores. Distance tables use metres; point-entry tables use
  points.
- Reconstructed tables are imported **on demand**: only when they win the
  match or are pinned by partial-match fallback. Tables the comp never uses
  (including unreferenced tables in the file) are skipped; the snapshot
  still contains them.

Landing **resolution** for a score row: exact key match of the landing
value string against the pinned table's entries. GS values are integral or
to tenths; both are exact keys. A score row referencing a table not
imported (comp out of scope) never happens for mappable comps by the rule
above.

#### 5.5.7 Unmappable or degraded values

Collected in one place, so the wizard renders them as review items:

- Composite GS roles (`TM/Plt`, `CD/Plt`): participation keeps `Pilot`.
- Comps out of scope by class (`F5B`, `Spd`, `Elec`) or class not yet
  implemented (`F3K`, `F3L`): comp listed, nothing created.
- `CompSeriesNo` / `CompSeries`: no Soar series concept.
- `PrelimCompNo`: not a preliminary-rounds setting.
- `durFlightPenalty`: contest-level constant without a Soar option.
- `Helper` ids: no matching Soar accounts.
- Team names: generated.
- `OmitFromTeamScore`: no per-pilot team exclusion.
- GS `ScoresLocked`, `*DrawLocked`: live lock state, not history.
- Every `RawScore`/`NormalisedScore`: validation targets only.

## 6. Not mapped, with reasons

| Table                                                                | Rows    | Why                                                                                                                    |
| -------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------- |
| `AudioSettings`                                                      | 296     | Timer audio; operational, no Soar counterpart, not needed by the current app                                           |
| `TimerNames`                                                         | 19      | Operational timers; not needed by the current app                                                                      |
| `TimerSettings`                                                      | 751     | Per-timer chime/announcement rows; not needed by the current app                                                       |
| `CustomReportsData`                                                  | 4       | Print header/logos                                                                                                     |
| `QRCodeSpecs`                                                        | 11      | Badge/QR layout; not needed by the current app                                                                         |
| `ModelNames`                                                         | 1       | Single sentinel row (`ModelNo: 0`), i.e. no named models in the reference file; model names live on `CompPilots.Model` |
| `DeviceNames`                                                        | 1       | Single sentinel row (`DeviceNo: 0`); scorer device labels                                                              |
| `DBParams`                                                           | 5       | File provenance (`DBVersion`, locale); kept as import metadata, not an entity                                          |
| `CompSeries`                                                         | 2       | No Soar series concept (see §5.5.7)                                                                                    |
| `CountryCodes`                                                       | 206     | Consumed as lookup for `Pilots.Country` mapping, not imported                                                          |
| `Roles`                                                              | 6       | Consumed as lookup for role mapping, not imported                                                                      |
| `F3KTaskByRound`                                                     | 9       | F3K per-round task definitions; class flagged, no Soar equivalent                                                      |
| `F5K`, `F5KTaskandRefHeightByRound`, `F5KBonusNames`, `F5KBonusData` | 0/0/1/4 | F5K-only rules data; F5K has no Soar profile and its data is not needed by the current app                             |
| `DurTargetTimeByRound`                                               | 0       | Per-round target time overrides; empty in reference file, no Soar per-round option                                     |

## 7. Open Questions and Decisions

Numbered for resolution with the wizard/profiles owners; each one is a
guess or an explicit skip in this design, not a silent one.

1. **Timezone (resolved).** `CompDate` is naive (no offset). Decision: use
   the current system's timezone — the import converts `CompDate` to UTC
   with it and sets the contest `timezone` to it; the wizard takes no
   timezone input. `end_date_time` has no source (set equal to start date).
2. **ALES vs ThermalDuration (resolved).** `DurALES` has a dedicated GS
   class. Soar has both ALES and ThermalDuration profiles. Decision: an
   imported `DurALES` comp becomes **ALES**.
3. **Preliminary comps (resolved).** GS supports a preliminary comp
   determining the participants of another comp via `PrelimCompNo`. Soar
   Score will not support this functionality in its initial release.
   Decision: ignore the link, import each comp standalone, warn.
4. **`GroupScoreOption` code table (resolved).** Only codes `1` (35 comps)
   and `2` (2) occur in the reference file. Decision: `1` -> `Normalized`,
   `2` -> `Time` (time normalized), per product owner.
5. **Drops (resolved).** GS allows five drop rounds (`Drop1..5AtRound`,
   `99` = none); Soar allows at most two. Decision: import the two lowest,
   warn on any discarded.
6. **`DrawMode` codes (resolved).** Only `0` occurs. Decision: `0` ->
   `StandardManOnMan`.
7. **Discipline field keys (resolved).** The `Dur` fields are the settings
   of an F5J (or F3J) contest: the import pins the **system** F5J/F3J
   profile — no new profile versions — and stores the per-contest values
   on the first `ContestConfigurationRevision`, where any difference from
   the profile defaults is recorded. `Comps.Enforce20KHz` is **discarded**:
   a configuration Soar Score does not track. Field keys from the system
   F5J profile: `durRefHeight` -> `reference_launch_height`,
   `durPenaltyUpToRefHeight` -> `minor_penalty_per_meter`,
   `durPenaltyOverRefHeight` -> `major_penalty_per_meter`.
8. **Two decimal settings (resolved).** `GroupScoreDecimals` and
   `durDecimalsForTiming` feed two different Soar fields — `decimal_places`
   (final group-score rounding) and `fractional_seconds` (time-entry
   precision) — so they never conflict, and each imports its own source
   value (§5.2). If a flown time carried more precision than
   `durDecimalsForTiming` allows, GS would be internally inconsistent (and
   the Soar calculator would reject the flight as `too_precise`); the mapper
   emits a warning in that case rather than failing.
9. **`durFlightPenalty` (resolved).** Inspected the `Dur` table: the value is
   a small per-comp penalty-regime **code**, uniformly set per class — **3**
   for every F5J comp, **1** for every F3J comp, **2** for the Elec comp,
   **0** for the ALES/Thermal/F3B/F3L/F3K comps — not a numeric penalty
   magnitude and not the per-flight `Scores.Penalty` (100/300). It has no
   Soar option; imported-flight penalties come solely from
   `Scores.Penalty` and the reference-height fields (§5.5.4). Decision: kept
   in `raw_components` as provenance, no effect on imported scores.
10. **`Retired` effective round (resolved from the reference file).** Retired
    pilots keep rows after retirement with `Updated = False`, so
    `retired_at_round` is the round after the pilot's last `Updated = True`
    flight (round 1 if none). Show the inferred round for confirmation; for
    the 33 retired pilots in the file the rule gives a clear round.
11. **`ModelData` (resolved, data-backed).** Meaning of the coded model data
    for `ContestModelLink.model_id`. Inspected `CompPilots.ModelData` in the
    reference database: **all 620 rows are `-1`**, so no model data to
    import. Decision: `-1`/empty -> null, `ContestModelLink.model_id` unset;
    if a future `.mdb` carries non-`-1` values, pass them through raw with a
    warning. Low priority.
12. **Re-flight and overlapping task mapping (product choices; persistence
    compatibility unresolved).** Preserve Q12-A1's draft description of
    subset re-flights as same-group `MoveToGroup`, but block persistence unless
    current capacity, role, and assignment invariants pass. Q12-B1 governs
    duplicate task-number handling; it does not establish a valid Soar matrix
    revision chain for partial overlaps. Define a valid extension/tail-redraw
    projection or block the affected comp; do not apply “later task wins” by
    superseding only overlapping rounds when that violates matrix invariants.
13. **`OriginalRoundNo` moves (product choice; persistence blocked).** Preserve
    the decision to represent the flight in the actual flight round, credited
    to `OriginalRoundNo`, without fabricating `Moved` rows or synthetic source
    slots. This conflicts with the current `Original` invariant, which requires
    scheduled and credited rounds to match. Such rows remain draft-only and
    block persistence of the affected comp until Persistence Compatibility specifies a supported
    historical representation. Score equivalence must be demonstrated after
    that representation is defined.
14. **Scorer identity (resolved).** `Helper` ids cannot resolve to Soar
    accounts. Imports use `Helper` only as raw provenance. Attempts are
    filed under the importing director with authority `Director` (§5.5.4),
    keeping Soar's director/local-operator actor model intact.
15. **Landing table selection, units, and key exactness (resolved from the reference DB).**
    The contest's own GS table is not imported by default. Each comp's distinct non-zero
    `Scores.Landing` values are matched against the candidates the discipline
    offers (its system default, any other shipped table, then the comp's own
    reconstructed `LndgPoints` table); the match is exact, and a candidate
    wins only if every value resolves to a unique entry (shipped distance
    tables' catch-all `over_*m` / 0 entries also match). The value encoding is
    table-specific: distance tables resolve metres, while point-entry tables
    resolve entered points. Key resolution alone is insufficient: for every
    observed value, compare the effective points awarded by the candidate with
    the source table's `LndgPoints.Points`.
    If the source encoding does not establish whether a value is distance or
    entered points, or multiple candidates match keys but award different
    points, mark the match ambiguous and require review; do not claim an exact
    semantic match. System tables are
    preferred over the custom one when both match; on a partial match the
    best candidate is pinned and non-matching rows warn (0 landing, Q17 delta
    surfaces divergence). Units need no separate rule — the match decides
    them; the reconstructed table uses `meters` or `points` according to the
    selected GS table, never from the `Distance` column name alone.
16. **`FlightScoreDeduction` (resolved, corrected).** For F5J this field is the
    **launch height in metres**, not a baked-in deduction. With the decoded
    time, the landing points, the height penalty (0.5 pt/m up to
    `durRefHeight`, 3 pt/m above, the `Dur` settings) and `Scores.Penalty`,
    all 2,648 scored F5J rows of the reference file reproduce `RawScore`
    exactly (the earlier OLS coefficient of about -0.56 was this piecewise
    penalty seen through a linear fit). Soar's F5J profile requires
    `launch_height` and computes the penalty itself, so map
    `FlightScoreDeduction` to `launch_height`. Dropping it, as the first draft
    proposed, would remove the penalty from every F5J flight. For other
    classes the field means something else (F3J: a point deduction), so its
    meaning depends on the class. `Penalty` (100/300) maps to `flight_penalty`
    as before.
17. **Validation report (score deltas are review-only; selection evidence
    unresolved).** GS `RawScore` / `NormalisedScore` vs the Soar
    calculator: the imported configuration is an approximation, so score
    deltas are review information and do not by themselves fail import.
    Selection comparison is made only when GS's counted flight is established
    independently; otherwise selection is unknown and group delta is not
    assessable. Structural and semantic blockers in the persistence
    compatibility section below still prevent persistence of affected data.
18. **Timestamps (resolved).** No import-time source for most `*_at` fields.
    Decision: use the import instant, noted in the draft.

## Persistence Compatibility

This section separates product mapping decisions from what the current Soar
Score entities can represent. A mapping decision does not waive entity
invariants. Until each blocker below has a documented resolution, the mapper
may produce a reviewable draft, but persistence must reject the affected
contest/flight with an actionable explanation rather than silently coercing,
dropping, or fabricating history.

### Flight placement and sequence

- **Moved credit (`OriginalRoundNo`).** One row in the whole reference file
  (comp 4, DurGeneral, round 13 credited to 12) and none in any F5J comp.
  Current `Original` requires scheduled and credited rounds to match, so a
  comp with such a row is refused (or that flight is) with a reason until an
  import-compatible historical representation is specified. Do not invent a
  source assignment or change the credited round to make the row fit.
- **Flight sequence and original assignments.** Resolved: `Scores.SeqNo` is the
  pilot's slot in the group (1..n, identical across re-flight rows), not an
  attempt counter. It maps to no `flight_sequence` (an `Original` is
  sequence 1); keep it as provenance.
- **Task revisions.** Not observed for any mappable class in the reference
  file: only comp 3 (F3B, skipped) has several tasks. `TaskNo` is per comp in
  practice (35 of 37 comps), not a global id. Keep the refusal rule: a file
  with partially overlapping or gapped task ranges is refused for that comp
  with a reason, and no projection is built until a real file needs one.
- **Unobserved matrix entries.** Superseded: `Scores` holds a row for every
  drawn flight, with `Updated = False` while unscored, so the matrix is the
  full draw, not a lower bound. Use the observed groups per round; the
  configured `*GroupsPerRound` can be stale (7 comps in the reference file).
  Build the groups and assignments from all rows, scored or not.

### Re-flight lifecycle and result semantics

- `ReFlightParticipant.role` is scoring-significant. Decided (Mike,
  2026-10-23): a pilot with no score in the original flight is `Awarded`;
  every other pilot of the re-flown group is `GroupMember`. GS stores no
  "granted" field, so the importer applies this rule and lists the roles in
  the review warnings. All three F5J re-flights in the reference file
  (comp 21 round 8 group 2, comp 22 round 2 group 2) are whole-group
  re-flights.
- Whole-group re-flights need a post-regular group under current Soar rules;
  GS's same-group number cannot be copied there without changing the source
  history. This representation decision (D5) remains open and blocks affected
  re-flights until resolved. Subset (`MoveToGroup`) re-flights are not
  observed in the reference file for any mappable class; keep the refusal
  rule for files that have them.
- The validation report uses the counted-flight rule in Which GS Flight Counts.

### Score facts and persistence pathway

- Zero outcomes follow a precedence table, now backed by the reference file
  (`Updated` is `False` for a drawn, unscored flight):
  1. `Updated = False`: pending `ScorePlaceholder`, no attempt, no official
     score. Not a zero outcome.
  2. `F5JMotorReStarted = 1` and the comp's restart option is 1 or 2: zero with
     reason `motor_restart` (components may be stored beside the flag; Soar's
     calculator ignores them). Option NULL (oldest comps): the flag never
     zeroed the flight; import the recorded score and keep the flag as
     provenance with a warning.
  3. `Updated = True` with no time, landing or height: explicit zero. GS gives
     no reason (did not launch, crash); use one documented
     import-approximation reason, marked as such.
  4. `Updated = True` with time and height recorded and `RawScore = 0`: the
     height penalty exceeded the flight score and the floor produced 0;
     import the components and let the calculator reproduce the zero.
     Reference file, F5J: 863 placeholders, 187 explicit zeros, 69 restart zeros,
     4 floored zeros.

- Specify whether import uses normal score acceptance and officialization or
  a dedicated import pathway. Give the exact record sequence and values for
  `ScoreAttempt.base_score_revision`, placeholder `score_revision` and
  `state`, and `OfficialScore.score_revision`. The accepted attempt increments
  the placeholder revision; officialization increments it again and the
  OfficialScore takes that resulting revision. If an import pathway differs,
  document how it preserves these invariants, append-only facts, actor
  attribution, audit events, and transaction boundaries.
- `client_mutation_id` only deduplicates a retry when the same stable import
  identity is reused. This design mints fresh entity IDs per draft and does
  not define re-import matching. Scope the key to an import operation and
  source flight, state that it protects retries of that operation only, and do
  not claim that rerunning the import deduplicates existing contests, profiles,
  or scores.

### Profile, role, configuration, and lifecycle scope

- Create `ParticipantProfile` drafts only for pilots referenced by
  participations in mappable comps, unless a deliberate whole-roster import
  is approved. Pilots found only in skipped comps or unused in all imported
  comps should not be silently added to the director's profile collection.
- Pin the exact `DisciplineProfile` version used by each
  `ContestConfigurationRevision`. Define whether the mapper selects the
  current published system version or a version matching the observed config;
  fail or require review if no compatible profile exists. A discipline type
  alone is not a sufficient persisted reference.
- Confirm profile ownership and `owner_account_id` behavior for offline/local
  imports and imported participants. Define how system roles are reused and
  how director-owned roles satisfy the role owner invariant. For GS composite
  roles that cannot map to one role, retain the raw source value and expose
  the degraded role in review rather than presenting the fallback Pilot role
  as exact.
- Imported contests keep an honest lifecycle state. The reference file shows
  most comps are not finished: 21 of the 30 mappable comps have drawn but
  unscored rows (whole future rounds, retired pilots' later rounds, pilots who
  did not fly), and only 8 are fully scored. A comp is `Completed` only when
  no non-retired pilot has an unscored row, through a documented
  import-specific transition and audit event; otherwise it imports in the
  state the lifecycle allows for "rounds remain". If the model has no
  supported import transition, persistence is blocked.

### Landing equivalence and validation statuses

- A landing candidate is an exact semantic match only when each observed
  non-zero source value resolves uniquely and the candidate awards the same
  points as the corresponding GS `LndgPoints` mapping. Matching string keys
  alone is insufficient. If GS values encode distance in one case and entered
  points in another, establish the encoding from the source table and data;
  if candidates share keys but award different points, mark the match
  ambiguous and require review. A partial fallback may still be offered, but
  must not be described as an exact match.
- Keep raw-score comparison independent of landing/selection claims. Use
  separate mapping, raw-score, group-score, and selection statuses. Use
  `selection_unknown` and `group_not_assessable` where the GS comparison target
  cannot be established. Define `match` as exact zero for an individual
  comparison and `delta_within_tolerance` as nonzero but within tolerance;
  unavailable comparisons are null, not zero. Tolerances remain provisional
  until the reference-DB run establishes source precision and expected
  rounding.

## Validation Report: GS-vs-Soar Score Delta

The persistence step (follow-up checkpoint 3) runs the Soar calculator — the
standing pipeline over the drafted contest: official components, the imported
configuration, and the discipline —
and produces a review report comparing what the calculator says with what
GliderScore already recorded. The report is **review information, not a gate**
for score deltas: a red row alone never blocks persisting the draft. Structural
mapping conflicts and unresolved source semantics in Persistence Compatibility
are separate from score deltas and can block persistence of the affected comp
or flight.

### Comparison Targets

For every imported comp, and every flight the Soar calculator produces a
`FlightResult` for:

| Check               | GS side (from `raw_components` of the official score)                                                                                    | Soar side (the recomputed `FlightResult`)                                    |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Raw score delta     | `RawScore` of the same flight, as recorded (F5J: exactly reproducible, so the delta is expected to be 0; see Known Approximation Causes) | `raw_points`                                                                 |
| Group score delta   | `NormalisedScore` of the independently established GS-counted flight (see Which GS Flight Counts), or not assessable                     | `group_score` of the Soar-selected flight for that credited round and pilot  |
| Selection agreement | independently established GS-counted flight (see Which GS Flight Counts), or unknown                                                     | the flight with `is_selected: true` for the same pilot and credited round    |
| Landing consistency | the raw `Landing` value and the pinned table's resolution for that row (§5.5.6)                                                          | `landing_points`, and null when the row resolved to no landing (warning row) |

The two score deltas are tracked separately because they fail for different
reasons: `raw_delta` tracks the per-flight scoring approximation,
`group_delta` additionally tracks any divergence in the normalization
population (re-flights in the group, retired pilots).

### Tolerance Bands and Status

For F5J the raw score is exactly reproducible (Q16), so a non-zero raw delta
is a mapping bug. For F3J, Thermal and ALES the configuration import is an
approximation until their rules are mapped, so raw exactness is not yet the
bar. Each row gets separate `mappingStatus`, `rawStatus`, `groupStatus`,
and `selectionStatus` values. Apply the first matching rule independently to
the raw and group comparisons:

- `mappingStatus: blocked` — unresolved structural or semantic conflict from
  Persistence Compatibility; do not calculate score statuses for blocked data.
  Otherwise `mappingStatus: ready`.
- `rawStatus` / `groupStatus: calculator_error` — the standing run failed for
  that comparison; render the error with the row.
- `rawStatus` / `groupStatus: no_result` — an imported `Scores` row with
  official components has no current `FlightResult` (for example, a superseded
  task-overlap row if a valid revision projection exists).
- `rawStatus` / `groupStatus: missing_target` — Soar produced a result for a
  credited round with no GS `Scores` row (a Soar-only round or miskeyed row).
- `groupStatus: not_assessable` — no independently established GS-counted
  flight supplies the group-score target; `groupDelta` is null, not zero.
- `rawStatus` / `groupStatus: match` — that comparison's delta is exactly 0.
- `rawStatus` / `groupStatus: delta_within_tolerance` — that comparison's
  delta is nonzero but within its tolerance.
- `rawStatus` / `groupStatus: large_delta` — that comparison's absolute delta
  exceeds its tolerance.
- `selectionStatus: agrees` — Soar and independently established GS selection
  identify the same flight, or there was only one GS flight.
- `selectionStatus: mismatch` — Soar's selected flight differs from an
  independently established GS-counted flight.
- `selectionStatus: unknown` — multiple GS flights exist and independent
  evidence does not establish which one counted.

Tolerance values (proposed defaults, owned by the wizard/persistence step):

- `rawTol = 0.005` for F5J. The reference-file run reproduced every scored F5J
  `RawScore` exactly, so any F5J raw delta above rounding is a mapping bug.
  Other disciplines keep their own provisional tolerance until their rules
  are mapped.
- `groupTol` = one unit in the last displayed decimal place of
  `GroupScoreDecimals`; both sides round once.

Rationale: GS `RawScore` is flight time capped at working time, plus landing
points, minus the F5J height penalty, minus `Scores.Penalty`, floored at 0;
Soar `raw_points` is the same recipe, so a fixed point tolerance is stable.

### Which GS Flight Counts

GliderScore records no explicit per-flight counted flag, but the rule is known
(Mike, 2026-10-23): for a re-flown group the pilot the re-flight was granted
for gets the re-flight score, and every other pilot in that group gets the
better of the two flights, which is Soar's `Awarded` / `GroupMember` rule.
The granted pilot is not recorded in GS; the importer treats a pilot with no
score in the original flight as `Awarded` and everyone else in the group as
`GroupMember`, and lists the assignments in the review warnings. For a credited
round with one flight, that row is the only candidate. The counted-flight
target for the group-score comparison is therefore known and the selection
status is `agrees` / `mismatch`, not `unknown`, whenever the roles above are
used (the roles are an inference, so a mismatch in a re-flown group is first
suspected as a role mistake). Each flight set normalises on its own
(`NormalisedScore = RawScore / max RawScore in the set * 1000`, true on all
4,525 mappable rows of the reference file with group score option 1).

### Row Shape

Universe: one row per imported `Scores` flight (including rows that were
superseded under Q12 and so have no current Soar result) plus one row per
Soar-selected result with no GS row (status `missing_target`). Rows are keyed
and sorted by the Soar assignment so two report runs over the same file are
diffable:

```
compNo, taskNo, roundNo(group of the credited round), groupNo,
pilotNo, seqNo, reFlightNo,            // source key, same as client_mutation_id
gsRawScore, gsNormalizedScore,         // raw_components of the official score
gsCounted,                             // true/false only with independent evidence; otherwise null
soarSelected,                          // FlightResult.is_selected for the pilot's credited round
rawDelta, groupDelta,                 // signed, Soar − GS; groupDelta null when not assessable
landingRaw, landingResolved,          // raw GS value, table entry key or null (warning row)
warnings,                              // mapping warnings attached to this flight (§5.5.4/§5.5.6)
mappingStatus, rawStatus, groupStatus, selectionStatus // independent outcomes; null deltas are not zero
```

An unflown retirement — a pilot with no `Scores` row and no Soar flight for
a round — is not a row: there is nothing on either side to compare. A
comp-level note records "N pilots unflown in round R; no GS counterpart".

### Summary Sections

- **Per comp:** flights checked, raw/group status counts for `match` /
  `delta_within_tolerance` / `large_delta` / `no_result` /
  `calculator_error` / `missing_target` / `not_assessable`, plus selection
  counts for `agrees` / `mismatch` / `unknown` and mapping counts for
  `ready` / `blocked`. Also show mean and max `|raw_delta|` and
  `|group_delta|` over assessable rows, the worst flight per delta, and the
  pinned landing table with its match outcome (§5.5.6: semantic exact match,
  catch-all only, partial match, or ambiguous).
- **Global (file):** the same aggregates across every persistable mappable comp, a
  per-discipline breakdown (F5J / F3J / ALES / ThermalDuration), and a top-10
  by `|raw_delta|` list so the director can jump straight to the outliers.

The report is rendered in the wizard's review screen together with the draft
and its `warnings` list, and is exportable as JSON (schema `gs-validation/v1`)
for the director's records. The report is not a stored entity in this design:
a future persistence step may keep a copy alongside the import metadata if
the director asks for it.

### Known Approximation Causes

Revised after the reference-file run (see findings.md): for F5J
the raw score is exactly reproducible. Decoded time (packed `M:SS`), the
landing points, `FlightScoreDeduction` as launch height under the 0.5 / 3
points-per-metre penalty, and `Scores.Penalty` reproduce `RawScore` on all
2,648 scored F5J rows. A non-zero F5J raw delta is therefore a mapping bug,
not an approximation. Deltas are expected only for (1) F3J, Thermal and ALES
rows, whose over-time and deduction rules differ and belong to the discipline
tickets, (2) landing rows resolved to no landing by the partial-match
fallback, (3) group deltas where the group carried re-flights or a retired
pilot (normalization population), and (4) a genuinely wrong mapping (comp
class, config field, or time decoding).

## 8. What this is not

- **Persistence.** No repository writes, sync/audit events, or actor
  resolution beyond the importing director. The draft is not yet a persistence
  contract; the compatibility blockers above must be resolved first.
- **Wizard UI**, routing, rail entry, and per-comp selection (the mapper can
  filter by `CompNo`; the service's existing table subset argument does not
  filter comps).
- **Re-import behavior** (profile dedupe, contest matching, conflict
  handling) — a follow-up design.
- **Hosted/web availability.** Like the backend, native Windows only.
- **Out-of-scope classes** (F5B, Spd, Elec, and unimplemented F3L/F3K):
  their comps appear in the draft only as skipped entries with reasons.

## 9. Follow-up checkpoints

1. Resolve the Persistence Compatibility blockers before implementing
   persistence: moved-flight representation, task-to-revision projection,
   re-flight roles/groups/capacity, score revision workflow, zero outcomes,
   exact profile version, and import lifecycle/audit path.
2. Validate independent GliderScore selection and landing semantics against
   the reference database; retain unknown/not-assessable report states where
   source evidence is insufficient.
3. Write the persistence step consuming this draft (repositories, audit
   events, supported lifecycle transition), with the calculator recompute
   and GS-vs-Soar delta report as review information.
