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
| `comps_missing_columns.json` | Comp 22 reduced to its required columns (no `Roles`, no `DBParams`, no optional columns anywhere).                                                                                                                                                    |

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

For competitions, export `Comps`, `CompPilots`, `Roles`, `Dur` and `DBParams` with `mdb-json` into one directory and pass it as the third argument. Regenerate with the steps at the top of the script. The output is deterministic.
