/**
 * Email and submission rules for the public support form (#220).
 *
 * The server repeats the email rule (validateSupportEmail in the API handlers),
 * so a direct POST is held to the same standard as the browser.
 */

/** The JSON body the form posts to `/api/public/support`. */
export type SupportRequestBody = {
  name: string;
  email: string;
  userType: string;
  requestType: string;
  message: string;
  captchaToken: string;
};

/** The endpoint, relative to the site so the same-origin proxy forwards it. */
export const supportEndpoint = "/api/public/support";

// Printable ASCII only; addresses with commas, semicolons, angle brackets or
// double quotes are refused because mail headers cannot carry them.
const printableAscii = /^[\x20-\x7e]*$/;
const emailShape =
  /^[A-Za-z0-9.!#$%&'*+\/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$/;

/**
 * The trimmed address when [raw] is one ASCII email address, else null.
 * Only ASCII spaces are trimmed. Unicode domains are refused, not converted.
 */
export function normalizeSupportEmail(raw: string): string | null {
  if (!printableAscii.test(raw)) return null;
  const trimmed = raw.replace(/^ +| +$/g, "");
  if (trimmed.length > 254) return null;
  return emailShape.test(trimmed) ? trimmed : null;
}

/** What the form does after a submission attempt. */
export type SubmitOutcome =
  /** Thanks: the server confirmed acceptance. */
  | { kind: "accepted" }
  /** Keep every field; the spent challenge must be replaced before a retry. */
  | { kind: "retry"; message: string; resetChallenge: boolean; waitSeconds?: number }
  /** The server could not confirm delivery; the message may have been sent. */
  | { kind: "unconfirmed" };

/**
 * Posts [body] and maps the response to an outcome. [fetcher] is injected so
 * tests can stub it. Only the exact success contract counts as accepted.
 */
export async function postSupport(
  fetcher: typeof fetch,
  body: SupportRequestBody,
): Promise<SubmitOutcome> {
  let response: Response;
  try {
    response = await fetcher(supportEndpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
  } catch {
    return { kind: "unconfirmed" };
  }

  if (response.status === 200) {
    try {
      const json = (await response.json()) as { accepted?: unknown };
      if (json.accepted === true) return { kind: "accepted" };
    } catch {
      // An unreadable success falls through to unconfirmed below.
    }
    return { kind: "unconfirmed" };
  }

  const code = await errorCode(response);
  switch (code) {
    case "captcha_invalid":
      return {
        kind: "retry",
        message: "The spam check did not pass. Complete it again and resubmit.",
        resetChallenge: true,
      };
    case "request_timeout":
      return {
        kind: "retry",
        message: "The request timed out. Complete the spam check again and resubmit.",
        resetChallenge: true,
      };
    case "rate_limited": {
      const waitSeconds = retryAfterSeconds(response);
      return {
        kind: "retry",
        message: waitSeconds
          ? `Too many requests. Wait ${waitSeconds} seconds before trying again.`
          : "Too many requests. Wait a few minutes before trying again.",
        resetChallenge: false,
        waitSeconds,
      };
    }
    case "delivery_unconfirmed":
      return { kind: "unconfirmed" };
    case "payload_too_large":
      return {
        kind: "retry",
        message: "The request is too long. Shorten the message and try again.",
        resetChallenge: false,
      };
    case "invalid_request":
      return {
        kind: "retry",
        message: "Check the highlighted fields and try again.",
        resetChallenge: false,
      };
    case "support_unavailable":
    default:
      return {
        kind: "retry",
        message: "Support requests are unavailable right now. Please try again later.",
        resetChallenge: true,
      };
  }
}

async function errorCode(response: Response): Promise<string | undefined> {
  try {
    const json = (await response.json()) as { error?: { code?: unknown } };
    const code = json.error?.code;
    return typeof code === "string" ? code : undefined;
  } catch {
    return undefined;
  }
}

function retryAfterSeconds(response: Response): number | undefined {
  const value = Number(response.headers.get("retry-after"));
  return Number.isFinite(value) && value > 0 ? Math.ceil(value) : undefined;
}
