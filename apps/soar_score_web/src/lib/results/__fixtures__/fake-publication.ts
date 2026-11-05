import type { JsonMap, PublicPublication, PublicPublicationSummary } from "../publication";

/** The publication id the fake server knows. */
export const fakeContestId = "019c0000-0000-7000-8000-000000000030";

/**
 * A three-round F5J contest with four pilots, in the shape of
 * `GET /public/publications/{id}` (ported from the Flutter test fixture).
 *
 * - Smith wins every round. Baker and Adams tie for second after round 2.
 * - Waters flies 900, 990, 990; as of round 3 round 1 is dropped.
 * - Adams falls to fourth in round 3.
 * - Teams: the Eagles (Smith, Adams) lead the Hawks (Baker, Waters).
 * - Round 3 flies in two groups; Waters' group 2 flight is replaced by a
 *   re-flight, and its scores carry raw components (#456, #457).
 */
export function fakePublication({
  contestStatus,
  teams = true,
  discipline = "F5J",
}: { contestStatus?: string; teams?: boolean; discipline?: string } = {}): PublicPublication {
  const team = (t: string) => (teams ? t : null);
  return {
    publication_id: fakeContestId,
    visibility: "Public",
    projection_revision: 1,
    published_at: "2026-10-17T14:00:00Z",
    contest: {
      name: "Front Range ALES Open",
      start: "2026-10-10T14:00:00Z",
      end: "2026-10-11T22:00:00Z",
      timezone: "America/Denver",
      host: "Front Range Soaring",
      city: "Boulder",
      state: "CO",
      country: "USA",
      discipline,
      ...(contestStatus ? { status: contestStatus } : {}),
    },
    discipline_type: discipline,
    calculation_version: "f5j-1",
    results_hidden_through_round: null,
    participants: [
      pilot("smith", "John", "Smith", team("eagles")),
      pilot("baker", "Mike", "Baker", team("hawks")),
      pilot("adams", "Dave", "Adams", team("eagles")),
      pilot("waters", "Chuck", "Waters", team("hawks")),
    ],
    teams: teams
      ? [
          { team_key: "eagles", name: "Eagles", pilots: ["adams", "smith"] },
          { team_key: "hawks", name: "Hawks", pilots: ["baker", "waters"] },
        ]
      : [],
    matrix: null,
    scores: [
      score(1, "smith", 1000),
      score(2, "smith", 1000),
      score(3, "smith", 1000, { time: 600, height: 120 }),
      score(1, "baker", 998),
      score(2, "baker", 998),
      score(3, "baker", 998, { time: 598.8, height: 122 }),
      score(1, "adams", 998),
      score(2, "adams", 998),
      score(3, "adams", 850, { group: 2, time: 510, height: 140 }),
      score(1, "waters", 900),
      score(2, "waters", 990),
      score(3, "waters", 400, { group: 2, selected: false, time: 240, height: 135 }),
      score(3, "waters", 990, { group: 2, reflight: 1, time: 594, height: 118 }),
    ],
    standings: {
      rounds: [
        {
          as_of_round: 1,
          pilots: [
            standing("smith", 1, 1000),
            standing("baker", 2, 998, { tied: true }),
            standing("adams", 2, 998, { tied: true }),
            standing("waters", 4, 900),
          ],
          teams: teams ? [teamStanding("eagles", 1, 1998), teamStanding("hawks", 2, 1898)] : [],
        },
        {
          as_of_round: 2,
          pilots: [
            standing("smith", 1, 2000),
            standing("baker", 2, 1996, { tied: true }),
            standing("adams", 2, 1996, { tied: true }),
            standing("waters", 4, 1890),
          ],
          teams: teams ? [teamStanding("eagles", 1, 3996), teamStanding("hawks", 2, 3886)] : [],
        },
        {
          as_of_round: 3,
          pilots: [
            standing("smith", 1, 3000),
            standing("baker", 2, 2994),
            standing("waters", 3, 1980, { dropped: [1], penalty: 50 }),
            standing("adams", 4, 2846),
          ],
          teams: teams ? [teamStanding("eagles", 1, 5846), teamStanding("hawks", 2, 4974)] : [],
        },
      ],
    },
    calculation: {
      as_of_round: 3,
      computed_at: "2026-10-11T22:00:00Z",
      score_fields: [
        { key: "time_flown", name: "Time Flown", type: "time", unit: null, precision: null },
        { key: "launch_height", name: "Launch Height", type: "int", unit: "m", precision: 0 },
      ],
    },
  };
}

function pilot(key: string, first: string, last: string, team: string | null): JsonMap {
  return {
    pilot_key: key,
    classification: null,
    number: null,
    retired_at_round: null,
    team_key: team,
    details: { first_name: first, last_name: last, club: null, city: null, state: null, country: "USA" },
  };
}

function score(
  round: number,
  key: string,
  points: number,
  {
    group = 1,
    selected = true,
    reflight,
    time,
    height,
  }: { group?: number; selected?: boolean; reflight?: number; time?: number; height?: number } = {},
): JsonMap {
  return {
    round,
    group,
    pilot_key: key,
    outcome: "flown",
    raw_points: points,
    landing_points: 0,
    penalty_points: 0,
    group_score: points,
    selected,
    preliminary: false,
    ...(reflight !== undefined ? { re_flight: reflight } : {}),
    ...(time !== undefined ? { raw_components: { time_flown: time, launch_height: height } } : {}),
  };
}

function teamStanding(key: string, place: number, score: number): JsonMap {
  return {
    team_key: key,
    place,
    tied: false,
    team_score: score,
    counted_pilots: key === "eagles" ? ["adams", "smith"] : ["baker", "waters"],
    preliminary: false,
  };
}

function standing(
  key: string,
  place: number,
  overall: number,
  { tied = false, dropped = [], penalty = 0 }: { tied?: boolean; dropped?: number[]; penalty?: number } = {},
): JsonMap {
  return {
    pilot_key: key,
    place,
    tied,
    raw_total: overall + penalty,
    dropped_rounds: dropped,
    penalty_total: penalty,
    overall_score: overall,
    preliminary: false,
  };
}

/** A publication summary as `GET /public/publications` returns it. */
export function fakeSummary({
  name,
  start,
  end,
  host,
  city,
  state,
  country,
  status,
  discipline,
  id,
}: {
  name: string;
  start: Date;
  end?: Date;
  host?: string;
  city?: string;
  state?: string;
  country?: string;
  status?: string;
  discipline?: string;
  id?: string;
}): PublicPublicationSummary {
  return {
    publication_id: id ?? crypto.randomUUID(),
    published_at: start.toISOString(),
    projection_revision: 1,
    contest: {
      name,
      start: start.toISOString(),
      end: (end ?? new Date(start.getTime() + 8 * 3600_000)).toISOString(),
      timezone: "UTC",
      host,
      city,
      state,
      country,
      ...(discipline !== undefined ? { discipline } : {}),
      ...(status ? { status } : {}),
    },
    discipline_type: "f5j",
  };
}
