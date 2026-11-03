import { describe, expect, it } from "vitest";

import { pageMetadata } from "./page-metadata";

describe("pageMetadata", () => {
  it("repeats the page title and description into share tags", () => {
    const m = pageMetadata("Contests", "Find a contest.");
    expect(m.title).toBe("Contests");
    expect(m.openGraph).toMatchObject({
      title: "Contests · RC Soar Score",
      description: "Find a contest.",
    });
    expect(m.twitter).toMatchObject({ description: "Find a contest." });
  });

  it("keeps the share image and falls back to the site description", () => {
    const m = pageMetadata("Support");
    expect(JSON.stringify(m.openGraph)).toContain("/brand/share-image.png");
    expect(m.description).toMatch(/^Scoring and management/);
  });
});
