import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const text = readFileSync(
  join(process.cwd(), "public/.well-known/security.txt"),
  "utf8",
);

describe("security.txt", () => {
  it("has the required fields", () => {
    expect(text).toMatch(/^Contact: .+/m);
    expect(text).toMatch(/^Expires: .+/m);
    expect(text).toMatch(/^Canonical: https:\/\/rcsoarscore\.com\/\.well-known\/security\.txt$/m);
  });

  it("has not expired and expires within a year", () => {
    const expires = new Date(/^Expires: (.+)$/m.exec(text)![1]);
    const now = Date.now();
    expect(expires.getTime()).toBeGreaterThan(now);
    expect(expires.getTime()).toBeLessThan(now + 366 * 24 * 3600 * 1000);
  });
});
