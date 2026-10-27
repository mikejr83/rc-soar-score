import { Reveal } from "@/components/reveal";

import styles from "./flight-plan.module.css";

const legs = [
  {
    n: "01",
    title: "Configure",
    copy: "Pick the discipline, the scoring options, drop rules and the landing table. Contest options are explained as you set them.",
  },
  {
    n: "02",
    title: "Register",
    copy: "Add pilots and their details from your own list. Build teams if the format has them.",
  },
  {
    n: "03",
    title: "Draw the matrix",
    copy: "Seeded groups, so every pilot meets every rival about as often, or a straight draw. Printed as a flight matrix so each pilot knows their group.",
  },
  {
    n: "04",
    title: "Fly and score",
    copy: "Officials enter scores per group, or pilots enter their own and the director checks them. Re-flights and penalties are handled, not fudged.",
  },
  {
    n: "05",
    title: "Publish",
    copy: "Standings go on this site round by round. Hide the overall results until the final flight if you want the drama.",
  },
] as const;

/**
 * A contest day as a flight plan. The glider follows the route as the
 * section scrolls through the viewport (CSS scroll-driven animation), bobbing
 * as if in lift while the dashes march like moving air; where scroll
 * timelines are unsupported it rests at the end of the route.
 */
export function FlightPlan() {
  return (
    <section className={`${styles.plan} section seams-host`} aria-labelledby="plan-title">
      <div className={`seams ${styles.seams}`} aria-hidden="true" />
      <div className="wrap">
        <Reveal className={styles.head}>
          <p className="eyebrow">
            <b>02</b> · Flight plan
          </p>
          <h2 id="plan-title">A contest day, start to finish.</h2>
        </Reveal>

        <div className={styles.route}>
          <svg className={styles.path} viewBox="0 0 1000 120" preserveAspectRatio="none" aria-hidden="true">
            <path
              className={styles.track}
              d="M0,100 C150,100 150,20 300,20 S450,100 600,100 S750,20 900,20 L1000,20"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeDasharray="6 8"
              pathLength="1000"
            />
            <g className={styles.glider}>
              <g className={styles.lift}>
                <path
                  d="M-30,-2 L-2,-5 L30,-12 L30,-9 L0,-1 L-2,1 L30,5 L30,8 L-2,1 L-30,-1 Z"
                  fill="var(--panel-accent)"
                />
              </g>
            </g>
          </svg>
          <ol className={styles.legs}>
            {legs.map((leg, i) => (
              <Reveal key={leg.n} as="li" className={styles.leg} delay={i * 80}>
                <span className={`stencil ${styles.n}`}>{leg.n}</span>
                <h3>{leg.title}</h3>
                <p>{leg.copy}</p>
              </Reveal>
            ))}
          </ol>
        </div>
      </div>
    </section>
  );
}
