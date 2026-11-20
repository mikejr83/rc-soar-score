import { describe, expect, test, vi } from "vitest";

import { normalizeSupportEmail, postSupport, supportEndpoint, type SupportRequestBody } from "./submit";

const body: SupportRequestBody = {
  name: "A Pilot",
  email: "pilot@example.test",
  userType: "Pilot",
  requestType: "Online Score Entry",
  message: "I cannot enter my score.",
  captchaToken: "fake-token",
};

function stub(status: number, json?: unknown, headers: Record<string, string> = {}) {
  return vi.fn(async () =>
    new Response(json === undefined ? null : JSON.stringify(json), {
      status,
      headers: { "content-type": "application/json", ...headers },
    }),
  ) as unknown as typeof fetch & ReturnType<typeof vi.fn>;
}

describe("normalizeSupportEmail", () => {
  test("accepts one ASCII address and trims ASCII spaces", () => {
    expect(normalizeSupportEmail("  pilot+x@example.com  ")).toBe("pilot+x@example.com");
    expect(normalizeSupportEmail("pilot@xn--bcher-kva.example")).toBe("pilot@xn--bcher-kva.example");
  });

  test("refuses Unicode, control characters and forbidden delimiters", () => {
    for (const raw of [
      "josé@example.com",
      "pilot@bücher.example",
      "pilot@example.com\n",
      "a,b@example.com",
      "a;b@example.com",
      "<a@example.com>",
      '"a"@example.com',
      "",
      "no-at-sign",
    ]) {
      expect(normalizeSupportEmail(raw), raw).toBeNull();
    }
  });
});

describe("postSupport", () => {
  test("posts the JSON body to the proxied endpoint", async () => {
    const fetcher = stub(200, { accepted: true });
    await postSupport(fetcher, body);
    expect(fetcher).toHaveBeenCalledWith(supportEndpoint, expect.objectContaining({ method: "POST" }));
    const init = (fetcher as unknown as { mock: { calls: [string, RequestInit][] } }).mock.calls[0][1];
    expect(JSON.parse(String(init.body))).toEqual(body);
    expect(supportEndpoint).toBe("/api/public/support");
  });

  test("only the exact success contract is accepted", async () => {
    expect(await postSupport(stub(200, { accepted: true }), body)).toEqual({ kind: "accepted" });
    expect((await postSupport(stub(200, {}), body)).kind).toBe("unconfirmed");
    expect((await postSupport(stub(200, { accepted: "yes" }), body)).kind).toBe("unconfirmed");
  });

  test("a network failure is unconfirmed", async () => {
    const fetcher = vi.fn(async () => {
      throw new TypeError("offline");
    }) as unknown as typeof fetch;
    expect((await postSupport(fetcher, body)).kind).toBe("unconfirmed");
  });

  test("delivery_unconfirmed is unconfirmed", async () => {
    const outcome = await postSupport(
      stub(503, { error: { code: "delivery_unconfirmed", message: "x" } }),
      body,
    );
    expect(outcome.kind).toBe("unconfirmed");
  });

  test("captcha_invalid asks for a fresh challenge", async () => {
    const outcome = await postSupport(stub(400, { error: { code: "captcha_invalid" } }), body);
    expect(outcome).toMatchObject({ kind: "retry", resetChallenge: true });
  });

  test("rate_limited shows the Retry-After wait and keeps the challenge", async () => {
    const outcome = await postSupport(
      stub(429, { error: { code: "rate_limited" } }, { "retry-after": "120" }),
      body,
    );
    expect(outcome).toMatchObject({ kind: "retry", resetChallenge: false, waitSeconds: 120 });
  });

  test("support_unavailable allows a retry with a new challenge", async () => {
    const outcome = await postSupport(stub(503, { error: { code: "support_unavailable" } }), body);
    expect(outcome).toMatchObject({ kind: "retry", resetChallenge: true });
  });

  test("a 408 asks for a fresh challenge", async () => {
    const outcome = await postSupport(stub(408, { error: { code: "request_timeout" } }), body);
    expect(outcome).toMatchObject({ kind: "retry", resetChallenge: true });
  });
});

describe("unrecognized failures", () => {
  test("a gateway 502 or 504 after a possible send is unconfirmed, not retry", async () => {
    for (const status of [502, 504]) {
      const gateway = new Response("<html>Bad gateway</html>", {
        status,
        headers: { "content-type": "text/html" },
      });
      const fetcher = vi.fn(async () => gateway) as unknown as typeof fetch;
      expect((await postSupport(fetcher, body)).kind, `HTTP ${status}`).toBe("unconfirmed");
    }
  });

  test("an unknown error code is unconfirmed", async () => {
    const outcome = await postSupport(stub(500, { error: { code: "internal_error" } }), body);
    expect(outcome.kind).toBe("unconfirmed");
  });
});
