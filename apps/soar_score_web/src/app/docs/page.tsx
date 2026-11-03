import Link from "next/link";
import type { Metadata } from "next";

import { TopicCards } from "@/components/docs/bits";
import styles from "@/components/docs/docs.module.css";
import { landingLinks } from "@/components/docs/topics";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("Documentation and Help");

export default function DocsLandingPage() {
  return (
    <>
      <p className="eyebrow">
        <b>Docs</b> · Help for directors, pilots and spectators
      </p>
      <h1>Documentation and Help</h1>
      <p className="lede">
        Short guides for the three things people come here to do: run a
        contest, enter a score and find a result.
      </p>

      <h2>Getting started</h2>
      <ol>
        <li>
          <strong>Watching a contest?</strong> You need nothing. Open{" "}
          <Link href="/results/contests">Contests</Link>, find the event and bookmark
          it; the address keeps the round you are looking at.
        </li>
        <li>
          <strong>Flying in one?</strong> Your contest director sends an
          invitation link by email or as a QR code at the field. Open it on your
          phone and keep it; it takes you back to your rounds all weekend. No
          account is needed.
        </li>
        <li>
          <strong>Running one?</strong> Sign in to the contest administration
          app, or download the Windows app for a field with no signal. Create the
          contest, add pilots, draw the matrix, score, publish.
        </li>
      </ol>

      <h2>Where to go</h2>
      <TopicCards topics={landingLinks} />

      <h2>Frequently asked questions</h2>
      <div className={styles.faq}>
        <details>
          <summary>Do I need an account to see results?</summary>
          <p>
            No. Published contests are public record and anyone can read them.
            Accounts are for contest directors who want their data backed up
            online and for pilots who want to be found by directors or follow
            their own placings.
          </p>
        </details>
        <details>
          <summary>Why does a contest say it is not shown yet?</summary>
          <p>
            Its results are pending or the director has marked it private. The
            contest appears after the final placing is announced and the
            director makes the results public, or 48 hours after the last score
            was entered. The page checks again every 15 minutes.
          </p>
        </details>
        <details>
          <summary>The overall standings stopped moving but round scores keep coming in. Why?</summary>
          <p>
            The director has hidden overall results, usually before the last
            rounds to keep the finish interesting. Standings freeze at the round
            they were hidden; flight-group scores still update. Hiding ends when
            the director turns it off, the contest completes, or 24 hours pass.
          </p>
        </details>
        <details>
          <summary>What does a struck-through round score mean?</summary>
          <p>
            That round was dropped from the pilot&apos;s total under the
            contest&apos;s drop rules. In a flight-group table a struck-through
            score is a flight that was replaced by a re-flight.
          </p>
        </details>
        <details>
          <summary>I lost my invitation link.</summary>
          <p>
            Ask your contest director to send it again. The same link keeps
            working until the director issues a new one, so the one in your
            email or camera roll is still good.
          </p>
        </details>
      </div>
    </>
  );
}
