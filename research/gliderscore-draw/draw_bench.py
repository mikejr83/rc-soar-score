"""Draw benchmark: matrix-draw.md simulated annealing and clean-room alternatives.

Usage: python draw_bench.py <config> [seeds]
  config: c1  (30 pilots / 5 groups / 16 rounds, 8 teams, team protection)
          c4  (63 pilots / 5 groups / 14 rounds, 14 teams, team protection)
          c10 (23 pilots / 3 groups / 6 rounds, no teams)

Standard library only. Team layouts are the team numbers of the non-retired pilots in three
competitions from GliderScore's shipped sample database (team numbers only, no pilot data).
Frequencies are ignored (all 2.4GHz); back-to-back is allowed, as in all three sample comps.

GliderScore figures in README.md are recorded results from a local port that is intentionally not
included here. See README.md §4–§5 for results and caveats.
"""
import sys, math, random, time, itertools
from collections import Counter, defaultdict

# config: (groups per round, rounds, team protection, team number per pilot; 0 = no team)
CONFIGS = {
    'c1': (5, 16, True, [8, 8, 6, 4, 3, 8, 5, 5, 4, 3, 3, 3, 1, 1, 2, 6, 1, 6, 2, 7, 4, 7, 4, 2, 7, 8, 5, 5, 1, 7]),
    'c4': (5, 14, True, [1, 1, 10, 6, 9, 3, 3, 3, 4, 8, 13, 9, 9, 11, 11, 11, 9, 6, 6, 6, 13, 13, 5, 12, 10, 10,
                         10, 10, 14, 14, 8, 8, 13, 5, 14, 2, 2, 2, 14, 11, 14, 8, 7, 1, 4, 8, 7, 7, 9, 11, 5, 3,
                         4, 4, 13, 12, 2, 2, 12, 12, 7, 5, 12]),
    'c10': (3, 6, False, [0] * 23),
}

def sizes(N, G):  # balanced; lower-numbered groups get the extra pilot
    b, r = divmod(N, G)
    return [b + 1] * r + [b] * (G - r)

# ---------------------------------------------------------------- shared metrics
def meetings(draw, N):
    M = [[0] * N for _ in range(N)]
    for rnd in draw:
        for g in rnd:
            for a, b in itertools.combinations(g, 2):
                M[a][b] += 1; M[b][a] += 1
    return M

def gs_mad(M, team, prot):
    """MAD of pairwise meeting counts over pairs that can meet (never-met teammates excluded)."""
    N = len(M)
    vals = [M[i][j] for i in range(N) for j in range(i + 1, N)
            if not (prot and team[i] and team[i] == team[j] and M[i][j] == 0)]
    m = sum(vals) / len(vals)
    return sum(abs(v - m) for v in vals) / len(vals), m, vals

def check_valid(draw, N, G, team, prot):
    want = sorted(sizes(N, G))
    for rnd in draw:
        flat = [p for g in rnd for p in g]
        assert sorted(flat) == list(range(N)), "round is not a partition of all pilots"
        assert sorted(len(g) for g in rnd) == want, "group sizes not balanced"
        if prot:
            for g in rnd:
                ts = [team[p] for p in g if team[p]]
                assert len(ts) == len(set(ts)), "team protection violated"

def lane_std(lanes, N, L):
    cnt = [[0] * L for _ in range(N)]
    for rnd in lanes:
        for p, l in rnd.items():
            cnt[p][l] += 1
    flat = [x for row in cnt for x in row]
    m = sum(flat) / len(flat)
    return math.sqrt(sum((x - m) ** 2 for x in flat) / len(flat)), cnt

def spec_J(M, lane_cnt, N, G, R, L):
    gbar = N / G; mu = R * (gbar - 1) / (N - 1); lam = R / L
    jm = sum((M[i][j] - mu) ** 2 for i in range(N) for j in range(i + 1, N))
    jl = sum((x - lam) ** 2 for row in lane_cnt for x in row)
    return jm + 0.15 * jl

