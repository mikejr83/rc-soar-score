import { venueOf } from "./contest-summary";
import { label } from "./format";
import type { JsonMap, PublicPublication } from "./publication";

/** How the projection labels one raw score field (`calculation.score_fields`). */
export interface ScoreFieldInfo {
  name: string;
  unit?: string;
  precision?: number;
}

/** Labels and number formats for the raw score fields; falls back to the key. */
export class ScoreFields {
  constructor(private readonly byKey: Map<string, ScoreFieldInfo> = new Map()) {}

  /** The field's name with its unit, or the key made readable. */
  label(key: string): string {
    const field = this.byKey.get(key);
    if (!field) return label(key);
    return field.unit ? `${field.name} (${field.unit})` : field.name;
  }

  /** A raw value at the field's precision; `-` when the scorer left it out. */
  format(key: string, value: unknown): string {
    if (value == null) return "-";
    const precision = this.byKey.get(key)?.precision;
    return typeof value === "number" && precision !== undefined ? value.toFixed(precision) : String(value);
  }
}

/** The contest identity the page header shows. */
export interface ContestHeader {
  name: string;
  start?: Date;
  end?: Date;
  venue: string;
  discipline: string;
  isCompleted: boolean;
}

/** One row of the Overall Individual Results as of a selected round. */
export interface PilotStandingRow {
  pilotKey: string;
  place: number;
  isTied: boolean;
  /** Empty for a redacted pilot. */
  firstName: string;
  lastName: string;
  country: string;
  overallScore: number;
  /** 0 to 100; 100 for the winner. */
  percentOfWinner: number;
  rawTotal: number;
  /** Round ordinal to that round's score; a round without a flight is absent. */
  roundScores: Map<number, number>;
  droppedRounds: Set<number>;
  penaltyTotal: number;
}

export interface TeamStandingRow {
  teamKey: string;
  place: number;
  isTied: boolean;
  name: string;
  teamScore: number;
  percentOfWinner: number;
  /** The team's pilots that have a standing as of the round, by place. */
  pilots: PilotStandingRow[];
}

/** The F5J profile's flight time field; other disciplines use it or none. */
export const timeKey = "time_flown";

export interface FlightScoreRow {
  pilotKey: string;
  name: string;
  country: string;
  outcome: string;
  /** The discipline's raw inputs; empty until the projection carries them (#456). */
  rawComponents: JsonMap;
  landingPoints: number;
  rawPoints: number;
  groupScore: number;
  penaltyPoints: number;
  /** False for a flight replaced by a re-flight. */
  isSelected: boolean;
}

export interface FlightGroup {
  round: number;
  group: number;
  /** The re-flight ordinal, or undefined for the group's original flight. */
  reflight?: number;
  flights: FlightScoreRow[];
}

export const pilotName = (row: { firstName: string; lastName: string }) =>
  `${row.firstName} ${row.lastName}`.trim() || "Pilot withheld";

export const groupTitle = (g: FlightGroup) =>
  g.reflight === undefined ? `Group ${g.group}` : `Group ${g.group}, re-flight ${g.reflight}`;

export const hasRawComponents = (g: FlightGroup) =>
  g.flights.some((f) => Object.keys(f.rawComponents).length > 0);

/** The raw component keys other than the flight time, in first-seen order. */
export function detailKeys(g: FlightGroup): string[] {
  const keys = new Set<string>();
  for (const f of g.flights) for (const k of Object.keys(f.rawComponents)) if (k !== timeKey) keys.add(k);
  return [...keys];
}

const num = (v: unknown, fallback = 0): number => (typeof v === "number" ? v : fallback);
const str = (v: unknown, fallback = ""): string => (typeof v === "string" ? v : fallback);
const parseDate = (v: unknown): Date | undefined => {
  if (typeof v !== "string") return undefined;
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? undefined : d;
};

export function contestHeaderFrom(contest: JsonMap, now: Date): ContestHeader {
  const end = parseDate(contest.end);
  const status = contest.status;
  return {
    name: str(contest.name, "Untitled contest"),
    start: parseDate(contest.start),
    end,
    venue: venueOf(contest),
    discipline: str(contest.discipline),
    // Completed comes from the lifecycle state once the projection carries it
    // (#454); until then a contest whose end date has passed counts.
    isCompleted: typeof status === "string" ? status === "Completed" : end !== undefined && end < now,
  };
}

export const headerStatus = (h: ContestHeader) => (h.isCompleted ? "Completed" : "In progress");

function scoreFieldsFrom(calculation: JsonMap | null | undefined): ScoreFields {
  const byKey = new Map<string, ScoreFieldInfo>();
  const fields = calculation?.score_fields;
  for (const f of Array.isArray(fields) ? (fields as JsonMap[]) : []) {
    if (typeof f?.key !== "string") continue;
    byKey.set(f.key, {
      name: str(f.name, label(f.key)),
      unit: typeof f.unit === "string" ? f.unit : undefined,
      precision: typeof f.precision === "number" ? f.precision : undefined,
    });
  }
  return new ScoreFields(byKey);
}

/** A published contest parsed once; components read this, never the raw maps. */
export class PublishedContest {
  readonly header: ContestHeader;
  readonly disciplineType: string;
  readonly scoreFields: ScoreFields;
  private readonly participants = new Map<string, JsonMap>();
  private readonly scores = new Map<string, JsonMap>();
  private readonly flights = new Map<number, JsonMap[]>();
  private readonly standings = new Map<number, JsonMap[]>();
  private readonly teams: JsonMap[];
  private readonly teamStandings = new Map<number, JsonMap[]>();

