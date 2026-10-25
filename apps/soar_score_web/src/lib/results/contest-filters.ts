import { dayOf, type ContestSummary } from "./contest-summary";

/**
 * The user-supplied contest search filters, carried as query parameters on
 * `/results/contests` so a filtered list can be bookmarked.
 */
export interface ContestFilters {
  name: string;
  venue: string;
  /** Inclusive start-date bounds, as local calendar days. */
  from?: Date;
  to?: Date;
}

export const emptyFilters: ContestFilters = { name: "", venue: "" };

function parseDay(raw: string | null): Date | undefined {
  if (!raw) return undefined;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(raw);
  if (!m) return undefined;
  return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
}

/** `yyyy-MM-dd` of a local day. */
export function formatDay(day: Date): string {
  const p = (n: number, w = 2) => String(n).padStart(w, "0");
  return `${p(day.getFullYear(), 4)}-${p(day.getMonth() + 1)}-${p(day.getDate())}`;
}

export function filtersFromQuery(query: URLSearchParams): ContestFilters {
  return {
    name: query.get("name") ?? "",
    venue: query.get("venue") ?? "",
    from: parseDay(query.get("from")),
    to: parseDay(query.get("to")),
  };
}

export function filtersAreEmpty(f: ContestFilters): boolean {
  return f.name === "" && f.venue === "" && !f.from && !f.to;
}

/** Query parameters, with unset filters left out so the URL stays clean. */
export function filtersToQuery(f: ContestFilters): URLSearchParams {
  const q = new URLSearchParams();
  if (f.name) q.set("name", f.name);
  if (f.venue) q.set("venue", f.venue);
  if (f.from) q.set("from", formatDay(f.from));
  if (f.to) q.set("to", formatDay(f.to));
  return q;
}

const contains = (haystack: string, needle: string) =>
  needle === "" || haystack.toLowerCase().includes(needle.toLowerCase());

export function filtersMatch(f: ContestFilters, c: ContestSummary): boolean {
  const day = dayOf(c.start);
  return (
    contains(c.name, f.name) &&
    contains(c.venue, f.venue) &&
    (!f.from || day >= f.from) &&
    (!f.to || day <= f.to)
  );
}