# ---------------------------------------------------------------- clean-room greedy construction
def generic_greedy(N, G, R, team, prot, rng, K=10):
    """Most-constrained-first insertion: teams largest first, each pilot into the compatible non-full
    group with the fewest prior meetings (random ties). Best of K builds per round, scored by the
    increase in the sum of squared meeting counts."""
    sz = sizes(N, G)
    M = [[0] * N for _ in range(N)]
    by_team = defaultdict(list)
    for p in range(N):
        by_team[team[p] if (prot and team[p]) else ('solo', p)].append(p)

    def build():
        tl = list(by_team.values()); rng.shuffle(tl); tl.sort(key=len, reverse=True)
        order = []
        for t in tl:
            t = t[:]; rng.shuffle(t); order += t
        groups = [[] for _ in range(G)]
        for p in order:
            cands = [gi for gi in range(G) if len(groups[gi]) < sz[gi]
                     and not (prot and team[p] and any(team[q] == team[p] for q in groups[gi]))]
            if not cands:
                return None
            cost = {gi: sum(M[p][q] for q in groups[gi]) for gi in cands}
            lo = min(cost.values())
            groups[rng.choice([gi for gi in cands if cost[gi] == lo])].append(p)
        return groups

    draw = []
    for r in range(R):
        best, best_s = None, None
        for _ in range(K):
            for _ in range(1000):
                g = build()
                if g is not None:
                    break
            else:
                raise RuntimeError("generic greedy: no feasible round in 1000 attempts")
            s = sum(2 * M[a][b] + 1 for grp in g for a, b in itertools.combinations(grp, 2))
            if best is None or s < best_s:
                best, best_s = g, s
        for grp in best:
            for a, b in itertools.combinations(grp, 2):
                M[a][b] += 1; M[b][a] += 1
        draw.append(best)
    lanes = [{p: k for grp in rnd for k, p in enumerate(grp)} for rnd in draw]
    return draw, lanes

# ---------------------------------------------------------------- matrix-draw.md simulated annealing
def sa_draw(N, G, R, team, prot, rng, alpha=0.992, T0=50.0, Tmin=0.001, iters=30000, stop_at_tmin=False,
            init=None, targeted=False):
    """init: optional (rounds, lanes) start state. targeted: half of pilot swaps take the pilot with the
    most excess meetings in its group (conflict-directed local search, as for the social golfer problem)."""
    sz = sizes(N, G); L = math.ceil(N / G)
    gbar = N / G; mu = R * (gbar - 1) / (N - 1); lam = R / L; wl = 0.15

    if init is None:
        # initial feasible state — randomized round-robin deal, largest teams first (always valid)
        by_team = defaultdict(list)
        for p in range(N):
            by_team[team[p] or ('solo', p)].append(p)
        rounds, lane = [], []
        for r in range(R):
            order = []
            tlist = list(by_team.values()); rng.shuffle(tlist); tlist.sort(key=len, reverse=True)
            for t in tlist:
                t = t[:]; rng.shuffle(t); order += t
            groups = [[] for _ in range(G)]; gi = 0
            for p in order:
                while len(groups[gi % G]) >= sz[gi % G]:
                    gi += 1
                groups[gi % G].append(p); gi += 1
            rounds.append(groups)
            lane.append({p: k for g in groups for k, p in enumerate(g)})
    else:
        rounds = [[g[:] for g in rnd] for rnd in init[0]]
        lane = [dict(lr) for lr in init[1]]

    M = meetings(rounds, N)
    lc = [[0] * L for _ in range(N)]
    for lr in lane:
        for p, l in lr.items():
            lc[p][l] += 1

    T = T0; done = 0
    for it in range(iters):
        if stop_at_tmin and T <= Tmin:
            break
        done += 1
        r = rng.randrange(R)
        if rng.random() < 0.8:  # inter-group pilot swap
            ga, gb = rng.sample(range(G), 2)
            A, B = rounds[r][ga], rounds[r][gb]
            if targeted and rng.random() < 0.5:
                ex = [sum(M[p][q] - mu for q in A if q != p and M[p][q] > mu) for p in A]
                hi = max(ex)
                px = rng.choice([p for p, e in zip(A, ex) if e == hi])
            else:
                px = rng.choice(A)
            py = rng.choice(B)
            if prot:
                if team[px] and any(team[q] == team[px] for q in B if q != py):
                    T = max(T * alpha, Tmin); continue
                if team[py] and any(team[q] == team[py] for q in A if q != px):
                    T = max(T * alpha, Tmin); continue
            dJ = 0.0  # incremental: only pairs involving px / py change
            for q in A:
                if q != px:
                    dJ += (-2 * (M[px][q] - mu) + 1) + (2 * (M[py][q] - mu) + 1)
            for q in B:
                if q != py:
                    dJ += (-2 * (M[py][q] - mu) + 1) + (2 * (M[px][q] - mu) + 1)
            la, lb = lane[r][px], lane[r][py]
            if la != lb:
                dl = ((-2 * (lc[px][la] - lam) + 1) + (2 * (lc[px][lb] - lam) + 1)
                      + (-2 * (lc[py][lb] - lam) + 1) + (2 * (lc[py][la] - lam) + 1))
                dJ += wl * dl
            if dJ < 0 or rng.random() < math.exp(-dJ / T):
                for q in A:
                    if q != px:
                        M[px][q] -= 1; M[q][px] -= 1; M[py][q] += 1; M[q][py] += 1
                for q in B:
                    if q != py:
                        M[py][q] -= 1; M[q][py] -= 1; M[px][q] += 1; M[q][px] += 1
                A[A.index(px)] = py; B[B.index(py)] = px
                if la != lb:
                    lc[px][la] -= 1; lc[px][lb] += 1; lc[py][lb] -= 1; lc[py][la] += 1
                lane[r][px], lane[r][py] = lb, la
        else:  # intra-group lane swap
            g = rounds[r][rng.randrange(G)]
            px, py = rng.sample(g, 2)
            la, lb = lane[r][px], lane[r][py]
            dl = ((-2 * (lc[px][la] - lam) + 1) + (2 * (lc[px][lb] - lam) + 1)
                  + (-2 * (lc[py][lb] - lam) + 1) + (2 * (lc[py][la] - lam) + 1))
            dJ = wl * dl
            if dJ < 0 or rng.random() < math.exp(-dJ / T):
                lc[px][la] -= 1; lc[px][lb] += 1; lc[py][lb] -= 1; lc[py][la] += 1
                lane[r][px], lane[r][py] = lb, la
        T = max(T * alpha, Tmin)
    return rounds, lane, done

