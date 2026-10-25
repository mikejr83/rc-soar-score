import Link from "next/link";

import { Reveal } from "@/components/reveal";

import { CountUp } from "./count-up";
import styles from "./score-anatomy.module.css";

/**
 * What an F5J flight score is made of, with made-up example numbers. The
 * component bars grow in as they scroll into view; the place card's score
 * counts up like an altimeter settling.
 */
export function ScoreAnatomy() {
  return (
    <section className="section" aria-labelledby="anatomy-title">
      <div className={`wrap ${styles.grid}`}>
        <Reveal className={styles.copy}>
          <p className="eyebrow">
            <b>03</b> · Anatomy of a score
          </p>
          <h2 id="anatomy-title">Every point, accounted for.</h2>
          <p className="lede">
            An F5J flight is scored from three things, and the site shows each
            of them so a pilot can see exactly where the points went.
          </p>
          <dl className={styles.parts}>
            <Reveal as="div" className={styles.part} delay={0}>
              <dt>
                <span>Flight time</span>
                <span className="num">9:58 of 10:00</span>
              </dt>
              <dd>
                <span className={styles.bar} style={{ "--w": "95%" } as React.CSSProperties} />
                Points for every second flown, up to the working time; past it
                and the penalty starts.
              </dd>
            </Reveal>
            <Reveal as="div" className={styles.part} delay={100}>
              <dt>
                <span>Landing</span>
                <span className="num">35 cm · 50 pts</span>
              </dt>
              <dd>
                <span className={styles.bar} style={{ "--w": "62%" } as React.CSSProperties} />
                Bonus points by distance to the spot, from the contest&apos;s
                landing table.
              </dd>
            </Reveal>
            <Reveal as="div" className={styles.part} delay={200}>
              <dt>
                <span>Launch height</span>
                <span className="num">118 m · −59 pts</span>
              </dt>
              <dd>
                <span className={`${styles.bar} ${styles.barPenalty}`} style={{ "--w": "38%" } as React.CSSProperties} />
                Half a point per metre of launch height, and three points a
                metre above 200 m. Lower launches cost less.
              </dd>
            </Reveal>
          </dl>
          <p className={styles.note}>
            Scores are normalised within a flight group, so the best flight of
            the group scores 1000 and the rest are a share of it.{" "}
            <Link href="/docs/participant-scoring/disciplines/f5j">Read the F5J quick reference</Link>
          </p>
        </Reveal>

        <Reveal className={`panel ${styles.place}`} delay={150}>
          <p className="eyebrow">Your place after round 4</p>
          <p className={`stencil ${styles.big}`}>3rd</p>
          <p className={styles.score}>
            <CountUp value={3941.8} decimals={1} className="num" /> pts
          </p>
          <p className={styles.behind}>45.6 points behind 1st. Best landing so far: 50.</p>
          <ul className={styles.rounds} aria-label="Round scores">
            {[
              ["R1", "1000"],
              ["R2", "987.4"],
              ["R3", "954.4", "dropped"],
              ["R4", "1000"],
            ].map(([r, s, dropped]) => (
              <li key={r} className={dropped ? styles.dropped : undefined}>
                <span className={styles.roundLabel}>{r}</span>
                <span className="num">
                  {s}
                  {dropped && <span className="visually-hidden"> (dropped)</span>}
                </span>
              </li>
            ))}
          </ul>
          <p className={styles.example}>Example numbers</p>
        </Reveal>
      </div>
    </section>
  );
}
