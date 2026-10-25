import Link from "next/link";
import type { ReactNode } from "react";

import styles from "./docs.module.css";
import type { Topic } from "./topics";

/** The unreviewed-content marker every help page carries until #165 closes. */
export function DraftNote() {
  return (
    <p className={styles.draft}>
      <span aria-hidden="true">✎</span> Draft, pending review (#165)
    </p>
  );
}

/** A labelled slot for a screenshot that has not been taken yet. */
export function FigurePlaceholder({
  caption,
  wide = false,
}: {
  caption: string;
  wide?: boolean;
}) {
  return (
    <figure className={`${styles.figure} ${wide ? styles["figure--wide"] : ""}`}>
      <div className={styles.figureBox} aria-hidden="true">
        Screenshot to come
      </div>
      <figcaption>Screenshot: {caption}</figcaption>
    </figure>
  );
}

export function Callout({ label, children }: { label: string; children: ReactNode }) {
  return (
    <aside className={styles.callout}>
      <div className="eyebrow">{label}</div>
      {children}
    </aside>
  );
}

/** The navigation cards shared by the docs landing and docs not-found pages. */
export function TopicCards({ topics }: { topics: Topic[] }) {
  return (
    <ul className={styles.cards}>
      {topics.map((t) => {
        const body = (
          <>
            <span className="eyebrow">
              {t.audience}
              {t.external ? " · external" : ""}
            </span>
            <strong>{t.label}</strong>
            <span>{t.description}</span>
          </>
        );
        return (
          <li key={t.href}>
            {t.external ? (
              <a className={styles.card} href={t.href} rel="noopener">
                {body}
              </a>
            ) : (
              <Link className={styles.card} href={t.href}>
                {body}
              </Link>
            )}
          </li>
        );
      })}
    </ul>
  );
}
