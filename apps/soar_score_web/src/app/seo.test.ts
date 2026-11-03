import { describe, expect, it } from "vitest";

import robots from "./robots";
import sitemap from "./sitemap";

describe("robots and sitemap", () => {
  it("blocks only the API proxy and links the sitemap", () => {
    const r = robots();
    expect(r.rules).toMatchObject({ allow: "/", disallow: "/api/" });
    expect(r.sitemap).toBe("https://rcsoarscore.com/sitemap.xml");
  });

  it("lists absolute canonical URLs on the apex host", () => {
    const urls = sitemap().map((e) => e.url);
    expect(urls).toContain("https://rcsoarscore.com");
    expect(urls).toContain("https://rcsoarscore.com/results/contests");
    expect(urls.every((u) => new URL(u).origin === "https://rcsoarscore.com")).toBe(true);
    expect(new Set(urls).size).toBe(urls.length);
  });
});
