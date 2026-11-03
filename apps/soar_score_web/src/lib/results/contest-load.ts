import { ApiHttpError, fetchPublication } from "./api";
import { PublishedContest } from "./published-contest";

/** What the contest page got when it asked for a contest. */
export type ContestLoadResult =
  | { kind: "loaded"; contest: PublishedContest }
  /** Unknown or delisted (HTTP 404). */
  | { kind: "notFound" }
  /** Exists but is pending or private (#463). */
  | { kind: "notVisible" }
  | { kind: "failed"; message: string };

const idShape = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function loadContest(
  contestId: string,
  signal?: AbortSignal,
  now: Date = new Date(),
): Promise<ContestLoadResult> {
  // A malformed id is the spec's "bad URL" case; no request is made.
  if (!idShape.test(contestId)) return { kind: "notFound" };
  try {
    return { kind: "loaded", contest: new PublishedContest(await fetchPublication(contestId, signal), now) };
  } catch (e) {
    if (e instanceof ApiHttpError) {
      // 404: no such publication. 403 `contest_not_visible`: it exists but is
      // pending or private (#463).
      if (e.status === 404) return { kind: "notFound" };
      if (e.status === 403 && e.code === "contest_not_visible") return { kind: "notVisible" };
    }
    return { kind: "failed", message: e instanceof Error ? e.message : String(e) };
  }
}
