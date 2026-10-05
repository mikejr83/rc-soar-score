# F5J scoring fixtures

Golden cases for the F5J scoring engine. They are plain JSON so any future client library can load the same files and must produce the same answers.

The expected values were produced by an independent exact-fraction (rational arithmetic) calculation, not by the Dart engine, so a bug in the engine cannot hide itself here.

## Files

- `flights.json`: one pilot's flight. Each case has `name`, `components` (the entered values, keyed like the F5J profile), optional `options` (profile overrides), optional `landing_bonus` (already resolved to points), and either `expected` or `expected_error` (a list of issue codes).
- `groups.json`: one group. Each case has `options`, `pilots` (each with `id`, `components`, optional `landing_bonus` and `retired`), and `expected` (pilot `id`, `raw_score`, `group_score`, in order).
- `contests.json`: pilots across rounds. Each case has `options` (including `drop_after_rounds`), `as_of_round`, `pilots` with their round scores, and expected totals and places, plus expected team results where a case has teams.

## Rules for the numbers

- Compare decimals with a tolerance of 1e-9; scores are only rounded once, at the end.
- Totals are summed in thousandths so decimal scores add without float drift.
