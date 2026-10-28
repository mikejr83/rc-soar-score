import { readFileSync } from "node:fs";
import path from "node:path";

import styles from "@/components/docs/docs.module.css";
import { renderMarkdown } from "@/lib/markdown";

/** Renders a legal document from `src/content/legal/<name>.md`. */
export function LegalPage({ name }: { name: "privacy" | "terms" }) {
  const file = path.join(process.cwd(), "src", "content", "legal", `${name}.md`);
  const html = renderMarkdown(readFileSync(file, "utf8"));
  return (
    <div className="wrap wrap--narrow" style={{ paddingBlock: 40 }}>
      <article
        className={styles.article}
        // The source is a file in this repository, escaped by renderMarkdown.
        dangerouslySetInnerHTML={{ __html: html }}
      />
    </div>
  );
}
