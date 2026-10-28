import Link from "next/link";

import { Reveal } from "@/components/reveal";
import { ExternalLink } from "@/components/external-link";
import { contestAppUrl, repositoryUrl } from "@/lib/site";

import styles from "./closing-cta.module.css";
import { SkyGlider } from "./sky-glider";

export function ClosingCta() {
  return (
    <section className={`${styles.cta} seams-host`} aria-labelledby="cta-title">
      <div className={`seams ${styles.seams}`} aria-hidden="true" />
      <SkyGlider className={styles.glider} />
      <div className="wrap">
        <Reveal className={styles.inner}>
          <p className={`stencil ${styles.round}`}>NEXT ROUND</p>
          <h2 id="cta-title" className={styles.title}>
            Ready when the wind is.
          </h2>
          <p className={styles.lede}>
            RC Soar Score is free and{" "}
            <ExternalLink href={repositoryUrl} destination="GitHub">open source</ExternalLink>, built by
            people who fly. Run your club&apos;s next F5J day on it, or follow one
            once its results are published.
          </p>
          <div className={styles.actions}>
            <ExternalLink href={contestAppUrl} className="btn btn--primary" destination="the contest app">
              Run a contest
            </ExternalLink>
            <Link href="/results/contests" className="btn btn--ghost btn--on-dark">
              Find a contest
            </Link>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
