# RC Soar Score Architecture - Flight Matrix Draw Algorithm

## 1. Purpose and Scope

The Flight Matrix Draw engine is responsible for generating the allocation of pilots into flight groups and lanes (flight line stations) across all rounds of a contest.

The primary objective of the draw is to maximize competition variety by minimizing duplicate matchups between pilots across the contest, while strictly enforcing team protection and balancing lane assignments across rounds.

The engine must support:

1. Initial full-matrix generation prior to contest start.
2. Incremental round generation (adding rounds to an ongoing contest) optimized against prior matchup history.
3. Deterministic reproducibility via explicit random seeds stored on matrix revisions.
4. Comprehensive fairness metrics and matchup distribution reporting for the Contest Director.

---

## 2. Invariants and Constraints

### 2.1. Hard Constraints (Must Never Be Violated)

1. **Team Protection**: Two pilots assigned to the same team must never be assigned to the same flight group in any round.
   - **Feasibility Invariant**: When teams and team protection are enabled, the minimum number of groups per round ($G$) must be greater than or equal to the maximum team size ($T_{\max}$), counting only participants with the `Pilot` role:
     $$\text{GroupsPerRound} \ge \max_{t \in \text{Teams}} |\text{Pilots}(t)|$$
   - If this condition is violated during wizard setup or configuration, the draw engine must reject execution with a validation error before running.
2. **Participant Role Scope**: Only participants with the `Pilot` role (and active contest status) are included in the draw. Non-flying roles (officials, team managers, timers) are excluded from matrix assignments.
3. **Balanced Group Sizes**: In any round with $N$ total pilots and $G$ groups, the group size must differ by at most 1 pilot:
   - Base group size: $b = \lfloor N / G \rfloor$
   - Remainder: $r = N \bmod G$
   - Exactly $r$ groups contain $b + 1$ pilots, and $G - r$ groups contain $b$ pilots.
