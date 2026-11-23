# `preliminary_rounds` and the SeededManOnMan draw

Research notes on the `preliminary_rounds` core option and the `SeededManOnMan`
draw mode, traced through `packages/soar_score_core` (plus the contest app's
reads). Sources: `plan/architecture-requirements/matrix-draw.md` (section 6),
`docs/contest-options-audit.md`, and the code in the current worktree.
`graphify` was used to locate the option's node and its neighbourhood;
file-and-line facts below were verified by reading the sources.

Paths are relative to `packages/soar_score_core/` unless noted.

## 1. Every place the option is read or validated

### Read

| File:line                                                           | What happens                                                                                                                                                                                                                                                 |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `lib/models/contest/core_options.dart:146-147`                      | `CoreOptions.fromMap` reads `preliminary_rounds`; when `draw_mode` is `SeededManOnMan` a missing value defaults to `1`, otherwise it reads as `null`.                                                                                                        |
| `lib/models/contest/core_options.dart:200`                          | `preliminary_rounds` is in `CoreOptions.knownKeys`.                                                                                                                                                                                                          |
| `lib/services/matrix/matrix_service.dart:249`                       | `MatrixService.drawFirst`: `options.preliminaryRounds ?? 1`.                                                                                                                                                                                                 |
| `lib/services/matrix/matrix_service.dart:250-258`                   | First draw of a seeded contest rejects `rounds > preliminaryRounds` with `ContestStateError('seeded_rounds_need_standings')`; the preliminary rounds are otherwise drawn like a standard one.                                                                |
| `lib/services/matrix/matrix_redraw_service.dart:34`                 | Class doc: rounds up to `preliminary_rounds` are drawn as above; later rounds are seeded by the standings after the round before them.                                                                                                                       |
| `lib/services/matrix/matrix_redraw_service.dart:330-347`            | `_prepareRedraw`: `options.preliminaryRounds ?? 1`; decides whether the requested range is standard or seeded, and refuses a range that crosses the boundary (`seeded_rounds_need_standings`) and more than one seeded round at a time (`one_seeded_round`). |
| `lib/services/contest_configuration_rules.dart:75`                  | `_matrixChanged`: a changed `preliminaryRounds` invalidates the matrix, so a `Ready` contest goes back to `Configuring` on save.                                                                                                                             |
| `lib/services/contest_configuration_rules.dart:95`                  | `_requireRunningChangesAllowed`: `preliminary_rounds` is fixed once a contest is `Running`; changing it is refused with `configuration_fixed`.                                                                                                               |
| `lib/scoring/recalculation/option_group.dart:27`                    | `preliminary_rounds` is classed `OptionGroup.structural` (a change does not stale any stored result).                                                                                                                                                        |
| `test/models/contest/core_options_test.dart:15, 45, 190-244`        | Option unit tests: null default, the `SeededManOnMan` dependency, the `1 or more` range, and the `1` default when missing in a seeded contest.                                                                                                               |
| `test/services/contest_configuration_rules_test.dart:75, 145`       | Matrix-invalidation and running-lock tests that set `draw_mode` to `SeededManOnMan`.                                                                                                                                                                         |
| `test/scoring/recalculation/config_change_classifier_test.dart:190` | Classifies a `preliminary_rounds` change as structural.                                                                                                                                                                                                      |
| `test/services/matrix/seeded_draw_test.dart:23-160`                 | Tests `SeededDraw.generate` and `DrawEngine.generateSeeded` directly (the engine itself never reads the option).                                                                                                                                             |

### Validation

