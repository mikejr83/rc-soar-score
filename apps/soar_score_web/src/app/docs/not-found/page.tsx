import type { Metadata } from "next";
import Link from "next/link";

import { TopicCards } from "@/components/docs/bits";
import styles from "@/components/docs/docs.module.css";
import { landingLinks } from "@/components/docs/topics";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Page Not Found");

/** Any unknown route under /docs lands here (docs-help.md, "Not Found"). */
export default function DocsNotFoundPage() {
  return (
    <>
      <p className="eyebrow">
        <b>404</b> · Docs
      </p>
      <h1>Page Not Found</h1>
      <p className="lede">The documentation page you asked for does not exist.</p>

      <section className={`panel ${styles.trouble}`}>
        <h2>Are you having trouble?</h2>
        <p>
          If you have questions on functionality, are seeing errors, or have
          feature requests please go to our support page.
        </p>
        <Link href="/support" className="btn btn--primary">
          Go to the support page
        </Link>
      </section>

      <h2>Documentation</h2>
      <TopicCards topics={landingLinks} />
    </>
  );
}
