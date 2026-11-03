import type { JsonMap, PublicPublicationSummary } from "./publication";

export type ContestStatus = "upcoming" | "inProgress" | "completed";

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
 * The server sends `status` (`upcoming`, `in_progress` or `completed`), worked
 * out when the list is read (#454). A recognised value wins; otherwise the
 * contest is completed once its end date has passed and upcoming before its
 * start. `state` is the venue's state, not a status.
 */
export function statusOf(raw: string | undefined, start: Date, end: Date, now: Date): ContestStatus {
  switch (raw?.toLowerCase()) {
    case "completed":
      return "completed";
    case "upcoming":
      return "upcoming";
    case "in_progress":
    case "running":
      return "inProgress";
  }
  if (end < now) return "completed";
  return start > now ? "upcoming" : "inProgress";
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
    status: statusOf(text(contest, "status"), start, end, now),
  };
}
