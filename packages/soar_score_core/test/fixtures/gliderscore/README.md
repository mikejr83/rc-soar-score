# GliderScore fixtures

Anonymised `gs-import/v1` snapshots for the pilot import tests (#697, part of
#696; single `Pilots` table) and the competition import tests (#744, part of
#742; `Comps`, `CompPilots`, `Pilots`, `Roles`, `Dur`, `DBParams`). Rows are shaped like the bundled `mdb-json`
writes them: a column that is null in the database is absent from the row.

| File                        | Purpose                                                                                                                                                                                 |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pilots_reference.json`     | Every pilot of a real GliderScore 6.78 file, scrubbed: 158 pilots, 74 of them `ZZ` test users, 21 with an email, none with a FAI number.                                                |
| `pilots_edge_cases.json`    | Hand-built rows for the mapper and matcher rules: same-name pilots, a shared email, real FAI and registration numbers, blanks, `ZZ` variants, missing names, IOC and unknown countries. |
| `pilots_old_columns.json`   | Twelve rows with only the older column set (no Email, State, FAI_ID, OtherRegistration).                                                                                                |
| `pilots_extra_columns.json` | Rows with columns the importer does not know about.                                                                                                                                     |

### Competition snapshots

| File                         | Purpose                                                                                                                                                                                                                                               |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `comps_reference.json`       | Real comps 22, 39 and 21 (F5J, 31/27/12 participants, comp 21 with four retired pilots), 20 (F3J) and 40 (F5L) as skipped classes, with their pilots, `Roles`, `Dur` rows and `DBVersion`.                                                            |
| `comps_edge_cases.json`      | Hand-built comps: 9001 with teams, team protection, all five drop slots, classes, models (same model with different case), numbering and a team manager; 9002 with retired pilots and every role; 9003 with no `Dur` row; 9004 with an unknown class. |
| `comps_integrity_cases.json` | Broken references the mapper must report: a duplicated `CompNo`, the same pilot twice in one competition, and a participant with no `Pilots` row.                                                                                                     |
| `comps_missing_columns.json` | Comp 22 reduced to its required columns (no `Roles`, no `DBParams`, no optional columns anywhere).                                                                                                                                                    |

### Draw snapshots (phase C, #768)

| File                    | Purpose                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `draws_reference.json`  | Real F5J comps 15, 21, 26, 28 and 39 with their `Scores` rows (806 rows, the drawn flights whether scored or not), `Comps`, `CompPilots`, `Pilots`, `Roles`, `Dur` and `DBParams`. **15**: lane count 6, a group of 7 pilots, gaps in `SeqNo`, retired pilots, unscored rounds. **21**: lane count 0, gaps in `SeqNo`, unequal groups, re-flights, retired pilots, scored and unscored rows (kept for phase D). **26**: configured groups per round (1) differ from the 2 groups drawn. **28**: trailing rounds drawn but not flown. **39**: a pure draw, nothing scored. |
| `draws_edge_cases.json` | Hand-built comp 9201 (four pilots, two rounds): round 2 holds a flight drawn in round 2 but credited to round 1 (`OriginalRoundNo` differs), which the importer refuses.                                                                                                                                                                                                                                                                                                                                                                                                  |

### Score snapshots (phase D, #768)

| File                     | Purpose                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scores_reference.json`  | Real F5J comps 35, 29, 16 and 19 (360 `Scores` rows) with `LndgNames` and `LndgPoints` for the tables they use. **35**: restart option 1, three restart zeros, a retired pilot, one unscored flight in every round, an unflown last round. **29**: restart option 2, restart zeros and a floored zero (time and height recorded, raw score 0), all-zero flights. **16**: restart option NULL with a flagged flight that kept its score, partly flown rounds. **19**: partly flown rounds, six pilots, one group. Comps 15 (restart NULL with ten flagged flights), 21 (re-flights, retired pilots), 22, 28 (trailing unflown rounds) are in the draw snapshots. |
| `scores_edge_cases.json` | Hand-built: 9301 has a landing value (7) that matches nothing in table 9 (partial match); 9302 uses a table only the competition has (reconstructed) and a retired pilot who never scored; 9303 re-flies two pilots of a group of four (a subset, refused); 9304 has two tasks whose rounds overlap (refused); 9305 uses landing table 5 (distance).                                                                                                                                                                                                                                                                                                            |
| `reimport_v1.json`       | Comp 19 early: rounds 1 and 2 scored, round 3 drawn but unscored.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `reimport_v2.json`       | Comp 19 later: round 3 scored, one landing corrected (round 1, pilot 109: 50 to 45, raw score 5 lower; group scores are not recomputed) and one pilot added. Same `CompID`, so it is the same competition.                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `reimport_v1_copy.json`  | The content of `reimport_v1.json` from another file (different snapshot id and file name): an import of it changes nothing.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

**Size ceiling:** all snapshots together stay under 900 KB (now about 750 KB; the score snapshots are about 285 KB of it). `scores_reference.json` is the largest; adding a competition means dropping another.

**Local comparison against the full file (not committed).** The real `.mdb` stays out of the repository. To run the importer's comparison over every competition of your own file:

1. Export the tables as above (`Scores`, `LndgNames`, `LndgPoints`, the competition tables) with `mdb-json`.
2. Run `dart run packages/soar_score_core/tool/gs_compare.dart <dir with the .jsonl files>`. It maps every importable competition with the restore mapper, runs Soar's calculator and prints, per competition, the number of flights compared and the first mismatches against `RawScore`. It reads only; nothing is written.

`Scores` holds numbers and the True/False `Updated` flag only; the scrubber checks the shape of every value, carries only an allowlist of columns and aborts on anything else. Rows of `Scores` are written one per line to keep the file reviewable. **Size ceiling:** the draw snapshots stay under 500 KB in total (now about 345 KB); adding a competition means dropping another.

`Roles` and `DBParams` are never copied: the scrubber checks them against the six known roles and a `DBVersion` number and emits fixed rows, and aborts when they differ. It also names (not shows) any source column it drops.

The real file has no F5J competition with teams and only plain pilots, which
is why the edge cases are hand-built. Competition and venue names, comp ids and
model names are replaced with fakes (`Fixture Open N`, `Example Field`,
`Example Model N`); the rest of a comp row is codes and flags and is kept.

## How they were made

`scripts/scrub_gliderscore_pilots.dart` reads the `Pilots` table exported with
`mdb-json` and writes these files. Names come from fixed pools (the same pilot
number always gets the same fake name; test users keep their `ZZ` prefix),
emails become `fixtureN@example.test`, and everything else that is not
identifying (country, state, class, filter flag, the `"0"` registration
placeholders) is kept. The script refuses to write if any original first name,
last name or email would appear in the output. No real personal data is
committed; the source database stays out of the repository.

For competitions, export `Comps`, `CompPilots`, `Roles`, `Dur` and `DBParams` with `mdb-json` into one directory and pass it as the third argument. For the draw snapshots add `mdb-json GliderScoreData.mdb Scores > comps/Scores.jsonl` to the same directory. Regenerate with the steps at the top of the script. The output is deterministic.
