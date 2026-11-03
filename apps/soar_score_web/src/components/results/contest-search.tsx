"use client";

import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import { ExternalLink } from "@/components/external-link";
import { fetchPublicationList } from "@/lib/results/api";
import {
  filtersAreEmpty,
  filtersFromQuery,
  filtersToQuery,
  listQuery,
  type ContestFilters,
} from "@/lib/results/contest-filters";
import { contestSummaryFrom, type ContestSummary } from "@/lib/results/contest-summary";
import { contestAppUrl } from "@/lib/site";

import { ContestRow } from "./contest-row";
import { FilterBar } from "./filter-bar";
import styles from "./results.module.css";
import { Skeleton } from "./skeleton";

/** Wait this long after the last keystroke before asking the server. */
const typingDelayMs = 250;

type State =
  | { kind: "loading" }
  | { kind: "loaded"; contests: ContestSummary[]; recentCount: number }
  | { kind: "failed"; message: string };

/**
 * Contest search at `/results/contests`: the filters live in the query, the
 * server filters, orders, caps and counts, and this page renders the answer
 * (#455).
 */
export function ContestSearch() {
  const router = useRouter();
  const pathname = usePathname();
  const query = useSearchParams();
  const filters = useMemo(() => filtersFromQuery(query), [query]);
  // Everything the request depends on, as one stable string.
  const requestKey = filtersToQuery(filters).toString();
  const [generation, setGeneration] = useState(0);
  // Keyed by the request and refresh generation so a change reads as
  // "loading" without a reset inside the effect.
  const key = `${requestKey}#${generation}`;
  const [loaded, setLoaded] = useState<{ key: string; state: State }>();
  const state: State = loaded?.key === key ? loaded.state : { kind: "loading" };
  // The filters of the last request sent: only a change to them is typing
  // worth waiting out; the first load and Refresh go straight out.
  const lastRequested = useRef<string>(undefined);

  useEffect(() => {
    const controller = new AbortController();
    const now = new Date();
    const params = listQuery(filtersFromQuery(new URLSearchParams(requestKey)), now);
    const typing = lastRequested.current !== undefined && lastRequested.current !== requestKey;
    const send = () => {
      lastRequested.current = requestKey;
      fetchPublicationList(params, controller.signal, generation > 0)
        .then(({ publications, recentCount }) => {
          const contests = publications.map((d) => contestSummaryFrom(d, now));
          setLoaded({ key, state: { kind: "loaded", contests, recentCount } });
        })
        .catch((e: unknown) => {
          if (controller.signal.aborted) return;
          setLoaded({
            key,
            state: { kind: "failed", message: e instanceof Error ? e.message : String(e) },
          });
        });
    };
    const timer = setTimeout(send, typing ? typingDelayMs : 0);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [key, requestKey, generation]);

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
    const listed = state.contests;
    const recent = state.recentCount;
    summary = (
      <p className={styles.summary}>
        <b>{recent}</b> {recent === 1 ? "contest" : "contests"} completed or in progress{" "}
        {filters.from || filters.to ? "within the selected time frame" : "in the last 30 days"}
      </p>
    );
    body =
      listed.length === 0 && filtersAreEmpty(filters) ? (
        <div className={`card ${styles.empty}`}>
          <h2>No contests published yet</h2>
          <p>
            Contests starting after this weekend are listed once you set an end date in the
            filters.
          </p>
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
