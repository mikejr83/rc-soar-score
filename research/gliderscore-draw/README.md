# Draw Algorithm Review — GliderScore Comparison and Recommendations for `matrix-draw.md`

Reviews [`plan/architecture-requirements/matrix-draw.md`](../../plan/architecture-requirements/matrix-draw.md)
as of `8413c04`. The benchmark harness is [`draw_bench.py`](draw_bench.py) in this folder. The Dart engine has its own port of the 30 and 63 pilot layouts, `packages/soar_score_core/tool/draw_bench.dart`, run with `scripts/draw-bench.sh [--check] [--layout c1|c4|c10|all] [--seeds N]` (or the `.ps1`). It prints MAD, never-met pairs, max repeat and variance, and `--check` fails when a layout drops below its stored baseline (30 pilots MAD about 0.42, 63 pilots about 0.70).

## Provenance and clean-room note

`matrix-draw.md` was designed independently, partly to keep RC Soar Score clear of GliderScore's
implementation. This review compares against GliderScore, so it is deliberately kept at arm's length:

- GliderScore 6.79 was analyzed to understand how its draw behaves. This document
  summarises that behaviour only at a high level (§1).
- No code used to take the GliderScore measurements is included. Neither
  is any decompiled source, GliderScore binary, or sample database. GliderScore figures below are
  recorded results.
- The improvements recommended in §5 use **standard, published local-search techniques** for this class
  of problem, not GliderScore's heuristics. Everything in `draw_bench.py` is independent code.

GliderScore is distributed "free and carries no warranty whatsoever," copyright Gerry Carter.

---

## TL;DR

- **GliderScore** builds the draw round by round with a greedy heuristic and random restarts, keeps the
  most even build of each round, and never revisits earlier rounds. It's simple and it's strong.
- **`matrix-draw.md` as written loses to it** on both team-protected contests tested — including on the
  spec's own cost function. Its cooling schedule freezes early, and 30,000 iterations is too small a budget.
- **GliderScore has room to improve.** Running local search over its finished draw improves fairness by
  4–7% on the team contests: freezing each round is what holds it back.
- **Clean-room methods can beat it.** A generic greedy construction followed by conflict-directed local
  search matches or beats GliderScore on all three contests (MAD −7.8% at 30 pilots, −3.3% at 63).
- **Recommended engine for Mike:** generic greedy construction → conflict-directed local search over all
  rounds with a size-scaled budget → seeded PRNG with best-of-several-seeds, plus an explicit penalty for
  pairs that never meet (§5).

---

## 1. GliderScore's draw, in brief

- **Groups:** built one round at a time with a greedy heuristic and random tie-breaks. Each round is built
  several times (10 by default) and the build that keeps pairwise meeting counts most even is kept.
  Earlier rounds are never revisited. Randomness is unseeded, so draws aren't reproducible. Re-running the
  draw only replaces the existing one if the new result scores better.
- **Fairness metric:** mean absolute deviation (MAD) of pairwise meeting counts, computed over pairs that
  can actually meet — teammates under team protection (and same-frequency pilots, where frequencies are
  used) are excluded when they've never met. The same number drives the draw and the CD's Check Draw
  screen. Lower is better.
- **Group sizes:** balanced; lower-numbered groups get the extra pilot.
- **Lanes:** assigned after the groups are final, balancing each pilot's lane history. The number of lanes
  is a contest setting.
- **Back-to-back option:** stops a pilot in the last group of one round from flying in the first group of
  the next.
- **Seeded man-on-man:** only round 1 is drawn up front; each later round is drawn from current standings
  (drop scores applied) once the previous round has scores. **Lowest scorers go in Group 1, so the leaders
  fly last.** Not allowed with team protection. A preview is shown before committing. There's no
  meeting-count avoidance within seeded rounds.
- **Late pilot:** added to a random compatible, non-full group in each drawn round; meeting history isn't
  considered.

---

## 2. Issues in `matrix-draw.md`

Each item has a way to verify it.