4. **Lane Exclusivity**: Within any flight group, no two pilots may be assigned to the same lane (flight line peg/station).
5. **Back-to-Back Flights (director option)**: The contest option **Allow back-to-back flights** is **on by default**, so by default a pilot may fly in the last group of round $N$ and the first group of round $N+1$. When the director turns the option off, the draw applies a hard constraint: no pilot may fly in the last group of round $N$ and the first group of round $N+1$. Turning the option off shows a notice that the fairness of the draw will decrease, because the constraint narrows the draws the optimizer can choose from. Re-flight groups are exempt. If the constraint makes a draw infeasible (for example in a small contest), the engine must reject the draw with a validation error that tells the director the constraint is the cause and that back-to-back flights can be allowed. Decision: [#78](https://github.com/mikejr83/rc-soar-score/issues/78).

### 2.2. Soft Optimization Goals (Cost Function Targets)

1. **Matchup Variety (Primary)**: Minimize the variance and duplicate count of head-to-head flights between all pairs of pilots across all rounds.
2. **Never-Met Pairs (Second)**: Among pairs that can meet, minimize the number that never fly together. Pilots notice "I never flew against X", and a squared-deviation cost alone under-weights it. Decision: Mike, 2026-10-07.
3. **Lane / Station Balance (Tertiary)**: Distribute lane assignments such that each pilot rotates through all available flight line stations as evenly as possible across the contest.

---

## 3. Mathematical Optimization Model

### 3.1. Definitions

- Let $P = \{p_1, p_2, \dots, p_N\}$ be the set of $N$ pilots.
- Let $R$ be the number of rounds, and $G$ be the number of groups per round.
- Let $L$ be the number of flight lanes: the contest option `lane_count`, which defaults to the largest group size $\lceil N / G \rceil$ and applies only when `lane_mode` is `Random`. It must be at least the largest group size. Decision: Mike, 2026-10-07 (supersedes the "derived" decision in ticket 029).
- Let a pair $(p_i, p_j)$ be **feasible** when the hard constraints allow it to meet: pairs on the same team under team protection can never meet and are **not feasible**. Let $P$ be the number of feasible pairs. Every target and every reported metric uses feasible pairs only.
- Let $c(p_i, p_j)$ be the cumulative number of times pilot $p_i$ and pilot $p_j$ fly in the same group across all evaluated rounds (including historical completed rounds in an incremental draw).
- Let $laneCount(p_i, l)$ be the number of times pilot $p_i$ is assigned to lane $l \in \{1, \dots, L\}$.

### 3.2. Target Baselines

- **Ideal Pairwise Matchup Target ($\mu$)**: the mean meeting count over feasible pairs,
  $$\mu = \frac{\text{total meetings}}{P} = \frac{R \cdot \sum_{g} \binom{|g|}{2}}{P}$$
  With no team protection and $G$ dividing $N$, this equals $R (\bar{g} - 1) / (N - 1)$ where $\bar{g} = N / G$. Counting teammates in the mean would make $\mu$ too low, because all meetings must be absorbed by the pairs that can meet.
- **Best Achievable Matchup Cost**: meeting counts are integers, so with $f = \mu - \lfloor \mu \rfloor$ the lowest possible $\sum (c - \mu)^2$ is $P \cdot f (1 - f)$, and the lowest possible mean absolute deviation is $2 f (1 - f)$. These are lower bounds. Combinatorial limits often make them unreachable.
- **Ideal Lane Allocation Target ($\lambda$)**:
  $$\lambda = \frac{R}{L}$$

### 3.3. Composite Cost Function

The optimization engine minimizes the total penalty $J$:

$$J = J_{\text{matchup}} + w_{\text{lane}} \cdot J_{\text{lane}}$$

1. **Matchup Penalty ($J\_{\text{matchup}}$)**:
   Penalizes deviations from ideal distribution, with quadratic weighting to heavily penalize multiple duplicate matchups ($c \ge 2$) over single matchups ($c = 1$ vs $c = 0$), summed over feasible pairs:
   $$J_{\text{matchup}} = \sum_{(i, j) \text{ feasible}} \left( c(p_i, p_j) - \mu \right)^2$$

2. **Lane Penalty ($J\_{\text{lane}}$)**:
   Penalizes uneven lane assignments for each pilot:
   $$J_{\text{lane}} = \sum_{i=1}^{N} \sum_{l=1}^{L} \left( laneCount(p_i, l) - \lambda \right)^2$$

3. **Weighting Factor**:
   $w_{\text{lane}} = 0.15$ (balances lane assignments without compromising group matchup fairness).
4. **Never-Met Priority**: Candidate draws are compared in this order: (1) fewest never-met feasible pairs, (2) lowest maximum repeat count, (3) lowest $J$. The optimizer applies this order when it accepts or keeps a draw. A pure quadratic $J$ under-weights never-met pairs: at 63 pilots a never-met pair costs about 6.9 while a pair meeting six times costs about 11.4, so the annealer trades never-met pairs for fewer heavy repeats. The research benchmark ([`research/gliderscore-draw`](../../research/gliderscore-draw/README.md)) did not test this order, so it must be benchmarked before it ships.

---

## 4. Optimization Algorithm

The draw engine **constructs a valid draw, then improves it across all rounds** with a **Constrained Seeded Conflict-Directed Simulated Annealing** local search. Round-by-round construction alone leaves fairness unclaimed, because an early round cannot be rearranged once later rounds show a better fit. Basis: [`research/gliderscore-draw`](../../research/gliderscore-draw/README.md), decision: Mike, 2026-10-07.

```
┌────────────────────────────────────────────────────────┐
│ 1. Validate Feasibility (Groups >= Max Team Size,      │
│    lane count, back-to-back feasibility)               │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│ 2. Seeded Greedy Construction (valid draw)             │
│    - Distribute teammates across distinct groups       │
│    - Balance group sizes and assign initial lanes      │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│ 3. Conflict-Directed Annealing over all rounds         │
│    - Pick random round r                               │
│    - Candidate swap: swap 2 pilots between groups or   │
│      swap lanes within a group                         │
│    - Verify hard constraints (team protection,         │
│      back-to-back when disallowed)                     │
│    - Evaluate ΔJ; accept if ΔJ < 0 or p < threshold(T) │
│    - Cool temperature T = T * α                        │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│ 4. Repeat for several seeds; keep the best draw        │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│ 5. Compute Fairness Metrics & Emit Matrix Revision     │
└────────────────────────────────────────────────────────┘
```

### 4.1. Pseudo-Random Number Generator (PRNG) and Determinism

- Must use a deterministic, seedable 32-bit PRNG (e.g., Mulberry32 or PCG32).
- If no seed is provided by the caller, generate a cryptographic 32-bit unsigned integer and store it in the matrix revision record.
- Running the engine with identical inputs ($P$, $R$, $G$, teams, prior history, and seed) must produce the exact same matrix on all platforms (web, desktop, server).
- A seeded PRNG is not enough. `exp` is approximated per implementation and is not guaranteed bit-identical across JavaScript engines, .NET and Dart. The acceptance test must use fixed-point arithmetic or precomputed thresholds, with an identical operation order everywhere.
- When $N \bmod G \ne 0$, the lower-numbered groups take the extra pilot (as GliderScore does), unless a move changes a group's size within the balanced bound.

### 4.2. Initial Feasible State Construction

1. Order pilots team by team (largest teams first, unteamed pilots last) and **deal them round-robin across groups $1 \dots G$**. Any team of size at most $G$ occupies consecutive positions modulo $G$, so its members land in distinct groups, and the deal also yields group sizes that differ by at most one. This is a constructive proof of the feasibility invariant, so it cannot dead-end.
2. For each round $r \in \{1, \dots, R\}$, shuffle the order of teams and of pilots within a team with the seeded PRNG before dealing.
3. A greedy refinement may then place each pilot in the compatible, non-full group with the fewest prior meetings (largest teams first, random ties, best of several builds per round).
4. Assign initial lanes $1 \dots |g|$ within each group.

### 4.3. Annealing Schedule & Perturbation

- **Parameters** (starting values, to be tuned by the benchmark):
  - Initial Temperature $T_0 = 2.0$ when starting from a greedy draw (a cool start); $50.0$ only from an unoptimized round-robin deal.
  - Cooling rate matched to the budget: $\alpha = (T_{\min} / T_0)^{1 / \text{iterations}}$.
  - $T_{\min} = 0.001$ is a **floor**, not a stop condition. Reaching it does not end the run, and the run always uses its full iteration budget.
  - **Iteration budget scales with problem size**, in proportion to pilots times rounds. The research needed about 300,000 iterations for 480 to 880 placements (roughly 340 to 625 per placement). 30,000 iterations lost to GliderScore on team contests.
- **Incremental ΔJ**: computing ΔJ in time proportional to the group size per swap is required. Swapping $p_x$ (group $a$) with $p_y$ (group $b$) changes only the pairs between $p_x$, $p_y$ and the other members of $a$ and $b$; each pair changes $(c - \mu)^2$ by $\pm 2(c - \mu) + 1$.
- **Perturbation Operators**:
  - **Inter-Group Pilot Swap (80% probability)**: Select a round $r$ and two groups $g_a, g_b$. Half of these moves are **conflict-directed**: the first pilot is the one with the most excess meetings in its group (the conflict-directed move used for the Social Golfer Problem, Dotú and Van Hentenryck, CPAIOR 2005). The other half pick a random pilot. If the swap does not violate a hard constraint (team collision in $g_a$ or $g_b$, or back-to-back when disallowed), compute $\Delta J$ and evaluate acceptance.
  - **Intra-Group Lane Swap (20% probability)**: Select a round $r$, group $g$, and two pilots $p_x, p_y \in g$. Swap their assigned lanes. (No team collision risk; optimizes $J_{\text{lane}}$).
- **Back-to-back hard constraint** (when the director option is off): checked on swaps that touch the last group of round $r$ or the first group of round $r + 1$.

### 4.4. Several Seeds, Keep the Best

- The engine runs the whole construct-and-improve pipeline for several seeds and keeps the best result by the order in section 3.3 item 4. The winning seed is stored on the matrix revision, so the draw stays reproducible.
- Re-running a draw replaces the existing one only when the new result is better, and the director previews it before committing. This matches what directors expect from GliderScore's "re-run the draw".
- Per-seed spread was 4 to 13% of the median MAD in the benchmark, so extra seeds are worth the time.

### 4.5. Running Time

A polish pass took 4 to 9 seconds in Python in the benchmark, and several seeds multiply that. The draw runs off the UI thread (an isolate on native, a worker on web) with progress and a cancel button.

### 4.6. Baseline Draw (`basic-2`)

The first draw is already fairness-driven, before the optimizer exists. The director sets the number of rounds and the number of **attempts per round** (default 50, 1 to 200). Rounds are built one after another, each round `attempts` times: every pilot goes to the open group where they meet the opponents they have met least in earlier rounds, teammates are kept apart, and the build with the lowest sum of squared meeting counts is kept. This is a greedy construction with best-of-N per round, the same family as GliderScore's. In a 30-pilot, 5-group, 16-round team contest it gave a mean absolute deviation of about 0.57 at 10 attempts and 0.53 at 50, against 0.71 with no comparison and 0.445 for GliderScore. The optimizer (sections 4.2 to 4.4) starts from this draw and closes the remaining gap.

---

## 5. Incremental Draw (Adding Rounds Mid-Contest)

When a Contest Director adds $K$ rounds to an ongoing contest that already has $R_{\text{done}}$ completed or scored rounds:

1. **History Ingestion**:
   - The engine extracts the cumulative matchup counts $c(p_i, p_j)$ and lane counts $laneCount(p_i, l)$ from rounds $1 \dots R_{\text{done}}$.
2. **Preservation**:
   - Assignments for rounds $1 \dots R_{\text{done}}$ are **immutable** and never modified.
3. **Target Recalculation**:
   - The new ideal target $\mu$ is computed over the total combined rounds $R_{\text{total}} = R_{\text{done}} + K$.
4. **Optimization**:
   - The optimizer runs only on the newly added rounds $R_{\text{done}} + 1 \dots R_{\text{total}}$, with $J_{\text{matchup}}$ and $J_{\text{lane}}$ measuring cumulative totals across all $R_{\text{total}}$ rounds.

---

## 6. Seeded Man on Man Draw Mode

In Seeded Man on Man mode, pilots are grouped by progressive performance so that competitors with similar cumulative scores fly directly against each other.

**Team protection is not available in Seeded Man on Man mode.** The new-contest wizard and contest configuration must prevent selecting both and explain why. Decision: [#77](https://github.com/mikejr83/rc-soar-score/issues/77).

### 6.1. Configuration and Preliminaries

1. **Preliminary Rounds Setting**: The contest configuration specifies `preliminaryRounds` (integer $\ge 1$, default $1$).
2. **Initial Draw Execution**:
   - **If `preliminaryRounds == 1`**: Round 1 is drawn as a **randomized allocation** that satisfies team protection, balanced group sizes, and lane exclusivity. (Because no scores exist prior to round 1, seeding cannot occur).
   - **If `preliminaryRounds > 1`**: Rounds $1 \dots \text{preliminaryRounds}$ are drawn as a block using the **standard Man on Man simulated annealing optimizer** (minimizing duplicate matchups while enforcing team protection and lane balance).
   - Seeded rounds ($\text{preliminaryRounds} + 1 \dots$) are **not** generated during the initial draw.

### 6.2. Round-by-Round Seeded Generation Workflow

1. **Single Next-Round Scope**: Seeded rounds must be drawn strictly **one round at a time**, for the immediate next round $R_{\text{next}}$ only. A contest director cannot draw round $R+2$ before round $R+1$ is flown and scored.
2. **Prerequisite Validation**:
   - All rounds $1 \dots R_{\text{next}} - 1$ must be complete with official/validated scores recorded for all active, non-retired pilots.
   - If any scores are unentered, unvalidated, or in an open review state, the engine rejects the draw request with a validation error identifying the incomplete assignments.

### 6.3. Seeded Group Assignment Algorithm

For round $R_{\text{next}}$:

1. **Calculate Standings**: Ingest the official cumulative standings and rankings for all active pilots computed through round $R_{\text{next}} - 1$ by the scoring calculation service (including dropped round and penalty rules as of that round).
2. **Sort by Rank**: Sort pilots in descending order by their cumulative contest score (rank 1 to $N$).
3. **Partition into Tiers**:
   - Determine group size quotas for $G$ groups such that $r = N \bmod G$ groups have size $\lfloor N/G \rfloor + 1$ and $G - r$ groups have size $\lfloor N/G \rfloor$.
   - Assign the **lowest-ranked** tier of pilots to Group 1, the next tier up to Group 2, through to the top-ranked tier in Group $G$. The leaders fly last, as in GliderScore: it plays like a final, and the leaders see the conditions everyone else flew in. Decision: Mike, 2026-10-07 (reverses the earlier top-ranked-first order).
4. **Team Protection Is Not Applied**: Seeded mode and team protection cannot be combined (see the note at the start of this section), so no team-clash swap is performed. The steps below describe a rejected combination, including their adjacent-group search that can fail (for example $G = 3$ with a team of three all ranked into one tier), and are kept only as design history. The tier order in step 3 would be reversed in them.
   - For each group $g_k$ from $1 \dots G$:
     - If $g_k$ contains multiple pilots from the same team:
       - Keep the highest-ranked teammate in $g_k$.
       - For each additional teammate $p_{\text{clash}}$ in $g_k$, find a replacement pilot $p_{\text{swap}}$ in the nearest adjacent group ($g_{k+1}$ or $g_{k-1}$) such that:
         1. $p_{\text{swap}}$ does not belong to any team currently represented in $g_k$.
         2. $p_{\text{clash}}$ does not belong to any team currently represented in $p_{\text{swap}}$'s group.
         3. The rank difference $|\text{rank}(p_{\text{clash}}) - \text{rank}(p_{\text{swap}})|$ is minimized.
       - Swap $p_{\text{clash}}$ and $p_{\text{swap}}$.
5. **Lane Assignment**:
   - Within each seeded group, assign lanes to pilots to minimize each pilot's cumulative lane variance based on their historical lane assignments in rounds $1 \dots R_{\text{next}} - 1$.
6. **Revision Emission**:
   - Generate an incremental `matrixRevision` linking the newly drawn round $R_{\text{next}}$ to the contest, recording the PRNG seed used for tie-breaking/lane allocation, the standings revision used for seeding, and the timestamp.

---

## 7. Fairness Metric and Audit Reporting

Every generated matrix revision produces a structured **Fairness Report** stored with the revision and displayed in the UI:

### 7.1. Metric Summary Attributes

| Metric                      | Description                                                                                                                           | Target                                                                          |
| :-------------------------- | :------------------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------ | ----------------------------------------------------------- | ------------------------------------------ |
| **Max Duplicate Matchups**  | The maximum number of times any single feasible pair of pilots $(p_i, p_j)$ fly against each other.                                   | $\le \lceil \mu \rceil + 1$ (Standard mode)                                     |
| **Matchup Distribution**    | Histogram of feasible-pair matchup counts: `0 times`, `1 time`, `2 times`, `3+ times`.                                                | Concentrated near $\lfloor \mu \rfloor$ and $\lceil \mu \rceil$ (Standard mode) |
| **Unmet Opponent Count**    | Number of **feasible** pilot pairs who never fly against each other ($c = 0$). Teammates under team protection are not counted.       | Minimized given $R$ and $G$                                                     |
| **Mean Absolute Deviation** | Mean of $                                                                                                                             | c - \mu                                                                         | $ over feasible pairs, shown with the matchup distribution. | Approaching $2 f (1 - f)$, the lower bound |
| **Lane Uniformity Index**   | Standard deviation of lane usage across all pilots.                                                                                   | Approaching 0                                                                   |
| **Overall Fairness Score**  | Normalized score from $0\%$ to $100\%$ comparing achieved $J$ against $J_{\text{ideal}}$ (100%) and $J_{\text{worst}}$ (0%), see 7.2. | $\ge 90\%$ (Standard mode)                                                      |

### 7.2. Fairness Score Scale

$$\text{Fairness} = 1 - \frac{J - J_{\text{ideal}}}{J_{\text{worst}} - J_{\text{ideal}}}$$

- **100%** means the achieved cost $J$ equals the theoretical best $J_{\text{ideal}}$, the lower bound in section 3.2 (often unreachable, so most draws score below 100%).
- **0%** means $J_{\text{worst}}$, the average cost of a purely random draw for the same contest size. A matrix worse than the random average is displayed as 0%.
- $J_{\text{worst}}$ is estimated by sampling random draws. The sample count and PRNG seed are fixed so that the same matrix always receives the same score.
- The score is reported for the whole matrix, with per-round detail shown alongside.

Decision: [#79](https://github.com/mikejr83/rc-soar-score/issues/79).

### 7.2. Matrix Revision Entity Contract

Each matrix revision stores:

- `matrixRevisionId`: Stable identifier.
- `contestId`: Owning contest.
- `revisionNumber`: Sequential integer.
- `drawMode`: `StandardManOnMan` or `SeededManOnMan`.
- `randomSeed`: 32-bit integer used for the draw.
- `algorithmVersion`: Version tag of the draw engine (e.g. `1.0.0`).
- `sourceStandingsRevision`: Reference to scoring calculation revision (for seeded rounds).
- `createdAt`: Timestamp.
- `createdBy`: Actor identity.
- `fairnessSummary`: JSON object containing matchup histogram, max duplicates, lane standard deviation, and quality score.
- `rounds`: Array of rounds with group and lane assignments.
