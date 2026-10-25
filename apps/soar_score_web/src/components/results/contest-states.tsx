"use client";

import Link from "next/link";
import { useEffect } from "react";

import { resultsPath } from "@/lib/results/paths";

import styles from "./results.module.css";

/** Unknown or delisted contest (plan/ui/public-site/contest-not-found.md). */
export function ContestNotFound() {
  return (
    <div className={`card ${styles.notice}`}>
      <p className="eyebrow">
        <b>Results</b> · Not found
      </p>
      <h1>Contest not found</h1>
      <p>The contest or its results could not be found. One of the following may have happened:</p>
      <ul>
        <li>The address may have been entered incorrectly.</li>
        <li>The contest may not have been published yet.</li>
        <li>The contest may have been removed at the direction of the contest director.</li>
      </ul>
      <div className={styles.actions}>
        <Link href={resultsPath} className="btn btn--primary">
          Search contests
        </Link>
        <Link href="/" className="btn btn--ghost">
          Home
        </Link>
      </div>
    </div>
  );
}

const recheckMinutes = 15;

/** Exists but is pending or private; re-checks every 15 minutes. */
export function ContestNotVisible({ onRecheck }: { onRecheck: () => void }) {
  useEffect(() => {
    const timer = setInterval(onRecheck, recheckMinutes * 60_000);
    return () => clearInterval(timer);
  }, [onRecheck]);
  return (
    <div className={`card ${styles.notice}`}>
      <p className="eyebrow">
        <b>Results</b> · Not shown
      </p>
      <h1>Contest not shown</h1>
      <p>
        This contest has pending results or has been marked private. It is not shown at this time. The
        contest will be shown after the final placing is announced and the contest director makes the
        results public or 48hrs after the last score entered.
      </p>
      <p>
        Please check back later. This page checks again every {recheckMinutes} minutes to see whether the
        contest has become public.
      </p>
      <div className={styles.actions}>
        <button type="button" className="btn btn--ghost" onClick={onRecheck}>
          Check now
        </button>
      </div>
    </div>
  );
}

export function ContestLoadFailed({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className={`card ${styles.failed}`} role="alert">
      <p>The contest could not be loaded: {message}</p>
      <button type="button" className="btn btn--primary" onClick={onRetry}>
        Try again
      </button>
    </div>
  );
}
