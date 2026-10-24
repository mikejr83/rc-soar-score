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

/** The Public publications, newest first. The server caps a page at 100. */
export async function fetchPublicationSummaries(
  signal?: AbortSignal,
): Promise<PublicPublicationSummary[]> {
  const json = await getJson<{ publications: PublicPublicationSummary[] }>(
    "/public/publications?limit=100",
    signal,
  );
  return json.publications;
}

/** The current projection of one Public or Unlisted publication. */
export function fetchPublication(id: string, signal?: AbortSignal): Promise<PublicPublication> {
  return getJson<PublicPublication>(`/public/publications/${encodeURIComponent(id)}`, signal);
}
