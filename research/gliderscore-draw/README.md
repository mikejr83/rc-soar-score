# GliderScore Draw Algorithm — Extracted and Compared to `matrix-draw.md`

Reviews [`plan/architecture-requirements/matrix-draw.md`](../../plan/architecture-requirements/matrix-draw.md)
as of `8413c04`. The benchmark harness is [`draw_bench.py`](draw_bench.py) in this folder.

**Source:** `GliderScore.exe` 6.79 (VB.NET, .NET 4.8), decompiled locally with ILSpy (`ilspycmd` 9.1).
Behaviour is described below in our own words with pseudocode; **no decompiled source is reproduced
here**, and the decompiled output was not committed anywhere. Method names are cited only as pointers.

GliderScore is distributed "free and carries no warranty whatsoever," copyright Gerry Carter, with no
stated restriction on reverse engineering. He is reachable at gerry.carter(at)gliderscore.com — several
questions below (especially seeded ordering) are one-sentence answers for him.

Primary code locations: `CreateDraw.Bw_DoWork` (outer loop), `CreateDraw.CreateDraw_Groups` (group
builder), `CreateDraw.GetMeanAbsoluteDeviation` + `modFunctions.CalcMeanAbsoluteDeviation` (metric),
`CreateDraw.AllocateRandomLanes1` (lanes), `Scoring.btnDrawNextSeededRound_Click` +
`Reports_SMOM.createSMOMFlightGroups` + `modFunctions.dtSMOMReport_Resolve_SMOM_DrawOrder` (seeded),
`AddLatePilot_MOD.AddLatePilotToDraw` (late entries).

---

## TL;DR

**GliderScore is not a sophisticated optimizer.** It is a *round-by-round greedy constructor with
random restarts*, a good tie-breaking heuristic, and a sensible fairness metric (mean absolute deviation
of pairwise meeting counts, excluding pairs that can never meet). Each round is built several times and
the best one is kept; earlier rounds are never revisited. That combination is what "handles it really
well" amounts to.

**It also beats the spec's simulated annealing as written.** In a head-to-head on three real contest
configurations (§4), GliderScore's greedy wins clearly on both team-protected contests — on its own
metric *and* on the spec's cost function J. The spec's cooling schedule freezes after ~4.5% of its
iterations, but fixing that alone doesn't help: **30,000 iterations is simply too small a budget.** At 10×
the budget, annealing ties GliderScore on a 30-pilot contest and still trails on a 63-pilot one.

Mike's approach is sound in principle and has real advantages (reproducibility, lane co-optimization), but
§4 of the spec needs a size-scaled budget — or a greedy starting state — before it will match GliderScore.
The fairness-metric definitions and the seeded-mode group order are the other things to revisit.

---

## 1. What GliderScore actually does (counterpart to `matrix-draw.md` §3–§4)

### 1.1 Outer loop — `Bw_DoWork`

```
K = "Iterations" control on the Create Draw screen   (default 10, min 1, max 50)

for round r in FromRound..ToRound:
    history = pilot×pilot meeting counts over rounds 1..r-1      (first flights only, ReFlightNo=0)

    if r == 1:
        repeat build_round() until feasible                       # NO best-of-K for round 1
        if 200 failed attempts: prompt "Draw is not likely to be possible… Keep trying?" (+200 more)

    else:
        for i in 1..K:
            repeat build_round() until feasible
            score = MAD(cumulative meetings over rounds 1..r)
            keep this round if i == 1 or score < best; otherwise discard it

    freeze round r                                                # never revisited

at the end:
    replace the existing draw ONLY IF final MAD < MAD of the existing draw
    (or "force replacement" is ticked, or no draw existed)
```

The replace-only-if-better step is the documented UX: *"no two draws will be the same… process the draw a
number of times… the system will keep the best draw."*

### 1.2 Building one round — `CreateDraw_Groups`, called for groups 1..G

