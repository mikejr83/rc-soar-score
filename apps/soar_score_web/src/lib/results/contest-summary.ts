import type { JsonMap, PublicPublicationSummary } from "./publication";

export type ContestStatus = "inProgress" | "completed";

/** One row of the contest search list, parsed once from the summary. */
export interface ContestSummary {
  publicationId: string;
  name: string;
  start: Date;
  end: Date;
  /** Host, city, state and country, whichever are set; empty when none are. */
  venue: string;
  status: ContestStatus;
}

function text(contest: JsonMap, key: string): string | undefined {
  const value = contest[key];
  return typeof value === "string" && value.trim() !== "" ? value.trim() : undefined;
}

function date(contest: JsonMap, key: string): Date | undefined {
  const value = text(contest, key);
  if (!value) return undefined;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? undefined : parsed;
}

/** Host, city, state, country joined; shared with the contest header. */
export function venueOf(contest: JsonMap): string {
  return ["host", "city", "state", "country"]
    .map((key) => text(contest, key))
    .filter((v): v is string => v !== undefined)
    .join(", ");
}

/**
 * The projection does not carry a contest status yet (#454). A recognised
 * `status` value wins; otherwise the contest is completed once its end date
 * has passed. `state` is the venue's state, not a status.
 */
function statusOf(raw: string | undefined, end: Date, now: Date): ContestStatus {
  switch (raw?.toLowerCase()) {
    case "completed":
      return "completed";
    case "in_progress":
    case "running":
      return "inProgress";
  }
  return end < now ? "completed" : "inProgress";
}

export function contestSummaryFrom(dto: PublicPublicationSummary, now: Date): ContestSummary {
  const contest = dto.contest;
  const start = date(contest, "start") ?? new Date(dto.published_at);
  const end = date(contest, "end") ?? start;
  return {
    publicationId: dto.publication_id,
    name: text(contest, "name") ?? "Untitled contest",
    start,
    end,
    venue: venueOf(contest),
    status: statusOf(text(contest, "status"), end, now),
  };
}

/** Local calendar day of a date, for date-only comparisons. */
export function dayOf(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

/**
 * True when the contest starts after the coming Sunday: a future contest is
 * listed only through the following weekend. Client-side until #455.
 */
export function startsAfterComingSunday(c: ContestSummary, now: Date): boolean {
  const today = dayOf(now);
  const sunday = new Date(today);
  sunday.setDate(today.getDate() + ((7 - today.getDay()) % 7));
  return dayOf(c.start) > sunday;
}

/** True when the contest was flown, in whole or in part, in the last 30 days. */
export function activeInLast30Days(c: ContestSummary, now: Date): boolean {
  const windowStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  return c.start <= now && c.end > windowStart;
}
