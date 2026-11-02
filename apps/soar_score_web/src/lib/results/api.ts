import { apiBaseUrl } from "@/lib/site";

import type { PublicPublication, PublicPublicationSummary } from "./publication";

/** A non-2xx answer, with the server's `{error:{code,message}}` when it sent one. */
export class ApiHttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string | undefined,
    message: string,
  ) {
    super(message);
    this.name = "ApiHttpError";
  }
}

async function getJson<T>(path: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    signal,
    headers: { accept: "application/json" },
  });
  if (!response.ok) {
    let code: string | undefined;
    let message = `HTTP ${response.status}`;
    try {
      const body = (await response.json()) as { error?: { code?: string; message?: string } };
      code = body.error?.code;
      message = body.error?.message ?? message;
    } catch {
      // Not a JSON body; keep the status text.
    }
    throw new ApiHttpError(response.status, code, message);
  }
  return (await response.json()) as T;
}

/** A page of the listing and the server's 30-day count. */
export interface PublicationList {
  publications: PublicPublicationSummary[];
  /** Contests completed or in progress in the last 30 days. */
  recentCount: number;
}

/**
 * The Public publications by contest start, newest first. [query] carries the
 * filters, `today` and `limit`; the server does the filtering and the cap.
 */
export async function fetchPublicationList(
  query: URLSearchParams,
  signal?: AbortSignal,
): Promise<PublicationList> {
  const json = await getJson<{
    publications: PublicPublicationSummary[];
    summary?: { recent_count?: number };
  }>(`/public/publications?${query.toString()}`, signal);
  return {
    publications: json.publications,
    recentCount: json.summary?.recent_count ?? 0,
  };
}

/** The current projection of one Public or Unlisted publication. */
export function fetchPublication(id: string, signal?: AbortSignal): Promise<PublicPublication> {
  return getJson<PublicPublication>(`/public/publications/${encodeURIComponent(id)}`, signal);
}