Group sizes are fixed up front: every group gets `PilotsMin`, and the first `N − G·PilotsMin` groups get
`PilotsMax` instead — **lower-numbered groups get the extra pilot.** Min/max come from contest config.

```
for group g in 1..G-1:
    pool = pilots not yet placed this round
    if back-to-back is disallowed and g == 1 and r > 1:
        remove from pool everyone who flew in the LAST group of round r-1

    m_min = smallest meeting count among compatible pairs still in pool
    seeds = pilots in pool with the MOST compatible opponents at exactly m_min
                                                   # i.e. start from the most "under-met" pilots
    for each seed:                                  # one candidate group per seed
        set = {seed}
        while |set| < size(g):
            mark teammates / same-frequency pilots of the set as clashing
            pigeonhole forcing:
              if some team (or frequency) has more unplaced pilots than groups remaining → infeasible
              if it has exactly as many → one of them MUST go in this group ("Force")
            candidates = forced pilots if any, else all non-clashing pilots
            add the candidate with the lowest SUM of prior meetings with the set   (random tie-break)
        set.score = MAX prior meeting count over any pair in the set               # bottleneck
    commit the candidate set with the lowest score                                 (random tie-break)
    if every candidate failed: round is infeasible → caller restarts the whole round

group G = everyone left over; validate no team / frequency clash, else restart the round
```

Note the two different aggregations: **sum** when growing a set, **max** when choosing between sets. The
max rewards avoiding any repeat pairing; the sum spreads meetings evenly.

### 1.3 Fairness metric — `GetMeanAbsoluteDeviation` / `CalcMeanAbsoluteDeviation`

```
pilots = non-retired contest pilots (IsPilot)
c(i,j) = number of rounds in which i and j were in the same group (first flights only)

exclude pair (i,j) if c(i,j) == 0 AND any of:
    team protection on and same team
    same frequency (and not 2.4GHz)
    20kHz spacing on, both non-2.4, frequencies within 0.0199

MAD = mean over remaining pairs of | c(i,j) − mean(c) |
```

This same definition drives the draw loop and the **Check Draw** screen (`CheckDrawDisplay`), so the
number the CD sees is the number the algorithm optimizes. Lower is better.

**Random numbers:** `System.Random`, unseeded. Draws are not reproducible.

### 1.4 Lanes — `AllocateRandomLanes1` (lane option "Random")

Lanes are assigned **after** the group draw is final — they never influence who flies with whom.

```
laneCount[pilot][lane] = history from rounds before FromRound
for each round, for each group:
    repeat |group| times:
        pick the (pilot, lane) cell with the lowest laneCount among unassigned pilots and free lanes
                                                   (random tie-break)
        assign it; increment laneCount; remove that pilot and that lane
```

Number of lanes is the configured `durNbrOfLanes`, not derived from group size. "Team" and "Closest" lane
modes are separate routines (`F3JAllocateTeamLanes`, `AllocateClosestLanes`).

### 1.5 Seeded man-on-man — drawn from the Scoring screen, not the Create Draw screen

