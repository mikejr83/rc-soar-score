import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";

import licences from "@/content/licences.json";
import {
  type LicenceData,
  fingerprint,
  sharedTexts,
} from "@/lib/licences";

const data = licences as LicenceData;
const repoRoot = path.resolve(process.cwd(), "..", "..");

describe("generated licence data", () => {
  it("has the four shipped products with stable ids", () => {
    expect(data.products.map((p) => p.id)).toEqual([
      "contest-app",
      "self-scoring",
      "server",
      "public-site",
    ]);
  });

  it("gives every entry a name, a licence, a home page and at least one text", () => {
    for (const product of data.products) {
      expect(product.entries.length).toBeGreaterThan(0);
      for (const e of product.entries) {
        expect(e.name, product.id).toBeTruthy();
        expect(e.license, e.name).toBeTruthy();
        expect(e.homepage, e.name).toMatch(/^https:\/\//);
        expect(["dart", "npm", "bundled"]).toContain(e.source);
        expect(e.texts.length, e.name).toBeGreaterThan(0);
        for (const i of e.texts) {
          expect(data.texts[i]?.trim().length, e.name).toBeGreaterThan(0);
        }
      }
    }
  });

  it("lists the production npm dependencies of the public site", () => {
    const site = data.products.find((p) => p.id === "public-site")!;
    const names = site.entries.map((e) => e.name);
    for (const dep of ["next", "react", "react-dom", "@vercel/analytics"]) {
      expect(names).toContain(dep);
    }
    // Development-only packages are not shipped.
    expect(names).not.toContain("vitest");
    expect(names).not.toContain("typescript");
  });

  it("lists the packages the Flutter apps ship and the Windows helpers", () => {
    const contest = data.products.find((p) => p.id === "contest-app")!;
    const names = contest.entries.map((e) => e.name);
    expect(names).toContain("go_router");
    expect(names.some((n) => n.startsWith("mdbtools"))).toBe(true);
    expect(names).not.toContain("melos");
  });

  it("is not stale: the lockfiles it was generated from still match", () => {
    // Fix with scripts/generate-licences.sh (or .ps1) and commit the result.
    for (const [file, expected] of Object.entries(data.inputs)) {
      const text = readFileSync(path.join(repoRoot, file), "utf8");
      expect(fingerprint(text), `${file} changed; regenerate the licences`).toBe(
        expected,
      );
    }
  });
});

describe("sharedTexts", () => {
  const long = "x".repeat(4000);
  const product = (texts: number[][]) => ({
    id: "p",
    name: "P",
    summary: "",
    entries: texts.map((t, n) => ({
      name: `e${n}`,
      version: "1",
      license: "L",
      homepage: "https://example.org",
      source: "dart" as const,
      texts: t,
    })),
  });

  it("returns long texts used by several entries", () => {
    expect(sharedTexts(product([[0], [0], [1]]), [long, long + "y"])).toEqual([0]);
  });

  it("keeps short texts inline", () => {
    expect(sharedTexts(product([[0], [0]]), ["short"])).toEqual([]);
  });
});

describe("fingerprint", () => {
  it("ignores CRLF and is 16 hex digits", () => {
    expect(fingerprint("a\r\nb")).toBe(fingerprint("a\nb"));
    expect(fingerprint("a")).toMatch(/^[0-9a-f]{16}$/);
  });
});
