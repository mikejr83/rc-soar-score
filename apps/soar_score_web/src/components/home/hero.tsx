import Link from "next/link";

import { ExternalLink } from "@/components/external-link";
import { contestAppUrl } from "@/lib/site";

import styles from "./hero.module.css";
import { WorkingTimeDial } from "./working-time-dial";

export function Hero() {
  return (
    <section className={`${styles.hero} seams-host`} aria-labelledby="hero-title">
      <div className={`seams ${styles.seams}`} aria-hidden="true" />
      <div className={`wrap ${styles.inner}`}>
        <div className={styles.copy}>
          <h1 id="hero-title" className={styles.title}>
            Contest scoring that keeps up with the field.
          </h1>
          <p className={styles.lede}>
            RC Soar Score runs the whole contest day for RC sailplane soaring:
            configure the event, draw the matrix, score every flight, and
            publish standings that pilots open on their phones between rounds.
          </p>
          <div className={styles.actions}>
            <Link href="/results/contests" className="btn btn--primary">
              Find a contest
            </Link>
            <ExternalLink href={contestAppUrl} className="btn btn--ghost btn--on-dark" destination="the contest app">
              Run a contest
            </ExternalLink>
          </div>
          <dl className={styles.facts}>
            <div>
              <dt>Disciplines</dt>
              <dd>F5J first, more to follow</dd>
            </div>
            <div>
              <dt>Runs on</dt>
              <dd>The web, or offline on Windows</dd>
            </div>
            <div>
              <dt>Results</dt>
              <dd>Public, round by round</dd>
            </div>
            <div>
              <dt>Copy</dt>
              <dd>Draft, pending review (#165)</dd>
            </div>
          </dl>
        </div>
        <div className={styles.instrument}>
          <WorkingTimeDial />
        </div>
      </div>
    </section>
  );
}