- Create Draw only allows **round 1** in seeded mode ("Both From Round and To Round must be 1… draw later
  rounds from the Scoring screen").
- **Setup rejects** seeded mode with: groups per round = 1, team protection on, or lane option Team/Random.
- "Draw Next Seeded Round" requires: no frequency clashes; scores **entered** for the current round; no
  scores yet in the next round; the current round is the last one. Re-drawing an existing next round asks
  for confirmation and deletes it.
- Ranking source: overall results through the current round, **with drop scores applied**. The `Score`
  used is the sum of normalised round scores minus penalties (floored at 0) — higher is better — and the
  seeded path passes the drop flag, so `dtCompResults_ApplyDropScores` →
  `UpdateScores_DropTasks`/`UpdateScores_DropRounds` rewrite `Score` before ranking whenever any drop
  threshold is set. (F5J non-droppable motor-restart zeros are held out of the drop candidates.)
- Group sizes: `ceil(remaining pilots / remaining groups)` per group → lower-numbered groups get the extra.
- Order: non-retired pilots sorted by **`Score` ascending**, random tie-break, dealt into groups in order —
  so **Group 1 gets the lowest scorers and the leaders fly last.**
- A preview dialog (`Reports_SMOM`) is shown before committing; the **Retired** column is editable there.
- There is **no meeting-count avoidance** within seeded rounds — grouping is purely by rank.

### 1.6 Late pilot — `AddLatePilotToDraw`

For each already-drawn round independently: candidate groups are those with no team clash (if protection),
no frequency clash, and not full (the full check is skipped when all groups in that round are the same
size). Pick one **uniformly at random**. If none qualify, a dialog lets the CD allow a team clash, raise max
pilots per group, or change the pilot's frequency. Meeting history is not considered.

---

## 2. Issues in `matrix-draw.md` that GliderScore's implementation illuminates

Each item has a way to verify it.

### 2.1 §4.3 — The cooling schedule freezes almost immediately, and the budget is too small

T₀ = 50, α = 0.992 applied every iteration, T_min = 0.001, 30,000 iterations.

T reaches T_min after **ln(50/0.001) / −ln(0.992) ≈ 1,347 iterations**. The remaining ~28,650 iterations
(95.5%) run at the floor, where `exp(−ΔJ/T)` is effectively 0 for any worsening move — i.e. pure greedy
hill-climbing.

- Verify: `python -c "import math; print(math.log(50000)/-math.log(0.992))"` → `1347.0`
- **Ambiguity:** the spec lists T_min alongside max iterations without saying whether reaching it *ends*
  the run. If it does, the whole optimizer runs 1,347 iterations — §4 shows that reading is dramatically
  worse. State explicitly that T_min is a floor.
- A schedule matched to the budget is α = (T_min/T₀)^(1/iterations) — ≈ 0.99964 for 30k.
- **But fixing α alone is not enough.** In §4, the matched schedule at 30k was no better than clamping at
  the floor. The binding constraint is the iteration budget: 30k swaps is ~60 per pilot-round placement for
  a 30-pilot/16-round contest and ~34 for 63 pilots/14 rounds. Scale the budget with N × R.

### 2.2 §3 / §7 — Teammate pairs distort the targets and reported metrics

Pairs that the hard constraint forbids from ever meeting always have c = 0. In J they contribute a constant,
so **the optimum is unchanged** — but every *reported* number and target built on all-pairs statistics is
skewed:

- μ is too low: all meetings must be absorbed by the pairs that *can* meet, so their true mean is higher.
- "Unmet Opponent Count" counts teammates who were never allowed to meet.
- "Max Duplicate Matchups ≤ ⌈μ⌉ + 1" uses the wrong mean.

Demonstration on GliderScore's shipped Comp 1 (30 pilots, 16 rounds, team protection), stored draw:

| Definition | Mean meetings | Pairs that never met |
|---|---|---|
| All pairs (Mike's §3) | 3.639 | 40 |
| Feasible pairs only (GliderScore) | 4.008 | **0** |

All 40 "unmet" pairs are teammates. **Recommendation:** adopt GliderScore's exclusion rule for every
reported metric, and compute the target from the feasible-pair mean m = (total meetings) / (feasible pairs).

Also minor: μ = R(ḡ−1)/(N−1) is exact only when G divides N. With unequal groups the true all-pairs mean
is R·Σ_g C(|g|,2) / C(N,2), which is slightly higher (convexity).

### 2.3 §7.1 — "Overall Fairness Score vs J_ideal" needs a definition

Meeting counts are integers, so the best possible distribution puts every feasible pair at ⌊m⌋ or ⌈m⌉.
With P feasible pairs and f = m − ⌊m⌋:

- **min Σ(c − m)² = P · f(1 − f)**
- **min MAD = 2f(1 − f)**

Those are lower bounds — combinatorial design limits mean they often aren't reachable (none of the §4
configurations get close). A 0–100% score still needs a second anchor (e.g. the expected J of a random
valid draw) to be meaningful; the spec should pick one.

### 2.4 §2.1 / §4.2 — Feasibility and the initial construction

G ≥ T_max is **sufficient** for a single round with balanced group sizes, and there's a one-line
constructive proof worth putting in §4.2: order pilots team by team and **deal them round-robin** across
groups 1..G. Any team of size ≤ G occupies consecutive positions mod G, so its members land in distinct
groups; the deal also produces sizes differing by at most one. (The §4 benchmark uses exactly this as the
annealing start state, and every one of its draws passes validity checks.)

The spec's current wording ("place members of the largest teams into distinct groups, then fill") can dead-end
if implemented naively. Specify the round-robin deal and it can't.

GliderScore does not pre-validate this; it relies on pigeonhole forcing plus the 200-attempt prompt, because
its greedy builder (and frequency constraints) can dead-end even when a solution exists.

### 2.5 §6.3 — Seeded group order is the opposite of GliderScore's

- **GliderScore:** Group 1 = lowest cumulative scores. Leaders fly in the last group.
- **Mike:** Group 1 = top-ranked tier.

This is a **decision, not a bug** — flying the leaders last is a common convention (it plays like a final and
the leaders see the conditions everyone else got), but it's worth confirming intent. Good question for Gerry.

### 2.6 §6.3 step 4 — Seeded + team protection needs a fallback

GliderScore simply **forbids** team protection in seeded mode. The spec allows it via a minimal
rank-displacement swap into an *adjacent* group, but adjacent-only search can fail. Example: G = 3 and all
three members of one team rank into Group 1. The first extra teammate swaps into Group 2; the second can't
also go to Group 2, and Group 3 isn't adjacent to Group 1. Either forbid the combination like GliderScore or
define the fallback (widen the search radius).

### 2.7 §3.1 — Number of lanes should be configuration

The spec derives L = ⌈N/G⌉. Fields have a fixed number of pegs, and GliderScore uses a configured lane count.
Make it a contest setting (defaulting to max group size).

### 2.8 Constraints GliderScore has that the spec doesn't

- **Back-to-back** (`durAllowBackToBack`): stops a pilot in the last group of round r from being in the first
  group of round r+1. Note how narrow GliderScore's implementation is — it only removes the previous round's
  last-group pilots from the *first* group's candidate pool. In SA terms that's a hard constraint checked on
  swaps touching group G of round r or group 1 of round r+1.
- **Frequencies** — already flagged as an owner decision in the GliderScore parity review (PR #1).

### 2.9 Implementation notes the spec should state

- **Incremental ΔJ.** Computing ΔJ in O(group size) per swap is required for any reasonable budget.
  Swapping p_x (group a) with p_y (group b) changes only the pairs between p_x, p_y and the other members
  of a and b; each changes (c−μ)² by ±2(c−μ)+1. `draw_bench.py` does exactly this.
- **Cross-platform determinism.** A seeded PRNG isn't enough: `Math.exp` is implementation-approximated in
  JavaScript engines and isn't guaranteed bit-identical to .NET. Identical matrices across web/desktop/server
  need a fixed-point acceptance test (or precomputed thresholds) and an identical operation order.
- **Which groups get the extra pilot** when N mod G ≠ 0 is unspecified. GliderScore uses the lowest-numbered
  groups in both modes.

---

## 3. What to adopt from each

### Adopt from GliderScore

1. **Don't replace unless better, and let the CD re-run.** With seeds this becomes "try another seed, keep
   the better result" — cheap and matches what CDs already expect.
2. **MAD over feasible pairs as the CD-facing number**, shown with the meeting histogram (GliderScore's Check
   Draw screen, which also supports a selectable round range).
3. **The greedy group builder itself**, at least as a construction step — §4 shows it's genuinely strong.
4. **Late pilot insertion:** per round, pick a random compatible non-full group; if none, offer explicit
   overrides. Better still: pick the compatible group minimising the new pilot's meetings — GliderScore
   ignores history here.
5. **Seeded-round guards:** current round scored, next round unscored, re-draw only the last round, preview
   with an editable retired flag before committing.
6. **Pigeonhole forcing** is a cheap, useful idea for any greedy construction step.

### Where Mike's spec is already better

1. **Reproducible, auditable draws** (seed + algorithm version stored on the revision). GliderScore can't
   reproduce a draw.
2. **Global optimization** across all rounds instead of freezing each round greedily. §4 shows this only
   pays off with a much larger budget than specified — but it can match greedy, and it's the natural
   place to add objectives greedy can't handle.
3. **Lane co-optimization** instead of lanes as an afterthought. With an adequate budget it produced
   slightly more even lanes than GliderScore's post-hoc assignment in §4.
4. **Fairness report stored as data** on the revision.
5. **`preliminaryRounds` > 1** generalizes GliderScore's round-1-only seeded start.
6. **Validated scores (no open reviews)** as the seeded prerequisite — stricter than GliderScore's "scores
   entered," and consistent with the review workflow GliderScore doesn't have.
7. **Seeded + team protection** — worth keeping if the fallback in §2.6 is defined.

---

## 4. Head-to-head benchmark

### Setup

- **Harness:** [`draw_bench.py`](draw_bench.py) — standard library only. Run `python draw_bench.py c1`
  (or `c4`, `c10`); an optional second argument sets the number of seeds. Both algorithms are ports, not
  the originals.
- **GliderScore port** — a behavioural port of §1.2: seed/grow/score/pick, team pigeonhole forcing,
  per-round best-of-10 on cumulative MAD, a single build for round 1, greedy post-hoc lanes. Frequencies
  are omitted (all pilots 2.4GHz) and back-to-back is allowed, matching all three sample contests.
- **Spec port** — `matrix-draw.md` as written: J with w_lane = 0.15, μ and λ per §3.2, L = ⌈N/G⌉, 80/20
  swap/lane-swap moves with team-collision rejection, T₀ = 50, T_min = 0.001, incremental ΔJ. Initial state
  is the round-robin deal from §2.4. Because of the §2.1 ambiguity, three readings are tested, plus one
  run with 10× the budget.
- **Inputs:** team layouts embedded in the script — the team numbers of the non-retired pilots in three
  competitions from GliderScore's shipped sample database (no pilot data).
- **Method:** 5 seeds per variant; medians reported. **Every generated draw passes validity assertions**
  (each round partitions all pilots, group sizes balanced, no team-protection violations).
- **Metrics:** GliderScore MAD over feasible pairs, the spec's J, the most times any feasible pair meets,
  and feasible pairs that never meet. Lower is better for all four.

**Port fidelity:** for the 63-pilot contest, GliderScore's **real stored draw** has MAD **0.7101**; the port's
median is **0.7100** (per-seed range 0.700–0.734). The 30-pilot contest's stored draw doesn't compare
cleanly — its stored group sizes (7–8 pilots) show it was drawn with ~38 pilots before retirements.

### Results

**c10 — 23 pilots, 3 groups, 6 rounds, no teams** (MAD floor 0.287)

| Algorithm | MAD | J | Max meets | Unmet pairs |
|---|---|---|---|---|
| GliderScore greedy | **0.677** | 205.6 | 5 | 10 |
| Spec SA — T_min ends run (1,348 iterations) | 0.685 | 197.7 | 4 | 9 |
| Spec SA — 30k, clamped at T_min | 0.684 | **193.5** | 4 | 13 |
| Spec SA — 30k, α = 0.99964 | 0.681 | **193.5** | 4 | 12 |
| Spec SA — 300k, α matched | 0.696 | **193.5** | 4 | 13 |

**c1 — 30 pilots, 5 groups, 16 rounds, 8 teams of 3–4, team protection** (MAD floor 0.101)

| Algorithm | MAD | J | Max meets | Unmet pairs |
|---|---|---|---|---|
| GliderScore greedy | 0.445 | 534.7 | 5 | 0 |
| Spec SA — T_min ends run (1,348 iterations) | 0.832 | 871.9 | 7 | 2 |
| Spec SA — 30k, clamped at T_min | 0.512 | 564.3 | 5 | 0 |
| Spec SA — 30k, α = 0.99964 | 0.522 | 569.7 | 5 | 0 |
| Spec SA — **300k**, α matched | **0.444** | **529.7** | 5 | 0 |

**c4 — 63 pilots, 5 groups, 14 rounds, 14 teams of 3–5 (T_max = G), team protection** (MAD floor 0.338)

| Algorithm | MAD | J | Max meets | Unmet pairs |
|---|---|---|---|---|
| GliderScore greedy | **0.710** | **2,291.7** | 6 | **2** |
| Spec SA — T_min ends run (1,348 iterations) | 1.112 | 4,479.1 | 8 | 60 |
| Spec SA — 30k, clamped at T_min | 0.824 | 2,805.8 | 6 | 13 |
| Spec SA — 30k, α = 0.99964 | 0.832 | 2,858.1 | 7 | 13 |
| Spec SA — **300k**, α matched | 0.726 | 2,348.6 | 6 | 5 |

### Findings

1. **As specified, the annealer loses to GliderScore's greedy on both team-protected contests** — on MAD
   *and* on the spec's own objective J. With no teams (c10) the two are indistinguishable; each edges the
   other on the metric it optimizes.
2. **Reading T_min as a stop condition is badly worse.** On the 63-pilot contest, 60 feasible pairs never
   meet, versus 2 for GliderScore.
3. **Fixing the cooling schedule alone doesn't help at 30k.** The matched α was marginally *worse* than
   clamping at the floor on both team contests. The budget is the problem, not just the schedule.
4. **With 10× the budget, annealing ties GliderScore at 30 pilots, still trails at 63, and gains nothing on
   the no-teams contest.** The spec's claim that 30k iterations suffices for 100 pilots × 20 rounds (2,000
   placements — ~15 swaps each) is not supported by these results.
5. **Lanes:** with an adequate budget the annealer's co-optimized lanes were slightly more even (lane-count
   standard deviation 0.363 vs 0.370 on c4, 0.471 vs 0.558 on c1). At 30k on c4, GliderScore's post-hoc
   lanes were better (0.370 vs 0.499).
