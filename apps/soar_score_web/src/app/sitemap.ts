import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/site";

/**
 * The static pages. Individual contests are not listed: results are dynamic
 * and a contest only becomes public when its director publishes it, so the
 * listing page is the entry point (#679).
 */
const paths = [
  "/",
  "/results/contests",
  "/docs",
  "/docs/competitions",
  "/docs/contests-and-scores",
  "/docs/participant-scoring",
  "/docs/participant-scoring/disciplines/f5j",
  "/docs/user-accounts",
  "/support",
  "/open-source",
  "/privacy",
  "/terms",
];

export default function sitemap(): MetadataRoute.Sitemap {
  return paths.map((path) => ({
    url: path === "/" ? siteUrl : `${siteUrl}${path}`,
  }));
}
