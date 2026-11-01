import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import licences from "@/content/licences.json";
import type { LicenceData } from "@/lib/licences";

import { OpenSourceView } from "./open-source-view";

const repo = "https://github.com/mikejr83/rc-soar-score";
const render = (commit?: string) =>
  renderToStaticMarkup(
    createElement(OpenSourceView, {
      data: licences as LicenceData,
      repositoryUrl: repo,
      commit,
    }),
  );

describe("OpenSourceView", () => {
  const html = render("0123456789abcdef");

  it("states our licences and links the source of this build", () => {
    expect(html).toContain("AGPL-3.0");
    expect(html).toContain("CC BY 4.0");
    expect(html).toContain(`${repo}/tree/0123456789abcdef`);
  });

  it("falls back to the repository when the commit is unknown", () => {
    expect(render()).not.toContain(`${repo}/tree/`);
  });

  it("has a section per product with the anchors the apps link to", () => {
    for (const id of ["contest-app", "self-scoring", "server", "public-site"]) {
      expect(html).toContain(`<section id="${id}"`);
    }
  });

  it("collapses entries with details and needs no script", () => {
    expect(html).toContain("<details");
    expect(html).toContain("<summary");
    expect(html).not.toContain("<script");
  });

  it("includes the licence text of every package", () => {
    expect(html).toContain("Permission is hereby granted, free of charge");
    expect(html).toContain("Apache License");
  });

  it("escapes licence text", () => {
    const evil = {
      schema: 1,
      inputs: {},
      texts: ["<script>alert(1)</script>"],
      products: [
        {
          id: "p",
          name: "P",
          summary: "",
          entries: [
            {
              name: "evil",
              version: "1",
              license: "MIT",
              homepage: "https://example.org",
              source: "npm" as const,
              texts: [0],
            },
          ],
        },
      ],
    };
    const out = renderToStaticMarkup(
      createElement(OpenSourceView, { data: evil, repositoryUrl: repo }),
    );
    expect(out).not.toContain("<script>");
    expect(out).toContain("&lt;script&gt;");
  });
});