| File:line                                                | Rule                                                                                                                                   |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/models/contest/core_options.dart:54-59`             | `team_protection` cannot be combined with `SeededManOnMan`: a seeded draw deals pilots by standing, so teammates cannot be kept apart. |
| `lib/models/contest/core_options.dart:61-65`             | `preliminary_rounds` and `intended_total_rounds` are only allowed with `SeededManOnMan`.                                               |
| `lib/models/contest/core_options.dart:66-73`             | `preliminaryRounds` (and `intendedTotalRounds`) must be `1` or more.                                                                   |
| `lib/services/matrix/matrix_service.dart:250-258`        | Guarded read: the first draw of a seeded contest may not reach past round `preliminaryRounds`.                                         |
| `lib/services/matrix/matrix_redraw_service.dart:332-340` | A standard draw (or redraw) may not cross from the preliminary rounds into the seeded ones in one revision.                            |
| `lib/services/matrix/matrix_redraw_service.dart:341-347` | Seeded rounds are drawn one at a time (`rounds != 1` is refused).                                                                      |

### `SeededManOnMan` itself

- `lib/enums/draw_mode.dart:9` — `seededManOnMan('SeededManOnMan')`, the enum value behind the `draw_mode` option.
- `lib/models/matrix/matrix_revision.g.dart:78` — generated JSON mapping of `DrawMode`.
- `lib/models/contest/core_options.dart:54, 61, 138` — the comparisons that drive the validation above.
- `lib/services/matrix/matrix_service.dart:250`, `lib/services/matrix/matrix_redraw_service.dart:34, 331` — the service decisions above.
- `lib/services/matrix/seeded_draw.dart:6`, `lib/services/matrix/draw_engine.dart:176` — doc comments naming the mode.

### The contest app (honours it in the UI, per the audit)

- `apps/soar_score_contest/lib/services/configuration/setting_keys.dart:35, 46, 55, 68` — key, value, and the dependency on `drawMode`.
- `apps/soar_score_contest/lib/services/configuration/setting_catalog.dart:254, 483` — the setting row and its availability rules.
- `apps/soar_score_contest/lib/services/configuration/configuration_values.dart:66, 122-123` — reads the value into the draft and offers it only when seeded.
- `apps/soar_score_contest/lib/services/configuration/configuration_validation.dart:153, 160` — form validation.
- `apps/soar_score_contest/lib/services/matrix/config_drift.dart:46-55` — the config drift check against the stored matrix.
- `apps/soar_score_contest/lib/pages/contest/matrix_page.dart:182-183, 232, 238, 334, 338-339` — draws, extends and previews rounds within the preliminary/seeded split.
- `apps/soar_score_contest/lib/widgets/matrix/draw_form_panel.dart:81, 97, 367`, `draw_config_rows.dart:26, 50`, `matrix_drawn_view.dart:124-125, 259` — the matrix page's forms and labels.
- `apps/soar_score_contest/lib/services/new_contest/draw_settings.dart:40`, `contest_creator.dart:167`, `draft_copy.dart:45` — the wizard stores and displays the value.
- `apps/soar_score_contest/lib/services/workspace/progress/progress_summary.dart:43`, `next_step/next_step_resolver.dart:49, 74`, `apps/soar_score_contest/lib/services/reports/reports_facts.dart:66` — workspace and report facts that read `drawMode` (not the option itself).

Note on the audit: `docs/contest-options-audit.md` (checked against master
2026-10-18) lists `preliminary_rounds` as "Honoured in the app only" and files
gap #475 ("not read by the draw"). The current worktree goes further: the two
services above read it and gate which rounds are drawn standard and which are
seeded. The draw _engine_ (`BasicDraw`, `DrawOptimizer`, `SeededDraw`) never
reads the option; the reads are in the service layer.

## 2. The seeded draw's algorithm, step by step

The preliminary rounds are drawn by `MatrixService.drawFirst` with the standard
engine (construction, annealing, several seeds, lane balancing,
`matrix_service.dart:282-297`). Every seeded round is drawn later, one at a
time, by `MatrixRedrawService.redraw` (`matrix_redraw_service.dart:94`):

1. **State checks** (`:262-291`): the contest is not locked, is `Ready` or
   `Running`, has a finalized latest matrix revision, and the caller's `base`
   equals the latest revision number (else `stale_matrix`).
2. **Round split** (`:293-315`): current rounds are split into `kept`
   (ordinal `< firstRound`) and `replaced` (ordinal `>= firstRound`).
   `_requireReplaceable` (`:520-554`) refuses any replaced round that has a
   score, a locked group, or a locked round.
3. **Read the configuration** (`:317-326`): the latest configuration revision
   supplies `CoreOptions`; `preliminaryRounds = options.preliminaryRounds ?? 1`
   (`:330`).
4. **Decide standard vs seeded** (`:331-347`): `seededMode` is
   `drawMode == DrawMode.seededManOnMan`; `seeded` is `seededMode &&
