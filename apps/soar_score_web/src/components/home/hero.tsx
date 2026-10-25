import Link from "next/link";

import { contestAppUrl, selfScoreAppUrl } from "@/lib/site";

import styles from "./hero.module.css";
import { WorkingTimeDial } from "./working-time-dial";

export function Hero() {
  return (
    <section className={`${styles.hero} seams-host`} aria-labelledby="hero-title">
      <div className={`seams ${styles.seams}`} aria-hidden="true" />
      <div className={`wrap ${styles.inner}`}>
        <div className={styles.copy}>
          <p className="eyebrow">
            <b>RC</b> Glider contest scoring
          </p>
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
            <a href={contestAppUrl} className="btn btn--ghost btn--on-dark" rel="noopener">
              Run a contest
            </a>
            <a href={selfScoreAppUrl} className="btn btn--ghost btn--on-dark" rel="noopener">
              Enter my score
            </a>
          </div>
          <dl className={styles.facts}>
            <div>
              <dt>Disciplines</dt>
              <dd>F5J first, more to follow</dd>
            </div>
            <div>
              <dt>Works</dt>
              <dd>Online, or offline on Windows</dd>
            </div>
            <div>
              <dt>Results</dt>
              <dd>Public, round by round</dd>
            </div>
          </dl>
        </div>
        <div className={styles.instrument}>
          <WorkingTimeDial />
        </div>
      </div>
      <div className={styles.scrollHint} aria-hidden="true">
        <span />
      </div>
    </section>
  );
}