6. **Timing** from Python ports is not representative of JavaScript/WASM or C#. For relative scale only:
   GliderScore port 0.05–1.4 s, annealer at 30k 0.12–0.21 s, at 300k 1.6–2.7 s.

### Recommendations for `matrix-draw.md` §4

- **Scale the iteration budget with problem size** (N × R), and state that T_min is a floor, not a stop.
- **Use a greedy start state** *(untested)*: seed the annealer with a GliderScore-style greedy draw instead
  of the round-robin deal. Annealing can then only improve on a strong baseline, and greedy is cheap.
- **Or ship greedy-plus-restarts first** with a seeded PRNG, which keeps the spec's reproducibility, and
  add annealing as a polish step later if the fairness report shows room.
- Re-run `draw_bench.py` against any revised parameters before committing to them.

### Caveats

- Both are ports. The GliderScore port omits frequencies and back-to-back, and simplifies two rarely-hit
  paths (per-seed restarts and the 200-attempt prompt) to restart-until-feasible.
- Three configurations and 5 seeds per variant. Directionally clear, not a statistical study.
- Deliberately no parameter sweep beyond the single 10× budget check.

---

## 5. Questions for Mike / Gerry Carter

1. **Draw engine:** scale the annealing budget, seed it from greedy, or ship greedy-plus-restarts first?
2. **Seeded order:** leaders in Group 1 (spec) or last group (GliderScore)? Intentional either way?
3. **Seeded + team protection:** support it with a defined fallback, or forbid it like GliderScore?
4. **Back-to-back:** add it? If so, exactly GliderScore's narrow version (last group → next round's first
   group), or broader?
5. **Lanes:** configured count, or derived?
6. **Fairness score:** what's the second anchor for the 0–100% scale?
