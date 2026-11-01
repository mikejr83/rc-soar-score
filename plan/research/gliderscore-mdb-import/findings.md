# GliderScore reference database: findings

Analysed `GliderScoreData.mdb` (uploaded by Mike, 2026-10-23) with the same mdbtools the app bundles (every table exported to JSON lines, analysed with Python). Companion to [mapping-plan.md](mapping-plan.md). No personal data is quoted here.

## 0. This is not the file the plan was written against

|                                  | Plan's reference file                                                        | File analysed                                                                             |
| -------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Comps / Scores rows / CompPilots | 37 / 6,522 / 620                                                             | 38 / 6,584 / 651                                                                          |
| Tables                           | backend plan says 26, mapping plan says 28                                   | 26 (backend plan is right)                                                                |
| `Pilots` columns                 | adds `State`, `Email`, `FAI_ID`, `OtherRegistration`                         | only PilotNo, Country, FAINumber, UsualClass, Filter, FirstName, LastName                 |
| Classes                          | F5J 23, F3J 3, DurGeneral 3, DurALES 1, plus F3B 2, F3K, F3L, F5B, Spd, Elec | same, plus one **F5L** comp (class not in the plan's table; "asdf", 62 rows, none scored) |
| `DBParams`                       | n/a                                                                          | DBVersion 6.78                                                                            |

Same 30 mappable comps (23 F5J, 3 F3J, 3 DurGeneral, 1 ALES), 523 participations. Two practical consequences: the mapper must tolerate **absent columns** (older or newer GliderScore versions differ), and `F5L` must be added to the class table as skipped. Comp 39 is a test comp ("Test", 270 rows, nothing scored) and is useful as the "drawn, nothing flown" fixture.

## 1. Findings that change the design

### 1.1 Times are packed `M:SS`, not minutes and seconds (plan is wrong)

For F5J, F3J, DurGeneral and ALES, `Time1Mins` holds the whole flight time packed as minutes*100 + seconds (for example `958` is 9:58, `1450` is 14:50) and `Time1Secs`, `Time2Mins`, `Time2Secs` are 0. Only F3B, F3K and F5B rows use the second timer and `Time1Secs`. With a timing-decimals setting above 0, the value carries a fraction (`952.4` is 9:52.4). Plan section 5.5.4 says "primary duration = first nonzero pair, mins*60+secs"; that would turn 958 into 57,480 s. Decode with `(v ~/ 100) * 60 + (v % 100)`.

### 1.2 `FlightScoreDeduction` is the F5J launch height in metres, and it is the penalty input (Q16 is wrong)

Using the decoded time, the comp's landing table, and a height penalty of 0.5 pt/m up to the reference height and 3 pt/m above it (exactly the `Dur` settings: ref 200, 0.5, 3), **all 2,648 scored F5J rows reproduce GS `RawScore` exactly**:

`raw = max(0, min(time, working_time) + landing_points - height_penalty(FlightScoreDeduction) - Penalty)`

The values (1 to 340 m) are launch heights, and the four F5J rows with raw 0 and a recorded time are rows where the height penalty exceeds the flight score (floored at 0). The plan's OLS coefficient of about -0.56 was the 0.5/3 piecewise penalty seen through a linear fit. The plan decided to keep it as provenance only so Soar would not "double-apply" it. That is backwards: Soar's F5J profile **requires** `launch_height` (int, metres) and computes the penalty itself (`f5j_profile.dart`), so dropping it removes the penalty from every F5J flight and the recompute would be wrong by up to hundreds of points. Map `FlightScoreDeduction` to `launch_height`.

Consequence for validation: for F5J the raw-score delta should be exactly 0 on every row, not "expected to absorb the deduction". The plan's tolerance reasoning (`rawTol`) can be tightened, and any non-zero F5J raw delta is a real mapping bug.

Other classes (not mapped by this check): F3J, DurGeneral and ALES rows do not match the F5J formula and use their own over-time or deduction rules (for example DurGeneral and ALES lose about 1 point per second over the target time; the F3J rows with deduction 30 come out exactly 30 below flight plus landing). Those rules belong to the discipline tickets, but they confirm `FlightScoreDeduction` is not a single universal field; its meaning depends on the class.

### 1.3 `Updated = False` rows are the draw, so GliderScore does keep the matrix (plan is wrong)

The plan says there is no draw table and the matrix is a lower bound reconstructed from scored rows. In fact `Scores` holds a row for every drawn flight, with `Updated = 'False'` and no data until it is scored:

- 863 F5J rows (and 13 ALES) are `Updated False`, none carries any time, landing or score.
- Whole future rounds exist as unscored rows (comp 39: all 10 rounds; comp 37: rounds 6 to 8; comp 22: rounds 13 to 15).
- Retired pilots keep their rows after retirement as `Updated False` (184 rows), so the retirement round is recoverable: the round after the pilot's last `Updated True` flight.
- The plan treats `Updated` as a "GS re-entry marker, last row wins". It is not. Duplicate keys: none in this file.

So: every `Updated False` row becomes a `MatrixAssignment` plus a pending `ScorePlaceholder` with no attempt and no official score, and an `Updated True` row becomes a scored flight. This removes the "lower bound, don't fabricate assignments" caveat for most comps, resolves the empty-groups problem, and decides the zero-outcome question below. It also means most imported comps are **not complete**: of the 30 mappable comps, 21 have unscored rows, 1 (comp 11) has no score rows at all, and only 8 (comps 1, 2, 4, 10, 12, 20, 21, 26) are fully scored; two more (29, 36) are complete except for retired pilots. So "import as Completed" (D8) would be wrong for most. The honest state is whatever the contest lifecycle allows for "rounds remain" (Running), and only comps with no unscored non-retired rows are Completed.

### 1.4 Zero outcomes: there is a usable rule

Of 1,123 F5J rows with `RawScore = 0`:

| Rows | Evidence                                                | Soar outcome                                                    |
| ---- | ------------------------------------------------------- | --------------------------------------------------------------- |
| 863  | `Updated False`, no data                                | Pending placeholder (not a score)                               |
| 187  | `Updated True`, no data                                 | Scored zero; no reason in GS (did not launch, crash, and so on) |
| 69   | `F5JMotorReStarted = 1`                                 | Zero with reason `motor_restart`                                |
| 4    | time and height recorded, penalty larger than the score | Not a zero outcome: re-derive and let the floor produce 0       |

(The setting is `Dur.F5JMotorRestartOption`, per comp: 2 in 14 comps, 1 in comps 35 and 39, 0 in comp 22, NULL in the six oldest comps. The 11 non-zero flagged rows are exactly comps 15 and 16, which have no option (NULL, from before GS had the setting). Every flagged row in a comp with value 1 or 2 is zero. Mapping to Soar's `motor_restart_mode`: GS has three modes (Mike): Not Allowed, Allowed with zero not droppable, Allowed with zero droppable. Likely values in that order: 0 = not allowed (comp 22 has no flags), 1 = non-droppable (comps 35, 39), 2 = droppable (14 comps); CONFIRMED by Mike (2026-10-23): 0 = Not Allowed (comp 22), 1 = Allowed, zero cannot be dropped (comps 35, 39), so 2 = Allowed, zero can be dropped. Soar: 0 to `not_allowed`, 1 to `non_droppable`, 2 to `allowed`; empty to flag kept as provenance only. NULL means the flag never zeroed the flight: import those comps with the flag kept as provenance, not applied. Mike's rule: the flag takes precedence over the components, and Soar can store the components alongside it.)

### 1.5 `SeqNo` is the pilot's slot in the group, not an attempt counter (plan is wrong)

It runs 1..n within a group, is identical for a pilot's original and re-flight rows, and has gaps and a few repeats (32 of 1,004 groups). The plan's "GS numbers attempts 1..n per (group, pilot); re-flights take the next sequence" is false. Map it to nothing in `flight_sequence` (an `Original` must be 1 anyway), keep it as provenance. It may be worth testing it as a draw slot or lane order later; for the comps with lanes it never exceeds the lane count by much (comps 15, 16: max 7, 6 on 6 lanes), so it is not the lane.

### 1.6 `TaskNo` is not global; task overlap does not occur for mappable classes

35 of 37 comps use a `TaskNo` different from their `CompNo`, and most comps simply use `TaskNo = 1`. Only comp 3 has several tasks (1, 2, 3, rounds overlapping), and that comp is F3B, which is skipped. The plan's description ("TaskNo is a global identifier, most single-task comps carry their own CompNo") is wrong for this file, and the task-overlap blocker (D4) does not arise for any mappable comp here. Keep the refusal rule for files that do have it; do not build the projection.

### 1.7 Re-flights: present in F5J, all whole-group

Re-flights occur in F5J comps 21 and 22 (12 rows: comp 21 round 8 group 2, comp 22 round 2 group 2; the other 8 in F3B and Elec comps). All are **complete re-flights of the whole group**, `ReFlightNo = 1`, same `GroupNo`, same pilots, same `SeqNo`. Each re-flight set is normalised on its own (`NormalisedScore = raw / max raw in the set * 1000`; this holds for all 4,525 mappable rows with group score option 1). One pilot's re-flight row repeats the original flight exactly (same time, landing, height), which means a pilot who did not re-fly is carried over, so the re-flight set is a complete replacement set. That is circumstantial evidence the re-flight set counts, not proof. Mike's rule (2026-10-23): the pilot the re-flight was granted for gets the re-flight score, and every other pilot in the group gets the better of the two. That matches Soar's `Awarded` / `GroupMember` roles, so the replacement reading above was wrong. GS stores no field saying who was granted the re-flight. The only hint is the original flight: in all three F5J re-flight groups the pilots whose original has no score (comp 22 round 2 group 2: pilots 76 and 92; comp 21 round 8 group 2: pilot 116) are the likely awarded ones, since a re-flight is normally granted for a flight that did not count. The others (for example pilot 81, 520 originally and 0 on the re-flight) would keep the better score under Mike's rule. **Decided by Mike (2026-10-23): the inference is accepted.** A pilot with no score in the original flight is `Awarded` (the re-flight score is theirs); every other pilot in the re-flown group is `GroupMember` (better of the two). The importer applies this rule and lists the assignments in the review warnings, no per-pilot confirmation step. The mismatch against GS `NormalisedScore` cannot test it, because each set is normalised separately. **Confirmed by Mike against GliderScore (comps 21 and 22): the higher score stands for pilots not granted the re-flight.**

The consequence for D5: no subset (`MoveToGroup`) re-flights exist in the F5J data, only whole-group ones, so the alpha can implement `ReflyEntireGroup` (the GS group number conflicts with Soar's "post-regular group", which still needs the decision) and refuse subset re-flights.

### 1.8 Moved flights: one row in the whole file

Only one `Scores` row has `OriginalRoundNo` different from `RoundNo` (comp 4, DurGeneral, round 13 credited to 12). No F5J comp has any. D1 is a non-issue for the alpha: refuse such comps (or flights) with a reason.

### 1.9 Landing: everything resolves, and almost all of it is the system table

All landing values in all 30 mappable comps resolve against that comp's own table (0 unresolved):

- 22 of 23 F5J comps use `LndgNo 9` ("F5J Enter Points", keys 5, 10, ... 50), the same as Soar's F5J Standard Landing Table (points entered directly). Comp 10 uses `LndgNo 5` (distance 1 to 10 m, 50 down to 5 points), the same as the F5J Distance Table. The ALES comp also uses `LndgNo 9`.
- F3J comps use `LndgNo 2` (distance) or `3` (points); DurGeneral comps use 2, 3 and 6.
- Comp 12 (DurGeneral, "ALES Landing", distance 1 to 10 m) and comp 2 (distance table) have no Soar system equivalent for Thermal, so they need the reconstructed table.

**Entry keys differ from the plan.** The plan reconstructs `entry_key` as the distance string ("7.4"). Soar's system tables use keys such as `points_50`, `within_7m`, `over_10m`. Matching therefore has to go GS value to points to Soar entry by input unit, not by key string equality. Encoding is determined by the table's name and unit exactly as the plan says, and the data confirms it (points tables store the points as the landing value).

### 1.10 Roles, teams, models, countries

- All 651 `CompPilots` rows are role `Plt` and `IsPilot = 1`; no helpers, directors or composite roles in this file (keep the rules, they cost nothing).
- Teams: 9 comps use teams; 400 rows have `Team = 0`. No team names (confirms the plan).
- Models: `ModelData` is `-1` on every row (confirms Q11); 635 rows have a `Model` name, so model names are importable.
- `StartNo = 0` on only 16 rows; participant numbering is mostly populated.
- Countries are 3-letter codes (USA 77, AUS 69, NZL, CAN) and 10 pilots have none; `FAINumber` is "0" everywhere in this file. The 3-letter to Soar country format question stands.
- Group counts: `durGroupsPerRound` is stale in 7 comps (configured fewer groups than the draw has: comp 1 says 4 and has 5, comp 21 says 2 and has 3, comp 26 says 1 and has 2, others similar). Always take the observed draw; the "configured count wins, create empty groups" rule would be wrong.
- Zeros and landing aside, `GroupScoreOption 1` was used by every mappable comp except two (`2`: one DurGeneral, the ALES comp). I did not test option 2.

## 2. Open questions: answered, partly answered, still open

| Question                                                      | Status                                                                                                                                                                                                                                                                       |
| ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Time encoding                                                 | Answered: packed `M:SS` (1.1)                                                                                                                                                                                                                                                |
| `FlightScoreDeduction` meaning                                | Answered: launch height, reproduces `RawScore` exactly for F5J (1.2)                                                                                                                                                                                                         |
| Does GS keep the draw                                         | Answered: yes, as `Updated False` rows (1.3)                                                                                                                                                                                                                                 |
| Zero-outcome classifier                                       | Mostly answered (1.4); the 187 reasonless explicit zeros need one approximation reason (D6)                                                                                                                                                                                  |
| `Retired` effective round                                     | Answered for this file: round after the last `Updated True` flight (1.3); pilots with no scored flights retire at round 1                                                                                                                                                    |
| Landing encoding and match                                    | Answered, all resolved (1.9); key scheme corrected                                                                                                                                                                                                                           |
| Which flight counts after a re-flight                         | Partly: circumstantial evidence the re-flight set replaces the original; **needs Mike's check in GS** (1.7)                                                                                                                                                                  |
| `motor_restart_mode` for imported comps                       | Answered in part: GS stores it per comp as `Dur.F5JMotorRestartOption` (I first missed it). Values: 2 in 14 comps, 1 in comps 35 and 39, 0 in comp 22, NULL in the six oldest comps (10, 15, 16, 18, 19, 21). Open: Mike to confirm which value is which Soar mode (see 1.4) |
| F3J, Thermal, ALES raw-score rules (over-time, F3J deduction) | Open, belongs to the discipline tickets                                                                                                                                                                                                                                      |
| Group score option 2 normalisation                            | Answered by Mike: the "Time" normalisation of the two ALES contests (comps 12, 23); rule detail goes to the discipline ticket                                                                                                                                                |

## 3. Documentation

`mapping-plan.md` was updated with these findings (sections 1, 4, 5.1 to 5.5, 7 Q10 and Q16, Persistence Compatibility and the validation report). Decisions taken with the product owner on 2026-10-23: re-flight roles, restart precedence and option mapping, whole-comp refusal for anything that cannot be mapped, and the validation report in the alpha.
