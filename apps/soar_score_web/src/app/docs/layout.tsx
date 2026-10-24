import type { ReactNode } from "react";

import styles from "@/components/docs/docs.module.css";
import { DocsNav } from "@/components/docs/docs-nav";

/** Reading layout for every /docs route: sub-navigation beside an article. */
export default function DocsLayout({ children }: { children: ReactNode }) {
  return (
    <div className={`wrap ${styles.layout}`}>
      <DocsNav />
      <article className={styles.article}>{children}</article>
    </div>
  );
}
