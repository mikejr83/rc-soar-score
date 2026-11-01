# GliderScore pilot fixtures

Anonymised `gs-import/v1` snapshots with a single `Pilots` table, for the pilot
import tests (#697, part of #696). Rows are shaped like the bundled `mdb-json`
writes them: a column that is null in the database is absent from the row.

| File                        | Purpose                                                                                                                                                                                 |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pilots_reference.json`     | Every pilot of a real GliderScore 6.78 file, scrubbed: 158 pilots, 74 of them `ZZ` test users, 21 with an email, none with a FAI number.                                                |
| `pilots_edge_cases.json`    | Hand-built rows for the mapper and matcher rules: same-name pilots, a shared email, real FAI and registration numbers, blanks, `ZZ` variants, missing names, IOC and unknown countries. |
| `pilots_old_columns.json`   | Twelve rows with only the older column set (no Email, State, FAI_ID, OtherRegistration).                                                                                                |
| `pilots_extra_columns.json` | Rows with columns the importer does not know about.                                                                                                                                     |

## How they were made

`scripts/scrub_gliderscore_pilots.dart` reads the `Pilots` table exported with
`mdb-json` and writes these files. Names come from fixed pools (the same pilot
number always gets the same fake name; test users keep their `ZZ` prefix),
emails become `fixtureN@example.test`, and everything else that is not
identifying (country, state, class, filter flag, the `"0"` registration
placeholders) is kept. The script refuses to write if any original first name,
last name or email would appear in the output. No real personal data is
committed; the source database stays out of the repository.

Regenerate with the steps at the top of the script. The output is deterministic.