### 2.1 §4.3 — The cooling schedule freezes almost immediately, and the budget is too small

T₀ = 50, α = 0.992 applied every iteration, T_min = 0.001, 30,000 iterations.

T reaches T_min after **ln(50/0.001) / −ln(0.992) ≈ 1,347 iterations**. The remaining ~28,650 iterations
(95.5%) run at the floor, where `exp(−ΔJ/T)` is effectively 0 for any worsening move — i.e. pure greedy
hill-climbing.

- Verify: `python -c "import math; print(math.log(50000)/-math.log(0.992))"` → `1347.0`
- **Ambiguity:** the spec lists T_min alongside max iterations without saying whether reaching it _ends_
  the run. If it does, the whole optimizer runs 1,347 iterations — §4 shows that reading is dramatically
  worse. State explicitly that T_min is a floor.
- A schedule matched to the budget is α = (T_min/T₀)^(1/iterations) — ≈ 0.99964 for 30k.
- **But fixing α alone is not enough.** In §4, the matched schedule at 30k was no better than clamping at
  the floor. The binding constraint is the iteration budget: 30k swaps is ~60 per pilot-round placement for
  a 30-pilot/16-round contest and ~34 for 63 pilots/14 rounds. Scale the budget with N × R.

### 2.2 §3 / §7 — Teammate pairs distort the targets and reported metrics

Pairs that the hard constraint forbids from ever meeting always have c = 0. In J they contribute a constant,
so **the optimum is unchanged** — but every _reported_ number and target built on all-pairs statistics is
skewed:

- μ is too low: all meetings must be absorbed by the pairs that _can_ meet, so their true mean is higher.
- "Unmet Opponent Count" counts teammates who were never allowed to meet.
- "Max Duplicate Matchups ≤ ⌈μ⌉ + 1" uses the wrong mean.

Demonstration on a stored draw from GliderScore's sample data (30 pilots, 16 rounds, team protection):

| Definition          | Mean meetings | Pairs that never met |
| ------------------- | ------------- | -------------------- |
| All pairs (spec §3) | 3.639         | 40                   |
| Pairs that can meet | 4.008         | **0**                |

All 40 "unmet" pairs are teammates. **Recommendation:** exclude pairs that can never meet from every
reported metric, and compute the target from the feasible-pair mean m = (total meetings) / (feasible pairs).

Also minor: μ = R(ḡ−1)/(N−1) is exact only when G divides N. With unequal groups the true all-pairs mean
is R·Σ_g C(|g|,2) / C(N,2), which is slightly higher (convexity).

### 2.3 §7.1 — "Overall Fairness Score vs J_ideal" needs a definition

Meeting counts are integers, so the best possible distribution puts every feasible pair at ⌊m⌋ or ⌈m⌉.
With P feasible pairs and f = m − ⌊m⌋:

- **min Σ(c − m)² = P · f(1 − f)**
- **min MAD = 2f(1 − f)**

Those are lower bounds — combinatorial design limits mean they often aren't reachable (none of the tested
configurations get close). A 0–100% score still needs a second anchor (e.g. the expected J of a random
valid draw) to be meaningful; the spec should pick one.

### 2.4 §2.1 / §4.2 — Feasibility and the initial construction

G ≥ T_max is **sufficient** for a single round with balanced group sizes, and there's a one-line
constructive proof worth putting in §4.2: order pilots team by team and **deal them round-robin** across
groups 1..G. Any team of size ≤ G occupies consecutive positions mod G, so its members land in distinct
groups; the deal also produces sizes differing by at most one. (`draw_bench.py` uses exactly this as the
annealing start state, and every one of its draws passes validity checks.)

The spec's current wording ("place members of the largest teams into distinct groups, then fill") can dead-end
if implemented naively. Specify the round-robin deal and it can't.

### 2.5 §6.3 — Seeded group order is the opposite of GliderScore's

- **GliderScore:** Group 1 = lowest cumulative scores. Leaders fly in the last group.
- **Spec:** Group 1 = top-ranked tier.

