"use client";

import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useState } from "react";

import { ExternalLink } from "@/components/external-link";
import { fetchPublicationSummaries } from "@/lib/results/api";
import {
  filtersAreEmpty,
  filtersFromQuery,
  filtersMatch,
  filtersToQuery,
  type ContestFilters,
} from "@/lib/results/contest-filters";
import {
  activeInLast30Days,
  contestSummaryFrom,
  startsAfterComingSunday,
  type ContestSummary,
} from "@/lib/results/contest-summary";
import { contestAppUrl } from "@/lib/site";

import { ContestRow } from "./contest-row";
import { FilterBar } from "./filter-bar";
import styles from "./results.module.css";
import { Skeleton } from "./skeleton";

/** Number of contests listed when no filter is set. */
const defaultCount = 10;

type State =
  | { kind: "loading" }
  | { kind: "loaded"; contests: ContestSummary[]; now: Date }
  | { kind: "failed"; message: string };


/**
 * Contest search at `/results/contests`: the most recent contests, filters
 * carried in the query, a 30-day summary and Refresh. Ordering, filtering,
 * the coming-Sunday rule and the summary run client-side until #455.
 */
export function ContestSearch() {
  const router = useRouter();
  const pathname = usePathname();
  const query = useSearchParams();
  const filters = useMemo(() => filtersFromQuery(query), [query]);
  const [generation, setGeneration] = useState(0);
  // Keyed by the refresh generation so a refresh reads as "loading" without
  // a reset inside the effect.
  const [loaded, setLoaded] = useState<{ generation: number; state: State }>();
  const state: State = loaded?.generation === generation ? loaded.state : { kind: "loading" };

  useEffect(() => {
    const controller = new AbortController();
    fetchPublicationSummaries(controller.signal)
      .then((dtos) => {
        const now = new Date();
        const contests = dtos
          .map((d) => contestSummaryFrom(d, now))
          .sort((a, b) => b.start.getTime() - a.start.getTime());
        setLoaded({ generation, state: { kind: "loaded", contests, now } });
      })
      .catch((e: unknown) => {
        if (controller.signal.aborted) return;
        setLoaded({
          generation,
          state: { kind: "failed", message: e instanceof Error ? e.message : String(e) },
        });
      });
    return () => controller.abort();
  }, [generation]);

  const applyFilters = useCallback(
    (next: ContestFilters) => {
      const q = filtersToQuery(next).toString();
      router.replace(q ? `${pathname}?${q}` : pathname, { scroll: false });
    },
    [router, pathname],
  );

  let body;
  let summary;
  if (state.kind === "loaded") {
    const visible = state.contests.filter((c) => !startsAfterComingSunday(c, state.now));
    const matching = visible.filter((c) => filtersMatch(filters, c));
    const listed = filtersAreEmpty(filters) ? matching.slice(0, defaultCount) : matching;
    const recent = visible.filter((c) => activeInLast30Days(c, state.now)).length;
    summary = (
      <p className={styles.summary}>
        <b>{recent}</b> {recent === 1 ? "contest" : "contests"} completed or in progress in the
        last 30 days
      </p>
    );
    body =
      visible.length === 0 ? (
        <div className={`card ${styles.empty}`}>
          <h2>No contests published yet</h2>
          <p>
            Every contest a director publishes appears here: overall standings, team
            scores and every flight group, as of any round, open to anyone without an
            account. The first one could be yours.
          </p>
          <div className={styles.emptyActions}>
            <ExternalLink href={contestAppUrl} className="btn btn--primary" destination="the contest app">
              Run a contest
            </ExternalLink>
            <Link href="/docs/competitions" className="btn btn--ghost">
              Contest Director Getting Started
            </Link>
          </div>
        </div>
      ) : listed.length === 0 ? (
        <p className={`card ${styles.message}`}>No contests match these filters.</p>
      ) : (
        <ul className={`card ${styles.list}`}>
          {listed.map((c) => (
            <li key={c.publicationId}>
              <ContestRow contest={c} />
            </li>
          ))}
        </ul>
      );
  } else if (state.kind === "failed") {
    body = (
      <div className={`card ${styles.failed}`} role="alert">
        <p>Could not load contests: {state.message}</p>
        <button type="button" className="btn btn--primary" onClick={() => setGeneration((g) => g + 1)}>
          Try again
        </button>
      </div>
    );
  } else {
    body = <Skeleton rows={6} />;
  }

  return (
    <div className={`wrap ${styles.page}`}>
      <div className={styles.pageHead}>
        <div>
          <p className="eyebrow">
            <b>Results</b> · Published contests
          </p>
          <h1>Contests</h1>
          {summary}
        </div>
        <button
          type="button"
          className="btn btn--ghost"
          onClick={() => setGeneration((g) => g + 1)}
          disabled={state.kind === "loading"}
        >
          <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
            <path d="M13 8a5 5 0 1 1-1.5-3.6M13 2v3h-3" />
          </svg>
          Refresh
        </button>
      </div>
      <FilterBar filters={filters} onChange={applyFilters} />
      {body}
    </div>
  );
}