  constructor(dto: PublicPublication, now: Date = new Date()) {
    this.header = contestHeaderFrom(dto.contest, now);
    this.disciplineType = dto.discipline_type;
    this.scoreFields = scoreFieldsFrom(dto.calculation);
    for (const p of dto.participants ?? []) this.participants.set(str(p.pilot_key), p);
    // One flight per pilot per round counts; a reflight replaces it. The
    // flight groups view shows every flight, so those are kept per round too.
    for (const s of dto.scores ?? []) {
      const round = num(s.round);
      const key = `${round}:${str(s.pilot_key)}`;
      if (s.selected !== false || !this.scores.has(key)) this.scores.set(key, s);
      let list = this.flights.get(round);
      if (!list) this.flights.set(round, (list = []));
      list.push(s);
    }
    for (const r of dto.standings?.rounds ?? []) {
      const asOf = num(r.as_of_round);
      this.standings.set(asOf, (r.pilots as JsonMap[] | undefined) ?? []);
      this.teamStandings.set(asOf, (r.teams as JsonMap[] | undefined) ?? []);
    }
    this.teams = dto.teams ?? [];
  }

  /** True when the contest has teams; the team view redirects otherwise. */
  get hasTeams(): boolean {
    return this.teams.length > 0;
  }

  /** The rounds that have standings, ascending. */
  get rounds(): number[] {
    return [...this.standings.keys()].sort((a, b) => a - b);
  }

  /** The highest-numbered round with standings, or undefined before any scores. */
  get latestRound(): number | undefined {
    return this.rounds.at(-1);
  }

  private details(pilotKey: string): JsonMap {
    return (this.participants.get(pilotKey)?.details as JsonMap | null | undefined) ?? {};
  }

  /** Overall results as of `round`: by place, then last name for ties. */
  rowsAsOf(round: number): PilotStandingRow[] {
    const pilots = this.standings.get(round);
    if (!pilots) return [];
    const winner = Math.max(0, ...pilots.map((p) => num(p.overall_score)));
    return pilots
      .map((p) => this.row(p, round, winner))
      .sort(
        (a, b) =>
          a.place - b.place ||
          a.lastName.localeCompare(b.lastName) ||
          a.firstName.localeCompare(b.firstName),
      );
  }

  private row(p: JsonMap, round: number, winner: number): PilotStandingRow {
    const key = str(p.pilot_key);
    const details = this.details(key);
    const overall = num(p.overall_score);
    const roundScores = new Map<number, number>();
    for (let r = 1; r <= round; r++) {
      const score = this.scores.get(`${r}:${key}`)?.group_score;
      if (typeof score === "number") roundScores.set(r, score);
    }
    return {
      pilotKey: key,
      place: num(p.place),
      isTied: p.tied === true,
      firstName: str(details.first_name),
      lastName: str(details.last_name),
      country: str(details.country),
      overallScore: overall,
      percentOfWinner: winner > 0 ? (overall / winner) * 100 : 0,
      rawTotal: num(p.raw_total),
      roundScores,
      droppedRounds: new Set(((p.dropped_rounds as number[] | undefined) ?? []).map(Number)),
      penaltyTotal: num(p.penalty_total),
    };
  }

  /** Team Scores as of `round`: teams by place, each with its pilots by place. */
  teamRowsAsOf(round: number): TeamStandingRow[] {
    const standings = this.teamStandings.get(round);
    if (!standings || standings.length === 0) return [];
    const pilots = new Map(this.rowsAsOf(round).map((p) => [p.pilotKey, p]));
    const winner = Math.max(0, ...standings.map((t) => num(t.team_score)));
    return standings
      .map((s) => {
        const key = str(s.team_key);
        const team = this.teams.find((t) => t.team_key === key) ?? {};
        const score = num(s.team_score);
        return {
          teamKey: key,
          place: num(s.place),
          isTied: s.tied === true,
          name: str(team.name, key),
          teamScore: score,
          percentOfWinner: winner > 0 ? (score / winner) * 100 : 0,
          pilots: ((team.pilots as string[] | undefined) ?? [])
            .map((p) => pilots.get(p))
            .filter((p): p is PilotStandingRow => p !== undefined)
            .sort((a, b) => a.place - b.place),
        };
      })
      .sort((a, b) => a.place - b.place || a.name.localeCompare(b.name));
  }

  /** The flight groups of `round` by group number, a re-flight after its group. */
  flightGroupsOf(round: number): FlightGroup[] {
    const groups = new Map<string, FlightGroup>();
    for (const f of this.flights.get(round) ?? []) {
      // TODO(#457): `reflight` is this page's provisional name for the ordinal.
      const raw = f.reflight;
      const reflight = typeof raw === "number" && raw > 0 ? raw : raw === true ? 1 : undefined;
      const group = num(f.group);
      const id = `${group}:${reflight ?? 0}`;
      let g = groups.get(id);
      if (!g) groups.set(id, (g = { round, group, reflight, flights: [] }));
      g.flights.push(this.flight(f));
    }
    return [...groups.values()]
      .sort((a, b) => a.group - b.group || (a.reflight ?? 0) - (b.reflight ?? 0))
      .map((g) => ({ ...g, flights: g.flights.sort((a, b) => b.groupScore - a.groupScore) }));
  }

  private flight(f: JsonMap): FlightScoreRow {
    const key = str(f.pilot_key);
    const details = this.details(key);
    return {
      pilotKey: key,
      name: pilotName({ firstName: str(details.first_name), lastName: str(details.last_name) }),
      country: str(details.country),
      outcome: str(f.outcome),
      rawComponents: (f.raw_components as JsonMap | null | undefined) ?? {},
      landingPoints: num(f.landing_points),
      rawPoints: num(f.raw_points),
      groupScore: num(f.group_score),
      penaltyPoints: num(f.penalty_points),
      isSelected: f.selected !== false,
    };
  }
}