This is a **decision, not a bug** — flying the leaders last is a common convention (it plays like a final and
the leaders see the conditions everyone else got), but it's worth deciding deliberately.

### 2.6 §6.3 step 4 — Seeded + team protection needs a fallback

GliderScore forbids team protection in seeded mode. The spec allows it via a minimal rank-displacement swap
into an _adjacent_ group, but adjacent-only search can fail. Example: G = 3 and all three members of one team
rank into Group 1. The first extra teammate swaps into Group 2; the second can't also go to Group 2, and
Group 3 isn't adjacent to Group 1. Either forbid the combination or define the fallback (widen the search
radius).

### 2.7 §3.1 — Number of lanes should be configuration

The spec derives L = ⌈N/G⌉. Fields have a fixed number of pegs. Make it a contest setting (defaulting to max
group size).

### 2.8 Constraints the spec doesn't have

- **Back-to-back:** stopping a pilot in the last group of round r from flying in the first group of round r+1.
  In annealing terms that's a hard constraint checked on swaps touching group G of round r or group 1 of
  round r+1.
- **Frequencies** — already flagged as an owner decision in the earlier parity review (PR #1).

### 2.9 Implementation notes the spec should state

- **Incremental ΔJ.** Computing ΔJ in O(group size) per swap is required for any reasonable budget.
  Swapping p_x (group a) with p_y (group b) changes only the pairs between p_x, p_y and the other members
  of a and b; each changes (c−μ)² by ±2(c−μ)+1. `draw_bench.py` does exactly this.
- **Cross-platform determinism.** A seeded PRNG isn't enough: `Math.exp` is implementation-approximated in
  JavaScript engines and isn't guaranteed bit-identical to .NET. Identical matrices across web/desktop/server
  need a fixed-point acceptance test (or precomputed thresholds) and an identical operation order.
- **Which groups get the extra pilot** when N mod G ≠ 0 is unspecified.

---

## 3. What to keep from each

### Worth matching from GliderScore (user-facing behaviour)

1. **Don't replace unless better, and let the CD re-run.** With seeds this becomes "try another seed, keep
   the better result" — cheap, and §5 shows it's worth ~5%.
2. **MAD over pairs that can meet as the CD-facing number**, shown with the meeting histogram and a
   selectable round range.
3. **Late pilot insertion with explicit overrides** when no compatible group exists (improved in §5).
4. **Seeded-round guards:** current round scored, next round unscored, re-draw only the last round, preview
   before committing.

### Where the spec is already better

1. **Reproducible, auditable draws** (seed + algorithm version stored on the revision).
2. **Global optimization across all rounds** — §5 shows this is exactly what improves on GliderScore, once
   the budget and move selection are right.
3. **Lane co-optimization** instead of lanes as an afterthought; it produced more even lanes in §4–§5.
4. **Fairness report stored as data** on the revision.
5. **`preliminaryRounds` > 1** generalizes a round-1-only seeded start.
6. **Validated scores (no open reviews)** as the seeded prerequisite.
7. **Seeded + team protection** — worth keeping if the fallback in §2.6 is defined.

---

## 4. Head-to-head benchmark: GliderScore vs the spec as written

### Setup

- **Harness:** [`draw_bench.py`](draw_bench.py) — standard library only. Run `python draw_bench.py c1`
  (or `c4`, `c10`); an optional second argument sets the number of seeds. It reproduces every non-GliderScore
  row in §4 and §5.
- **GliderScore rows** are recorded from a local behavioural port that is not included (see Provenance). For
  the 63-pilot contest the port's median MAD was **0.7100** against **0.7101** for GliderScore's real stored
  draw of that contest. The port omits frequencies and back-to-back.
- **Spec rows** — `matrix-draw.md` as written: J with w_lane = 0.15, μ and λ per §3.2, L = ⌈N/G⌉, 80/20
  swap/lane-swap moves with team-collision rejection, T₀ = 50, T_min = 0.001, incremental ΔJ, round-robin
  start (§2.4). Because of the §2.1 ambiguity, three readings are tested, plus one run with 10× the budget.
- **Inputs:** team layouts embedded in the script — the team numbers of the non-retired pilots in three
  competitions from GliderScore's sample data (no pilot data). Frequencies ignored; back-to-back allowed.
- **Method:** 5 seeds per variant; medians reported. **Every generated draw passes validity assertions**
  (each round partitions all pilots, group sizes balanced, no team-protection violations).
- **Metrics:** MAD over feasible pairs, the spec's J, the most times any feasible pair meets, and feasible
  pairs that never meet. Lower is better for all four.

### Results

**c10 — 23 pilots, 3 groups, 6 rounds, no teams** (MAD floor 0.287)

| Algorithm                                   | MAD       | J         | Max meets | Unmet pairs |
| ------------------------------------------- | --------- | --------- | --------- | ----------- |
| GliderScore _(recorded)_                    | **0.677** | 205.6     | 5         | 10          |
| Spec SA — T_min ends run (1,348 iterations) | 0.685     | 197.7     | 4         | 9           |
| Spec SA — 30k, clamped at T_min             | 0.684     | **193.5** | 4         | 13          |
| Spec SA — 30k, α = 0.99964                  | 0.681     | **193.5** | 4         | 12          |
| Spec SA — 300k, α matched                   | 0.696     | **193.5** | 4         | 13          |

**c1 — 30 pilots, 5 groups, 16 rounds, 8 teams of 3–4, team protection** (MAD floor 0.101)

| Algorithm                                   | MAD       | J         | Max meets | Unmet pairs |
| ------------------------------------------- | --------- | --------- | --------- | ----------- |
| GliderScore _(recorded)_                    | 0.445     | 534.7     | 5         | 0           |
| Spec SA — T_min ends run (1,348 iterations) | 0.832     | 871.9     | 7         | 2           |
| Spec SA — 30k, clamped at T_min             | 0.512     | 564.3     | 5         | 0           |
| Spec SA — 30k, α = 0.99964                  | 0.522     | 569.7     | 5         | 0           |
| Spec SA — **300k**, α matched               | **0.444** | **529.7** | 5         | 0           |

**c4 — 63 pilots, 5 groups, 14 rounds, 14 teams of 3–5 (T_max = G), team protection** (MAD floor 0.338)

| Algorithm                                   | MAD       | J           | Max meets | Unmet pairs |
| ------------------------------------------- | --------- | ----------- | --------- | ----------- |
| GliderScore _(recorded)_                    | **0.710** | **2,291.7** | 6         | **2**       |
| Spec SA — T_min ends run (1,348 iterations) | 1.112     | 4,479.1     | 8         | 60          |
| Spec SA — 30k, clamped at T_min             | 0.824     | 2,805.8     | 6         | 13          |
| Spec SA — 30k, α = 0.99964                  | 0.832     | 2,858.1     | 7         | 13          |
| Spec SA — **300k**, α matched               | 0.726     | 2,348.6     | 6         | 5           |

### Findings

1. **As specified, the annealer loses to GliderScore on both team-protected contests** — on MAD _and_ on the
   spec's own objective J. With no teams (c10) the two are indistinguishable.
2. **Reading T_min as a stop condition is badly worse.** On the 63-pilot contest, 60 feasible pairs never
   meet, versus 2 for GliderScore.
3. **Fixing the cooling schedule alone doesn't help at 30k.** The budget is the problem, not just the schedule.
4. **With 10× the budget, annealing ties GliderScore at 30 pilots and still trails at 63.** The spec's claim
   that 30k iterations suffices for 100 pilots × 20 rounds (2,000 placements — ~15 swaps each) is not
   supported.
5. **Timing** from Python is not representative of JavaScript/WASM or C#. For relative scale only: annealer
   at 30k 0.12–0.21 s, at 300k 1.6–2.7 s.

---

## 5. Improving on GliderScore

### Methods tested (all standard, none GliderScore-specific)

- **Generic greedy construction** — most-constrained-first insertion: teams largest first, each pilot into
  the compatible non-full group with the fewest prior meetings, random ties; best of 10 builds per round by
  sum of squared meeting counts. A textbook constructive heuristic.
- **Local-search polish** — the spec's annealer started from a finished draw instead of the round-robin deal,
  starting cool (T₀ = 2) with α matched to 300k iterations.
- **Conflict-directed annealing** — the spec's annealer from the round-robin deal, where half of pilot swaps
  take the pilot with the most excess meetings in its group rather than a random one. This is the
  conflict-directed move used in local search for the **Social Golfer Problem**, which is the same
  combinatorial problem (CSPLib problem 010; Dotú & Van Hentenryck, _Scheduling Social Golfers Locally_,
  CPAIOR 2005).
- **Greedy + conflict-directed polish** — the generic greedy construction, then the conflict-directed
  annealer starting cool (T₀ = 2) for 300k iterations. This is the combination recommended below.
- **GliderScore + local-search polish** — _measurement only, not a recommendation._ Polishing GliderScore's
  own output shows how much fairness its round-by-round construction leaves unclaimed.

Same harness, seeds, validity checks and metrics as §4.

### Results

**c10 — 23 pilots, no teams**

| Method                                          | MAD       | J         | Max meets | Unmet pairs |
| ----------------------------------------------- | --------- | --------- | --------- | ----------- |
| GliderScore _(recorded)_                        | 0.677     | 205.6     | 5         | **10**      |
| GliderScore + local search _(measurement only)_ | 0.683     | 193.5     | 4         | 13          |
| Generic greedy                                  | 0.698     | 213.9     | 4         | 13          |
| Generic greedy + local search                   | 0.677     | **193.5** | 4         | 11          |
| Conflict-directed annealing                     | 0.676     | **193.5** | 4         | 15          |
| Greedy + conflict-directed polish               | **0.674** | **193.5** | 4         | 14          |

**c1 — 30 pilots, 8 teams, team protection**

| Method                                          | MAD       | J         | Max meets | Unmet pairs |
| ----------------------------------------------- | --------- | --------- | --------- | ----------- |
| GliderScore _(recorded)_                        | 0.445     | 534.7     | 5         | 0           |
| GliderScore + local search _(measurement only)_ | 0.415     | 517.7     | 5         | 0           |
| Generic greedy                                  | 0.522     | 766.9     | 5         | 0           |
| Generic greedy + local search                   | 0.444     | 530.0     | 5         | 0           |
| Conflict-directed annealing                     | 0.415     | 517.7     | 5         | 0           |
| Greedy + conflict-directed polish               | **0.410** | **513.7** | 5         | 0           |

**c4 — 63 pilots, 14 teams, team protection**

| Method                                          | MAD       | J           | Max meets | Unmet pairs |
| ----------------------------------------------- | --------- | ----------- | --------- | ----------- |
| GliderScore _(recorded)_                        | 0.710     | 2,291.7     | 6         | **2**       |
| GliderScore + local search _(measurement only)_ | 0.684     | 2,177.7     | 6         | 2           |
| Generic greedy                                  | 0.738     | 2,722.7     | 6         | 8           |
| Generic greedy + local search                   | 0.702     | 2,259.7     | **5**     | 5           |
| Conflict-directed annealing                     | 0.707     | 2,267.4     | 6         | 3           |
| Greedy + conflict-directed polish               | **0.687** | **2,203.4** | 6         | 3           |

### Findings

1. **GliderScore leaves fairness on the table.** Local search over its finished draw improves it on both team
   contests without adding repeats or never-met pairs: MAD −6.6% and J −3.2% at 30 pilots; MAD −3.7% and
   J −5.0% at 63. Freezing each round is the limitation — an early round can't be rearranged once later
   rounds show a better fit.
2. **Clean-room methods match or beat it.** The best is the combination — greedy construction followed by
   conflict-directed polish — with the lowest MAD and J of any recommended method on all three contests:
   MAD −7.8% and J −3.9% at 30 pilots, MAD −3.3% and J −3.9% at 63. At 30 pilots it even edges polishing
   GliderScore's own draw (0.410 vs 0.415). Generic greedy + plain local search also matches or beats
   GliderScore on MAD, J and max repeats everywhere.
3. **Construction alone isn't enough.** The generic greedy by itself trails GliderScore (63 pilots: MAD 0.738
   vs 0.710) — GliderScore's construction heuristic is better than simple insertion. Local search is what
   closes and then passes the gap.
