import Link from "next/link";

import {
  contestAppUrl,
  repositoryUrl,
  selfScoreAppUrl,
  siteName,
  tagline,
} from "@/lib/site";

import { BrandMark } from "./brand-logo";
import styles from "./site-footer.module.css";

export function SiteFooter() {
  return (
    <footer className={styles.footer}>
      <div className={`wrap ${styles.inner}`}>
        <div className={styles.brand}>
          <BrandMark size={32} decorative />
          <div>
            <div className={styles.name}>{siteName}</div>
            <div className={styles.tagline}>{tagline}</div>
          </div>
        </div>

        <nav aria-label="Footer" className={styles.cols}>
          <div>
            <div className="eyebrow">Site</div>
            <ul>
              <li>
                <Link href="/results/contests">Contests</Link>
              </li>
              <li>
                <Link href="/docs">Documentation</Link>
              </li>
              <li>
                <Link href="/support">Support</Link>
              </li>
            </ul>
          </div>
          <div>
            <div className="eyebrow">Apps</div>
            <ul>
              <li>
                <a href={contestAppUrl} rel="noopener">
                  Contest administration
                </a>
              </li>
              <li>
                <a href={selfScoreAppUrl} rel="noopener">
                  Enter my score
                </a>
              </li>
              <li>
                <a href={repositoryUrl} rel="noopener">
                  Source on GitHub
                </a>
              </li>
            </ul>
          </div>
        </nav>

        <p className={styles.legal}>
          © {new Date().getFullYear()} {siteName}. Published results are a
          public record; see a contest director to correct a score.
        </p>
      </div>
    </footer>
  );
}
