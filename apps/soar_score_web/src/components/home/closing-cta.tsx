import Link from "next/link";

import { Reveal } from "@/components/reveal";
import { contestAppUrl, repositoryUrl } from "@/lib/site";

import styles from "./closing-cta.module.css";

export function ClosingCta() {
  return (
    <section className={styles.cta} aria-labelledby="cta-title">
      <div className={`seams ${styles.seams}`} aria-hidden="true" />
      <div className="wrap">
        <Reveal className={styles.inner}>
          <p className={`stencil ${styles.round}`}>NEXT ROUND</p>
          <h2 id="cta-title" className={styles.title}>
            Ready when the wind is.
          </h2>
          <p className={styles.lede}>
            RC Soar Score is free and open source, built by people who fly.
            Run your club&apos;s next F5J day on it, or follow one that is on
            now.
          </p>
          <div className={styles.actions}>
            <a href={contestAppUrl} className="btn btn--primary" rel="noopener">
              Run a contest
            </a>
            <Link href="/results/contests" className="btn btn--ghost btn--on-dark">
              Find a contest
            </Link>
            <a href={repositoryUrl} className="btn btn--ghost btn--on-dark" rel="noopener">
              Source on GitHub
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