# ---------------------------------------------------------------- run
def report(name, fn, N, G, R, team, prot, seeds):
    L = math.ceil(N / G); rows = []
    for seed in range(seeds):
        rng = random.Random(seed)
        t0 = time.perf_counter(); draw, lanes, done = fn(rng); dt = time.perf_counter() - t0
        check_valid(draw, N, G, team, prot)
        M = meetings(draw, N)
        mad, m, vals = gs_mad(M, team, prot)
        ls, cnt = lane_std(lanes, N, L)
        f = m - math.floor(m)
        rows.append(dict(mad=mad, floor=2 * f * (1 - f), maxm=max(vals), unmet=vals.count(0),
                         J=spec_J(M, cnt, N, G, R, L), lane=ls, t=dt, it=done))
    med = lambda k: sorted(x[k] for x in rows)[len(rows) // 2]
    print(f"{name:30} MAD={med('mad'):.4f} (floor {rows[0]['floor']:.4f}) maxMeet={med('maxm')} "
          f"unmetFeasible={med('unmet')} J={med('J'):.1f} laneStd={med('lane'):.3f} "
          f"time={med('t'):.2f}s" + (f" iters={med('it')}" if rows[0]['it'] else ""))
    print(f"{'':30} MAD per seed={[round(x['mad'], 4) for x in rows]}")
    return rows

def main():
    cfg = sys.argv[1]; seeds = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    G, R, prot, team = CONFIGS[cfg]
    N = len(team)
    tsz = Counter(t for t in team if t)
    print(f"# {cfg}: N={N} G={G} R={R} protection={prot} teams={len(tsz)} "
          f"team sizes={dict(sorted(Counter(tsz.values()).items()))} group sizes={sizes(N, G)}")
    IT, Tmin = 300000, 0.001
    a50 = (Tmin / 50) ** (1 / IT)
    a2 = (Tmin / 2) ** (1 / IT)
    polish = lambda init, rng: sa_draw(N, G, R, team, prot, rng, T0=2.0, alpha=a2, iters=IT, init=init)
    tpolish = lambda init, rng: sa_draw(N, G, R, team, prot, rng, T0=2.0, alpha=a2, iters=IT, init=init,
                                        targeted=True)
    variants = [
        # §4 — matrix-draw.md as written
        ('Spec SA, T_min stops run', lambda rng: sa_draw(N, G, R, team, prot, rng, stop_at_tmin=True)),
        ('Spec SA, 30k at T_min floor', lambda rng: sa_draw(N, G, R, team, prot, rng)),
        ('Spec SA, alpha=0.99964 30k', lambda rng: sa_draw(N, G, R, team, prot, rng, alpha=0.99964)),
        ('Spec SA, 300k alpha matched', lambda rng: sa_draw(N, G, R, team, prot, rng, alpha=a50, iters=IT)),
        # §5 — clean-room improvements
        ('Generic greedy', lambda rng: generic_greedy(N, G, R, team, prot, rng) + (None,)),
        ('Generic greedy + 300k polish', lambda rng: polish(generic_greedy(N, G, R, team, prot, rng), rng)),
        ('Conflict-directed SA 300k', lambda rng: sa_draw(N, G, R, team, prot, rng, alpha=a50, iters=IT,
                                                          targeted=True)),
        ('Greedy + conflict polish 300k', lambda rng: tpolish(generic_greedy(N, G, R, team, prot, rng), rng)),
    ]
    for name, fn in variants:
        report(name, fn, N, G, R, team, prot, seeds)

if __name__ == '__main__':
    main()
