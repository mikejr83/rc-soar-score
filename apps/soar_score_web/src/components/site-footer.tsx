import Link from "next/link";

import {
  companyName,
  contestAppUrl,
  repositoryUrl,
  siteName,
  tagline,
} from "@/lib/site";

import { ExternalLink } from "./external-link";
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
                <ExternalLink href={contestAppUrl} destination="the contest app">
                  Contest administration
                </ExternalLink>
              </li>
              <li>
                <ExternalLink href={repositoryUrl} destination="GitHub">
                  Source on GitHub
                </ExternalLink>
              </li>
            </ul>
          </div>
        </nav>

        <p className={styles.legal}>
          © {new Date().getFullYear()} {companyName}, Mike Gardner. Site design credits: Mason Beard. Published results are a
          public record. To correct a score, contact the contest director, or{" "}
          <Link href="/support">request support</Link>.
        </p>
      </div>
    </footer>
  );
}
