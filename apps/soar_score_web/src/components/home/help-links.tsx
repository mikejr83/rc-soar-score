import Link from "next/link";

import { Reveal } from "@/components/reveal";

import styles from "./help-links.module.css";

const topics = [
  {
    who: "Director",
    title: "Contest Director Getting Started",
    copy: "From an empty contest to published results, on the web or offline.",
    href: "/docs/competitions",
  },
  {
    who: "Pilot",
    title: "Help Me Enter My Score",
    copy: "Entering your flight from your phone, and what the director's options change.",
    href: "/docs/participant-scoring",
  },
  {
    who: "Everyone",
    title: "I Need An Account?",
    copy: "Who needs one, who does not, and how to register.",
    href: "/docs/user-accounts",
  },
  {
    who: "Everyone",
    title: "Finding Contests and Results",
    copy: "Searching for a contest and reading the three results views.",
    href: "/docs/contests-and-scores",
  },
] as const;

export function HelpLinks() {
  return (
    <section className={`section ${styles.help}`} aria-labelledby="help-title">
      <div className="wrap">
        <Reveal className={styles.head}>
          <p className="eyebrow">
            <b>04</b> · Pre-flight check
          </p>
          <h2 id="help-title">Answers before you ask.</h2>
          <p className="lede">
            Short guides for each seat at the contest. If they do not cover it,
            the support page does.
          </p>
        </Reveal>
        <ul className={styles.grid}>
          {topics.map((t, i) => (
            <Reveal key={t.href} as="li" delay={i * 70}>
              <Link href={t.href} className={`card ${styles.topic}`}>
                <span className="eyebrow">{t.who}</span>
                <span className={styles.title}>{t.title}</span>
                <span className={styles.copy}>{t.copy}</span>
                <span className={styles.arrow} aria-hidden="true">
                  →
                </span>
              </Link>
            </Reveal>
          ))}
        </ul>
        <Reveal className={styles.support} delay={300}>
          <Link href="/support" className="btn btn--ghost">
            Request support
          </Link>
          <Link href="/docs" className="btn btn--ghost">
            All documentation
          </Link>
        </Reveal>
      </div>
    </section>
  );
}
