import Link from "next/link";

import { contestAppUrl, primaryNav, siteName } from "@/lib/site";

import { ExternalLink } from "./external-link";

import { BrandMark } from "./brand-logo";
import styles from "./site-header.module.css";

/**
 * The instrument-panel header shared by every page: the mark and name home
 * link, the primary navigation and the Sign in link out to the contest
 * administration app (the site has no sign-in of its own, #464).
 *
 * On a phone, Contests stays one tap away beside a native `<details>` menu
 * that needs no JavaScript.
 */
export function SiteHeader() {
  return (
    <header className={styles.header}>
      <a href="#main" className={styles.skip}>
        Skip to content
      </a>
      <div className={`wrap ${styles.inner}`}>
        <Link href="/" className={styles.home} aria-label={`${siteName} home`}>
          <BrandMark size={36} decorative />
          <span className={styles.wordmark}>
            <span className={styles.rc}>RC</span> Soar Score
          </span>
        </Link>

        <nav className={styles.nav} aria-label="Primary">
          <ul className={styles.links}>
            {primaryNav.map((item) => (
              <li key={item.href}>
                <Link href={item.href}>{item.label}</Link>
              </li>
            ))}
          </ul>
          <ExternalLink
            className={`btn btn--ghost btn--sm btn--on-dark ${styles.login}`}
            href={contestAppUrl}
            destination="the contest app"
          >
            Sign in
          </ExternalLink>
        </nav>

        <div className={styles.compact}>
          <Link href="/results/contests" className={`btn btn--ghost btn--sm btn--on-dark`}>
            Contests
          </Link>
          <details className={styles.menu}>
            <summary className={styles.menuButton} aria-label="Menu">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="M4 7h16M4 12h16M4 17h16" />
              </svg>
            </summary>
            <nav aria-label="Primary, compact" className={styles.sheet}>
              <ul>
                <li>
                  <Link href="/">Home</Link>
                </li>
                {primaryNav.map((item) => (
                  <li key={item.href}>
                    <Link href={item.href}>{item.label}</Link>
                  </li>
                ))}
                <li>
                  <ExternalLink href={contestAppUrl} destination="the contest app">
                    Sign in or register
                  </ExternalLink>
                </li>
              </ul>
            </nav>
          </details>
        </div>
      </div>
    </header>
  );
}
