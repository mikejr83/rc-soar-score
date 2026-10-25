import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = { title: "Page not found" };

/** Any unknown route: say what happened, offer Home, Contests and Docs. */
export default function NotFound() {
  return (
    <div className="wrap wrap--narrow section">
      <p className="eyebrow">
        <b>404</b> · Off course
      </p>
      <h1 style={{ marginTop: 12 }}>Page not found</h1>
      <p className="lede" style={{ marginTop: 16 }}>
        There is no page at this address. It may have moved, or the link may
        have been typed incorrectly.
      </p>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 12, marginTop: 28 }}>
        <Link href="/" className="btn btn--primary">
          Back to Home
        </Link>
        <Link href="/results/contests" className="btn btn--ghost">
          Find a contest
        </Link>
        <Link href="/docs" className="btn btn--ghost">
          Documentation
        </Link>
      </div>
    </div>
  );
}