firstRound > preliminaryRounds`. A range that starts in the preliminary
   rounds and reaches past them is refused (`seeded_rounds_need_standings`,
   `:333-340`); a seeded draw of more than one round is refused
   (`one_seeded_round`, `:341-347`).
5. **Pilots and history** (`:349-367`, `:557-584`): every pilot without a
   retirement, with its team mapping; the `kept` rounds' groups and lanes
   (reflights excluded) become the engine's matchup history.
6. **Standings gate** (`:372-378`, `_requireStandings` `:435-498`): for
   `asOfRound = firstRound - 1`, every live assignment in the kept rounds
   (retired pilots skipped) must carry an official score placeholder (else
   `scores_incomplete`); `ResultsService.read` must return a standing as of
   that round (else `standings_missing`); the standing must be neither stale
   nor preliminary (else `standings_not_validated`). The result is a map from
   participation to place, where place `1` is the leader.
7. **Draw the round** (`:386-393` → `DrawEngine.generateSeeded`,
   `draw_engine.dart:183-212` → `SeededDraw.generate`,
   `seeded_draw.dart:25-69`):
   1. `groupsPerRound` must be between 1 and the number of pilots.
   2. Pilots without a place rank below every pilot that has one
      (`worstPlace = max(place) + 1`).
   3. The pilots are shuffled with the seeded PRNG, then stably sorted by
      (place, shuffle position), giving the ranked order with the leader
      first; the shuffle breaks ties reproducibly.
   4. With `base = pilots ~/ groups` and `extra = pilots % groups`, groups
      are filled from the last group back to group 1: groups `1` to `extra`
      hold `base + 1` pilots, the rest `base`; each group takes the next
      `size` pilots of the ranked order, so the leaders fly last, in the last
      group.
   5. Each group's members are shuffled; when `laneMode` is `random` the
      pilots are assigned lanes `1` to the group size, otherwise no lanes.
   6. There is no optimization: the tiers fix who flies with whom, so the seed
      only orders pilots of equal place and the lanes.
8. **Fairness and storage** (`draw_engine.dart:198-211`,
   `matrix_redraw_service.dart:128-185`): the fairness report covers the
   history plus the seeded round (team protection off), with a
   `fairness_score` against a random baseline; the new revision records
   `drawMode = SeededManOnMan` and `seedingStandings`
   (`{as_of_round, places}`, `:379-385`), replaces the superseded rounds, and
   appends a `MatrixDrawn` audit event.

## 3. Three candidate meanings of `preliminary_rounds` for that draw

### A. Length of the preliminary block (the implemented meaning)

Rounds `1` to `k` are drawn with the standard optimizer, and the first seeded
round is `k + 1`.

- **Pro.** It is what the code does (`matrix_service.dart:250-258`,
  `matrix_redraw_service.dart:332-333`), what plan section 6.1 specifies, and
  why the option invalidates the matrix when changed
  (`contest_configuration_rules.dart:75`): moving the boundary re-draws
  everything.
- **Con.** The rounds named "preliminary" are themselves unseeded: for `k`
  rounds the pilots fly in random groups, and the value's only effect is to
  postpone seeding. Changing it mid-contest is also expensive — it sends a
  `Ready` contest back to `Configuring`, wiping the stored matrix for one
  integer.

### B. Seeding window: how many earlier rounds feed each seeded round

When seeding round `R`, the standings used would be computed over the `k`
most recent preliminary rounds before `R`, a sliding window that grows until
it covers the whole field.

- **Pro.** It gives the word "preliminary" a per-round meaning for every
  seeded round rather than only the first, and reads naturally as "seeded by
  the last `k` preliminary scores".
- **Con.** Nothing implements it: `_requireStandings` seeds from the
  cumulative standings after `firstRound - 1` and never reads
  `preliminary_rounds`, and `ResultsService.read` has no window argument. A
  test asserting this meaning would fail against the current code.

### C. The preliminary phase of the whole contest, paired with `intended_total_rounds`

`k` is the size of the preliminary phase and the remaining
`intended_total_rounds - k` rounds are the seeded block, so the option marks
where the finals begin.

- **Pro.** The two options are gated together (`core_options.dart:61-65` both
  need `SeededManOnMan`), the wizard presents them as a pair, and
  `intended_total_rounds` exists precisely to "show people" the intended
  length — a phase split is the most natural reading of the pair.
- **Con.** `intended_total_rounds` is documented as having "no effect on the
  draw" (`core_options.dart:255`), and the engine draws seeded rounds one at a
  time with no cap or end-of-block behaviour, so no code consumes `k` or the
  difference between the two values.

## 4. The smallest test that would prove the value changes the draw

`preliminary_rounds` never reaches the seeded draw itself: a seeded round is
drawn from the standings at draw time and the seed only, so the value changes
_which_ rounds are seeded, not _how_ a seeded round is drawn. The smallest
proof is therefore at the service level, one call per value: a seeded contest
with the same pilots and the same seed, where `preliminary_rounds` is the
only thing that differs, and `rounds: 2` is the only draw requested.

- With `preliminary_rounds: 1`, `MatrixService.drawFirst(rounds: 2, ...)`
  must throw `ContestStateError` with reason `seeded_rounds_need_standings`
  (`matrix_service.dart:252-257`): the draw cannot reach round 2.
- With `preliminary_rounds: 2`, the identical call succeeds and stores a
  revision with two rounds.

Same inputs, one changed value, opposite outcomes — that is the value
changing the draw, in a single test body.

Sketch:

```dart
test('preliminary_rounds decides whether the first draw reaches round 2', () async {
  for (final (preliminary, expectOk) in [
    (1, false),
    (2, true),
  ]) {
    // Contested setup, identical each pass except preliminary_rounds:
    // a seeded contest ({'draw_mode': 'SeededManOnMan',
    // 'preliminary_rounds': preliminary}), four pilots, 2 groups per round.
    final draw = () => MatrixService(repository).drawFirst(
          contestId,
          id: Id.create(),
          rounds: 2,
          groupsPerRound: 2,
          randomSeed: 42,
          actorId: actor,
          metadata: metadata,
        );
    if (expectOk) {
      await draw();
    } else {
      expect(draw(), throwsA(isA<ContestStateError>().having((e) => e.reason, 'reason', 'seeded_rounds_need_standings')));
    }
  }
});
```

An equivalent handler-level proof already exists:
`packages/soar_score_api_handlers/test/handlers/matrix_handlers_test.dart:320-335`
draws a seeded contest configured with `preliminary_rounds: 2` and expects
the default-round draw to fail with `seeded_rounds_need_standings` (409) while
`rounds: 2` succeeds (201). No core test currently exercises the guard with
differing values of the option itself.
