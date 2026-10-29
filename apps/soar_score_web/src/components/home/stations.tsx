import Link from "next/link";

import { ExternalLink } from "@/components/external-link";
import { Reveal } from "@/components/reveal";
import { contestAppUrl, downloadUrl } from "@/lib/site";

import styles from "./stations.module.css";

const stations = [
  {
    code: "CD",
    role: "Contest director",
    title: "Contest administration",
    status: null,
    copy: "Create the contest, set the rules, register pilots and teams, draw the matrix, enter official scores and publish. In the browser, or on a Windows laptop with no signal at the field. The Windows build is an alpha.",
    links: [
      { href: contestAppUrl, label: "Run a contest", external: "the contest app" },
      { href: downloadUrl, label: "Windows alpha download", external: "the GitHub releases page" },
    ],
  },
  {
    code: "PLT",
    role: "Pilot and helper",
    title: "Self scoring",
    status: "Coming",
    copy: "Enter your own flight from your phone: time, landing, launch height. See your group's preliminary scores as they land, and your place once the round is in. You will get there from the invitation your director sends.",
    // No link until invitations exist (#589); a pilot reaches it from the invitation, not from here.
    links: [],
  },
  {
    code: "PUB",
    role: "Everyone",
    title: "Public results",
    status: null,
    copy: "Overall standings, team scores and every flight group, as of any round. No account needed. Share a link to a contest and it stays correct as rounds are published.",
    links: [{ href: "/results/contests", label: "Find a contest", external: null }],
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
              <div className={styles.titleRow}>
                <h3>{s.title}</h3>
                {s.status && (
                  <span className={`pill ${styles.status}`}>
                    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                      <circle cx="8" cy="8" r="6" />
                      <path d="M8 4.5V8l2.5 1.5" />
                    </svg>
                    {s.status}
                  </span>
                )}
              </div>
              <p className={styles.copy}>{s.copy}</p>
              {s.links.length > 0 && (
                <div className={styles.links}>
                  {s.links.map((l) =>
                    l.external ? (
                      <ExternalLink key={l.href} href={l.href} className="btn btn--ghost btn--sm" destination={l.external}>
                        {l.label}
                      </ExternalLink>
                    ) : (
                      <Link key={l.href} href={l.href} className="btn btn--ghost btn--sm">
                        {l.label}
                      </Link>
                    ),
                  )}
                </div>
              )}
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
