/**
 * Site-wide names and the addresses of the other parts of the suite.
 *
 * The hosts follow ADR 0003 (root for this site, `app.`, `score.` and `api.`
 * subdomains) and are overridden per deployment with `NEXT_PUBLIC_*`
 * variables, read at build time.
 */

export const siteName = "RC Soar Score";
export const tagline = "RC glider contest scoring";

const env = (name: string, fallback: string) =>
  process.env[name]?.trim() || fallback;

/** The API server; the results pages read `/public/publications` from it. */
export const apiBaseUrl = env(
  "NEXT_PUBLIC_SOAR_SCORE_API_BASE_URL",
  "http://localhost:8080",
);

/** The contest administration app. Login and registration go here (#464). */
export const contestAppUrl = env(
  "NEXT_PUBLIC_CONTEST_APP_URL",
  "https://app.rc-soar-score.com/",
);

/** The participant self-scoring app. */
export const selfScoreAppUrl = env(
  "NEXT_PUBLIC_SELF_SCORE_APP_URL",
  "https://score.rc-soar-score.com/",
);

/** The offline (Windows) application download. TODO(#222): the release page. */
export const downloadUrl = env(
  "NEXT_PUBLIC_DOWNLOAD_URL",
  "https://github.com/mikejr83/rc-soar-score/releases",
);

export const repositoryUrl = "https://github.com/mikejr83/rc-soar-score";

/** Header navigation, in order. Contests comes first on a phone. */
export const primaryNav = [
  { href: "/results/contests", label: "Contests" },
  { href: "/docs", label: "Docs" },
  { href: "/support", label: "Support" },
] as const;
