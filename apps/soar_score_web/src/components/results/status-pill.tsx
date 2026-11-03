import type { ContestStatus } from "@/lib/results/contest-summary";

/** Upcoming / In progress / Completed, as text plus an icon (never colour alone). */
export function StatusPill({ status }: { status: ContestStatus }) {
  if (status === "completed") {
    return (
      <span className="pill pill--done">
        <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
          <path d="M3 8.5 6.5 12 13 4.5" />
        </svg>
        Completed
      </span>
    );
  }
  if (status === "upcoming") {
    return (
      <span className="pill pill--soon">
        <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
          <circle cx="8" cy="8" r="5.5" />
          <path d="M8 5v3.2l2 1.3" />
        </svg>
        Upcoming
      </span>
    );
  }
  return (
    <span className="pill pill--live">
      <svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
        <path d="M4 2.5v11l9-5.5z" />
      </svg>
      In progress
    </span>
  );
}
