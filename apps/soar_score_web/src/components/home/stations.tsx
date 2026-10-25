import Link from "next/link";

import { Reveal } from "@/components/reveal";
import { contestAppUrl, downloadUrl, selfScoreAppUrl } from "@/lib/site";

import styles from "./stations.module.css";

const stations = [
  {
    code: "CD",
    role: "Contest director",
    title: "Contest administration",
    copy: "Create the contest, set the rules, register pilots and teams, draw the matrix, enter official scores and publish. In the browser, or on a Windows laptop with no signal at the field.",
    links: [
      { href: contestAppUrl, label: "Open the app", external: true },
      { href: downloadUrl, label: "Windows download", external: true },
    ],
  },
  {
    code: "PLT",
    role: "Pilot and helper",
    title: "Self scoring",
    copy: "Enter your own flight from your phone: time, landing, launch height. See your group's preliminary scores as they land, and your place once the round is in.",
    links: [{ href: selfScoreAppUrl, label: "Enter my score", external: true }],
  },
  {
    code: "PUB",
    role: "Everyone",
    title: "Public results",
    copy: "Overall standings, team scores and every flight group, as of any round. No account needed. Share a link to a contest and it stays correct as rounds are published.",
    links: [{ href: "/results/contests", label: "Find a contest", external: false }],
  },
] as const;

export function Stations() {
  return (
    <section className="section" aria-labelledby="stations-title">
      <div className="wrap">
        <Reveal className={styles.head}>
          <p className="eyebrow">
            <b>01</b> · The flight deck
          </p>
          <h2 id="stations-title">One suite, three stations.</h2>
          <p className="lede">
            Each person at a contest gets the screen for their job. They all
            read and write the same contest, so nobody copies numbers twice.
          </p>
        </Reveal>
        <div className={styles.grid}>
          {stations.map((s, i) => (
            <Reveal key={s.code} as="article" className={`card ${styles.station}`} delay={i * 90}>
              <div className={styles.bezel}>
                <span className={`stencil ${styles.code}`}>{s.code}</span>
                <span className={styles.role}>{s.role}</span>
              </div>
              <h3>{s.title}</h3>
              <p className={styles.copy}>{s.copy}</p>
              <div className={styles.links}>
                {s.links.map((l) =>
                  l.external ? (
                    <a key={l.href} href={l.href} rel="noopener" className="btn btn--ghost btn--sm">
                      {l.label}
                    </a>
                  ) : (
                    <Link key={l.href} href={l.href} className="btn btn--ghost btn--sm">
                      {l.label}
                    </Link>
                  ),
                )}
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