4. **The quadratic objective under-weights pairs that never meet.** The spec's target at 63 pilots is
   μ ≈ 2.6 meetings, so a never-met pair costs (0 − 2.6)² ≈ 6.9 — much less than a pair meeting six times
   (≈ 11.4). So the annealers
   trade never-met pairs for fewer heavy repeats: lower max meets, slightly more unmet pairs (63 pilots: 3–5
   vs GliderScore's 2). If "I never flew against X" is the complaint CDs hear, weight it explicitly.
5. **Best-of-several-seeds is worth having.** Per-seed spread is 4–13% of the median MAD. Best of 5 seeds for
   conflict-directed annealing at 30 pilots is 0.396, versus a median of 0.415 and GliderScore's best of
   0.411.
6. **Gains are modest and per-seed ranges overlap.** These are directionally consistent results across three
   contests and 5 seeds each, not a statistical study. On the no-teams contest every method ties on MAD.
7. **Timing** (Python, relative only): generic greedy 0.01–0.18 s; + local search 2.3–3.0 s;
   conflict-directed annealing 6.0–8.7 s; greedy + conflict-directed polish 3.7–8.4 s. The targeted move
   costs O(group size²).

### Recommendations for `matrix-draw.md` §4

In priority order. _Measured_ means supported by the results above; _untested_ means reasoned but not run.

1. **Construct, then improve over all rounds.** Build a valid draw with a simple greedy construction, then run
   conflict-directed local search across every round, starting cool. It had the best MAD and J of every
   recommended method on all three contests. _Measured._
2. **Scale the budget with problem size** (pilots × rounds). 300k iterations for 480–882 placements was enough
   to match or beat GliderScore; 30k was not. Treat T_min as a floor, and start polish cool (T₀ ≈ 2) when
   beginning from a greedy draw. _Measured._
3. **Run several seeds and keep the best**, storing the winning seed on the matrix revision. It keeps the
   spec's reproducibility and matches the "re-run the draw" behaviour CDs already expect. _Measured (per-seed
   spread)._
