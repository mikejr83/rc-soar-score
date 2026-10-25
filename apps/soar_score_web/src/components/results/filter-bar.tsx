"use client";

import {
  emptyFilters,
  filtersAreEmpty,
  formatDay,
  type ContestFilters,
} from "@/lib/results/contest-filters";

import { useWide } from "@/components/use-wide";

import styles from "./results.module.css";

/**
 * Name, venue and start-date range over the contest list. Collapsed behind a
 * native <details> on a phone, inline on a desktop (CSS hides the summary).
 */
export function FilterBar({
  filters,
  onChange,
}: {
  filters: ContestFilters;
  onChange: (filters: ContestFilters) => void;
}) {
  const wide = useWide();
  const set = Object.values(filters).filter((v) => v !== "" && v !== undefined).length;
  const day = (value: string) => {
    if (!value) return undefined;
    const [y, m, d] = value.split("-").map(Number);
    return new Date(y, m - 1, d);
  };
  return (
    <details className={styles.filters} open={wide || set > 0 || undefined}>
      <summary>
        <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true" width="16" height="16">
          <path d="M2 4h12M4.5 8h7M7 12h2" />
        </svg>
        Filters
        {set > 0 && <span className={styles.count}>{set}</span>}
      </summary>
      <div className={styles.filterGrid}>
        <div className="field">
          <label htmlFor="filter-name">Name</label>
          <input
            id="filter-name"
            className="input"
            type="search"
            value={filters.name}
            onChange={(e) => onChange({ ...filters, name: e.target.value })}
          />
        </div>
        <div className="field">
          <label htmlFor="filter-venue">Venue</label>
          <input
            id="filter-venue"
            className="input"
            type="search"
            value={filters.venue}
            onChange={(e) => onChange({ ...filters, venue: e.target.value })}
          />
        </div>
        <div className="field">
          <label htmlFor="filter-from">Starts from</label>
          <input
            id="filter-from"
            className="input"
            type="date"
            value={filters.from ? formatDay(filters.from) : ""}
            onChange={(e) => onChange({ ...filters, from: day(e.target.value) })}
          />
        </div>
        <div className="field">
          <label htmlFor="filter-to">Starts to</label>
          <input
            id="filter-to"
            className="input"
            type="date"
            value={filters.to ? formatDay(filters.to) : ""}
            onChange={(e) => onChange({ ...filters, to: day(e.target.value) })}
          />
        </div>
        {!filtersAreEmpty(filters) && (
          <button type="button" className="btn btn--ghost" onClick={() => onChange(emptyFilters)}>
            Clear
          </button>
        )}
      </div>
    </details>
  );
}
