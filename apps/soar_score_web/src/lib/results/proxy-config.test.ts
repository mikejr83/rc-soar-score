import { type ChildProcess, spawn } from "node:child_process";
import { createServer, type Server } from "node:http";
import { type AddressInfo, createServer as createNetServer } from "node:net";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import nextConfig from "../../../next.config";

/**
 * The public site reads the API through a same-origin rewrite (`/api/*`). The
 * API sets the cache policy (30-second `public` reads, `no-store` errors,
 * #906) and the rewrite must pass status, headers and body through untouched.
 * These tests run the real Next.js server against a stub upstream and ask it
 * through `/api`, the way a browser does.
 */

const visibleBody = JSON.stringify({ publication_id: "visible", scores: [] });
const forbiddenBody = JSON.stringify({ error: { code: "contest_not_visible", message: "hidden" } });
const notFoundBody = JSON.stringify({ error: { code: "not_found", message: "unknown" } });

const upstreamPaths: string[] = [];

function freePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const server = createNetServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address() as AddressInfo;
      server.close(() => resolve(port));
    });
  });
}

let upstream: Server;
let next: ChildProcess;
let site: string;

beforeAll(async () => {
  upstream = createServer((request, response) => {
    upstreamPaths.push(request.url ?? "");
    const reply = (status: number, cache: string, body: string) => {
      response.writeHead(status, {
        "content-type": "application/json",
        "cache-control": cache,
        "x-robots-tag": "noindex, nofollow",
      });
      response.end(body);
    };
    if (request.url?.endsWith("/visible")) reply(200, "public, max-age=30", visibleBody);
    else if (request.url?.endsWith("/hidden")) reply(403, "no-store", forbiddenBody);
    else reply(404, "no-store", notFoundBody);
  });
  await new Promise<void>((resolve) => upstream.listen(0, "127.0.0.1", resolve));
  const upstreamPort = (upstream.address() as AddressInfo).port;

  const port = await freePort();
  site = `http://127.0.0.1:${port}`;
  next = spawn(process.execPath, ["node_modules/next/dist/bin/next", "dev", "-p", String(port)], {
    env: { ...process.env, SOAR_SCORE_API_URL: `http://127.0.0.1:${upstreamPort}`, NEXT_TELEMETRY_DISABLED: "1" },
    stdio: "ignore",
  });

  // Ready once the proxy answers; the first request compiles the config.
  const deadline = Date.now() + 90_000;
  for (;;) {
    try {
      await fetch(`${site}/api/public/publications/visible`);
      return;
    } catch {
      if (Date.now() > deadline) throw new Error("next dev did not start");
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }
}, 120_000);

afterAll(() => {
  next?.kill();
  upstream?.close();
});

describe("the /api proxy (#906)", () => {
  it("passes a shown publication through: status, cache policy, headers, body", async () => {
    const response = await fetch(`${site}/api/public/publications/visible`);

    expect(response.status).toBe(200);
    expect(response.headers.get("cache-control")).toBe("public, max-age=30");
    expect(response.headers.get("x-robots-tag")).toBe("noindex, nofollow");
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
    expect(response.headers.get("referrer-policy")).toBe("strict-origin-when-cross-origin");
    expect(response.headers.has("set-cookie")).toBe(false);
    expect(await response.text()).toBe(visibleBody);
    expect(upstreamPaths).toContain("/public/publications/visible");
  });

  it("passes a not-visible 403 through uncached, with the same body", async () => {
    const response = await fetch(`${site}/api/public/publications/hidden`);

    expect(response.status).toBe(403);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(response.headers.has("set-cookie")).toBe(false);
    expect(await response.text()).toBe(forbiddenBody);
  });

  it("passes an unknown 404 through uncached, and differs from the 403 only by its body", async () => {
    const response = await fetch(`${site}/api/public/publications/unknown`);

    expect(response.status).toBe(404);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(await response.text()).toBe(notFoundBody);
  });

  it("does not override the API's headers on the rewrite", async () => {
    const rules = nextConfig.headers ? await nextConfig.headers() : [];
    const own = rules.flatMap((rule) => rule.headers.map((header) => header.key.toLowerCase()));
    // The API sets these (#906); the site's security headers must not.
    for (const key of ["cache-control", "x-robots-tag", "content-type", "set-cookie"]) {
      expect(own).not.toContain(key);
    }
  });
}, 30_000);