4. **Penalise pairs that never meet**, either with an added weight or a lexicographic objective: never-met
   pairs first, then max repeats, then variance. _Untested._
5. **Keep lane co-optimization.** The annealers produced more even lanes than GliderScore's post-hoc
   assignment once given an adequate budget (lane-count std. dev. 0.35 vs 0.37 at 63 pilots, 0.47 vs 0.56 at
   30). _Measured._
6. **History-aware late pilots:** place a late entry in the compatible group that minimises their meetings,
   then run a short local-search pass over rounds not yet flown. _Untested._
7. **Seeded rounds with meeting avoidance:** after ranking into tiers, allow swaps between adjacent-rank pilots
   across tier boundaries when they reduce repeat pairings, and use the same widened swap search to support
   team protection (§2.6). _Untested._
8. **Report what pilots notice:** show never-met pairs and max repeats alongside MAD in the fairness report.

### Caveats

- The analysis omits frequencies and back-to-back.
- Three configurations, 5 seeds per variant. Only T₀ = 2 was tried for polish; no other parameter tuning.

4. **Seeded + team protection:** support it with a defined fallback, or forbid it?
5. **Back-to-back:** add it?
6. **Lanes:** configured count, or derived?
7. **Fairness score:** what's the second anchor for the 0–100% scale?
