"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { useWide } from "@/components/use-wide";

import styles from "./docs.module.css";
import { helpTopics } from "./topics";

/** The docs sub-navigation; a sidebar on desktop, a collapsed menu on a phone. */
export function DocsNav() {
  const pathname = usePathname();
  const wide = useWide();
  const current = (href: string) =>
    pathname === href || (href !== "/docs" && pathname.startsWith(`${href}/`))
      ? "page"
      : undefined;
  const item = (href: string, label: string) => (
    <li key={href}>
      <Link href={href} aria-current={current(href)}>
        {label}
      </Link>
    </li>
  );
  return (
    <nav aria-label="Documentation" className={styles.sidebar}>
      <details open={wide || undefined}>
        <summary>On this site</summary>
        <ul className={styles.navList}>{item("/docs", "Documentation and Help")}</ul>
        <div className={styles.navGroup}>
          <div className="eyebrow">Guides</div>
          <ul className={styles.navList}>
            {helpTopics.map((t) => item(t.href, t.label))}
            {item("/docs/participant-scoring/disciplines/f5j", "F5J quick reference")}
          </ul>
        </div>
        <div className={styles.navGroup}>
          <div className="eyebrow">Help</div>
          <ul className={styles.navList}>{item("/support", "Request Support")}</ul>
        </div>
      </details>
    </nav>
  );
}
