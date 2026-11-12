import { describe, expect, it } from "vitest";

import nextConfig from "../../../next.config";
import { apiBaseUrl } from "@/lib/site";

/**
 * The public site reads the API through a same-origin rewrite (`/api/*`). The
 * API sets the cache policy (30-second `public` reads, `no-store` errors, #906)
 * and Next passes an upstream's headers through a rewrite untouched, so the
 * policy holds as long as this config adds none of its own. Checked by hand
 * against `next dev` with a stub upstream when the policy last changed.
 */
describe("the /api proxy (#906)", () => {
  it("forwards /api/* to the API server's root, path unchanged", async () => {
    const rewrites = (await nextConfig.rewrites?.()) as { source: string; destination: string }[];

    expect(apiBaseUrl).toBe("/api");
    expect(rewrites).toHaveLength(1);
    expect(rewrites[0].source).toBe("/api/:path*");
    expect(rewrites[0].destination).toMatch(/\/:path\*$/);
    // Public reads stay under /public on the upstream: nothing rewrites to /api/v1.
    expect(rewrites[0].destination).not.toContain("/api/v1");
  });

  it("sets no response headers of its own, so the API's cache policy stands", () => {
    expect(nextConfig.headers).toBeUndefined();
  });
});
